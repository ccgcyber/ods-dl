#!/bin/bash
#####################################################################
#
# Deploy
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
		case "${CLOUD_ID}" in 
			"aws" )
				bash::lib::log info Using GPU for this deployment
				CONSTRAINTS="instance-type=g2.2xlarge root-disk=${LOG_STORAGE}G"
				bash::lib::log info Using constraints ${CONSTRAINTS} for this deployment
				;;
			"azure" ) 
				bash::lib::log warn GPU not enabled on Azure, switching back to no GPU
				ENABLE_GPU=0
				CONSTRAINTS="mem=4G cpu-cores=2 root-disk=${LOG_STORAGE}G"
				bash::lib::log warn Using constraints ${CONSTRAINTS} for this deployment
				;;
			"local" )
				bash::lib::log warn GPU not enabled on LXD
				ENABLE_GPU=0
				CONSTRAINTS="mem=4G cpu-cores=2 root-disk=${LOG_STORAGE}G"
				;;
		esac
	;;
	* )
	;;
esac

#####################################################################
#
# Deploy Apache Hadoop
#
#####################################################################
## Deploy HDFS Master
juju::lib::deploy cs:trusty/apache-hadoop-namenode-1 namenode "mem=4G cpu-cores=2 root-disk=32G"

## Deploy YARN 
juju::lib::deploy cs:trusty/apache-hadoop-resourcemanager-1 resourcemanager "mem=2G cpu-cores=2"

## Deploy Compute slaves
juju::lib::deploy cs:trusty/apache-hadoop-slave-1 slave "${CONSTRAINTS}"

juju::lib::add_unit slave 2

## Deploy Hadoop Plugin
juju::lib::deploy cs:trusty/apache-hadoop-plugin-13 plugin

## Manage Relations
juju::lib::add_relation resourcemanager namenode
juju::lib::add_relation slave resourcemanager
juju::lib::add_relation slave namenode
juju::lib::add_relation plugin resourcemanager
juju::lib::add_relation plugin namenode

#####################################################################
#
# Deploy Apache Spark 
#
#####################################################################

# Services
juju::lib::deploy cs:trusty/apache-spark-7 spark "mem=2G cpu-cores=2"

# Relations
juju::lib::add_relation spark plugin

#####################################################################
#
# Deploy Spark Notebook
#
#####################################################################

# # Services
# juju::lib::deploy spark-notebook-1 spark-notebook

# # Relations
# juju::lib::add_relation spark spark-notebook

# # Exposition
# juju::lib::expose spark-notebook
