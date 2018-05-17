#!/usr/bin/env python
''' Module for abstracting notifications to email or slack
'''

import logging
import re
import os
import io
import json
import boto3
# provided by AWS lambda
# pylint: disable=import-error
import slackclient
import yaml
import requests

LOGGER = logging.getLogger()
LOGGER.setLevel(logging.INFO)
REGISTERED_ADDR = os.environ.get('ses_registered_address', 'contact@example.com')
ICON_EMOJI = ':staticbot:'
SLACK_TOKEN = os.environ.get('slack_token')
SLACK_BOT = os.environ.get('slack_bot', 'DEVOPS_BOT')
SLACK_TEAM = os.environ.get('slack_team', 'OUR_TEAM')
AWS_REGION = os.environ.get('aws_region')
KIBANA_LINK = '''https://proxy.example.com/_plugin/kibana/app/kibana\
#/discover?_g=()&_a=(columns:!(_source),index:{index},interval:auto,query:\
(match_all:()),sort:!(_score,desc))'''

class Service(object):
    ''' Abstract service providing shared functionality to subclasses
    '''
    def __init__(self, who=None):
        ''' Set up information common to all notifications
        '''
        self._fixed = None
        self._new = None
        self._updated_lt = None
        self._updated_gt = None
        self._index = None
        self._msg = None
        self._who = who
    @property
    def fixed(self):
        ''' Propertize the fixed warnings
        '''
        return self._fixed
    @fixed.setter
    def fixed(self, fixes):
        ''' Allow fixed warnings to be overwritten
        '''
        self._fixed = fixes
    @property
    def new(self):
        ''' Propertize the new warnings
        '''
        return self._new
    @new.setter
    def new(self, news):
        ''' Allow new warnings to be overwritten
        '''
        self._new = news
    @property
    def updated_lt(self):
        ''' Propertize the updated_lt warnings
        '''
        return self._updated_lt
    @updated_lt.setter
    def updated_lt(self, updated_lts):
        ''' Allow updated_lt warnings to be overwritten
        '''
        self._updated_lt = updated_lts
    @property
    def updated_gt(self):
        ''' Propertize the updated_gt warnings
        '''
        return self._updated_gt
    @updated_gt.setter
    def updated_gt(self, updated_gts):
        ''' Allow updated_gt warnings to be overwritten
        '''
        self._updated_gt = updated_gts
    @property
    def index(self):
        ''' Propertize the index
        '''
        return self._index
    @index.setter
    def index(self, idx):
        ''' Allow index to be overwritten
        '''
        self._index = idx
    def report_identifier(self):
        ''' Obtain project and branch name from index name
            Assumes self.index was provided as matching r'[^_]+_.*'

            Return a descriptive string of project and branch if possible, or
            index and warning if not
        '''
        if not self.index:
            raise ValueError('Unable to determine index, project, and branch \
for report.')
        parts = self.index.split('_')
        try:
            return ('Project: %s and branch: %s'
                    % (parts[0], '_'.join(parts[1:])))
        except IndexError:
            return 'Index: %s' % self.index
    @property
    def who(self):
        ''' Propertize the recipient(s)
        '''
        return self._who

class SES(Service):
    ''' Subclass of Service, abstracting SES notifications
    '''
    def notify(self):
        ''' Use SES to notify interested parties about fixed/new warnings in
            static analysis

        '''
        if not self._who:
            # Nobody to notify
            return
        if (not self.new
                and not self.fixed
                and not self.updated_lt
                and not self.updated_gt):
            # Nothing to say
            return
        LOGGER.info('Notifying interested parties "%s" about recently fixed and \
    recently introduced warnings.', self.who)
        client = boto3.client('ses', region_name=AWS_REGION)
        subject = 'Static Analysis Report for %s' % self.report_identifier()
        msg = '<p>Warnings no longer found in static analysis:</p>'
        msg += ('<a href="%s">View index %s on kibana</a>'
                % (KIBANA_LINK.format(index=self.index), self.index))
        msg += '<pre>' + yaml.dump(self.fixed, default_flow_style=False) + '</pre>'
        msg += '<p>New warnings found in static analysis:</p>'
        msg += '<pre>' + yaml.dump(self.new, default_flow_style=False) + '</pre>'
        msg += '<p>Warnings occurring on multiple lines with fewer counts \
than last time:</p>'
        msg += '<pre>' + yaml.dump(self.updated_lt, default_flow_style=False) + '</pre>'
        msg += '<p>Warnings occurring on multiple lines with more counts \
than last time:</p>'
        msg += '<pre>' + yaml.dump(self.updated_gt, default_flow_style=False) + '</pre>'
        email_dict = {'Source': REGISTERED_ADDR,
                      'Destination':{'ToAddresses': self.who.split(',')},
                      'Message':{'Subject': {'Data': subject,
                                             'Charset': 'utf-8'},
                                 'Body': {'Html': {'Data': msg,
                                                   'Charset': 'utf-8'}}},
                      'Tags':[{'Name': 'static-analysis-report',
                               'Value': re.sub(r'\W+', '', self.index)}]}
        client.send_email(**email_dict)
class Slack(Service):
    ''' Sublcass of service, abstracting Slack notifications
    '''
    def notify(self):
        ''' Use Slack to notify interested parties about fixed/new warnings in
            static analysis
        '''
        if not SLACK_TOKEN:
            LOGGER.info('No slack token, unable to notify via slack.')
            return
        if (not self.new
                and not self.fixed
                and not self.updated_lt
                and not self.updated_gt):
            # Nothing to say
            return
        msg = 'Static Analysis Report for %s\n' % self.report_identifier()
        msg += 'Warnings no longer found in static analysis:\n'
        msg += yaml.dump(self.fixed, default_flow_style=False)
        msg += '\nNew warnings found in static analysis:\n'
        msg += yaml.dump(self.new, default_flow_style=False)
        msg += '\nWarnings occurring on multiple lines with fewer counts than \
last time:\n'
        msg += yaml.dump(self.updated_lt, default_flow_style=False)
        msg += '\nWarnings occurring on multiple lines with more counts than \
last time:\n'
        msg += yaml.dump(self.updated_gt, default_flow_style=False)
        fallback = ("View index %s on kibana: %s" % (self.index,
                                                     (KIBANA_LINK
                                                      .format(index=self.index))))
        link_text = ('<%s|View index %s on kibana>'
                     % (KIBANA_LINK.format(index=self.index),
                        self.index))
        attachments = [{"fallback": fallback,
                        "text": link_text}]
        client = slackclient.SlackClient(SLACK_TOKEN)
        req = requests.post('https://slack.com/api/files.upload',
                            data={'token': SLACK_TOKEN,
                                  'channels': [self.who],
                                  'title': 'Static Analysis Results'},
                            files={'file': io.BytesIO(msg.encode('utf-8'))})
        LOGGER.info('Result of slack file upload: "%s"', req.text)
        outtext = client.api_call("chat.postMessage",
                                  team=SLACK_TEAM,
                                  botname=SLACK_BOT,
                                  as_user=False,
                                  channel=self.who,
                                  attachments=json.dumps(attachments),
                                  icon_emoji=ICON_EMOJI)
        LOGGER.info('Result of slack notification: "%s"', outtext)
