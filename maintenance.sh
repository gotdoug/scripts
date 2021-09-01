#!/bin/bash
##############################################################################################################
##
##                                   General Maintenance Script for DevOps
##
################################################### SUMMARY ##################################################
##
## Script Name 	: maintenance.sh                                          Date: April 24, 2020
##
## Author  	: Doug Corwine - douglas_corwine@comcast.com
##
## Purpose 	: Script to simplify the regular maintenance task that are performed by DevOps.
##
##
##############################################################################################################
ATTENTION="\033[41m\033[1;93m"
COLOR_RESET="\033[0m"
SCRIPT_NAME=$(readlink -f "$0")

if [[ $EUID > 0 ]]
then
    echo -e "${ATTENTION}This needs to be run as root. Please login as root and run again.${COLOR_RESET}"
    exit 1
fi

function showMenu {
    echo; echo;
    echo "#####################################################"
    echo "## Pick the option for the task you would like to do."
    echo "#####################################################"
    echo " 1 : Update Patching Repository File."
    echo " 2 : Update Meta Data for last patch."
    echo " 3 : Clean yum cache."
    echo " 4 : Check what packages have an update."
    echo " 5 : Check for package exclusions"
    echo " 6 : Run O/S patching"
    echo " 7 : Check if OP5 Notifications are enabled (You will need your API key for this function)"
    echo " 8 : Enable All OP5 Notifications (You will need your API key for this function)"
    echo " 9 : Disable All OP5 Notifications (You will need your API key for this function)"
    echo "10 : Reset local user password to random password."
    echo "11 : Check for Read-Only mounts"
    echo "12 : Check for used space on all partitions"
    echo "13 : Check status of SELinux"
    echo "14 : Disable SELinux (Will require server restart)"
    echo "15 : Enable SELinux, set to permissive (Will require server restart)"
    echo "16 : Enable SELinux, set to enforcing (Will require server restart) "
    echo "17 : Install common packages for all systems"
    echo "18 : Install NRPE base packages (installation only)"
    echo "19 : Attempt to update this script"
    echo " 0 : Exit"
    read -p "Select option to run: " menuOption
    runIt
} ## End function showMenu

function getPatchRepo () {
    ## Menu Option 1
    ## Check if this is a CentOS or RHEL system
    if [[ $(command -v lsb_release) != "" ]]
    then
        DISTRO=$(lsb_release -i | awk '{print $3}')
        OS_VER=$(lsb_release -rs | cut -f1 -d.)
    fi
    if [[ "${DISTRO}" == "" || "${OS_VER}" == "" || "${DISTRO}" == "n/a" || "${OS_VER}" == "n/a" ]]
    then
        if [[ -e /etc/centos-release ]]
        then
            DISTRO="CentOS"
            OS_VER=$(cat /etc/centos-release | tr -dc '0-9.'|cut -d \. -f1)
        elif [[ -e /etc/redhat-release ]]
        then
            DISTRO="RedHatEnterpriseServer"
            OS_VER=$(cat /etc/redhat-release | tr -dc '0-9.'|cut -d \. -f1)
        else
            echo -e "${ATTENTION}Unable to determine Operating Systems. Exiting.${COLOR_RESET}"
            exit 101
        fi
    fi

    if [[ ${DISTRO} == "CentOS" ]]
    then
        OS=centos
    elif [[ ${DISTRO} == "RedHatEnterpriseServer" ]]
    then
        OS=rhel
    else
        echo -e "${ATTENTION}Unknown Operating Systems. Exiting.${COLOR_RESET}"
        exit 101
    fi

    TMP_FILE="/tmp/repos.txt"
    rm -f ${TMP_FILE}

    ## Do we have previous patching repositories?
    cnt=$(ls /etc/yum.repos.d/ppstie-${OS}*.repo 2>/dev/null | wc -l)
    if [[ ${cnt} > 0 ]]
    then
        ## Get needed excludes line
        EXCLUDES=$(grep -h exclude $(ls -tr /etc/yum.repos.d/ppstie-${OS}*.repo | tail -n1))
    fi

    BASE_URL="https://yumrepo.sys.comcast.net/custom/${OS}/x86_64/${OS_VER}"
    curl -L -s -o ${TMP_FILE} ${BASE_URL}/?C=M\&O=A
    REPO=$(grep "a href=\"ppstie" ${TMP_FILE} | tail -n1  | awk -F'"' '{print $6}' | tr -d "/")
    REPO_FILE="/etc/yum.repos.d/${REPO}.repo"
    PATCH_FILE="/etc/ppstie_host_metadata.yml"
    ## Check if the repo file already exists. If it does not, write out the new repository file
    if [[ ! -e ${REPO_FILE} ]]
    then
        yum clean all
        sed -i"" 's/enabled[ ]*=[ ]*1/enabled=0/g' /etc/yum.repos.d/ppstie-${OS}*.repo 2>/dev/null
        if [[ ! -d "/etc/yum.repos.d/backup" ]]
        then
            mkdir -p /etc/yum.repos.d/backup
        fi
        mv /etc/yum.repos.d/ppstie-${OS}*.repo /etc/yum.repos.d/backup
        echo "[${REPO}]" > ${REPO_FILE}
        echo "baseurl = ${BASE_URL}/${REPO}/" >> ${REPO_FILE}
        echo "enabled = 1" >> ${REPO_FILE}
        echo "gpgcheck = 0" >> ${REPO_FILE}
        echo "name = ${REPO}" >> ${REPO_FILE}
        if [[ ${EXCLUDES} != "" ]]
        then
            echo ${EXCLUDES} >> ${REPO_FILE}
        fi
    fi
    rm -f ${TMP_FILE}
} ## End function getPatchRepo

function updatePatchMeta () {
    ## Menu Option 2
    PATCH_FILE="/etc/ppstie_host_metadata.yml"
    REPO_FILE=$(ls -tr /etc/yum.repos.d/ppstie*.repo 2>/dev/null | tail -n1)

    ## Check if the repo file exists. If it does not, write out failure message
    if [[ "${REPO_FILE}" != "" ]]
    then
        REPO=$(grep "name[ ]*=" ${REPO_FILE} | tail -n1  | awk -F'=' '{print $2}')
        if [[ -e ${PATCH_FILE} ]]
        then
            chattr -i ${PATCH_FILE}
        fi
        echo "---" > ${PATCH_FILE}
        echo "repo: \"$(echo ${REPO} | tr -d "^ ")\"" >> ${PATCH_FILE}
        echo "patch_version: \"$(echo ${REPO} | awk -F"-" '{print $4$5$6}')\"" >> ${PATCH_FILE}
        echo "patch_channel: \"others\"" >> ${PATCH_FILE}
        PATCH_DATE=$(date -d "$(yum history 2>/dev/null | grep -e "Update" -e " U" | head -n1 | awk -F"|" '{print $3}')" +"%Y-%m-%dT%H:%M:%SZ")
        echo -n "patch_date: \"${PATCH_DATE}\"" >> ${PATCH_FILE}
        chattr +i ${PATCH_FILE}
        echo "Patching meta file updated:"
        cat ${PATCH_FILE}
        echo
    else
        echo "Unable to determine last patch repository."
    fi
} ## End function updatePatchMeta

function cleanYumCache () {
    ## Menu Option 3
    YUMCACHE=$(grep cachedir /etc/yum.conf | awk -F"=" '{print $2}')
    if [[ "${YUMCACHE}" == *"/app/yum"* ]]
    then
        CACHEPATH="/app/yum/cache/x86_64"
    else
        CACHEPATH="/var/cache/yum/x86_64"
    fi
    SIZE=$(du -sh ${CACHEPATH}/* 2>/dev/null | awk '{print $1}')
    yum clean all > /dev/null 2>&1
    rm -rf ${CACHEPATH}/*
    echo "Cleaned up ${SIZE:-0 bytes} leaving available space:"
    df -Ph ${CACHEPATH}
} ## End function cleanYumCache

function checkPatchUpdates () {
    ## Menu Option 4
    read -p "Would you like to update the patching repo file before checking for updates?" UPDATE_PATCH_REPO
    if [[ ${UPDATE_PATCH_REPO,,} == "y" || ${UPDATE_PATCH_REPO,,} == "yes" ]]
    then
        getPatchRepo
    fi
    echo "The following packages are ready for update via yum:"
    yum -q --disablerepo=* --enablerepo=ppstie* check-update 2>/dev/null
}

function checkPackageExclusions () {
    ## Menu Option 5
    echo "The following exclusions were found for this server:"
    grep exclude /etc/yum.conf /etc/yum.repos.d/*.repo
}

function patchServer () {
    ## Menu Option 6
    yum --disablerepo=* --enablerepo=ppstie* --assumeyes update
    if [[ $? -ne 0 ]]
    then
        echo -e "${ATTENTION}Running update failed. Please check output and try again.${COLOR_RESET}"
        exit 104
    fi
    touch /fastboot 2>/dev/null
    echo -e "  ${ATTENTION}** Remember to reboot the server after patching has been completed.${COLOR_RESET}"
} ## End function patchServer

function checkNotificationStatus () {
    ## Menu Option 7
    ## check GRU for the notification status of this host
    if [[ ${GRU_API_KEY} == "" ]]
    then
        echo "You must set your api key for accessing the GRU API. To get you API key go to https://gru.xcal.tv/profile and copy your Api Token key."
        read -p "Enter your API Key: " GRU_API_KEY
    fi
    if [[ ${GRU_API_KEY} != "" ]]
    then
        curl -s -X GET "https://gru.xcal.tv/api/v1/hosts/$(hostname)/status" -H "authorization: Bearer ${GRU_API_KEY}" -H 'cache-control: no-cache'
    else
        echo -e "${ATTENTION}Unable to read API key. Exiting.${COLOR_RESET}"
        exit 107
    fi
} ## End fucnction checkNotificationStatus

function enableNotifications () {
    ## Menu Option 8
    if [[ ${GRU_API_KEY} == "" ]]
    then
        echo "You must set your api key for accessing the GRU API. To get you API key go to https://gru.xcal.tv/profile and copy your Api Token key."
        read -p "Enter your API Key: " GRU_API_KEY
    fi
    if [[ ${GRU_API_KEY} != "" ]]
    then
        curl -s -X POST "https://gru.xcal.tv/api/v1/hosts/$(hostname)/enable_all" -H "authorization: Bearer ${GRU_API_KEY}" -H 'cache-control: no-cache' > /dev/null
    else
        echo -e "${ATTENTION}Unable to read API key. Exiting.${COLOR_RESET}"
        exit 108
    fi
} ## End function enableNotifications

function disableNotifications () {
    ## Menu Option 9
    if [[ ${GRU_API_KEY} == "" ]]
    then
        echo "You must set your api key for accessing the GRU API. To get you API key go to https://gru.xcal.tv/profile and copy your Api Token key."
        read -p "Enter your API Key: " GRU_API_KEY
    fi
    if [[ ${GRU_API_KEY} != "" ]]
    then
        curl -s -X POST "https://gru.xcal.tv/api/v1/hosts/$(hostname)/disable_all" -H "authorization: Bearer ${GRU_API_KEY}" -H 'cache-control: no-cache' > /dev/null
    else
        echo -e "${ATTENTION}Unable to read API key. Exiting.${COLOR_RESET}"
        exit 109
    fi
} ## End function disableNotifications

function resetLocalPassword () {
    ## Menu Option 10
    read -p "Which local user's password would you like to reset? " localUser
    if [[ $(grep -c "^${localUser}:" /etc/passwd) -ne 1 ]]
    then
        echo "Requested user does not exist as a local user on this system. Halting password reset."
    else
        echo $(openssl rand -base64 32) | passwd --stdin ${localUser} >/dev/null
        if [[ $? != 0 ]]
        then
            echo -e "${ATTENTION}Resetting password for ${user} failed.${COLOR_RESET}"
            exit 110
        fi
    fi
} ## End function resetLocalPassword

function checkReadOnlyMounts () {
    ## Menu Option 11
    if [[ -e /usr/lib64/nagios/plugins/check_ro_mounts ]]
    then
        roMounts=$(/usr/lib64/nagios/plugins/check_ro_mounts -x /sys/fs/cgroup)
    else
        echo "Unable to find nagios plugin, checking with secondary method"
        roMounts=$(findmnt | grep "ro," | grep -v /sys/fs/cgroup)
    fi
    if [[ "${roMounts}" != "" && "${roMounts}" != *"RO_MOUNTS OK"* ]]
    then
        echo -e "Found Read-Only mounts:\n ${roMounts}"
    else
        echo "No Read only mounts found."
    fi
} ## End function checkReadOnlyMounts

function checkDiskSpace () {
    ## Menu Option 12
    echo "Available space on all partitions"
    df -Ph
} ## End function for checkDiskSpace

function checkSeLinuxStatus () {
    ## Menu Option 13
    sestatus | grep -e "SELinux status" -e "Current mode"
}

function disableSeLinux () {
    ## Menu Option 14
    sed -i.bak 's/\(SELINUX=\)\(.*\)/\1disabled/' /etc/selinux/config
    touch /fastboot 2>/dev/null
    echo -e "${ATTENTION}You need to reboot the server to completely disable SELinux.${COLOR_RESET}"
}

function enablePermissiveSeLinux () {
    ## Menu Option 15
    sed -i.bak 's/\(SELINUX=\)\(.*\)/\1permissive/' /etc/selinux/config
    touch /fastboot 2>/dev/null
    echo -e "${ATTENTION}You need to reboot the server to completely set SELinux to permissive.${COLOR_RESET}"
}

function enableEnforcingSeLinux () {
    ## Menu Option 16
    sed -i.bak 's/\(SELINUX=\)\(.*\)/\1enabled/' /etc/selinux/config
    touch /fastboot 2>/dev/null
    echo -e "${ATTENTION}You need to reboot the server to completely enable SELinux.${COLOR_RESET}"
}

function installCommonPackages () {
    ## menu option 17
    read -p "Would you like to update the patching repo file before installing common packages?" UPDATE_PATCH_REPO
    if [[ ${UPDATE_PATCH_REPO,,} == "y" || ${UPDATE_PATCH_REPO,,} == "yes" ]]
    then
        getPatchRepo
    fi
    yum --assumeyes install curl telnet openssh screen ntp vim-common vim-enhanced vim-filesystem vim-minimal smem
    echo -e "\nLatest version of common packages have bene installed/updated."
    cleanYumCache
}

function installNrpe () {
    ## menu option 18
    ## Check if we have the correct repo available
    CHK_REPO=$(yum -C repolist | grep -c epel)
    if [[ ${CHK_REPO} -ge 1 ]]
    then
        yum --assumeyes install nrpe nagios-plugins-nrpe nagios-plugins-all
        cleanYumCache
        echo -e "\nBase NRPE package installation completed. You can now configure NRPE for this server"
    else
        echo -e "${ATTENTION}Unable to find EPEL repo for package installation. Please install/enable the EPEL repository and try again.${COLOR_RESET}"
    fi
}

function updateMaintenenceScript () {
    ## menu option 19
    ## First check if we can get to the internal github, if we can, then pull in the upadted script
    nc -w 10 -z github.comcast.com 443
    if [[ $? -eq 0 ]]
    then
        curl -s -o ${SCRIPT_NAME} https://github.comcast.com/raw/SPA-CODE/Devopstore/main/misc_scripts/maintenance.sh?token=AAADAO5TPJYKY64CWO2BQ3DBBP6C4
        echo "Attepmting restart of script. If you don't see the expected changes, you may need to exit and restart."
        exec "${SCRIPT_NAME}" && exit 
    else
        echo -e "${ATTENTION}Unable to talk to internal GitHUb repository. Not able to update this script.${COLOR_RESET}"
    fi
}

function waitToContinue () {
    if [[ ${SKIP_WAIT} != "skip" ]]
    then
        read  -p "Press enter to continue: " waitKey
    fi
}

function runIt () {
    ## script starts here
    case ${menuOption} in
        "1")
            cleanYumCache
            getPatchRepo
            waitToContinue
            ;;
        "2")
            updatePatchMeta
            waitToContinue
            ;;
        "3")
            cleanYumCache
            waitToContinue
            ;;
        "4")
            checkPatchUpdates
            waitToContinue
            ;;
        "5")
            checkPackageExclusions
            waitToContinue
            ;;
        "6")
            cleanYumCache
            getPatchRepo
            patchServer
            waitToContinue
            cleanYumCache
            updatePatchMeta
            waitToContinue
            ;;
        "7")
            checkNotificationStatus
            waitToContinue
            ;;
        "8")
            enableNotifications
            waitToContinue
            ;;
        "9")
            disableNotifications
            waitToContinue
            ;;
        "10")
            resetLocalPassword
            waitToContinue
            ;;
        "11")
            checkReadOnlyMounts
            waitToContinue
            ;;
        "12")
            checkDiskSpace
            waitToContinue
            ;;
        "13")
            checkSeLinuxStatus
            waitToContinue
            ;;
        "14")
            disableSeLinux
            waitToContinue
            ;;
        "15")
            enablePermissiveSeLinux
            waitToContinue
            ;;
        "16")
            enableEnforcingSeLinux
            waitToContinue
            ;;
        "17")
            installCommonPackages
            waitToContinue
            ;;
        "18")
            installNrpe
            waitToContinue
            ;;
        "19")
            updateMaintenenceScript
            waitToContinue
            ;;
        "0" | "q" | "Q")
            echo "Good bye"
            exit
            ;;
        *)
            clear
            showMenu
            ;;
    esac
} ## End function runIt

## Check if an arugment was passed and that it is an integer. If so, run that instead of displaying the menu
re='^[0-9]+$'
if [[ $# -gt 0 && $# -lt 2 && $1 =~ ${re} ]]
then
    menuOption="$1"
    export SKIP_WAIT="skip"
    runIt
else
    while [[ true ]]
    do
        showMenu
    done
fi
