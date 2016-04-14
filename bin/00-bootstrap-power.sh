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

wget -C /tmp http://us.download.nvidia.com/Ubuntu/352.88/NVIDIA-Linux-ppc64le-352.88.run
/tmp/NVIDIA-Linux-ppc64le-352.88.run -a --update -q -s --disable-nouveau

MD5="af735cee83d5c80f0b7b1f84146b4614"
wget -c -P /tmp "http://developer.download.nvidia.com/compute/cuda/${CUDA_VERSION}/Prod/local_installers/cuda-repo-ubuntu1404-${CUDA_PKG_VERSION}-local_${CUDA_VERSION}-${CUDA_SUB_VERSION}_$(arch).deb"

# Install CUDA dependencies manually
apt-get install -yqq \
    openjdk-8-jre openjdk-8-jre-headless java-common \
    ca-certificates default-jre-headless fonts-dejavu-extra \
    freeglut3 freeglut3-dev \
    libatk-wrapper-java libatk-wrapper-java-jni \
    libdrm-dev libgl1-mesa-dev libglu1-mesa-dev libgnomevfs2-0 libgnomevfs2-common \
    libice-dev libpthread-stubs0-dev libsctp1 libsm-dev libx11-dev \
    libx11-doc libx11-xcb-dev libxau-dev libxcb-dri2-0-dev libxcb-dri3-dev \
    libxcb-glx0-dev libxcb-present-dev libxcb-randr0-dev libxcb-render0-dev \
    libxcb-shape0-dev libxcb-sync-dev libxcb-xfixes0-dev libxcb1-dev \
    libxdamage-dev libxdmcp-dev libxext-dev libxfixes-dev libxi-dev \
    libxmu-dev libxmu-headers libxshmfence-dev libxt-dev libxxf86vm-dev \
    x11proto-core-dev x11proto-damage-dev x11proto-dri2-dev x11proto-fixes-dev x11proto-gl-dev \
    x11proto-kb-dev x11proto-xext-dev x11proto-xf86vidmode-dev x11proto-input-dev \
    xorg-sgml-doctools xtrans-dev libgles2-mesa-dev \
    lksctp-tools mesa-common-dev build-essential \
    libopenblas-base libopenblas-dev

dpkg -i /tmp/cuda-repo-ubuntu1404-${CUDA_PKG_VERSION}-local_${CUDA_VERSION}-${CUDA_SUB_VERSION}_$(arch).deb
# What this does is really copy all packages from CUDA into /var/cuda-repo-7-5-local
for PACKAGE in cuda-core cuda-toolkit cuda cuda-nvrtc cuda-cusolver cuda-cublas cuda-cufft cuda-curand cuda-cusparse cuda-npp cuda-cudart
do
    dpkg -i /var/cuda-repo-${CUDA_PKG_VERSION}-local/${PACKAGE}-${CUDA_PKG_VERSION}_${CUDA_VERSION}-${CUDA_SUB_VERSION}_$(arch).deb
done

# Switching to project
juju::lib::switchenv "${PROJECT_ID}" 

# Bootstrapping project 
juju bootstrap deeplearning lxd 2>/dev/null \
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
git clone https://github.com/SaMnCo/layer-skymind-dl4j.git "${LAYER_PATH}/deeplearning4j" 2>/dev/null 1>/dev/null \
	&& bash::lib::log info "Successfully cloned deeplearning4j charm" \
	|| bash::die "Could not clone deeplearning4j charm"
git clone https://github.com/SaMnCo/layer-nvidia-cuda.git "${LAYER_PATH}/cuda" 2>/dev/null 1>/dev/null \
	&& bash::lib::log info "Successfully cloned cudacuda charm" \
	|| bash::die "Could not clone cuda charm"

bzr branch lp:~samuel-cozannet/charms/trusty/mesos-slave/trunk "${JUJU_REPOSITORY}/trusty/mesos-slave" 2>/dev/null 1>/dev/null \
	&& bash::lib::log info "Successfully cloned Mesos Slave charm" \
	|| bash::die info "Could not clone Mesos Slave charm"
bzr branch lp:~frbayart/charms/trusty/mesos-master/trunk "${JUJU_REPOSITORY}/trusty/mesos-master" 2>/dev/null 1>/dev/null \
	&& bash::lib::log info "Successfully cloned Master charm charm" \
	|| bash::die "Could not clone Mesos Master charm"
bzr branch lp:~frbayart/charms/trusty/datafellas-notebook/trunk "${JUJU_REPOSITORY}/trusty/datafellas-notebook" 2>/dev/null 1>/dev/null \
	&& bash::lib::log info "Successfully cloned Spark Notebook charm" \
	|| bash::lib::die "Could not clone Spark Notebook charm"

for CHARM in deeplearning4j cuda
do
	cd "${LAYER_PATH}/${CHARM}" 2>/dev/null 1>/dev/null \
	&& bash::lib::log info "Successfully built ${CHARM} charm" \
	|| bash::die "Could not build ${CHARM} charm"
	charm build 
done


