#!/bin/bash
backupDir=/mnt/backupDaily/file
backDate=$(date +%Y%m%d%H%M%S)

## Now backup the /etc/ directory
tar -cf ${backupDir}/ETC_${backDate}.tar /etc/ 2>&1 | grep -v Removing
nice rzip ${backupDir}/ETC_${backDate}.tar

## Now backup the /var/www/html/ and the /var/lib/rabbitmq/ directory
tar -cf ${backupDir}/VAR_${backDate}.tar /var/www/html/ /var/lib/rabbitmq/ 2>&1 | grep -v Removing
nice rzip ${backupDir}/VAR_${backDate}.tar
