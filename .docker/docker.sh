#!/bin/bash

set -o errexit

main() {
    case $1 in
        "prepare")
            docker_prepare
            ;;
        "build")
            docker_build
            ;;
        "test")
            docker_test
            ;;
        "tag")
            docker_tag
            ;;
        "push")
            docker_push
            ;;
        "manifest-list")
            docker_manifest_list
            ;;
        *)
            echo "none of above!"
    esac
}

docker_prepare() {
    # Prepare the machine before any code installation scripts
    setup_dependencies

    # Update docker configuration to enable docker manifest command
    update_docker_configuration

    # Prepare qemu to build images other then x86_64 on travis
    prepare_qemu
}

docker_build() {
    echo "DOCKER BUILD: Build all docker images."
    docker build --no-cache --build-arg BASE_IMAGE=arm32v6/alpine --build-arg QEMU_ARCH=arm --file ./.docker/Dockerfile.alpine-tmpl --tag $IMAGE:build-$EMQ_VERSION-alpine-arm32v6 .
    #docker build --no-cache --build-arg NODE_RED_VERSION=v$NODE_RED_VERSION --build-arg ARCH=arm32v6 --build-arg NODE_IMAGE_TAG=8-alpine --build-arg QEMU_ARCH=arm    --file ./.docker/Dockerfile.alpine-tmpl --tag $IMAGE:build-8-alpine-arm32v6 .
    #docker build --no-cache --build-arg NODE_RED_IMAGE_TAG=$NODE_RED_VERSION-debian-arm32v7 --build-arg QEMU_ARCH=arm    --file ./.docker/Dockerfile.debian-tmpl --tag $IMAGE:build-$NODE_RED_VERSION-debian-arm32v7 .
    #docker build --no-cache --build-arg NODE_RED_VERSION=v$NODE_RED_VERSION --build-arg ARCH=arm64v8 --build-arg NODE_IMAGE_TAG=8-alpine  --build-arg QEMU_ARCH=aarch64 --file ./.docker/Dockerfile.alpine-tmpl --tag $IMAGE:build-8-alpine-arm64v8 .
}

docker_test() {
    echo "DOCKER TEST: Test all docker images."
    docker run -d --name=test-$EMQ_VERSION-alpine-arm32v6 $IMAGE:build-$EMQ_VERSION-alpine-arm32v6
    if [ $? -ne 0 ]; then
        echo "ERROR: Docker container failed to start for build-$EMQ_VERSION-alpine-arm32v6 ."
        exit 1
    fi
    docker stop test-$EMQ_VERSION-alpine-arm32v6 && docker rm test-$EMQ_VERSION-alpine-arm32v6

    # docker run -d --name=test-8-alpine-arm32v6 $IMAGE:build-8-alpine-arm32v6
    # if [ $? -ne 0 ]; then
    #     echo "ERROR: Docker container failed to start for build-8-alpine-arm32v6."
    #     exit 1
    # fi
    # docker stop test-8-alpine-arm32v6 && docker rm test-8-alpine-arm32v6
    #
    #docker run -d --name=test-$NODE_RED_VERSION-debian-arm32v7 $IMAGE:build-$NODE_RED_VERSION-debian-arm32v7
    #if [ $? -ne 0 ]; then
    #    echo "ERROR: Docker container failed to start for build-$NODE_RED_VERSION-debian-arm32v7."
    #    exit 1
    #fi
    #docker stop test-$NODE_RED_VERSION-debian-arm32v7 && docker rm test-$NODE_RED_VERSION-debian-arm32v7
    #
    # docker run -d --name=test-8-alpine-arm64v8 $IMAGE:build-8-alpine-arm64v8
    # if [ $? -ne 0 ]; then
    #     echo "ERROR: Docker container failed to start for build-8-alpine-arm64v8."
    #     exit 1
    # fi
    # docker stop test-8-alpine-arm64v8 && docker rm test-8-alpine-arm64v8
}

docker_tag() {
    echo "DOCKER TAG: Tag all docker images."
    # Tag node v8 based images
    docker tag $IMAGE:build-$EMQ_VERSION-alpine-arm32v6 $IMAGE:latest-$EMQ_VERSION-alpine-arm32v6
    docker tag $IMAGE:build-$EMQ_VERSION-alpine-arm32v6 $IMAGE:$EMQ_VERSION-alpine-arm32v6

    # docker tag $IMAGE:build-8-alpine-arm32v6 $IMAGE:latest-8-alpine-arm32v6
    # docker tag $IMAGE:build-8-alpine-arm32v6 $IMAGE:$NODE_RED_VERSION-8-alpine-arm32v6
    #
    #docker tag $IMAGE:build-$NODE_RED_VERSION-debian-arm32v7 $IMAGE:latest-$NODE_RED_VERSION-debian-arm32v7
    #docker tag $IMAGE:build-$NODE_RED_VERSION-debian-arm32v7 $IMAGE:$NODE_RED_HOMEKIT_VERSION-$NODE_RED_VERSION-debian-arm32v7
    #
    # docker tag $IMAGE:build-8-alpine-arm64v8 $IMAGE:latest-8-alpine-arm64v8
    # docker tag $IMAGE:build-8-alpine-arm64v8 $IMAGE:$NODE_RED_VERSION-8-alpine-arm64v8
}

docker_push() {
    echo "DOCKER PUSH: Push all docker images."
    docker push $IMAGE:latest-$EMQ_VERSION-alpine-arm32v6
    docker push $IMAGE:$EMQ_VERSION-alpine-arm32v6

    # docker push $IMAGE:latest-8-alpine-arm32v6
    # docker push $IMAGE:$NODE_RED_VERSION-8-alpine-arm32v6
    #
    #docker push $IMAGE:latest-$NODE_RED_VERSION-debian-arm32v7
    #docker push $IMAGE:$NODE_RED_HOMEKIT_VERSION-$NODE_RED_VERSION-debian-arm32v7
    #
    # docker push $IMAGE:latest-8-alpine-arm64v8
    # docker push $IMAGE:$NODE_RED_VERSION-8-alpine-arm64v8
}

docker_manifest_list() {
    # Create and push manifest lists, displayed as FIFO
    echo "DOCKER MANIFEST: Create and Push docker manifest list."
    # docker_manifest_list_rpi_1
    # docker_manifest_list_rpi_1_latest
    # docker_manifest_list_rpi_2_3
    # docker_manifest_list_rpi_2_3_latest
    docker_manifest_list_node_v8
    docker_manifest_list_default
    docker_manifest_list_latest
}

# docker_manifest_list_rpi_1() {
#     # Manifest Create rpi 1
#     docker manifest create $IMAGE:$NODE_RED_VERSION-8-rpi1 \
#         $IMAGE:latest-8-alpine-arm32v6
#
#     # Manifest Annotate rpi 1
#     docker manifest annotate $IMAGE:$NODE_RED_VERSION-8-rpi1 $IMAGE:latest-8-alpine-arm32v6 --os=linux --arch=arm --variant=v6
#
#     # Manifest Push rpi 1
#     docker manifest push $IMAGE:$NODE_RED_VERSION-8-rpi1
# }
#
# docker_manifest_list_rpi_1_latest() {
#     # Manifest Create rpi 1
#     docker manifest create $IMAGE:latest-8-rpi1 \
#         $IMAGE:latest-8-alpine-arm32v6
#
#     # Manifest Annotate rpi 1
#     docker manifest annotate $IMAGE:latest-8-rpi1 $IMAGE:latest-8-alpine-arm32v6 --os=linux --arch=arm --variant=v6
#
#     # Manifest Push rpi 1
#     docker manifest push $IMAGE:latest-8-rpi1
# }
#
# docker_manifest_list_rpi_2_3() {
#     # Manifest Create rpi 2 and 3
#     docker manifest create $IMAGE:$NODE_RED_VERSION-8-rpi23 \
#         $IMAGE:latest-8-debian-arm32v7
#
#     # Manifest Annotate rpi 2 and 3
#     docker manifest annotate $IMAGE:$NODE_RED_VERSION-8-rpi23 $IMAGE:latest-8-debian-arm32v7 --os=linux --arch=arm --variant=v7
#
#     # Manifest Push rpi 2 and 3
#     docker manifest push $IMAGE:$NODE_RED_VERSION-8-rpi23
# }

# docker_manifest_list_rpi_2_3_latest() {
#     # Manifest Create rpi 2 and 3
#     docker manifest create $IMAGE:latest-8-rpi23 \
#         $IMAGE:latest-8-debian-arm32v7
#
#     # Manifest Annotate rpi 2 and 3
#     docker manifest annotate $IMAGE:latest-8-rpi23 $IMAGE:latest-8-debian-arm32v7 --os=linux --arch=arm --variant=v7
#
#     # Manifest Push rpi 2 and 3 latest
#     docker manifest push $IMAGE:latest-8-rpi23
# }

docker_manifest_list_default() {
    # Manifest Create NODE_RED_VERSION default (v8 based)
    docker manifest create $IMAGE:$EMQ_VERSION \
        $IMAGE:$EMQ_VERSION-alpine-arm32v6

    # Manifest Annotate EMQ_VERSION
    docker manifest annotate $IMAGE:$EMQ_VERSION $IMAGE:$EMQ_VERSION-alpine-arm32v6 --os=linux --arch=arm --variant=v6

    # Manifest Push EMQ_VERSION
    docker manifest push $IMAGE:$EMQ_VERSION
}

docker_manifest_list_latest() {
    # Manifest Create LATEST
    docker manifest create $IMAGE:latest \
        $IMAGE:latest-alpine-arm32v6

    # Manifest Annotate LATEST
    docker manifest annotate $IMAGE:latest $IMAGE:latest-alpine-arm32v6 --os=linux --arch=arm --variant=v6

    # Manifest Push LATEST
    docker manifest push $IMAGE:latest
}

setup_dependencies() {
  echo "PREPARE: Setting up dependencies."

  sudo apt update -y
  # sudo apt install realpath python python-pip -y
  sudo apt install --only-upgrade docker-ce -y
  # sudo pip install docker-compose || true

  docker info
  # docker-compose --version
}

update_docker_configuration() {
  echo "PREPARE: Updating docker configuration"

  mkdir $HOME/.docker

  # enable experimental to use docker manifest command
  echo '{
    "experimental": "enabled"
  }' | tee $HOME/.docker/config.json

  # # enable experimental
  # echo '{
  #   "experimental": true,
  #   "storage-driver": "overlay2",
  #   "max-concurrent-downloads": 100,
  #   "max-concurrent-uploads": 100
  # }' | sudo tee /etc/docker/daemon.json

  sudo service docker restart
}

prepare_qemu(){
    echo "PREPARE: Qemu"
    # Prepare qemu to build non amd64 / x86_64 images
    docker run --rm --privileged multiarch/qemu-user-static:register --reset
    mkdir tmp
    pushd tmp &&
    curl -L -o qemu-x86_64-static.tar.gz https://github.com/multiarch/qemu-user-static/releases/download/$QEMU_VERSION/qemu-x86_64-static.tar.gz && tar xzf qemu-x86_64-static.tar.gz &&
    curl -L -o qemu-arm-static.tar.gz https://github.com/multiarch/qemu-user-static/releases/download/$QEMU_VERSION/qemu-arm-static.tar.gz && tar xzf qemu-arm-static.tar.gz &&
    curl -L -o qemu-aarch64-static.tar.gz https://github.com/multiarch/qemu-user-static/releases/download/$QEMU_VERSION/qemu-aarch64-static.tar.gz && tar xzf qemu-aarch64-static.tar.gz &&
    popd
}

main $1
