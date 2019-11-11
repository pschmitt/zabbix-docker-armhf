#!/usr/bin/env bash

cd "$(readlink -f "$(dirname "$0")")" || exit 9

usage() {
  echo "Usage: $(basename "$0") TARGET"
}

list_remote_tags() {
  git ls-remote --tags "$1" | \
    awk '{print $2}' | \
    sed 's|refs/tags/||' | \
    sort -r
}

if [[ "$#" -lt 1 ]]
then
  usage
  exit 2
fi

case "$1" in
  -h|--help|help|h)
    usage
    exit 0
    ;;
esac

SUCCESSFUL_BUILDS=()
FAILED_BUILDS=()

for git_tag in $(list_remote_tags https://github.com/zabbix/zabbix-docker)
do
  if ./build.sh "$1" "$git_tag" -p
  then
    SUCCESSFUL_BUILDS+=("$git_tag")
  else
    FAILED_BUILDS+=("$git_tag")
  fi
done

if [[ "${#SUCCESSFUL_BUILDS[@]}" -ne 0 ]]
then
  echo "Successful builds:"
  for build in "${SUCCESSFUL_BUILDS[@]}"
  do
    echo "  - $build ✔️"
  done
fi

if [[ "${#FAILED_BUILDS[@]}" -ne 0 ]]
then
  echo "Failed builds:"
  for build in "${FAILED_BUILDS[@]}"
  do
    echo "  - $build ❌"
  done
fi
