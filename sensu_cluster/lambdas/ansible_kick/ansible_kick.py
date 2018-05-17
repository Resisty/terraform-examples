#!/usr/bin/env python
''' Accept S3 notifications and, if applicable, notify SQS
'''

import os
import logging
import base64
import io
import boto3
import paramiko

ASG_NAME = os.environ.get('ASG_NAME')
REGION = os.environ.get('REGION')
S3_OBJ_NAME = os.environ.get('S3_OBJ_NAME')
HOSTS_FILE = os.environ.get('HOSTS_FILE')
PLAYBOOK = os.environ.get('PLAYBOOK')
#pylint: disable=line-too-long
EC2_PEM = '''GIGANTIC_CIPHER'''

LOGGER = logging.getLogger()
LOGGER.setLevel(logging.INFO)

def kms_decrypt(ciphertext):
    ''' Use boto3's kms client to decrypt ciphertext

        Positional Arguments:
            ciphertext -- string to decrypt
    '''
    kms = boto3.client('kms', region_name=REGION)
    keystring = (kms
                 .decrypt(CiphertextBlob=base64
                          .b64decode(ciphertext))
                 .get('Plaintext')
                 .decode('utf-8'))
    return io.StringIO(keystring)

def sensu_instances():
    ''' Use boto3's ec2 client to look for ec2 instances, filtering by ASG name
        Returns all found instances' private ip address
    '''
    ec2 = boto3.client('ec2', region_name=REGION)
    filters = [{'Name': 'tag:aws:autoscaling:groupName',
                'Values': [ASG_NAME]}]
    data = ec2.describe_instances(Filters=filters)
    return [res['Instances'][0]['PrivateIpAddress']
            for res in data['Reservations']]

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
        if not key == S3_OBJ_NAME:
            LOGGER.debug('Object %s/%s does not fit whitelist ("%s"), \
ignoring.', bucket, key, S3_OBJ_NAME)
            continue
        ec2_instances = sensu_instances()

        for ipaddr in ec2_instances:
            ssh = paramiko.SSHClient()
            ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
            privkey = paramiko.RSAKey.from_private_key(kms_decrypt(EC2_PEM))
            ssh.connect(ipaddr, username='ubuntu', pkey=privkey)
            cmd_fmt = ('''export HOME=/root; /usr/local/bin/ansible-playbook'''
                       ''' -i {hosts} -c local {playbook} -s'''
                       ''' --extra-vars="var_region={region}"''')
            cmd = cmd_fmt.format(hosts=HOSTS_FILE,
                                 playbook=PLAYBOOK,
                                 region=REGION)
            LOGGER.info('About to run command: "%s"', cmd)
            stdin, stdout, stderr = ssh.exec_command(cmd)
            stdin.flush()
            for line in stdout.read().splitlines():
                LOGGER.info(line)
            for line in stderr.read().splitlines():
                LOGGER.error(line)
            ssh.close()
