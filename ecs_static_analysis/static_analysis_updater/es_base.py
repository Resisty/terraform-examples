#!/usr/bin/python
# -*- coding: utf-8 -*-
"""
This is a base class for 2 other lambda functions
Remixed and lovingly stolen from https://github.com/cloudreach/aws-lambda-es-cleanup
"""
import urllib
import json
import time
import os
import logging
from botocore.auth import SigV4Auth
from botocore.awsrequest import AWSRequest
from botocore.credentials import create_credential_resolver
from botocore.session import get_session
from botocore.vendored.requests import Session

LOGGER = logging.getLogger()
LOGGER.setLevel(logging.INFO)


class ESException(Exception):
    """Exception capturing status_code from Client Request"""
    status_code = 0
    payload = ""

    def __init__(self, status_code, payload):
        self.status_code = status_code
        self.payload = payload
        Exception.__init__(self,
                           "ESException: status_code={}, payload={}".format(
                               status_code, payload))

#pylint: disable=too-few-public-methods
class ESRequest(object):
    ''' Abstraction for a request made to ElasticSearch
    '''
    def __init__(self):
        self.cfg = {}
        self.cfg["es_endpoint"] = os.environ.get("es_endpoint", None)
        self._index = self.cfg["index"] = os.environ.get("index", "logs")
        self._es_type = self.cfg["type"] = os.environ.get("type",
                                                          "static-analysis")
        self.cfg["es_max_retry"] = int(os.environ.get("es_max_retry", 3))
        self._method = 'GET'
        self._headers = {}

        if not self.cfg["es_endpoint"]:
            raise Exception("[es_endpoint] OS variable is not set")

    @property
    def index(self):
        ''' Propertize the ElasticSearch index
        '''
        return self._index
    @index.setter
    def index(self, idx):
        ''' Allow override of ElasticSearch index
        '''
        self._index = idx

    @property
    def es_type(self):
        ''' Propertize the ElasticSearch _type
        '''
        return self._es_type
    @es_type.setter
    def es_type(self, idx):
        ''' Allow override of ElasticSearch _type
        '''
        self._es_type = idx

    @property
    def method(self):
        ''' Propertize the default HTTP method
        '''
        return self._method
    @method.setter
    def method(self, meth):
        ''' Allow override of default HTTP method
        '''
        self._method = meth

    @property
    def headers(self):
        ''' Propertize the default HTTP headers
        '''
        return self._headers
    @headers.setter
    def headers(self, headers_dict):
        ''' Allow override of default HTTP headers
        '''
        self._headers.update(headers_dict)

    def send_to_es(self,
                   path="/",
                   method=None,
                   payload=None,
                   extra_headers=None):
        """Low-level POST data to Amazon Elasticsearch Service generating a Sigv4 signed request

        Args:
            path (str): path to send to ES
            method (str, optional): HTTP method default:GET
            payload (dict, optional): additional payload used during POST or PUT

        Returns:
            dict: json answer converted in dict

        Raises:
            #: Error during ES communication
            ESException: Description
        """
        # resolve default kwargs
        payload = payload or {}
        extra_headers = extra_headers or {}
        if not path.startswith("/"):
            path = "/" + path
        method = method if method else self.method
        es_region = self.cfg["es_endpoint"].split(".")[1]

        # send to ES with exponential backoff
        retries = 0
        while retries < int(self.cfg["es_max_retry"]):
            if retries > 0:
                seconds = (2**retries) * .1
                # print('Waiting for %.1f seconds', seconds)
                time.sleep(seconds)

            extra_headers.update({"Host": self.cfg["es_endpoint"]})
            req = AWSRequest(method=method,
                             url=('https://%s%s?pretty&format=json'
                                  % (self.cfg['es_endpoint'],
                                     urllib.parse.quote(path))),
                             data=payload,
                             headers=extra_headers)
            credential_resolver = create_credential_resolver(get_session())
            credentials = credential_resolver.load_credentials()
            SigV4Auth(credentials, 'es', es_region).add_auth(req)

            try:
                preq = req.prepare()
                session = Session()
                res = session.send(preq)
                if res.status_code >= 200 and res.status_code <= 299:
                    LOGGER.debug("%s %s", res.status_code, res.content)
                    return json.loads(res.content)
                else:
                    LOGGER.debug("%s %s", res.status_code, res.content)
                    raise ESException(res.status_code, res.content)

            except ESException as err:
                if (err.status_code >= 500) and (err.status_code <= 599):
                    retries += 1  # Candidate for retry
                else:
                    raise  # Stop retrying, re-raise exception
    def get(self):
        ''' Obtain paginated results matching everything from index
        '''
        data = {'size': 1000,
                'from': 0,
                'query': {'match_all': {}
                         }
               }
        path = '/%s/%s/_search' % (self._index, self._es_type)
        records = []
        while True:
            payload = json.dumps(data)
            try:
                result = self.send_to_es(path=path,
                                         method='POST',
                                         payload=payload)
            except ESException as err:
                if 'no such index' in str(err):
                    LOGGER.info('Index %s not found, no previous records to \
obtain.', self._index)
                    return []
                else:
                    raise
            ids = [i for i in result['hits']['hits']]
            records += ids
            LOGGER.info('Obtained %s records from index %s',
                        len(records),
                        self._index)
            data['from'] += len(ids)
            if len(records) >= result['hits']['total']:
                break
        LOGGER.info('Got a total of %s records from index %s',
                    len(records),
                    self._index)
        return records
