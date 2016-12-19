#!/bin/bash

set -e

################################################################################
# init
################################################################################
BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
APP="lab1"
WORKDIR=$BASEDIR/.work
ARCH=${ARCH:-arm}
ZOOKEEPER_VERSION=3.4.6

log() {
  timestamp=$(date +"[%m%d %H:%M:%S]")
  echo "+++ $APP $timestamp $1"
  shift
  for message; do
    echo "  $message"
  done
}

clone() {
  if [ -d "$WORKDIR/$2" ]; then
    return
  fi
  log "cloning $1 in to $2"
  git clone $1 $WORKDIR/$2
}

init() {
  if [ -d "$WORKDIR" ]; then
    return
  fi
  log "creating work directory: $WORKDIR"
  mkdir -p $WORKDIR/image
}

copy_files() {
  log "copying files..."
  cp $WORKDIR/fabric8-zookeeper-docker/zoo.cfg $WORKDIR/image
  cp $WORKDIR/fabric8-zookeeper-docker/config-and-run.sh $WORKDIR/image
  cp $BASEDIR/Dockerfile.template $WORKDIR/image/Dockerfile
}

configure_dockerfile() {
  sed -i template "s;zookeeper.version;$ZOOKEEPER_VERSION;" $WORKDIR/image/Dockerfile
}

build_image() {
  log "start building image ..."
  docker build --rm=true --no-cache -t kodbasen/zookeeper-arm:latest $WORKDIR/image
  docker tag kodbasen/zookeeper-arm:latest kodbasen/zookeeper-arm:v$ZOOKEEPER_VERSION
  docker push kodbasen/zookeeper-arm:latest
  docker push kodbasen/zookeeper-arm:v$ZOOKEEPER_VERSION
  log "done building image"
}

init
clone https://github.com/fabric8io/fabric8-zookeeper-docker.git fabric8-zookeeper-docker
copy_files
configure_dockerfile
build_image
