#!/usr/bin/env python
''' Accept S3 notifications and, if applicable, notify SQS
'''

import os
import logging
import json
import pprint
import slackclient
import boto3

SQS_QUEUE = os.environ.get('SQS_QUEUE')
SLACK_TOKEN = os.environ.get('SLACK_TOKEN')
SLACK_CHANNEL = os.environ.get('SLACK_CHANNEL')
ICON_EMOJI = ':staticbot:'
SLACK_BOT = os.environ.get('slack_bot', 'DEVOPS_BOT')
SLACK_TEAM = os.environ.get('slack_team', 'OUR_TEAM')
LOGGER = logging.getLogger()
LOGGER.setLevel(logging.DEBUG)

#pylint: disable=unused-argument
def lambda_handler(event, context):
    ''' Main Lambda function
        Args:
            event (dict): AWS Cloudwatch alarm notification
            context (object): AWS running context
        Returns:
            None
    '''
    for record in event['Records']:
        LOGGER.info('Obtained record notification: %s', record)
        message = json.loads(record['Sns']['Message'])
        queuename = [i['value']
                     for i in message['Trigger']['Dimensions']
                     if i['name'] == 'QueueName'][0]
        sqsclient = boto3.client('sqs')
        queue_url = sqsclient.get_queue_url(QueueName=queuename)['QueueUrl']
        received = sqsclient.receive_message(QueueUrl=queue_url)
        messages = []
        for msg in received['Messages']:
            msg_body = msg['Body']
            try:
                msg_body = json.loads(msg_body)
                msg_body = pprint.pformat(msg)
            except json.decoder.JSONDecodeError:
                pass
            messages.append(msg_body)
        slacker = slackclient.SlackClient(SLACK_TOKEN)
        text = ('''The dead letter queue (%s) for the DevOps account has \
raised an alarm:
```
%s
```
Messages in queue:
```
%s
```
''' % (queuename,
       message['NewStateReason'],
       '\n'.join(messages)))
        response = slacker.api_call('chat.postMessage',
                                    team=SLACK_TEAM,
                                    botname=SLACK_BOT,
                                    as_user=False,
                                    channel=SLACK_CHANNEL,
                                    text=text,
                                    icon_emoji=ICON_EMOJI)
        LOGGER.info('Result of slack notification: "%s"', response)
