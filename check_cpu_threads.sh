#!/bin/bash
########################################################################################################################
## Script Name       : check_cpu_threads.sh
## Description       : Nagios Plugin to monitor number of cpu threads currently running
## Notes/Args        : # Nagios exit codes:
##                         STATE_OK=0
##                         STATE_WARNING=1
##                         STATE_CRITICAL=2
##                         STATE_UNKNOWN=3
##                         STATE_DEPENDENT=4
## Author            : Doug Corwine [@gotdoug]
##
## Usage example: check_cpu_threads.sh -w 2000 -c 4000
########################################################################################################################

if [[ $# -ne 4 ]]
then
    echo "You must pass warning and critical levels to the script, like check_cpu_threads -w 10 -c 20"
    exit ${STATE_UNKNOWN}
fi

. /usr/lib64/nagios/plugins/utils.sh

THREADCNT=$(ps -eLf | wc -l)

if [[ $1 == "-w" && $2 =~ ^[0-9]+$ ]]
then
    WARN=$2
elif [[ $3 == "-w" && $4 =~ ^[0-9]+$ ]]
then
    WARN=$4
else
    echo "Unable to determine warning level."
    exit ${STATE_UNKNOWN}
fi

if [[ $1 == "-c" && $2 =~ ^[0-9]+$ ]]
then
    CRIT=$2
elif [[ $3 == "-c" && $4 =~ ^[0-9]+$ ]]
then
    CRIT=$4
else
    echo "Unable to determine critical level."
    exit ${STATE_UNKNOWN}
fi

if [[ ${THREADCNT} -ge ${CRIT} ]]
then
    echo "${THREADCNT} cpu threads currently running"
    exit ${STATE_CRITICAL}
elif [[ ${THREADCNT} -ge ${WARN} ]]
then
    echo "${THREADCNT} cpu threads currently running"
    exit ${STATE_WARNING}
else
    echo "${THREADCNT} cpu threads currently running"
    exit ${STATE_OK}
fi

echo "Unable to run check. Exiting."
exit ${STATE_UNKNOWN}
