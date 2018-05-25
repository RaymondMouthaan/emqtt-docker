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
    #
    docker build --build-arg BUILD_REF=$TRAVIS_COMMIT --build-arg BUILD_DATE=$(date +"%Y-%m-%dT%H:%M:%SZ") --build-arg BUILD_VERSION=$EMQ_VERSION --build-arg BASE_IMAGE=amd64/alpine --build-arg QEMU_ARCH=x86_64 --file ./.docker/Dockerfile.alpine-tmpl --tag $TARGET:build-alpine-amd64 .
    docker build --build-arg BUILD_REF=$TRAVIS_COMMIT --build-arg BUILD_DATE=$(date +"%Y-%m-%dT%H:%M:%SZ") --build-arg BUILD_VERSION=$EMQ_VERSION --build-arg BASE_IMAGE=arm32v6/alpine --build-arg QEMU_ARCH=arm --file ./.docker/Dockerfile.alpine-tmpl --tag $TARGET:build-alpine-arm32v6 .
}

docker_test() {
    echo "DOCKER TEST: Test all docker images."
    docker run -d --rm --name=test-alpine-amd64 $TARGET:build-alpine-amd64
    if [ $? -ne 0 ]; then
       echo "DOCKER TEST: FAILED - Docker container failed to start for build-alpine-amd64."
       exit 1
    else
       echo "DOCKER TEST: PASSED - Docker container succeeded to start for build-alpine-amd64."
    fi

    docker run -d --rm --name=test-alpine-arm32v6 $TARGET:build-alpine-arm32v6
    if [ $? -ne 0 ]; then
       echo "DOCKER TEST: FAILED - Docker container failed to start for build-alpine-arm32v6."
       exit 1
    else
       echo "DOCKER TEST: PASSED - Docker container succeeded to start for build-alpine-arm32v6."
    fi
}

docker_tag() {
    echo "DOCKER TAG: Tag all docker images."
    docker tag $TARGET:build-alpine-amd64 $TARGET:$EMQ_VERSION-alpine-amd64
    docker tag $TARGET:build-alpine-arm32v6 $TARGET:$EMQ_VERSION-alpine-arm32v6
}

docker_push() {
    echo "DOCKER PUSH: Push all docker images."
    docker push $TARGET:$EMQ_VERSION-alpine-amd64
    docker push $TARGET:$EMQ_VERSION-alpine-arm32v6
}

docker_manifest_list() {
    # Create and push manifest lists, displayed as FIFO
    echo "DOCKER MANIFEST: Create and Push docker manifest lists."
    docker_manifest_list_version
    docker_manifest_list_latest
    docker_manifest_list_version_os_arch
}

docker_manifest_list_version() {
  # Manifest Create EMQ_VERSION
  echo "DOCKER MANIFEST: Create and Push docker manifest list - $TARGET:$EMQ_VERSION."
  docker manifest create $TARGET:$EMQ_VERSION \
      $TARGET:$EMQ_VERSION-alpine-amd64 \
      $TARGET:$EMQ_VERSION-alpine-arm32v6

  # Manifest Annotate EMQ_VERSION
  docker manifest annotate $TARGET:$EMQ_VERSION $TARGET:$EMQ_VERSION-alpine-arm32v6 --os=linux --arch=arm --variant=v6

  # Manifest Push EMQ_VERSION
  docker manifest push $TARGET:$EMQ_VERSION
}

docker_manifest_list_latest() {
  # Manifest Create latest
  echo "DOCKER MANIFEST: Create and Push docker manifest list - $TARGET:latest."
  docker manifest create $TARGET:latest \
      $TARGET:latest-alpine-amd64 \
      $TARGET:latest-alpine-arm32v6

  # Manifest Annotate EMQ_VERSION
  docker manifest annotate $TARGET:latest $TARGET:latest-alpine-arm32v6 --os=linux --arch=arm --variant=v6

  # Manifest Push EMQ_VERSION
  docker manifest push $TARGET:latest
}

docker_manifest_list_version_os_arch() {
  # Manifest Create alpine-amd64
  echo "DOCKER MANIFEST: Create and Push docker manifest list - $TARGET:$EMQ_VERSION-alpine-amd64."
  docker manifest create $TARGET:$EMQ_VERSION-alpine-amd64 \
      $TARGET:$EMQ_VERSION-alpine-amd64

  # Manifest push alpine-amd64
  docker manifest push $TARGET:$EMQ_VERSION-alpine-amd64

  # Manifest Create alpine-arm32v6
  echo "DOCKER MANIFEST: Create and Push docker manifest list - $TARGET:$EMQ_VERSION-alpine-arm32v6."
  docker manifest create $TARGET:$EMQ_VERSION-alpine-arm32v6 \
      $TARGET:$EMQ_VERSION-alpine-arm32v6

  # Manifest push alpine-amd64
  docker manifest push $TARGET:$EMQ_VERSION-alpine-arm32v6
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
