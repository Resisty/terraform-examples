#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
This AWS Lambda function will generate a PagerDuty incident when it is
triggered, if it's able to.
'''

import base64
import json
import os

import utils

SPAN = 4 # Hardcoded here, related to ../../../analytics_sql/failures*.sql
         # which is/are deployed as this Lambda's Kinesis Analytics application
SEVERITY = os.environ.get('severity', 'critical')
KIBANA_SEARCH = '''/_plugin/kibana/app/kibana#/discover?_g=()&_a=\
(columns:!(_source),index:'*',interval:auto,query:(query_string:\
(query:'tag:%20%22{tag}%22')),sort:!(_score,desc))'''

def validate(data):
    ''' Validate that the data has the required information.
        If a key doesn't exist or its value is None (False is also a nonsense
        value for this purpose), raise a KeyError.

        Positional Arguments:
            data -- dict from Lambda payload
        Returns:
            2-tuple of summary, severity
        Side Effects:
            data -- adds 'links' key and Kibana search query value to data dict if at
                    all possible
    '''
    num = data['counter']
    job_id = data['job_id']
    tag = data['tag']
    threshold = data['threshold']
    if not any([num, job_id, tag, threshold]):
        raise KeyError('Data from Kinesis Analytics missing values!')
    project = tag.split('.')[0]
    summary = ('Project {proj} has had more than {thresh} failures occurred \
this last {span} hours: {num}!'
               .format(proj=project,
                       thresh=threshold,
                       span=SPAN,
                       num=num))
    return summary, SEVERITY

#pylint: disable=unused-argument
def lambda_handler(event, context):
    """Main Lambda function
    Args:
        event (dict): AWS Cloudwatch Scheduled Event
        context (object): AWS running context
    Returns:
        None
    """
    numrecords = len(event['Records'])
    for record in event['Records']:
        payload = base64.b64decode(record['kinesis']['data'])
        print("Decoded payload: %s" % payload)
        data = json.loads(payload)
        try:
            summary, severity = validate(data)
            service = utils.ServiceChooser.genhost_endswithtest(data['gen_host'])
            if data['counter'] > data['threshold']:
                proxy = os.environ.get('kibana_proxy')
                kibana_search = KIBANA_SEARCH.format(tag=data['tag'])
                service.links.append({'href': ('{proxy}{search}'
                                               .format(proxy=proxy,
                                                       search=kibana_search)),
                                      'text': 'Kibana Search'})
                service.send_request(summary, severity, data)
        except KeyError as err:
            ''' If we have a key error, the payload is missing something
                important. Send an error to PagerDuty.
            '''
            msg = 'Insufficient data! Raised KeyError: "{exc}" from Kinesis \
Analytics Data!'.format(exc=str(err))
            pagerduty = utils.ServiceChooser.genhost_endswithtest('')
            pagerduty.send_request(msg, 'critical', data)
    return ('Successfully processed {num} records.'
            .format(num=numrecords))
