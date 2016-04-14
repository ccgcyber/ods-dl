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

				juju deploy local:${DEFAULT_SERIES}/cuda 2>/dev/null 1>/dev/null && \
					bash::lib::log info Successfully added CUDA to the environment || \
					bash::lib::die Could not add CUDA. Please build the charm locally. 
				;;
			"azure" ) 
				bash::lib::log warn GPU not enabled on Azure, switching back to no GPU
				ENABLE_GPU=0
				CONSTRAINTS="mem=4G cpu-cores=2 root-disk=${LOG_STORAGE}G"
				bash::lib::log warn Using constraints ${CONSTRAINTS} for this deployment

				juju deploy local:${DEFAULT_SERIES}/cuda 2>/dev/null 1>/dev/null && \
					bash::lib::log info Successfully added CUDA to the environment || \
					bash::lib::die Could not add CUDA. Please build the charm locally. 
				;;
			"local" )
				bash::lib::log warn GPU not enabled on LXD
				bash::lib::ensure_cmd_or_install_package_apt lxc lxd 
				for CHAR_DEVICE in $(ls /dev | grep nvidia)
				do
					lxc profile device add docker ${CHAR_DEVICE} unix-char path=/dev/${CHAR_DEVICE}
				done 
				CONSTRAINTS="mem=4G cpu-cores=2 root-disk=${LOG_STORAGE}G"

				# NOTE: There is no need to deploy the CUDA charm as all units will have the GPU
				# 		enabled by default via LXD sharing the char device. 
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
juju::lib::deploy cs:${DEFAULT_SERIES}/apache-hadoop-namenode-1 namenode "mem=4G cpu-cores=2 root-disk=32G"


## Deploy Compute slaves
juju::lib::deploy cs:${DEFAULT_SERIES}/apache-hadoop-slave-1 slave "${CONSTRAINTS}"

juju::lib::add_unit slave 2

## Deploy Hadoop Plugin
juju::lib::deploy cs:${DEFAULT_SERIES}/apache-hadoop-plugin-13 plugin

## Manage Relations
juju::lib::add_relation slave namenode
juju::lib::add_relation plugin namenode

#####################################################################
#
# Deploy Scheduler
#
#####################################################################
case "${SCHEDULER}" in
	"yarn" )
		## Deploy YARN 
		bash::lib::log info "Using YARN as the default Scheduler"
		SCHEDULER_SERVICE="resourcemanager"
		juju::lib::deploy cs:${DEFAULT_SERIES}/apache-hadoop-resourcemanager-1 "${SCHEDULER_SERVICE}" "mem=2G cpu-cores=2"
		juju::lib::add_relation namenode "${SCHEDULER_SERVICE}" 
		juju::lib::add_relation slave "${SCHEDULER_SERVICE}"
		juju::lib::add_relation plugin "${SCHEDULER_SERVICE}"
	
		#####################################################################
		#
		# Deploy Apache Spark 
		#
		#####################################################################

		# Services
		juju::lib::deploy cs:${DEFAULT_SERIES}/apache-spark-7 spark "mem=2G cpu-cores=2"

		# Relations
		juju::lib::add_relation spark plugin
	;;
	* )
		# Deploy Mesos
		bash::lib::log info "Using Mesos as the default scheduler"
		SCHEDULER_SERVICE="mesos-master"

		juju::lib::deploy local:${DEFAULT_SERIES}/mesos-master "${SCHEDULER_SERVICE}" "${CONSTRAINTS}"

		# # Using Mesos Slave "classic charm"
		# for UNIT in $(juju status --format=json | jq '.services.gpu2.units[].machine' | tr -d \" | sort )
		# do
		# 	juju::lib::deploy_to "local:${DEFAULT_SERIES}/mesos-slave" "mesos-slave-${UNIT}" "${UNIT}"
		# 	juju::lib::add_relation "mesos-slave-${UNIT}" "mesos-master"
		# done

		# Using Mesos Slave in the subordinate format
		juju deploy local:${DEFAULT_SERIES}/mesos-slave mesos-slave 2>/dev/null 1>/dev/null && \
			bash::lib::log info Successfully added mesos-slave to the environment || \
			bash::lib::die Could not add mesos-slave. Please build the charm locally. 
		
		# Relations
		juju::lib::add-relation mesos-slave:juju-info slave:juju-info
		juju::lib::add-relation mesos-slave:"${SCHEDULER_SERVICE}" "${SCHEDULER_SERVICE}":"${SCHEDULER_SERVICE}"
		# # Need to add a timer for that to make sure Hadoop is done when rebooting
		# juju::lib::add-relation cuda "${SCHEDULER_SERVICE}"

		#####################################################################
		#
		# Deploy DL4j
		#
		#####################################################################

		# Services
		juju deploy local:${DEFAULT_SERIES}/deeplearning4j dl4j 2>/dev/null 1>/dev/null && \
			bash::lib::log info Successfully added DL4j to the environment || \
			bash::lib::die Could not add DL4j. Please build the charm locally. 
		
		# Relations
		juju::lib::add_relation "${SCHEDULER_SERVICE}" dl4j

		#####################################################################
		#
		# Deploy Spark Notebook
		#
		#####################################################################

		# Services
		juju deploy local:${DEFAULT_SERIES}/datafellas-notebook datafellas-notebook 2>/dev/null 1>/dev/null && \
			bash::lib::log info Successfully added Data Fellas to the environment || \
			bash::lib::die Could not add Data Fellas. Please build the charm locally. 

		# Relations
		juju::lib::add_relation "${SCHEDULER_SERVICE}" datafellas-notebook

		# Exposition
		juju::lib::expose datafellas-notebook

	;;
esac

STATUS=""
# Now wait until Slave service is up & running to deploy CUDA
until [ "${STATUS}" = "active" ]
do 
	bash::lib::log debug Waiting for Slaves to be up & running
	STATUS=$(juju status --format=json | jq '.services.slave."service-status".current' | tr -d \")
	sleep 30
done

# # Need to add a timer for that to make sure Hadoop is done when rebooting
juju::lib::add_relation cuda slave

STATUS=""
# Now wait until Slave service is up & running to deploy CUDA
until [ "${STATUS}" = "active" ]
do 
	bash::lib::log debug Waiting for Mesos Master to be up & running
	STATUS=$(juju status --format=json | jq '.services."mesos-master"."service-status".current' | tr -d \")
	sleep 30
done

juju::lib::add_relation deeplearning4j mesos-master

# OK!! 
