#!/bin/bash
########################################################################################################################
## Script Name       : check_broken_links_cg.sh
## Description       : Nagios Plugin to monitor for broken links on a Website
## Notes/Args        : # Nagios exit codes:
##                         STATE_OK=0
##                         STATE_WARNING=1
##                         STATE_CRITICAL=2
##                         STATE_UNKNOWN=3
##                         STATE_DEPENDENT=4
## Author            : Doug Corwine [@gotdoug]
##
## Usage example: check_broken_links_cg.sh https://test.site1.com
########################################################################################################################

. /usr/lib64/nagios/plugins/utils.sh

# error handling
function err_exit { echo -e 1>&2; exit ${STATE_UNKNOWN}; }

## Check that we have a single argument
if [ $# -ne 1 ]; then
    echo -e "\n Usage error!\n Please provide URL to check.\n Example: $0 https://internetsecurity.xfinity.com\n"
    exit ${STATE_UNKNOWN}
fi

# check if proper site is supplied as the first argument
# https://test.site1.com
# https://www.site2.com
# http://www.site3.com
sites=("https://test.site1.com" "https://www.site2.com" "http://www.site3.com")
if [[ " ${sites[*]} " != *" ${1} "* ]]
then
    echo "Unknown site passed. Exiting"
    exit ${STATE_UNKNOWN}
fi

# check if wget is a valid command, else the execution of plugin will stop.
if ! which wget &> /dev/null; then echo "wget not found"; exit ${STATE_UNKNOWN}; fi

# normalize url for log name in /tmp
url=$(echo $1 | sed -r 's_https?://__;s/www\.//;s_/_._g;s/\.+/\./g;s/\.$//')

# remove log if it already exists in location specified in the variable of our script.
rm -f /tmp/$url.log || err_exit

if [[ -e /tmp/broken_links ]]
then
    rm -f /tmp/broken_links/*
else
    mkdir /tmp/broken_links
fi

wget --directory-prefix=/tmp -e robots=off --spider --no-check-certificate -r -S -nd -nH --delete-after $1 &> /tmp/$url.log &

while [ $(pgrep -l -f $url | grep wget | wc -l) != 0 ]; do
    sleep 8
    total=$(grep "HTTP request sent" /tmp/$url.log | wc -l)
    echo "$total HTTP requests sent thus far"
done

echo -e "\nAll done at $(date), calculating response codes.."
echo -e "\nResponse counts, sorted by HTTP code"

grep -A1 "^HTTP request sent" /tmp/$url.log |egrep -o "[0-9]{3} [A-Za-z]+(.*)" |sort |uniq -c |sort -nr || err_exit

a=$(cat /tmp/$url.log | grep -Eoh "Found [0-9]{1,3} broken link"| grep -oE "[0-9]{1,3}")
c=$(cat /tmp/$url.log | egrep -o "Found [A-Za-z]+(.*) broken links.")

if [[ $c != "Found no broken links." ]]; then
    echo -e "\nERROR: there are broken links."
    declare -i b
    b=$a+1;
    if [ $b = 2 ];
    then
        grep -A$b "1 broken link." /tmp/$url.log
    else
        grep -A$b "broken links." /tmp/$url.log
    fi
    exit ${STATE_CRITICAL}
    mv -f /tmp/$url.log /tmp/$url.FAILED_$(date +%Y%m%d%H%M%S) || err_exit
else
    echo "ALL IS WELL: No broken links found."
    rm -f /tmp/$url.log || err_exit
    exit ${STATE_OK}
fi
