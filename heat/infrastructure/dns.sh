#!/bin/bash -x

export SATELLITE_IP_ADDR=${SATELLITE_IP_ADDR:-10.33.11.10}
export CONF_BIND_KEY=${CONF_BIND_KEY:-sM6LJvrKqb2R074G8vlGf7x02s9AsZ6RpldyQpHDqyI=}
export CONF_DOMAIN=${CONF_DOMAIN:-ose.saleslab.fab.redhat.com}

export CONF_NAMED_IP_ADDR=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
export CONF_INSTALL_COMPONENTS=named
export CONF_FORWARD_DNS=true
export CONF_KEEP_HOSTNAME=true
export CONF_KEEP_NAMESERVERS=true

fix_gso() {
  cat >>/etc/rc.local <<EOF
ethtool -K eth0 gso off
ethtool -K eth0 tso off
EOF

  ethtool -K eth0 gso off
  ethtool -K eth0 tso off
}

set_tz() {
  ln -sf /usr/share/zoneinfo/$1 /etc/localtime 
}

register_channels() {
  for CHANNEL in $*
  do
    curl -so /etc/yum.repos.d/$CHANNEL.repo http://$SATELLITE_IP_ADDR:8085/$CHANNEL.repo
  done
}

install_packages() {
  yum -y install $*
}

ose_install() {
  curl -so /tmp/openshift.sh https://raw.githubusercontent.com/openshift/openshift-extras/enterprise-2.1/enterprise/install-scripts/generic/openshift.sh
  chmod 0755 /tmp/openshift.sh

  /tmp/openshift.sh
}

fix_gso
set_tz Europe/London
register_channels rhel-x86_64-server-6

ose_install
