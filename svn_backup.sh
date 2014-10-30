#!/bin/bash
    
dow=$(date +"%A")
#backDir="/mnt/ioSafe/svn_backups"
backDir="/home/backup/internal_backups/svn_backups"
numWeeks=4

## Make sure destination directories exist
for w in $(seq 1 ${numWeeks})
do
    if [[ ! -e ${backDir}/week_${w} ]] ; then mkdir -p ${backDir}/week_${w}/{Sunday,Monday,Tuesday,Wednesday,Thursday,Friday,Saturday} ; fi
done

## Which external backup drive to copy things to?
if [[ $(( $(date +"%-W") % 2 )) -eq 0 ]] ; then week="even" ; else week="odd" ; fi
    
if [ -d ${backDir} ]
then
    ## Get non-padded week number
    num=$(( $(( $(date +"%-U") % ${numWeeks} )) + 1 ))
    backupPath=${backDir}/week_${num}
    
    # backup the repositories on the local machine
    for r in $(ls -d /home/svn_repos/[A-Z]* | grep -v hook_scripts)
    do
        /usr/bin/svnadmin -q dump $r | /bin/gzip -q > $backupPath/${dow}/$(basename $r)_repo.dump.gz
    done

    if [ $(date +"%A") == "Sunday" ]
    then
        weekDir=$(date +"%Y_week_%W")
        # Copy the repository backups to the external devices
        if [[ ! -d "/mnt/${week}/backups/${weekDir}" ]]
        then
            mkdir /mnt/${week}/backups/${weekDir}/
        fi 
        cp -pr ${backupPath}/${dow}/ /mnt/${week}/backups/${weekDir}/SVN_Backups
    fi
else
    echo "Primary backup drive not mounted. Aborting."
fi
