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
import boto3
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
        self.cfg["index"] = os.environ.get("index", "logs")
        self.cfg["es_max_retry"] = int(os.environ.get("es_max_retry", 3))

        if not self.cfg["es_endpoint"]:
            raise Exception("[es_endpoint] OS variable is not set")

    def send_to_es(self,
                   path="/",
                   method="GET",
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
                                     urllib.quote(path))),
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


class ESCleanup(ESRequest):
    ''' Subclass of ESRequest, specifically created to clean up ElasticSearch
    '''
    name = "lambda_es_cleanup"

    def __init__(self):
        ESRequest.__init__(self)
        self.report = []
        self.cfg["delete_after"] = int(os.environ.get("delete_after", 15))
        self.cfg["index_format"] = os.environ.get("index_format", "%Y-%m-%d-%H")
        self.cfg["sns_alert"] = os.environ.get("sns_alert", "")
        self.cfg["emergency_threshold"] = os.environ.get("emergency_threshold", 0.15)

    def send_error(self, msg):
        """Send SNS error

        Args:
            msg (str): error string

        Returns:
            None
        """
        _msg = "[%s] %s" % (self.name, msg)
        LOGGER.info(_msg)
        if self.cfg["sns_alert"] != "":
            sns_region = self.cfg["sns_alert"].split(":")[4]
            sns = boto3.client("sns", region_name=sns_region)
            _ = sns.publish(TopicArn=self.cfg["sns_alert"], Message=_msg)

    def delete_index(self, index_name):
        """ES DELETE specific index

        Args:
            index_name (str): Index name

        Returns:
            dict: ES answer
        """
        return self.send_to_es(index_name, "DELETE")

    def get_indices(self):
        """ES Get indices

        Returns:
            dict: ES answer
        """
        return self.send_to_es("/_cat/indices")
