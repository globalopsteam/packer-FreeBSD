#!/bin/sh
set -e

if [ -e /tmp/rc-local ]; then
	CLEARTMP_RC_CONF_FILE=/etc/rc.conf.local
	NETOPTIONS_RC_CONF_FILE=/etc/rc.conf.local
	ROUTING_RC_CONF_FILE=/etc/rc.conf.local
	SSHD_RC_CONF_FILE=/etc/rc.conf.local
	SYSLOGD_RC_CONF_FILE=/etc/rc.conf.local
elif [ -e /tmp/rc-vendor ]; then
	CLEARTMP_RC_CONF_FILE=/etc/defaults/vendor.conf
	NETOPTIONS_RC_CONF_FILE=/etc/defaults/vendor.conf
	ROUTING_RC_CONF_FILE=/etc/defaults/vendor.conf
	SSHD_RC_CONF_FILE=/etc/defaults/vendor.conf
	SYSLOGD_RC_CONF_FILE=/etc/defaults/vendor.conf
elif [ -e /tmp/rc-name ]; then
	CLEARTMP_RC_CONF_FILE=/etc/rc.conf.d/cleartmp
	NETOPTIONS_RC_CONF_FILE=/etc/rc.conf.d/netoptions
	ROUTING_RC_CONF_FILE=/etc/rc.conf.d/routing
	SSHD_RC_CONF_FILE=/etc/rc.conf.d/sshd
	SYSLOGD_RC_CONF_FILE=/etc/rc.conf.d/syslogd
else
	CLEARTMP_RC_CONF_FILE=/etc/rc.conf
	NETOPTIONS_RC_CONF_FILE=/etc/rc.conf
	ROUTING_RC_CONF_FILE=/etc/rc.conf
	SSHD_RC_CONF_FILE=/etc/rc.conf
	SYSLOGD_RC_CONF_FILE=/etc/rc.conf
fi

# Disable weak SSH keys
sysrc -f "$SSHD_RC_CONF_FILE" sshd_ecdsa_enable=NO
rm -f /etc/ssh/ssh_host_ecdsa_key*

# Configure SSH server
sed -i '' -e 's/^#Compression delayed/Compression no/' \
	/etc/ssh/sshd_config
sed -i '' -e 's/^#ChallengeResponseAuthentication yes/ChallengeResponseAuthentication no/' \
	/etc/ssh/sshd_config
sed -i '' -e 's/^#KbdInteractiveAuthentication yes/KbdInteractiveAuthentication no/' \
	/etc/ssh/sshd_config
sed -i '' -e 's/^#UsePAM yes/UsePAM no/' \
	/etc/ssh/sshd_config
sed -i '' -e 's/^#VersionAddendum .*$/VersionAddendum none/' \
	/etc/ssh/sshd_config
sed -i '' -e 's/^#X11Forwarding yes/X11Forwarding no/' \
	/etc/ssh/sshd_config

# Change umask
sed -i '' -e 's/:umask=022:/:umask=027:/g' /etc/login.conf

# Remove toor user
pw userdel toor

# Secure ttys
sed -i '' -e 's/ secure/ insecure/g' /etc/ttys

# Secure newsyslog
sed -i '' -e 's|^/var/log/init.log			644|/var/log/init.log			640|' \
	/etc/newsyslog.conf
sed -i '' -e 's|^/var/log/messages			644|/var/log/messages			640|' \
	/etc/newsyslog.conf
sed -i '' -e 's|^/var/log/devd.log			644|/var/log/devd.log			640|' \
	/etc/newsyslog.conf
