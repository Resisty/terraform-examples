FROM ubuntu:17.10

MAINTAINER Brian Auron <briauron@amazon.com>

# Libraries and Dependencies

RUN \
  apt-get update && apt-get -y install \
  build-essential \
  python3 \
  python3-dev \
  python3-pip 

RUN \
  pip3 install \
  awscli \
  boto3 \
  requests \
  pyyaml \
  slackclient \
  beautifulsoup4

WORKDIR /

COPY es_base.py utils.py notifiers.py s3_to_es.py /

CMD [ "/usr/bin/python3", "s3_to_es.py" ]
