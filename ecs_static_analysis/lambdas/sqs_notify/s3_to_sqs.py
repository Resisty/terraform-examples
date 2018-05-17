#!/usr/bin/env python
''' Accept S3 notifications and, if applicable, notify SQS
'''

import os
import logging
import json
import boto3

SQS_QUEUE = os.environ.get('SQS_QUEUE')
ECS_TASK = os.environ.get('ECS_TASK')
ECS_CLUSTER = os.environ.get('ECS_CLUSTER')
S3_KEY_SUFFIX_WHITELIST = os.environ.get('S3_KEY_SUFFIX_WHITELIST', '.tar.gz')
S3_KEY_SUFFIX_WHITELIST = S3_KEY_SUFFIX_WHITELIST.split(',')
LOGGER = logging.getLogger()
LOGGER.setLevel(logging.DEBUG)

#pylint: disable=unused-argument
def lambda_handler(event, context):
    ''' Main Lambda function
        Args:
            event (dict): AWS S3 notification
            context (object): AWS running context
        Returns:
            None
    '''
    for record in event['Records']:
        LOGGER.info('Obtained record notification: %s', record)
        bucket = record['s3']['bucket']['name']
        key = record['s3']['object']['key']
        if not any([i in key for i in S3_KEY_SUFFIX_WHITELIST]):
            LOGGER.debug('Object %s/%s does not fit whitelist ("%s"), \
ignoring.', bucket, key, S3_KEY_SUFFIX_WHITELIST)
            continue
        sqsclient = boto3.client('sqs')
        LOGGER.info('Sending record "%s" to SQS queue %s.', record, SQS_QUEUE)
        sqsclient.send_message(QueueUrl=SQS_QUEUE,
                               MessageBody=json.dumps(record))
        LOGGER.info('Notifying ECS task %s.', ECS_TASK)
        ecsclient = boto3.client('ecs')
        ecsclient.run_task(taskDefinition=ECS_TASK,
                           cluster=ECS_CLUSTER,
                           count=1)
