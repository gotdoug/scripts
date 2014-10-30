#!/bin/bash

currentDir=$(dirname $0)
bkupDir=/mnt/backupWeekly
backupWeeklyDir=${bkupDir}/file
backupDailyDir=/mnt/backupDaily/file
repoDir=/data/repository
dateStamp=$(date +"%Y_week_%V") ## This is Year_week_WeekNumber, like 2010_week_03

function encryptDir () {
    ## Takes a directory with no subdirectories as an argument and encrypts all files within with aes-256 encryption
    for f in $(ls $1 | grep -v -e des3$ -e aes)
    do  
        ## Changing encryption to AES-256 (-aes-256-cbc) instead of TripleDES (-des3)
        ## openssl enc -des3 -salt -pass file:/root/.encPass.txt -in $1/${f} -out $1/${f}.des3
        openssl enc -aes-256-cbc -salt -pass file:/root/.encPass.txt -in $1/${f} -out $1/${f}.aes
        # Removing the original file because the encryption makes a copy
        rm -f $1/${f}
    done
}

function splitFile () {
    ## Takes a filename as an argument
    split -d -b 1024m $1 $1. 
    # Since split works on a copy of the file, we need to remove the original file after we split it
    rm -f $1
}

echo "Starting backups at $(date)"

# Clear out last week's backup
rm -f ${bkupDir}/*.md5sum
rm -rf ${backupWeeklyDir}/*

# First run the daily backups
${currentDir}/backupDaily.sh

# Move all daily backups to the weekly backup directory
mv ${backupDailyDir}/* ${backupWeeklyDir}

# Backup the customer repositories
echo "Starting repository backups at $(date)"
cd ${repoDir}

for repo in $(ls | grep -v -e ^dougcorwine -e ^adam.ellucid )
do
    repoName=REPOSITORY_${repo}
    tar -czf ${backupWeeklyDir}/${repoName}.tar.gz --exclude="*/temp_dir" --exclude="*/cache/convert" --exclude="*/import" --exclude="*/backups" --exclude="*/site_backup*" ${repo}
########################################################
## Changing to gzip due to time savings,
## This is the old rzip command
#######################################################
##    tar -cf ${backupWeeklyDir}/${repoName}.tar --exclude="*/temp_dir" --exclude="*/cache/convert" --exclude="*/import" --exclude="*/backups" --exclude="*/site_backup*" ${repo}
##    rzip -1 ${backupWeeklyDir}/${repoName}.tar
#######################################################
    if [ $(stat -c %s ${backupWeeklyDir}/${repoName}.tar.gz) -gt 1073741824 ]
    then
        splitFile "${backupWeeklyDir}/${repoName}.tar.gz"
    fi  
    unset repoName
done

# Backup the home directories, excluding the backup directories under ellucid
echo "Starting home directory backups at $(date)"
cd /home/
for d in $(ls /home/ | grep -v -e backup -e ftp -e httpd -e rack)
do
    dirName=HOME_${d}
    tar -cf ${backupWeeklyDir}/${dirName}.tar --exclude="*backup*" ${d}
    rzip -1 ${backupWeeklyDir}/${dirName}.tar
    if [ $(stat -c %s ${backupWeeklyDir}/${dirName}.tar.rz) -gt 1073741824 ]
    then
        splitFile "${backupWeeklyDir}/${dirName}.tar.rz"
    fi
    unset dirName
done

################################################################
## This is now done on a different system, so we don't have to duplicate it here
################################################################
## echo "Starting data directory backups at $(date)"
## cd /mnt/store/
## for d in $(ls -d dougc ellucid_code customer_logos )
## do
##     dirName=DATA_${d}
##     tar -cf ${backupWeeklyDir}/${dirName}.tar ${d}
##     rzip -1 ${backupWeeklyDir}/${dirName}.tar
##     if [ $(stat -c %s ${backupWeeklyDir}/${dirName}.tar.rz) -gt 1073741824 ]
##     then
##         splitFile "${backupWeeklyDir}/${dirName}.tar.rz"
##     fi
##     unset dirName
## done
################################################################

# After finished with all the backups, now encrypt the files for downloading
echo "Starting to encrypt the backups at $(date)"
encryptDir "${backupWeeklyDir}"

echo "Finished backup encryption at $(date)"

## Adding this here because this system is the last to finish
## Creating md5sum to check the downloads

cd ${bkupDir}
find . -mindepth 2 -type f -exec md5sum {} \; >> ${bkupDir}/${dateStamp}.md5sum

echo "Finished creating check hash at $(date)"
