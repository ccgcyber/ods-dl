#!/bin/bash
#####################################################################
#
# Deploy demo
#
# Notes: 
# 
# Maintainer: Samuel Cozannet <samuel.cozannet@canonical.com> 
#
#####################################################################

# In this context, bypassing GPU configuraiton 
ENABLE_GPU=1

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
done 

# Check install of all dependencies
bash::lib::log debug Validating dependencies
bash::lib::ensure_cmd_or_install_package_apt git git-all

# Switching to project 
juju::lib::switchenv "${PROJECT_ID}" 

# Compute Slave Constraints
CONSTRAINTS=""
case "${ENABLE_GPU}" in
	"0" )
		bash::lib::log info Not using GPU for this deployment
		CONSTRAINTS="mem=4G cpu-cores=2 root-disk=${LOG_STORAGE}G"
	;;
	"1" )
		case "${CLOUD}" in 
			"aws" )
				bash::lib::log info Using GPU for this deployment
				CONSTRAINTS="instance-type=g2.2xlarge"
				;;
			"azure" ) 
				bash::lib::log warn GPU not enabled on Azure, exiting.
				exit 3
				;;
			"local" )
				bash::lib::log warn GPU not enabled on LXD. Exiting
				exit 3
				;;
		esac
	;;
	* )
	;;
esac

#####################################################################
#
# Deploy GPU Machine
#
#####################################################################
## Deploy HDFS Master
juju::lib::deploy trusty/ubuntu gpu-machine "${CONSTRAINTS}"

