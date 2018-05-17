#!/bin/bash
# update limits
echo "root - nofile 65536" >> /etc/security/limits.conf

# make sure we can get pip
apt-get update
# get pip
apt-get install -y python3 \
    python3-pip \
    unzip \
    build-essential \
    zlib1g-dev \
    libxml2-dev \
    unzip \
    libffi-dev \
    python3-dev \
    jq

# Fix pip
python3 -m pip install --upgrade pip
# Pip won't install the right version of cryptography by itself
python3 -m pip install --upgrade cryptography
# get awscli
python3 -m pip install awscli ansible boto3

# ansible expects /usr/bin/python
ln -s /usr/bin/python3 /usr/bin/python

# set up and run ansible play for Sensu
mkdir /opt/ansible-sensu
pushd /opt/ansible-sensu
/usr/local/bin/aws s3 cp s3://${bucket}/${zipfile} .
/usr/bin/unzip ${zipfile}
/usr/local/bin/ansible-galaxy install sensu.sensu -p roles/
# github suggests $HOME is unset https://github.com/ansible/ansible/issues/20572
export HOME=/root
REGION=$(curl --silent http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region)
/usr/local/bin/ansible-playbook -i ${hosts_file} -c local ${playbook} -s --extra-vars="var_region=$REGION"
