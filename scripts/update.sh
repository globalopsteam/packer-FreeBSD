#!/bin/sh
set -e

# Set the time
service ntpdate onestart || true

# Update FreeBSD
freebsd-update --not-running-from-cron fetch install || true

# Set to quarterly package repo
mkdir -p /usr/local/etc/pkg/repos
echo "FreeBSD: { url: \"pkg+http://pkg.FreeBSD.org/\${ABI}/quarterly\" }" > /usr/local/etc/pkg/repos/FreeBSD.conf

# Bootstrap pkg
env ASSUME_ALWAYS_YES=yes pkg bootstrap -f

# Upgrade packages
pkg upgrade -qy
