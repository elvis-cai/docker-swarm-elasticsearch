Docker Swarm support for elasticsearch
======================================

Automatically configures elasticsearch to connect other nodes inside docker swarm cluster.

## Prerequisites

- setup [virtual box](https://www.virtualbox.org/)
- setup [Vagrant](https://www.vagrantup.com/downloads.html) in your mac os / windows

## Test and run
- gitclone this repo and go to clone folder
- run `vagrant up` then you will get a docker swarm environment
- run `vagrant ssh elastic0`
    - `sudo -u docker docker stack deploy --compose-file /vagrant/docker-compose.yml elasticsearch`
- check the service: `sudo -u docker docker service ls`
- remove the stack: `sudo -u docker docker stack rm elasticsearch`

## Affects elasticsearch parameters:

- `network.host` - an IP address of the container
- `network.publish_host` - an IP address of the container
- `discovery.zen.ping.unicast.hosts` - a list of IP addresses other nodes inside docker swarm service

In order to run docker swarm service from this image it is REQUIRED to set environment variable SERVICE_NAME to the name of service in docker swarm.
Please avoid to manually configure parameters listed above.

Example:

```
docker network create --driver overlay --subnet 10.0.10.0/24 \
  --opt encrypted elastic_cluster

docker service create --name elasticsearch --network=elastic_cluster \
  --replicas 3 \
  --env SERVICE_NAME=elasticsearch \
  --env bootstrap.memory_lock=true \
  --env "ES_JAVA_OPTS=-Xms512m -Xmx512m -XX:-AssumeMP" \
  --publish 9200:9200 \
  --publish 9300:9300 \
  youngbe/docker-swarm-elasticsearch:5.5.0

docker service create --name kibana --network=elastic_cluster \
  --replicas 1 \
  --env ELASTICSEARCH_URL="http://192.168.100.20:9200" \
  --publish 5601:5601 \
  docker.elastic.co/kibana/kibana:5.5.0
```

After started, you can go to http://192.168.100.20:5601/ to see the kibana and connect to elasticsearch cluster http://192.168.100.20:9200.

## Parameters

* "-XX:-AssumeMP" :
If you encountered "-XX:ParallelGCThreads=N" error and stop elasticsearch service, this is because some JavaSDK with -XX:+AssumeMP enabled by default. So, you should turn it off. Reference [issue](https://github.com/elastic/elasticsearch/issues/22245)

* "bootstrap.memory_lock=true" :
Production mode need to lock memory to avoid elasticsearch swap to file. It's will cause performance issue. If you encountered memory lock issue in developing, set "bootstrap.memory_lock=false".

* production mode: max_map_count and ulimit
[elasticsearch docker production mode](https://www.elastic.co/guide/en/elasticsearch/reference/current/docker.html#docker-cli-run-prod-mode) requires:
    * vm.max_map_count=262144
    * elasticsearch using uid:gid 1000:1000
    * ulimit for /etc/security/limits.conf
        * nofile  65536 (open file)
        * nproc   65535 (process thread)
        * memlock unlimited (max memory lock)

You need to setup it BEFORE Docker service up. On CentOS7.0, you can reference the script: es-require-on-host.sh.

Since elasticsearch requires vm.max_map_count to be at least 262144 but docker service create does not support sysctl management you have to set 
vm.max_map_count on all your nodes to proper value BEFORE starting service.
On Linux Ubuntu: `sysctl -w "vm.max_map_count=262144"`. Or `echo "vm.max_map_count=262144" >> /etc/sysctl.conf` to set it permanently.


To access elasticsearch cluster connect to any docker swarm node to port 9200 using default credentials: `curl http://elastic:changeme@my-es-node.mydomain.com:9200`.

To change default elasticsearch parameters use environment variables. See https://www.elastic.co/guide/en/elasticsearch/reference/current/docker.html for more details.
