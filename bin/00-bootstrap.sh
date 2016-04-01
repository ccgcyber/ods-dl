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
bash::lib::ensure_cmd_or_install_package_apt juju juju juju-core juju-deployer juju-quickstart python-jujuclient

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
