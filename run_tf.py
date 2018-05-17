#!/usr/bin/env python
''' Docstring
'''
import os
import argparse
import subprocess
import shlex
import re
import base64
import boto3
import yaml
SHARED_CREDS = os.path.expanduser('~/.aws/credentials')
REMOTE_CONFIG_BLOB = '''provider "aws" {
  version    = "~> 1.18"
  region     = "${var.aws_region}"
  access_key = "${var.aws_access_key_id}"
  secret_key = "${var.aws_secret_access_key}"
}
provider "null" {}
# UNFORTUNATELY THIS MUST BE HARDCODED
terraform {
  backend "s3" {
    bucket = "%s"
    key    = "states/logs/terraform.tfstate"
    region = "us-west-2"
  }
}'''


def update_remote_config(bucket):
    ''' Generate the remote_config.tf file
    '''
    contents = REMOTE_CONFIG_BLOB % bucket
    with open('remote_config.tf', 'w') as data:
        data.write(contents)

def proc_exec(cmd, printer=print):
    ''' Use subprocess to execute a command string
    '''

    if not printer:
        printer = lambda x: None
    printer('Executing: "%s"' % cmd)
    proc = subprocess.Popen(shlex.split(cmd),
                            stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT,
                            universal_newlines=True)
    while True:
        line = proc.stdout.readline()
        if not line:
            break
        printer(line.strip())

def run_tf(args):
    ''' Execute terraform with arguments
    '''
    if args.debug:
        os.environ['TF_LOG'] = 'debug'
    if re.match(r'apply', args.action, re.I):
        args.action = 'plan -input=false'
        tmp = ''.join([i for i in args.extra])
        args.extra += ' -out=tfplan'
        run_tf(args)
        args.action = 'apply -input=false'
        args.extra = ' tfplan' + tmp
    cmd = 'terraform %s %s' % (args.action, args.extra)
    proc_exec(cmd)

def docker_login(session):
    ''' Use boto3 session to give docker a login for pushing containers
    '''
    client = session.client('ecr')
    resp = client.get_authorization_token()
    token = resp['authorizationData'][0]['authorizationToken']
    address = resp['authorizationData'][0]['proxyEndpoint']
    user, password = base64.b64decode(token).decode('utf-8').split(':')
    cmd = ('''docker login -u %s -p %s %s'''
           % (user, password, address))
    proc_exec(cmd, printer=False)

def interpolate(value):
    ''' Turn lists and dicts into Terraform lists and maps
    '''
    if isinstance(value, list):
        retval = '''[%s]''' % ', '.join([interpolate(i) for i in value])
    elif isinstance(value, dict):
        retval = ('''{%s}'''
                  % ', '.join(['%s = %s' % (i, interpolate(j))
                               for i, j in value.items()]))
    else:
        retval = '"%s"' % value
    return retval

def create_vars(**kwargs):
    ''' Create terraform variables """dynamically"""
    '''
    with open('variables.yaml') as data:
        varsdict = yaml.load(data.read())
    varsdict.update(kwargs)
    contents = ''
    for key, value in varsdict.items():
        contents += '''%s = %s
''' % (key, interpolate(value))
    with open('terraform.tfvars', 'w') as data:
        data.write(contents)

def doit(args):
    ''' Do the thing:
        Gather access/secret keys and run terraform
    '''
    session = boto3.Session(profile_name=args.profile)
    os.environ['AWS_REGION'] = session.region_name
    os.environ['TF_VAR_aws_region'] = session.region_name
    creds = session.get_credentials()
    os.environ['AWS_ACCESS_KEY_ID'] = creds.access_key
    os.environ['TF_VAR_aws_access_key_id'] = creds.access_key
    os.environ['AWS_SECRET_ACCESS_KEY'] = creds.secret_key
    os.environ['TF_VAR_aws_secret_access_key'] = creds.secret_key
    docker_login(session)
    update_remote_config('%s-tf-state-bucket' % args.profile)
    create_vars(aws_region=session.region_name)
    run_tf(args)

def main():
    ''' Quick and dirty, make it good later
    '''
    parser = argparse.ArgumentParser('Run terraform here by profile name')
    parser.add_argument('-a', '--action',
                        default='plan',
                        help='Which Terraform action to perform')
    parser.add_argument('-e', '--extra',
                        type=str,
                        default='',
                        help='Extra terraform arguments, e.g. "-destroy \
                        -target RESOURCE_TYPE.NAME"')
    parser.add_argument('-d', '--debug',
                        action='store_true',
                        help='Enable TF_LOG=debug')
    parser.add_argument('profile',
                        default='default',
                        help='Name of the profile in %s to use for \
authenticating against AWS for Terraform' % SHARED_CREDS)
    parser.set_defaults(func=doit)
    args = parser.parse_args()
    args.func(args)

if __name__ == '__main__':
    main()
