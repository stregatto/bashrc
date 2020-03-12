#!/bin/bash

#
# my kubernetes alias
#

GREPPODSTATUS='Error|Unknown|CrashLoopBackOff|Terminating|Creating|Pending|ErrImagePull|ImagePullBackOff'

KENV__sre="sre"
KENV__nonprd="nonprod"
KENV__dev="dev"
KENV__prd="production"

ALIAS__node="get node --no-headers |cut -d\" \" -f1"
# to be fixed
ALIAS__wwp="get pod --all-namespaces -o wide|egrep '${GREPPODSTATUS}'"
ALIAS__events="get events --sort-by='.lastTimestamp'"
ALIAS__drain="--delete-local-data --force --ignore-daemonsets"
ALIAS__uncordon="uncordon"

function build_alias() {
  keyContext=$1
  CONTEXT=$2
  alias k${keyContext}="kubectl --context ${CONTEXT}"
  for k in ${!ALIAS__*}; do
    key=$k
    value=${!key}
    key=${key##ALIAS__}
    alias k${keyContext}${key}="kubectl --context ${CONTEXT} ${value}"
  done
}

for k in ${!KENV__*}; do
  key=$k
  value=${!key}
  key=${key##KENV__}
  build_alias ${key} ${value}
done
