#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
This module is intended to be invoked as the CMD of a docker container.

It will reach out to SQS for a record, use the record to pull down a file from
S3, and operate on the contents of that file to update ElasticSearch records.

If certain sentinel files exist, Slack and/or Email notifications will be
sent.
'''

import logging
import io
import re
import os
import tarfile
import threading
import json
import hashlib
import boto3

import utils
import notifiers
import es_base

LOGGER = logging.getLogger()
LOGGER.setLevel(logging.DEBUG)
LOGGER.addHandler(logging.StreamHandler())

REPORT_PAT = os.environ.get('report_pat', r'report-.*\.html')
CPPCHECK_PAT = os.environ.get('cppcheck_pat', r'scan-cppcheck.txt')
EMAIL_PAT = os.environ.get('email_pat', r'email.txt')
SLACK_PAT = os.environ.get('slack_pat', r'slack.txt')
CHUNK_SIZE = int(os.environ.get('chunk_size', 25))
SQS_QUEUE = os.environ.get('sqs_queue')
AWS_REGION = os.environ.get('aws_region')

def s3_tarball(record):
    ''' Look up and download the tarball from a single record coming from
        Lambda's event

        Positional Arguments:
            record -- dictionary comprising an s3 record from triggering Event
    '''
    s3client = boto3.client('s3', region_name=AWS_REGION)
    LOGGER.info('Got a record: %s', record)
    s3_obj = s3client.get_object(Bucket=record['s3']['bucket']['name'],
                                 Key=record['s3']['object']['key'])
    file_like_obj = io.BytesIO(s3_obj['Body'].read())
    return tarfile.open(fileobj=file_like_obj)

def get_from_tarball(tarball):
    ''' Obtain all HTML reports in tarball and create utils.HTMLWarnings from them
        The "files" in question are actually byte streams
        Also obtain sentinel file "email.txt" for SES targets

        Positional Arguments:
            tarball -- tarfile object

        Returns:
            warnings -- list of HTMLWarnings objects
            notifiers -- objects from subclasses of notifiers.Service()
    '''
    htmlwarnings, cppcheckwarnings = [], []
    emails = None
    notify_services = []
    for member in tarball.getmembers():
        if re.search(REPORT_PAT, member.name):
            LOGGER.info('Processing report file "%s"', member.name)
            member_bytes = tarball.extractfile(member)
            htmlwarnings.append(utils.HTMLWarnings(report_file=member_bytes,
                                                   name=member.name))
        if re.search(CPPCHECK_PAT, member.name):
            LOGGER.info('Processing cppcheck file "%s"', member.name)
            member_bytes = tarball.extractfile(member)
            cppcheckwarnings = [i for i in
                                utils.CPPWarnings(report_file=member_bytes,
                                                  name=member.name).analyze()]
        if re.search(EMAIL_PAT, member.name):
            LOGGER.info('Found SES targets file "%s"', member.name)
            email_bytes = tarball.extractfile(member)
            emails = email_bytes.read().decode('ascii').strip()
            notify_services.append(notifiers.SES(who=emails))
        if re.search(SLACK_PAT, member.name):
            LOGGER.info('Found Slack targets file "%s"', member.name)
            slack_bytes = tarball.extractfile(member)
            channel = slack_bytes.read().decode('ascii').strip()
            notify_services.append(notifiers.Slack(who=channel))
    return htmlwarnings, cppcheckwarnings, notify_services

def index_from_record(record):
    ''' Try to obtain the index to work against in ElasticSearch from the
        record's s3 object's key

        Positional Arguments:
            record -- dictionary comprising an s3 record from triggering Event
    '''
    # At the time of this writing, tarballs are expected to be generated from
    # triggered builds off of git branches and named accordingly
    # E.g. feature/BRANCH-0001 =>
    #      BRANCH-0001.tar.gz =>
    #      s3:///LeadingFolder/BRANCH-0001.tar.gz
    branchname = (record['s3']['object']['key']
                  .split('/')[-1]
                  .replace('.tar.gz', '')).lower()
    return branchname

def generate_id_from(data):
    ''' Use sha512 to generate a sufficiently unique ID for the JSON record
        being indexed by elasticsearch such that collisions are unlikely
        Note that by setting the id we are able to specify create-only-if-not-exist

        Positional Arguments:
            data -- dict HTMLWarnings().data
    '''
    bytestring = bytes(json.dumps(data), 'utf-8')
    return hashlib.sha512(bytestring).hexdigest()

def diff_records(requestor, warnings):
    ''' Check ElasticSearch index for any records which don't exist in current
        warnings. This implies that those records/warnings have been fixed.
        Also check for warnings which don't exist as ElasticSearch records.
        This imples that those warnings are new and should be created.

        Positional Arguments:
            requestor -- es_base.ESRequest object which allows us to obtain all
                relevant records
            warnings -- generator yielding dicts of static analysis warnings

        Returns:
            4-tuple -- list of record IDs, expected to be sha512 hashes of the records
                       list of warnings not in ElasticSearch yet
                       list of warnings with more counts of instances in the
                           same
                       list of warnings with fewer counts of instances in the
                           same file
    '''
    # Map IDs to warnings
    generated_warnings = {}
    for warning in warnings:
        if warning.uid not in generated_warnings:
            warning.data['count'] = 1
            generated_warnings[warning.uid] = warning
        else:
            generated_warnings[warning.uid].data['count'] += 1

    records = requestor.get()
    if not records:
        # The index doesn't exist or is empty
        # Return records (which is empty), the generated warnings, and no
        # updated warnings
        return records, list(generated_warnings.values()), [], []

    # Map IDs to records
    recorded_warnings = {}
    for record in records:
        warn = utils.HTMLWarnings.from_data(record)
        recorded_warnings[warn.uid] = warn

    # Subtract warning_ids from records to find any records that weren't raised
    # as a warning in most recent analysis
    fixed_warnings = list(set(recorded_warnings.keys())
                          - set(generated_warnings.keys()))
    # Obtain all warnings from map according to ID
    fixed_warnings = [recorded_warnings[i] for i in fixed_warnings]

    # Subtract records from warning_ids to find any warnings that were created
    # in most recent analysis
    new_warnings = list(set(generated_warnings.keys())
                        - set(recorded_warnings.keys()))
    # Obtain all warnings from map according to ID
    new_warnings = [generated_warnings[i] for i in new_warnings]

    # Warnings in common may have multiple instances in the same file, so save
    # those for updating from *the ones most recently generated*

    update_warnings = list(set(generated_warnings.keys())
                           & set(recorded_warnings.keys()))
    update_lt_warnings = []
    for i in update_warnings:
        if (generated_warnings[i].data['count'] <
                recorded_warnings[i].data['count']):
            LOGGER.debug('Found generated warning "%s" with fewer counts than \
last time "%s"',
                         generated_warnings[i].data,
                         recorded_warnings[i].data)
            update_lt_warnings.append(generated_warnings[i])
    update_gt_warnings = []
    for i in update_warnings:
        if (generated_warnings[i].data['count'] >
                recorded_warnings[i].data['count']):
            LOGGER.debug('Found generated warning "%s" with more counts than \
last time "%s"',
                         generated_warnings[i].data,
                         recorded_warnings[i].data)
            update_gt_warnings.append(generated_warnings[i])

    return fixed_warnings, new_warnings, update_lt_warnings, update_gt_warnings

#pylint: disable=too-many-arguments
def bulk_requests(requestor, path, es_type, chunk_data, action='create'):
    ''' Make bulk reqeusts to ElasticSearch

        Positional Arguments:
            requestor -- es_base.ESRequest object
            path -- URL to which to make request
            method -- HTTP verb to use in request, e.g. GET, PUT, POST, etc
            index -- ElasticSearch index to target
            es_type -- ElasticSearch type associated with index
            chunk_data -- Lists of HTMLWarnings objects to format into
                newline-delimited json
        Keyword Arguments:
            headers -- HTTP headers to clobber into a dict. Always uses at
                least {'Content-type': 'application/x-ndjson'}
            action -- One of ['create', 'update', 'delete']
    '''
    LOGGER.info('Started a thread for bulk action "%s" on %s items',
                action,
                len(chunk_data))
    if action == 'create':
        optfields = lambda x: x.data
    elif action == 'update':
        optfields = lambda x: {'doc': x.data, 'doc_as_upsert': True}
    else:
        optfields = lambda x: None
    payload = ''
    for warning in chunk_data:
        action_and_meta = {action: {'_index': requestor.index,
                                    '_type': es_type,
                                    '_id': warning.uid}}
        fields = optfields(warning)
        payload += '%s\n' % json.dumps(action_and_meta)
        payload += '%s\n' % json.dumps(fields) if fields else ''

    kwargs = {'path': path}
    if payload:
        kwargs['payload'] = payload
    LOGGER.info('Thread for bulk action "%s" on %s items has successfully \
massaged data, about to send request.',
                action,
                len(chunk_data))
    result = requestor.send_to_es(**kwargs)
    LOGGER.info('Got json response: "%s"', result)

def threadify_requests(requestor, warntype, action_warnings_map):
    ''' This function is basically a wrapper for threading bulk_requests()

        Positional Arguments:
            requestor -- ESRequest object to be used by thread target
            warntype -- ElasticSearch type, possibly multiple per index.
            action_warnings_map -- Map of actions to lists for iterating over
                multiple operations
    '''
    for action, warnings in action_warnings_map.items():
        LOGGER.info('Attempting to bulk %s %s new records',
                    action,
                    len(warnings))
        warnings_chunks = list(chunks(warnings, CHUNK_SIZE))
        threads = []
        for chunk in warnings_chunks:
            thread = threading.Thread(target=bulk_requests,
                                      args=[requestor,
                                            '_bulk',
                                            warntype,
                                            chunk],
                                      kwargs={'action': action})
            threads.append(thread)
            thread.start()
        for thread in threads:
            thread.join()

def chunks(lst, num):
    ''' Yield successive n-sized chunks from l.
    '''
    for i in range(0, len(lst), num):
        yield lst[i:i + num]

#pylint: disable=too-many-locals
def main():
    ''' Main function
    '''
    sqsclient = boto3.client('sqs', region_name=AWS_REGION)
    message = sqsclient.receive_message(QueueUrl=SQS_QUEUE)
    receipt = message['Messages'][0]['ReceiptHandle']
    record = json.loads(message['Messages'][0]['Body'])
    (htmlwarnings,
     cppcheckwarnings,
     notify_services) = get_from_tarball(s3_tarball(record))
    index = index_from_record(record)
    for warntype, warnings in {'clang': htmlwarnings,
                               'cppcheck': cppcheckwarnings}.items():
        requestor = es_base.ESRequest()
        requestor.method = 'POST'
        requestor.index = index
        requestor.es_type = warntype
        # Bulk ElasticSearch requests require an unusual json payload
        # Set header accordingly
        requestor.headers = {'Content-type': 'application/x-ndjson'}

        # Find any warnings from previous runs that no longer exist
        # meaning they've been fixed
        # Find any new warnings which do not yet exist in ES
        (fixed_recs,
         new_warnings,
         update_lt_warnings,
         update_gt_warnings) = diff_records(requestor,
                                            warnings)
         # List comprehensions are used here to reference each warning's .data
         # property sequentially, forcing .read() from the tarfile's contents.
         # Since the tarfile is not designed with multithreading/thread safety
         # in mind, these reads must happen in this way.
        LOGGER.info('Diff report: %s fixed records, %s new records to \
create, %s records with fewer counts, %s records with more counts.',
                    len([i.data for i in fixed_recs]),
                    len([i.data for i in new_warnings]),
                    len([i.data for i in update_lt_warnings]),
                    len([i.data for i in update_gt_warnings]))
        # reclaim memory if possible
        del warnings

        action_warnings_map = {'create': new_warnings,
                               'update': update_lt_warnings+update_gt_warnings,
                               'delete': fixed_recs}
        threadify_requests(requestor, warntype, action_warnings_map)

        # Notify interested parties about any fixed errors
        for notifier in notify_services:
            LOGGER.info('Sending notification via service object of type "%s" \
to "    %s"', type(notifier), notifier.who)
            notifier.fixed = [i.data for i in fixed_recs]
            notifier.new = [i.data for i in new_warnings]
            notifier.updated_lt = [i.data for i in update_lt_warnings]
            notifier.updated_gt = [i.data for i in update_gt_warnings]
            notifier.index = index
            notifier.notify()

    # Delete the message from SQS now that it's been handled
    sqsclient.delete_message(QueueUrl=SQS_QUEUE, ReceiptHandle=receipt)
    return 'Done processing s3 upload of static analysis.'

if __name__ == '__main__':
    main()
