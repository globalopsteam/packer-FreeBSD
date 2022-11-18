#!/bin/sh
[ -n "$1" ] || { echo "Must specify build version" >&2; exit 1; }
VERSION="-$1"
shift
PACKER_KEY_INTERVAL=25ms packer build -timestamp-ui -var-file="variables${VERSION}.json" "$@" "template-na.json"
