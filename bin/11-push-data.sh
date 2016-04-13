#!/bin/bash
#####################################################################
#
# Configure Demo
#
# Notes: 
# 
# Maintainer: Samuel Cozannet <samuel.cozannet@canonical.com> 
#
#####################################################################

# Validating I am running on debian-like OS
[ -f /etc/debian_version ] || {
	echo "We are not running on a Debian-like system. Exiting..."
	exit 1
}

# Load Configuration
MYNAME="$(readlink -f "$0")"
MYDIR="$(dirname "${MYNAME}")"
MYCONF="project.conf"

for file in $(find ${MYDIR}/../etc -name "${MYCONF}") $(find ${MYDIR}/../lib -name "*lib*.sh" | sort) ; do
	echo Sourcing ${file}
	source ${file}
	sleep 1
done 

# Check install of all dependencies

# Switching to project
juju::lib::switchenv "${PROJECT_ID}" 

#####################################################################
#
# Uploading OIL runs to machine
#
#####################################################################

TARGET_UNIT="namenode/0"
TARGET_FOLDER="$(echo ${DATASET} | cut -f1 -d'.')"
juju scp "${DATASET}" "${TARGET_UNIT}":/home/ubuntu/ && \

juju ssh "${TARGET_UNIT}" "sudo tar -xfz /home/ubuntu/${DATASET} -C /mnt/"
juju ssh "${TARGET_UNIT}" "sudo find /mnt/${TARGET_FOLDER} -name "*:*" -delete"
juju ssh "${TARGET_UNIT}" "hdfs dfs -copyFromLocal /mnt/${TARGET_FOLDER} /user/ubuntu/"



