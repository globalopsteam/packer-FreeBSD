#!/bin/sh
set -e

# Disable root logins
sed -i '' -e 's/^PermitRootLogin yes/#PermitRootLogin no/' /etc/ssh/sshd_config

# Purge files we no longer need
rm -rf /boot/kernel.old
rm -f /etc/ssh/ssh_host_*
rm -f /root/*.iso
rm -f /root/.vbox_version
rm -rf /tmp/*
rm -rf /var/db/freebsd-update/files/*
rm -f /var/db/freebsd-update/*-rollback
rm -rf /var/db/freebsd-update/install.*
rm -f /var/db/pkg/repo-*.sqlite
rm -rf /var/log/*

printf "\n# Enable resource limits\n"
printf "echo kern.racct.enable=1 >>/boot/loader.conf\n"
printf "\n# Growfs on first boot\n"
printf "service growfs enable\n"
printf "touch /firstboot\n"