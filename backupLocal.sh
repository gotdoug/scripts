#!/bin/bash

## This will do an rsync to create "incrementals" every night.
## Then on Saturday, it will do a full backup, after copying the existing backup to another directory
## It will utilize hard links and rsync to maintain the backups

currentDir=$(dirname $0)
localDir="/home/dougc"
backDir="/data/backups/home_dougc"
numBackups=6

if [[ $(date +"%u") -eq 6 ]]
then
    ## Saturday is the rotation day, so rotate to the next directory for "full" backups
    oldestBackup=$(expr ${numBackups} - 1)
    ## Remove oldest backup
    rm -rf ${backDir}/backup-${oldestBackup}

    ## Move the backups to the next on for "rotation"
    for i in $(seq -w ${oldestBackup} -1 1); 
    do
        prevBackup=$(expr ${i} - 1)

        ## Move previous backup out of the way 
        mv ${backDir}/backup-${prevBackup} ${backDir}/backup-${i}
    done
    mkdir ${backDir}/backup-0

    ## now do the backup
    rsync --quiet --archive --delete --ignore-errors --exclude-from=${currentDir}/backupLocal_exclude --link-dest=${backDir}/backup-1/ ${localDir}/ ${backDir}/backup-0/
else
    ## It is not Saturday, so just do an rsync to get "incremental"
    rsync --quiet --archive --exclude-from=${currentDir}/backupLocal_exclude ${localDir}/ ${backDir}/backup-0/
fi

