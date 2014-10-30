#!/bin/bash

backupDir=/mnt/backupDaily/slaveDB
backDate=$(date +%Y%m%d%H%M%S)

bhnd=$(echo "SHOW SLAVE STATUS\G" | mysql | grep "Seconds_Behind_Master:" | awk '{print $2}')

if [[ ${bhnd} > 0 ]]
then
    if [[ ${bhnd} -le 60 ]]
    then
        echo "slaveDB is ${bhnd} seconds behind, sleeping before continuing"
        sleep 120
    else
        echo "slaveDB is ${bhnd} seconds behind, exiting"
        echo "Check during nightly backups, at $(date), the slaveDB is ${bhnd} seconds behind masterDB" | mail -s "slaveDB replication is behind" sysadmin@mcnhealthcare.com
        exit 1
    fi
fi

for db in $(echo "SHOW DATABASES;" | mysql | grep -v -e ^Database -e schema$)
do
    if [[ ${db} == *prefix_* ]]
    then
        ## We don't want to make backup copies of the sessions table, but still need the table structure
        mysqldump --events --opt --ignore-table=${db}.ci_sessions ${db} > ${backupDir}/DB_${db}_${backDate}.sql
        mysqldump --no-data --opt ${db} ci_sessions >> ${backupDir}/DB_${db}_${backDate}.sql
    else
        mysqldump --events --opt ${db} > ${backupDir}/DB_${db}_${backDate}.sql
    fi
    rzip ${backupDir}/DB_${db}_${backDate}.sql
done

## Now backup the /etc/ directory
tar -cf ${backupDir}/ETC_${backDate}.tar /etc/ 2>&1 | grep -v Removing
rzip ${backupDir}/ETC_${backDate}.tar
