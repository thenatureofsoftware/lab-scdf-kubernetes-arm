#!/bin/bash

set -e

################################################################################
# init
################################################################################
BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
APP="lab1"
WORKDIR=$BASEDIR/.work
ARCH=${ARCH:-arm}
ZOOKEEPER_VERSION="3.4.6"
FABRIC8_ZOOKEEPER_DOCKER_VERSION="d2e7b83c49068e85614f78d3150503382280df2d"
KAFKA_DOCKER_VERSION="971c811fcca126053b9e625e3334edd742fd9abe"
KAFKA_VERSION="0.10.1.0"
# 1.1.0.RC1
SCDF_ARTIFACT_ID="spring-cloud-dataflow-server-kubernetes"
SCDF_VERSION="1.1.0.RELEASE"
SCDF_JAR="${SCDF_ARTIFACT_ID}-${SCDF_VERSION}.jar"

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
  mkdir -p $WORKDIR/zk_image
  mkdir -p $WORKDIR/kafka_image
  mkdir -p $WORKDIR/scdf_image
}

copy_zk_files() {
  log "copying files..."
  cp $WORKDIR/fabric8-zookeeper-docker/zoo.cfg $WORKDIR/zk_image
  cp $WORKDIR/fabric8-zookeeper-docker/config-and-run.sh $WORKDIR/zk_image
  cp $BASEDIR/Dockerfile.zookeeper $WORKDIR/zk_image/Dockerfile
}

configure_zk_dockerfile() {
  sed -i "s;zookeeper.version;$ZOOKEEPER_VERSION;" $WORKDIR/zk_image/Dockerfile
}

copy_kafka_files() {
  log "copying files..."
  cp $WORKDIR/kafka-docker/*.sh $WORKDIR/kafka_image
  cp $BASEDIR/Dockerfile.kafka $WORKDIR/kafka_image/Dockerfile
}

configure_kafka_dockerfile() {
  sed -i "s;kafka.version;$KAFKA_VERSION;" $WORKDIR/kafka_image/Dockerfile
}

copy_scdf_files() {
  cp $BASEDIR/Dockerfile.scdf $WORKDIR/scdf_image/Dockerfile
}

configure_scdf_dockerfile() {
  sed -i "s;scdf.version;$SCDF_VERSION;" $WORKDIR/scdf_image/Dockerfile
}

build_image() {
  IMG="kodbasen/$2-arm"
  log "start building image $IMG:v$3 ..."
  docker build --rm=true --no-cache -t $IMG:latest $WORKDIR/$1
#  docker build -t $IMG:latest $WORKDIR/$1
  docker tag $IMG:latest $IMG:v$3
  docker push $IMG:latest
  docker push $IMG:v$3
  log "done building image $IMG:v$3"
}

init

log "start building zookeeper image for ARM"
clone https://github.com/fabric8io/fabric8-zookeeper-docker.git fabric8-zookeeper-docker $FABRIC8_ZOOKEEPER_DOCKER_VERSION
copy_zk_files
configure_zk_dockerfile
build_image zk_image zookeeper $ZOOKEEPER_VERSION
log "done building zookeeper image for ARM"

log "start building kafka image for ARM"
clone https://github.com/wurstmeister/kafka-docker.git kafka-docker $KAFKA_DOCKER_VERSION
copy_kafka_files
configure_kafka_dockerfile
build_image kafka_image kafka $KAFKA_VERSION
log "done building kafka image for ARM"

log "start building scdf image for ARM"
wget -O $WORKDIR/scdf_image/$SCDF_JAR http://search.maven.org/remotecontent?filepath=org/springframework/cloud/$SCDF_ARTIFACT_ID/$SCDF_VERSION/$SCDF_JAR
copy_scdf_files
configure_scdf_dockerfile
build_image scdf_image $SCDF_ARTIFACT_ID $SCDF_VERSION
log "done building scdf image for ARM"
