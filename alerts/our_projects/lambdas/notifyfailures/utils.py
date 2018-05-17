#!/usr/bin/env python
# -*- coding: utf-8 -*-
''' This module defines utilities for the notifyfailures lambda
'''

import os
import json
import time
import datetime
import hashlib
import requests
import boto3
import yaml

PD_API_KEY = os.environ.get('pd_api_key', 'REDACRED')
EMAIL_ADDRS = os.environ.get('email_addresses', 'devops@example.com')
REGISTERED_ADDR = os.environ.get('registered_address', 'offhours@example.com')
TIMEZONE = os.environ.get('default_tz', 'US/Pacific')
ENABLE_OFFHOURS = os.environ.get('ENABLE_OFFHOURS')
ALERTS_DEFS = 'https://documents.example.com/Alert+Definitions'

def timezone_now():
    ''' Figure out what time it is in the TIMEZONE timezone
        Return a datetime object
    '''
    os.environ.putenv('TZ', TIMEZONE)
    time.tzset()
    return datetime.datetime.fromtimestamp(time.mktime(time.localtime()))

#pylint: disable=too-few-public-methods
class Service(object):
    ''' Abstract service providing shared functionality to subclasses
    '''
    def __init__(self):
        ''' Set up standard links inherent to all alerts
        '''
        self._links = [{'href': ALERTS_DEFS,
                        'text': 'Alert Definitions Doc'}]
    @property
    def links(self):
        ''' Propertize self._links
        '''
        return self._links
    @links.setter
    def links(self, lst):
        ''' Allow setting of links
            Positional Argumens:
                lst -- list of dicts of links with key:value -> href:text
        '''
        self._links = lst

#pylint: disable=too-few-public-methods
class PDService(Service):
    ''' Subclass of Service abstracting PagerDuty service
        Intentionally limited to sending POSTs for event creation
    '''
    def __init__(self, apikey):
        ''' Initialize

            Positional Arguments:
                apikey -- Integration key required for POSTing to PagerDuty api
        '''
        super().__init__()
        self._apikey = apikey
        self._url = 'https://events.pagerduty.com/v2/enqueue'
        self._params = {'routing_key': self._apikey,
                        'event_action': 'trigger',
                        'payload': {'summary': None,
                                    'source': 'Failure Analytics Lambda',
                                    'severity': None,
                                    'custom_details': None}}
        self._headers = {'Content-Type': 'application/json'}
    @staticmethod
    def dedup_key(data):
        ''' Create a dedup_key for Events to stack up the same category of failures from the same
            Job on the same Jenkins environment

            Positional Arguments:
                data -- Dictionary of additional data to provide in incident
        '''
        fmt = '{tag}:{gen_host}:{category}'
        bytestring = bytes(fmt.format(tag=data['tag'],
                                      gen_host=data['gen_host'],
                                      category=data['category']),
                           'utf-8')
        return hashlib.sha512(bytestring).hexdigest()
    def send_request(self, summary, severity, data):
        ''' Send a POST to PagerDuty's event API endpoint, creating an
            event with the provided description, severity, and extra data.

            Positional Arguments:
                summary -- Incident description
                severity -- info, warning, critical, or error
                data -- Dictionary of additional data to provide in incident
            Returns a requests.Response object
        '''
        self._params['payload']['summary'] = summary
        self._params['payload']['severity'] = severity
        self._params['payload']['custom_details'] = data
        self._params['links'] = self.links
        self._params['dedup_key'] = self.dedup_key(data)
        return requests.post(self._url,
                             data=json.dumps(self._params),
                             headers=self._headers)

class EmailService(Service):
    ''' Subclass of Service abstracting emails as a notification.
        Use this class/service when there is nobody on-call in PagerDuty to
        avoid losing awareness of failures
    '''
    def __init__(self):
        ''' Initialize the service
        '''
        super().__init__()
        self._addresses = os.environ.get('email_addresses', EMAIL_ADDRS)
        self._registered_sender = (os
                                   .environ
                                   .get('registered_sender', REGISTERED_ADDR))
    def send_request(self, summary, severity, data):
        ''' Send an email to configured address(es) with information that
            normally would be sent to PagerDuty.

            Positional Arguments:
                summary -- Incident description
                severity -- info, warning, critical, or error
                data -- Dictionary of additional data to provide in incident
        '''
        client = boto3.client('ses', 'us-west-2')
        subject = 'Off-hours failure from PROJECT'
        msg = ('<p>{severity} alert from PROJECT</p><p>{summary}</p>'
               .format(summary=summary,
                       severity=severity.capitalize()))
        msg += '<pre>' + yaml.dump(data, default_flow_style=False) + '</pre>'
        for link in self.links:
            msg += '<a href="{href}">{text}</a>'.format(href=link['href'],
                                                        text=link['text'])
        email_dict = {'Source': self._registered_sender,
                      'Destination':{'ToAddresses': ','.split(self._addresses)},
                      'Message':{'Subject': {'Data': subject,
                                             'Charset': 'utf-8'},
                                 'Body': {'Html': {'Data': msg,
                                                   'Charset': 'utf-8'}}},
                      'Tags':[{'Name': 'project-off-hours-alert',
                               'Value': self._addresses}]}
        client.send_email(**email_dict)

class ServiceChooser(object):
    ''' Abstract the choice of notification service.
        Supports PagerDuty and chooses between integration keys
        Supports Email for off-hours notifications
            PagerDuty does not support off-hours notifications for Basic Plans
    '''
    def __init__(self):
        ''' Initialize the choices
        '''
        self._prodkey = PD_API_KEY
        self._testkey = os.environ.get('test_pd_api_key', PD_API_KEY)
    @property
    def testkey(self):
        ''' Propertize the test key
        '''
        return self._testkey
    @property
    def prodkey(self):
        ''' Propertize the prod key
        '''
        return self._prodkey
    @classmethod
    def genhost_endswithtest(cls, genhost):
        ''' Choose API key based on whether genhost ends with 'test'

            Positional Arguments:
                genhost -- string value, should be obtained from Lambda
                payload, sourced from Fluentd logging agent which turns
                hostname into gen_host tag

            Returns PDService object
        '''
        choice = cls()
        # Get shortname in case it's an fqdn
        genhost_short = genhost.split('.')[0]
        print('Choosing PD API key based on whether gen_host ends with \
"test": gen_host=%s, prod_key=%s, test_key=%s' % (genhost,
                                                  choice.prodkey,
                                                  choice.testkey))
        key = {True: choice.testkey,
               False: choice.prodkey}[genhost_short.endswith('test')]
        # is it after-hours?
        now = timezone_now()
        after_hours = (True if (now.hour >= 17 or now.hour < 8 or
                                now.weekday() in [5, 6])
                       and ENABLE_OFFHOURS
                       else False)
        return EmailService() if after_hours else PDService(key)
