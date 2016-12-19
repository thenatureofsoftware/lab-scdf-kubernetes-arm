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
FABRIC8_ZOOKEEPER_DOCKER_VERSION="d2e7b83c49068e85614f78d3150503382280df2d"

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
  cd $WORKDIR/$2
  git checkout $3
  cd $BASEDIR
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
  sed -i "s;zookeeper.version;$ZOOKEEPER_VERSION;" $WORKDIR/image/Dockerfile
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
clone https://github.com/fabric8io/fabric8-zookeeper-docker.git fabric8-zookeeper-docker $FABRIC8_ZOOKEEPER_DOCKER_VERSION
copy_files
configure_dockerfile
build_image
