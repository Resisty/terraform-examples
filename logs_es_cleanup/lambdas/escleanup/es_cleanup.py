#!/usr/bin/python
# -*- coding: utf-8 -*-
"""
This AWS Lambda function allowed to delete the old Elasticsearch index
Lovingly stolen from: https://github.com/cloudreach/aws-lambda-es-cleanup
"""
import logging
import datetime
import re
import es_base

LOGGER = logging.getLogger()
LOGGER.setLevel(logging.INFO)

#pylint: disable=unused-argument
def lambda_handler(event, context):
    """Main Lambda function
    Args:
        event (dict): AWS Cloudwatch Scheduled Event
        context (object): AWS running context
    Returns:
        None
    """
    escleanup = es_base.ESCleanup()
    # Index cutoff definition, remove older than this date
    earliest_to_keep = (datetime.date.today()
                        - datetime.timedelta(days=int(escleanup
                                                      .cfg["delete_after"])))
    LOGGER.info('earliest to keep is %s', earliest_to_keep)
    # We're looking for index formats resembling prefix-2017-12-01[-12]
    pat = re.compile(r'(\d{4})[-\.](\d{2})[-\.](\d{2})([-\.]\d{2})?')
    for index in escleanup.get_indices():
        matching = re.search(pat, index['index'])
        if index["index"] == ".kibana" or not matching:
            # ignore .kibana index
            continue
        # Drop the date string
        idx = index['index'].replace(matching.group(), '')
        # Drop any dangling separators
        if idx.endswith('-') or idx.endswith('.'):
            idx = idx[:-1]
        LOGGER.debug(idx)
        if idx in escleanup.cfg['index'] or 'all' in escleanup.cfg['index']:
            idx_date = (datetime
                        .date(*[int(matching.groups()[i])
                                for i in range(3)]))
            if idx_date <= earliest_to_keep:
                LOGGER.info("Deleting index: %s", index["index"])
                escleanup.delete_index(index["index"])
