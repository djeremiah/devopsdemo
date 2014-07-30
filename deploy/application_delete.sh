#!/bin/bash -ex

if [ -z $OS_AUTH_URL ] || [ -z $PREFIX ]; then
  echo "error: must set OpenStack credentials and inputs"
  exit 1
fi

get_ips() {
  eval $(utils/wait-stack.py openshift)
}

delete_stacks() {
  heat stack-delete $PREFIX-database
  heat stack-delete $PREFIX-fabric
}

delete_openshift() {
  utils/deploy-openshift.py delete https://$BROKER_IP/broker/rest ${PREFIX}monster
}

get_ips
delete_stacks
delete_openshift