Emqtt-docker
================
[![Build Status](https://travis-ci.org/RaymondMouthaan/emqtt-docker.svg?branch=master)](https://travis-ci.org/RaymondMouthaan/emqtt-docker)
[![This image on DockerHub](https://img.shields.io/docker/pulls/raymondmm/emqtt.svg)](https://hub.docker.com/r/raymondmm/emqtt/)
[![This image on DockerHub](https://img.shields.io/docker/stars/raymondmm/emqtt.svg)](https://hub.docker.com/r/raymondmm/emqtt/)

EMQ (Erlang MQTT Broker) is a distributed, massively scalable, highly extensible MQTT message broker written in Erlang/OTP.

EMQTT docker is supported by manifest list, which means one doesn't need to specify the tag for a specific architecture. Using the image without any tag or the latest tag , will pull the right image for the architecture required.

## Architecture
Currently EMQTT docker has support for multiple architectures:
- `amd64` : based on linux Alpine - for most desktop computer (e.g. x64, x86-64, x86_64)
- `arm32v6` : based on linux Alpine - (i.e. Raspberry PI 1, 2, 3, Zero)
- `arm64v8` : based on linux Alpine - (i.e. Pine64)

## Usage
### docker run
```
docker run -d -p1883:1883 --name myEmqtt raymondmm/emqtt
```

### docker stack

```
docker stack deploy emqtt --compose-file docker-compose-emqtt.yml
```

Example of docker-compose.yml

```
version: "3.4"

services:
  emqtt-master:
    image: raymondmm/emqtt
    hostname: emqtt-master
    environment:
      - "EMQ_NAME=emq"
      - "EMQ_HOST=master.mq.tt"
      - "EMQ_NODE__COOKIE=ef16498f66804df1cc6172f6996d5492"
      - "EMQ_WAIT_TIME=60"
    networks:
      emqtt-net:
        aliases:
          - master.mq.tt

    volumes:
      - type: bind
        source: /etc/localtime
        target: /etc/localtime
        read_only: true

      - type: bind
        source: /etc/timezone
        target: /etc/TZ
        read_only: true

    deploy:
      replicas: 1

  emqtt-worker-1:
    image: raymondmm/emqtt
    hostname: emqtt-worker-1
    environment:
      - "EMQ_JOIN_CLUSTER=emq@master.mq.tt"
      - "EMQ_NODE__COOKIE=ef16498f66804df1cc6172f6996d5492"
      - "EMQ_WAIT_TIME=60"

    depends_on:
     - emqtt-master

    networks:
      emqtt-net:

    volumes:
      - type: bind
        source: /etc/localtime
        target: /etc/localtime
        read_only: true

      - type: bind
        source: /etc/timezone
        target: /etc/TZ
        read_only: true

    deploy:
      replicas: 1

  emqtt-worker-2:
    image: raymondmm/emqtt
    hostname: emqtt-worker-2
    environment:
      - "EMQ_JOIN_CLUSTER=emq@master.mq.tt"
      - "EMQ_NODE__COOKIE=ef16498f66804df1cc6172f6996d5492"
      - "EMQ_WAIT_TIME=60"

    depends_on:
     - emqtt-master

    networks:
      emqtt-net:

    volumes:
      - type: bind
        source: /etc/localtime
        target: /etc/localtime
        read_only: true

      - type: bind
        source: /etc/timezone
        target: /etc/TZ
        read_only: true

    deploy:
      replicas: 1

networks:
  emqtt-net:
    external: true
```

Please refer to the offical documentation for more info: https://github.com/emqtt/emq-docker
