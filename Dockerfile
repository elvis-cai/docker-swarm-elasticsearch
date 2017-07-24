FROM docker.elastic.co/elasticsearch/elasticsearch:5.5.0

USER root

RUN yum install -y bind-utils

# configuring system settings
# https://www.elastic.co/guide/en/elasticsearch/reference/current/setting-system-settings.html#limits.conf
# https://www.elastic.co/guide/en/elasticsearch/reference/current/setup-configuration-memory.html
RUN ulimit -n 65536
RUN ulimit -l unlimited

COPY es-docker /usr/share/elasticsearch/bin/
USER elasticsearch
