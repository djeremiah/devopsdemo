#!/bin/bash -x

SATELLITE_IP_ADDR=${SATELLITE_IP_ADDR:-10.33.11.10}
PROXY_IP_ADDR=${PROXY_IP_ADDR:-10.33.11.12}
FUSE_VERSION=${FUSE_VERSION:-jboss-fuse-6.1.0.redhat-379}

LOCAL_IP_ADDR=$(ifconfig eth0 | sed -ne '/inet addr:/ { s/.*inet addr://; s/ .*//; p }')
FLOATING_IP_ADDR=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

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

disable_firewall() {
  service iptables stop
  chkconfig iptables off
}

fuse_fix_hosts() {
  echo "$LOCAL_IP_ADDR $(hostname)" >>/etc/hosts
}

fuse_install() {
  curl -so /tmp/$FUSE_VERSION.zip http://$PROXY_IP_ADDR/jboss-fuse-medium-6.1.0.redhat-379.zip
  unzip -q /tmp/$FUSE_VERSION.zip -d /usr/local
}

fuse_create_admin_user() {
  echo -e "\n$1=$2,admin" >>/usr/local/$FUSE_VERSION/etc/users.properties 
}

fuse_set_nexus() {
  sed -ie "/^org.ops4j.pax.url.mvn.repositories=/,/[^\]$/ d; $ a\
org.ops4j.pax.url.mvn.repositories=http://$PROXY_IP_ADDR:8081/nexus/content/groups/public@id=mirror.repo" /usr/local/$FUSE_VERSION/fabric/import/fabric/configs/versions/1.0/profiles/default/io.fabric8.agent.properties
}

fuse_disable_indexer() {
  sed -ie '/<feature>hawtio-maven-indexer<\/feature>/ d' /usr/local/$FUSE_VERSION/system/io/hawt/hawtio-karaf/1.2-redhat-379/hawtio-karaf-1.2-redhat-379-features.xml
}

fuse_start() {
  export JAVA_HOME=/usr/lib/jvm/jre-1.7.0

  /usr/local/$FUSE_VERSION/bin/start
  while ! /usr/local/$FUSE_VERSION/bin/client </dev/null &>/dev/null
  do
    sleep 5
  done
}

fuse_create_fabric() {
  /usr/local/$FUSE_VERSION/bin/client "fabric:create --wait-for-provisioning --resolver manualip --manual-ip $FLOATING_IP_ADDR --profile fabric"
}

fix_gso
set_tz Europe/London
register_channels rhel-x86_64-server-6
install_packages java-1.7.0-openjdk unzip

disable_firewall

fuse_fix_hosts
fuse_install
fuse_create_admin_user admin admin
fuse_set_nexus
fuse_disable_indexer
fuse_start
fuse_create_fabric