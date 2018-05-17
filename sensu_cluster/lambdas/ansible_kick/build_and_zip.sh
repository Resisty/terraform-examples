#!/usr/bin/env bash

apt-get update
apt-get install -y python3-pip zip bcrypt
cd /build
rm -rf __pychache__ || /bin/true
pip3 install -r requirements.txt -t . --upgrade
zip -r ansible_kick.zip .
