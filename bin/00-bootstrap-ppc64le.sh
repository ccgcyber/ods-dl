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

[ "${PROJECT_ID}" = "ENTER_PROJECT_NAME" ] && bash::lib::die PROJECT_ID not set. Please update etc/project.conf
[ "${DATASET}" = "PATH_TO_DATASET_TGZ" ] && bash::lib::die PATH_TO_DATASET_TGZ not set. Please update etc/project.conf.

# Check install of all dependencies
bash::lib::log debug Validating dependencies
bash::lib::ensure_cmd_or_install_package_apt jq jq
bash::lib::ensure_cmd_or_install_package_apt git git
bash::lib::ensure_cmd_or_install_package_apt bzr bzr
bash::lib::ensure_cmd_or_install_package_apt awk awk
bash::lib::ensure_cmd_or_install_package_apt wget wget curl
bash::lib::ensure_cmd_or_install_package_apt juju juju juju-core juju-deployer juju-quickstart python-jujuclient 
bash::lib::ensure_cmd_or_install_package_apt charm charm-tools

#####################################################################
#
# Fix locales problems on Power 8
#
#####################################################################

export LC_ALL="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"
dpkg-reconfigure locales


cat >> /etc/profile.d/locales.sh <<EOF
#!/bin/bash
export LC_ALL="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"
EOF

chmod +x /etc/profile.d/locales.sh

#####################################################################
#
# Prepare for GPU
#
#####################################################################
apt-get update -yqq && apt-get upgrade -yqq
apt-get install -yqq build-essential linux-image-extra-virtual linux-image-extra-`uname -r`

CUDA_VERSION="7.5"
CUDA_SUB_VERSION="18"
CUDA_PKG_VERSION="7-5"

wget -c -P /tmp "http://developer.download.nvidia.com/compute/cuda/7.5/Prod/local_installers/cuda-repo-ubuntu1404-7-5-local_7.5-18_ppc64el.deb"
dpkg -i /tmp/cuda-repo-ubuntu1404-7-5-local_7.5-18_ppc64el.deb

apt-add-repository -y ppa:openjdk-r/ppa
apt-add-repository -y ppa:jochenkemnade/openjdk-8

apt-get update -yqq

# What this does is really copy all packages from CUDA into /var/cuda-repo-7-5-local
apt-get install -yqq --no-install-recommends --force-yes \
    cuda-license-${CUDA_PKG_VERSION} \
    cuda-misc-headers-${CUDA_PKG_VERSION} \
    cuda-core-${CUDA_PKG_VERSION} \
    cuda-cudart-${CUDA_PKG_VERSION} \
    cuda-driver-dev-${CUDA_PKG_VERSION} \
    cuda-cudart-dev-${CUDA_PKG_VERSION} \
    cuda-command-line-tools-${CUDA_PKG_VERSION} \
    cuda-nvrtc-${CUDA_PKG_VERSION} \
    cuda-cusolver-${CUDA_PKG_VERSION} \
    cuda-cublas-${CUDA_PKG_VERSION} \
    cuda-cufft-${CUDA_PKG_VERSION} \
    cuda-curand-${CUDA_PKG_VERSION} \
    cuda-cusparse-${CUDA_PKG_VERSION} \
    cuda-npp-${CUDA_PKG_VERSION} \
    cuda-nvrtc-dev-${CUDA_PKG_VERSION} \
    cuda-cusolver-dev-${CUDA_PKG_VERSION} \
    cuda-cublas-dev-${CUDA_PKG_VERSION} \
    cuda-cufft-dev-${CUDA_PKG_VERSION} \
    cuda-curand-dev-${CUDA_PKG_VERSION} \
    cuda-cusparse-dev-${CUDA_PKG_VERSION} \
    cuda-npp-dev-${CUDA_PKG_VERSION} \
    cuda-samples-${CUDA_PKG_VERSION} \
    cuda-documentation-${CUDA_PKG_VERSION} \
    cuda-visual-tools-${CUDA_PKG_VERSION} \
    cuda-toolkit-${CUDA_PKG_VERSION} \
    cuda

# Switching to project
juju::lib::switchenv "${PROJECT_ID}" 

# Bootstrapping project 
juju bootstrap "${PROJECT_ID}" lxd --upload-tools 2>/dev/null \
  && bash::lib::log debug Succesfully bootstrapped "${PROJECT_ID}" \
  || bash::lib::log info "${PROJECT_ID}" already bootstrapped

bash::lib::log debug Bootstrapping process finished for ${PROJECT_ID}. You can safely move to deployment. 

for FOLDER in layers trusty xenial; do
	[ -d /root/charms/${FOLDER} ] || mkdir -p /root/charms/${FOLDER}
done


export JUJU_REPOSITORY="/root/charms"
export LAYER_PATH="${JUJU_REPOSITORY}/layers"

cat >> /etc/profile.d/juju.sh << EOF
#!/bin/bash
export JUJU_REPOSITORY="/root/charms"
export LAYER_PATH="${JUJU_REPOSITORY}/layers"
EOF

chmod +x /etc/profile.d/juju.sh 

bash::lib::log info Cloning repos to get access to local charms
[ -d "${LAYER_PATH}/deeplearning4j" ] || { git clone https://github.com/SaMnCo/layer-skymind-dl4j.git "${LAYER_PATH}/deeplearning4j" 2>/dev/null 1>/dev/null \
	&& bash::lib::log info "Successfully cloned deeplearning4j charm" \
	|| bash::die "Could not clone deeplearning4j charm" ; } \
&& { cd "${LAYER_PATH}/deeplearning4j" ; git pull origin master ; }

[ -d "${LAYER_PATH}/cuda" ] || { git clone https://github.com/SaMnCo/layer-nvidia-cuda.git "${LAYER_PATH}/cuda" 2>/dev/null 1>/dev/null \
	&& bash::lib::log info "Successfully cloned cudacuda charm" \
	|| bash::die "Could not clone cuda charm" ; } \
&& { cd "${LAYER_PATH}/cuda" ; git pull origin master ; }

[ -d "${LAYER_PATH}/cuda" ] || { bzr branch lp:~samuel-cozannet/charms/trusty/mesos-slave/trunk "${JUJU_REPOSITORY}/trusty/mesos-slave" 2>/dev/null 1>/dev/null \
	&& bash::lib::log info "Successfully cloned Mesos Slave charm" \
	|| bash::die info "Could not clone Mesos Slave charm" ; } \
&& { cd "${LAYER_PATH}/cuda" ; bzr pull ; }

[ -d "${LAYER_PATH}/cuda" ] || { bzr branch lp:~samuel-cozannet/charms/trusty/mesos-master/trunk "${JUJU_REPOSITORY}/trusty/mesos-master" 2>/dev/null 1>/dev/null \
	&& bash::lib::log info "Successfully cloned Master charm charm" \
	|| bash::die "Could not clone Mesos Master charm" ; } \
&& { cd "${LAYER_PATH}/cuda" ; bzr pull ; }

[ -d "${LAYER_PATH}/cuda" ] || { bzr branch lp:~frbayart/charms/trusty/datafellas-notebook/trunk "${JUJU_REPOSITORY}/trusty/datafellas-notebook" 2>/dev/null 1>/dev/null \
	&& bash::lib::log info "Successfully cloned Spark Notebook charm" \
	|| bash::lib::die "Could not clone Spark Notebook charm" ; } \
&& { cd "${LAYER_PATH}/cuda" ; bzr pull ; }

for CHARM in deeplearning4j cuda
do
	cd "${LAYER_PATH}/${CHARM}" 
	charm build --force 2>/dev/null 1>/dev/null \
	&& bash::lib::log info "Successfully built ${CHARM} charm" \
	|| bash::die "Could not build ${CHARM} charm"
	charm build 
done


