#!/bin/bash
######################################################################
##
## This script will cycle through all the rabbit processing scripts
## in the codeDir directory, and kill each of them, including any
## parent or child processes that were launched because of the script.
## 
######################################################################

codeDir="/home/code/public_html/application/cron_scripts"
rabbitCommand="/usr/sbin/rabbitmqctl list_queues | grep -v -e ^Listing -e done.$ -e 0$ | wc -l"

## list the rabbit queues, MUST be run as root or rabbituser
## Don't run the script if there are things currently being processed
rabbitqueues=$(ssh rabbituser@rabbit.host ${rabbitCommand})
chk=0
while [[ ${rabbitqueues} -gt 0 ]]
do
    if [[ ${chk} -lt 10 ]]
    then
        chk=$[chk + 1]
        sleep 30
        rabbitqueues=$(ssh rabbitmq@rabbit.mcn ${rabbitCommand})
    else
        echo "Unable to kill rabbit processes, queues still active"
        exit 1
    fi
done

## Recursive function to get the parent id of the process id passed
function getPid {
    local kp=''
    for p in $(pgrep -d " " -P $1 )
    do
        kp+=" ${p} $(getPid ${p})"
    done
    echo "${kp}"
}

cd ${codeDir}
for f in $(ls process*.sh)
do
    for pid in $(ps -C ${f} -o pid= )
    do
        ## get parent id of pid and then send that through the loop
        ppid=$(ps -o ppid= ${pid})
        kpid=$(getPid ${ppid})
        kill ${kpid} ${ppid}
    done
done
