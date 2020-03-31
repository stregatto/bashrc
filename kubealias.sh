#!/bin/bash

#
# my kubernetes alias
#
# you can use both standard kubernetes config file or ${context}.yaml file 
#

GREPPODSTATUS='Error|Unknown|CrashLoopBackOff|Terminating|Creating|Pending|ErrImagePull|ImagePullBackOff'

# list of contexts
# put a ${context}.yaml file if you want to separate config files
KENV__sre="sre"
KENV__nonprd="nonprod"
KENV__dev="dev"
KENV__prd="production"

# aliases 
ALIAS__node="get node --no-headers |cut -d\" \" -f1"
# to be fixed
ALIAS__wwp="get pod --all-namespaces -o wide|egrep '${GREPPODSTATUS}'"
ALIAS__events="get events --sort-by='.lastTimestamp'"
ALIAS__drain="--delete-local-data --force --ignore-daemonsets"
ALIAS__uncordon="uncordon"

function build_alias() {
  keyContext=$1
  CONTEXT=$2
  if [ -f "${HOME}/.kube/${CONTEXT}.yaml" ];
    then
        alias k${keyContext}="kubectl  --kubeconfig=${HOME}/.kube/${CONTEXT}.yaml"
    else
        alias k${keyContext}="kubectl --context ${CONTEXT}"
  fi
  for k in ${!ALIAS__*}; do
    key=$k
    value=${!key}
    key=${key##ALIAS__}
    if [ -f "${HOME}/.kube/${CONTEXT}.yaml" ];
    then
        alias k${keyContext}${key}="kubectl  --kubeconfig=${HOME}/.kube/${CONTEXT}.yaml ${value}"
    else
        alias k${keyContext}${key}="kubectl --context ${CONTEXT} ${value}"
    fi
  done
}

for k in ${!KENV__*}; do
  key=$k
  value=${!key}
  key=${key##KENV__}
  build_alias ${key} ${value}
done
