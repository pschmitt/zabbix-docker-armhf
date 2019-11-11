#!/usr/bin/env bash

set -e

cd "$(readlink -f "$(dirname "$0")")" || exit 9

usage() {
  echo "$(basename "$0") TARGET [GITREF] [--push]"
}

if [[ -z "$1" ]]
then
  usage
  exit 2
fi

GITREF=master

case "$2" in
  -f|--force|-p|--push)
    PUSH_IMAGE=1
    ;;
  *)
    GITREF="$2"
    case "$3" in
      -f|--force|-p|--push)
        PUSH_IMAGE=1
        ;;
    esac
    ;;
esac

read -r PROJECT OS <<< "$(sed -r 's/(.+)-(.+)/\1 \2/' <<< "$1")"

if [[ -z "$PROJECT" ]] || [[ -z "$OS" ]]
then
  echo "Unable to determine target project or OS" >&2
  exit 3
fi

BUILD_DIR="${PWD}/data"

if [[ -d "$BUILD_DIR" ]]
then
  cd "$BUILD_DIR" || exit 9
  git clean -d -f -f
  git reset --hard HEAD > /dev/null
  git checkout master
  git pull > /dev/null
else
  git clone https://github.com/zabbix/zabbix-docker "$BUILD_DIR"
fi

cd "$BUILD_DIR"
git checkout "$GITREF"

if ! cd "${BUILD_DIR}/${PROJECT}/${OS}" 2> /dev/null
then
  echo "No such project/OS combination: ${PROJECT} on ${OS}" >&2
  exit 4
fi

if [[ "$GITREF" == "master" ]]
then
  DOCKER_TAG=latest
else
  DOCKER_TAG="$GITREF"
fi

DOCKER_IMAGE="pschmitt/zabbix-${PROJECT}-${OS}-armhf:native-${DOCKER_TAG}"
echo "Building $DOCKER_IMAGE"

case "$(uname -m)" in
  x86_64|i386)
    echo "Setting up ARM compatibility"
    docker run --rm --privileged docker/binfmt:820fdd95a9972a5308930a2bdfb8573dd4447ad3
    ;;
esac

docker build --platform=linux/arm -t "$DOCKER_IMAGE" .

if [[ -n "$PUSH_IMAGE" ]]
then
  docker push "$DOCKER_IMAGE"
fi

# vim set et ts=2 sw=2 :
