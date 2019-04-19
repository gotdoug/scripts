#!/bin/bash
########################################################################################################################
## Script Name       : check_redis_sentinels.sh
## Description       : Nagios Plugin to monitor for a quorum with the Redis Sentinels
## Notes/Args        : # Nagios exit codes:
##                         STATE_OK=0
##                         STATE_WARNING=1
##                         STATE_CRITICAL=2
##                         STATE_UNKNOWN=3
##                         STATE_DEPENDENT=4
## Author            : Doug Corwine [@gotdoug]
##
## Usage example: check_redis_sentinels.sh
########################################################################################################################

. /usr/lib64/nagios/plugins/utils.sh
OUTPUT=$(redis-cli -p 26379 SENTINEL ckquorum redis_cluster_name)
STATUS=$(echo ${OUTPUT} | awk '{print $1}')
COUNT=$(echo ${OUTPUT} | awk '{print $2}')
checkExit=$?
if [[ ${checkExit} != 0 ]]
then
    echo "Unable to connect to local Redis Sentinel."
    exit ${STATE_WARNING}
fi

if [[ ${STATUS} == "OK" ]]
then
    echo ${OUTPUT}
    exit ${STATE_OK}
else
    echo "Redis Sentinels do NOT have a quorum for failover."
    echo ${OUTPUT}
    exit ${STATE_CRITICAL}
fi
