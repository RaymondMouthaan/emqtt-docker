Emqtt-docker
================
EMQ (Erlang MQTT Broker) is a distributed, massively scalable, highly extensible MQTT message broker written in Erlang/OTP.

[![Build Status](https://travis-ci.org/RaymondMouthaan/emqtt-docker.svg?branch=master)](https://travis-ci.org/RaymondMouthaan/emqtt-docker)
[![This image on DockerHub](https://img.shields.io/docker/pulls/raymondmm/emqtt.svg)](https://hub.docker.com/r/raymondmm/emqtt/)

This project is based on the official EMQ Docker image, but adds qemu-arm-static and uses manifest-tool to push manifest list to docker hub.

## Architectures
Currently supported archetectures:
- **linux-arm**

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

Please refer to the offical documentation: https://github.com/emqtt/emq-docker
