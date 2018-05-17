#!/usr/bin/env bash

TAG_NAME="${nexus_tag_name}"
TAG_VALUE="${nexus_tag_value}"
TAG_NAME="$${TAG_NAME:-"aws:autoscaling:groupName"}"
TAG_VALUE="$${TAG_VALUE:-"nexus-repository-asg"}"
ALL_IPS=
AWS=/usr/local/bin/aws
for ipaddr in $($${AWS} ec2 describe-instances \
                --region us-west-2 \
                --filters "Name=tag:$${TAG_NAME},Values=$${TAG_VALUE}" \
                | grep PrivateIpAddress\" \
                | tr -s ' ' \
                | uniq \
                | cut -d '"' -f4);
do
    ALL_IPS="$${ALL_IPS} $${ipaddr}"
    curl -f $ipaddr:80 2>/dev/null 1>&2
    if [ 0 -eq $? ]
    then
        echo "Nexus EC2 instance $${ipaddr} is responding on port 80."
        exit 0
    fi
done
echo "No Nexus EC2 instances ($${ALL_IPS}) were found responding on port 80!"
exit 2


