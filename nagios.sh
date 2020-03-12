#!/bin/bash

#
# my naemon alias
#

COMMENT='Updating Server'
TIME='5'
HOST_PRD='thruk.production'
HOST_NONPROD='thruk.nonprod'
ENVIRONMENT='production'
HELP=0

function thruk_help() {
  echo "
This is the thruk/nagios/naemon/omd utility
You can use it via command line to add a downtime or do
other things... if you write the bash.
Firs, you need to pass the ThrukAuthKey as env var.
ThrukAuthKey_PRD for production and
ThrukAuthKey_NONPRD for NONPRD, if you do not have qa this is useless.

-t --target         the target server, perhaps his fqdn
-e --environment    the environment 'prd' or 'qa' (or else DEFAULT: prd)
-m --minutes        the miutes for downtime (DEFAULT: 20m)
-c --comment        some clever comment (DEFAULT: Updating Server )
"
}

function nagios_util() {
    if [[ $# -lt 1 ]]
      then
        thruk_help
        HELP=1
    fi
    while [[ $# -gt 0 ]]
      do
        key="$1"
        case $key in
          -t|--target)
            TARGET="$2"
            shift
            shift
          ;;
          -e|--environment)
            ENVIRONMENT="$2"
            shift
            shift
          ;;
          -m|--minutes)
            TIME="$2"
            shift
            shift
          ;;
          -c|--comment)
            COMMENT="$2"
            shift
            shift
          ;;
          -h|--help)
            thruk_help
            HELP=1
            shift
            shift
          ;;
          *)
            thruk_help
            HELP=1
          ;;
        esac
      done
    if [ ${HELP} == 0 ]
      then
        if [ ${ENVIRONMENT} == 'prd' ]
        then
          ThrukAuthKey=${ThrukAuthKey_PRD}
          HOST=${HOST_PRD}
        fi
        if [ ${ENVIRONMENT} == 'nonprd' ]
        then
          ThrukAuthKey=${ThrukAuthKey_NONPRD}
          HOST=${HOST_NONPROD}
        fi
        if [ -z ${COMMENT+x} ]; then echo 'find'; fi
        DATA='{ "start_time": "now", "end_time": "+'${TIME}'m", "comment_data": "'${COMMENT}'"}'
        echo "Setting the downtime: ${TIME}m to host: ${HOST} "
        curl -l -H 'Content-Type: application/json' -H "X-Thruk-Auth-Key: ${ThrukAuthKey}" --data "${DATA}" "https://${HOST}/omd/PRD/thruk/r/host/${TARGET}/cmd/schedule_and_propagate_host_downtime"
      fi
}
