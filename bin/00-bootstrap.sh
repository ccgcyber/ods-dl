#!/bin/bash
#####################################################################
#
# Initialize Juju environment 
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
bash::lib::ensure_cmd_or_install_package_apt jq jq
bash::lib::ensure_cmd_or_install_package_apt awk awk
bash::lib::ensure_cmd_or_install_package_apt juju juju juju-core juju-deployer juju-quickstart python-jujuclient charm-tools
bash::lib::ensure_cmd_or_install_package_apt bzr bzr

# Switching to project
juju::lib::switchenv "${PROJECT_ID}" 

# Bootstrapping project 
juju bootstrap 2>/dev/null \
  && bash::lib::log debug Succesfully bootstrapped "${PROJECT_ID}" \
  || bash::lib::log info "${PROJECT_ID}" already bootstrapped

juju deploy --to 0 juju-gui 2>/dev/null \
  && bash::lib::log debug Successfully deployed juju-gui to machine-0 \
  || bash::lib::log info juju-gui already deployed or failed to deploy juju-gui

juju expose juju-gui 2>/dev/null \
  && {
		export JUJU_GUI="$(juju api-endpoints | cut -f2 -d' ' | cut -f1 -d':')"
		export JUJU_PASS="$(grep "password" "/home/${USER}/.juju/environments/${PROJECT_ID}.jenv" | cut -f2 -d' ')"
		bash::lib::log info Juju GUI now available on https://${JUJU_GUI} with user admin:${JUJU_PASS}
  } \
  || bash::lib::log info juju-gui already deployed or failed to deploy juju-gui

bash::lib::log debug Bootstrapping process finished for ${PROJECT_ID}. You can safely move to deployment. 

for file in $(find "${MYDIR}/../var/ssh" -name "*.pub"); do
	juju authorized-keys import "$(cat ${file})" \
	  && bash::lib::log debug Successfully imported SSH key ${file} \
	  || bash::lib::log warn Could not import SSH key ${file}

done

# Now copying charms and layers to local FS
if [ "x${JUJU_REPOSITORY}" = "x" ]
then
	bash::lib::log info Creating folder "${HOME}/charms" to store local charms
	[ -d "~/charms" ] || mkdir -p "${HOME}/charms"
	[ -d "~/charms/trusty" ] || mkdir -p "${HOME}/charms/trusty"

	bash::lib::log info Creating JUJU_REPOSITORY="${HOME}/charms" environment variable
	export JUJU_REPOSITORY="${HOME}/charms"
fi

if [ "x${LAYER_PATH}" = "x" ]
then
	bash::lib::log info Creating folder "${HOME}/charms/layers" to store local layers
	[ -d "~/charms" ] || mkdir -p "${HOME}/charms/layers"

	bash::lib::log info Creating JUJU_REPOSITORY="${HOME}/charms/layers" environment variable
	export LAYER_PATH="${HOME}/charms/layers"
fi

bash::lib::log info Cloning repos to get access to local charms
git clone https://github.com/SaMnCo/layer-skymind-dl4j.git "${LAYER_PATH}/deeplearning4j" 2>/dev/null 1>/dev/null \
	&& bash::lib::log info "Successfully cloned deeplearning4j charm" \
	|| bash::die "Could not clone deeplearning4j charm"
git clone https://github.com/SaMnCo/layer-nvidia-cuda.git "${LAYER_PATH}/cuda" 2>/dev/null 1>/dev/null \
	&& bash::lib::log info "Successfully cloned cudacuda charm" \
	|| bash::die "Could not clone cuda charm"

bzr branch lp:~samuel-cozannet/charms/trusty/mesos-slave/trunk "${JUJU_REPOSITORY}/charms/mesos-slave" 2>/dev/null 1>/dev/null \
	&& bash::lib::log info "Successfully cloned Mesos Slave charm" \
	|| bash::die info "Could not clone Mesos Slave charm"
bzr branch lp:~frbayart/charms/trusty/mesos-master/trunk "${JUJU_REPOSITORY}/charms/mesos-master" 2>/dev/null 1>/dev/null \
	&& bash::lib::log info "Successfully cloned Master charm charm" \
	|| bash::die "Could not clone Mesos Master charm"
bzr branch lp:~frbayart/charms/trusty/datafellas-notebook/trunk "${JUJU_REPOSITORY}/charms/datafellas-notebook" 2>/dev/null 1>/dev/null \
	&& bash::lib::log info "Successfully cloned Spark Notebook charm" \
	|| bash::lib::die "Could not clone Spark Notebook charm"

for CHARM in deeplearning4j cuda
do
	cd "${LAYER_PATH}/${CHARM}" 2>/dev/null 1>/dev/null \
	&& bash::lib::log info "Successfully built ${CHARM} charm" \
	|| bash::die "Could not build ${CHARM} charm"
	charm build 
done

bash::lib::log info "Bootstrapping complete. You can now move to the next step, Deployment"

