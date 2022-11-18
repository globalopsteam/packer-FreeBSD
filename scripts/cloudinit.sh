#!/bin/sh
set -e

# Install python and root certificates
pkg install -y py39-cloud-init

sysrc cloudinit_enable="YES"
