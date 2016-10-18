#!/bin/bash

# Main-top-script Invokes selected scripts in sub folder that generates a working armhf Debian Jessie or Stretch/sid sd-card-image().img
# base kernel is the x.xx.xx-rt-ltsi kernel from the alterasoc repo (currently 4.1.22-rt23)
# ongoing work is done to get pluged into the 4.4.4-rt mainline kernel.
#
# !!! warning while using the script to generate u-boot, kernels and sd-image, is quite safe
# the (qemu)rootfs generation can be more tricky. and might potentially overwrite files in your host root file system.
# if something goes wrong underway you need to know how to use lsblk, sudo losetup -D and sudo umount -R
# the machinekit Rip cross build script is in an even higher risc zone, and it is highly recomended to install the .deb packages,
# unless you really need a local rip build for development purposes on you soc.
# as installing machinekit packages works just fine for runtime purposes ....
#
# Initially developed for the Terasic De0 Nano / Altera Atlas Soc-Fpga dev board

# v.02 TODO:   more cleanup

# 1.initial source: make minimal rootfs on amd64 Debian Jessie, according to "How to create bare minimum Debian Wheezy rootfs from scratch"
# http://olimex.wordpress.com/2014/07/21/how-to-create-bare-minimum-debian-wheezy-rootfs-from-scratch/
#------------------------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------- #
#-----------+++     Full Flow Control                       +++-------------------- #
#---------------------------------------------------------------------------------- #
#USER_NAME=machinekit;
USER_NAME=holosynth;

#install_deps # --->- only needed on first new run of a function see function above -------#

#
#BUILD_UBOOT="yes";
# #
# BUILD_KERNEL="yes";
KERNEL_2_REPO="yes";
CLEAN_KERNELREPO="yes";
# # #
#	#CROSS_BUILD_DTC="yes";
#
#GEN_ROOTFS_IMAGE="yes";
#CUSTOM_PREFIX="3.10-updated"
# #
#MAKE_NEW_ROOTFS="yes";
#
#ADD_SD_USER="yes";
#
#INST_QT="yes";INST_QT_DEPS="yes";
##	#INST_LOCALKERNEL_DEBS="yes";#GEN_UINITRD_SCRIPT="yes";
#
#INST_REPOKERNEL_DEBS="yes";GEN_UINITRD_SCRIPT="yes";
# #	ISCSI_CONV="yes";
#
#
#CREATE_BMAP="yes"; INST_UBOOT="yes";
#


#------------------------------------------------------------------------------------------------------
# Variables Prerequsites
#apt_cmd=apt
apt_cmd="apt-get"
#------------------------------------------------------------------------------------------------------
WORK_DIR=${1}

MAIN_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SUB_SCRIPT_DIR=${MAIN_SCRIPT_DIR}/subscripts
DTS_DIR=${MAIN_SCRIPT_DIR}/../dts

CURRENT_DIR=`pwd`
#ROOTFS_MNT=/mnt/rootfs
ROOTFS_MNT=/tmp/myimage

ROOTFS_IMG=${CURRENT_DIR}/rootfs.img

CURRENT_DATE=`date -I`
REL_DATE=${CURRENT_DATE}
#REL_DATE=2016-03-07

ALT_GIT_KERNEL_URL="https://github.com/altera-opensource/linux-socfpga.git"

## http://releases.linaro.org/components/toolchain/binaries/5.2-2015.11-1/arm-linux-gnueabihf/gcc-linaro-5.2-2015.11-1-x86_64_arm-linux-gnueabihf.tar.xz
PCH52_CC_FOLDER_NAME="gcc-linaro-5.2-2015.11-1-x86_64_arm-linux-gnueabihf"
PCH52_CC_FILE="${PCH52_CC_FOLDER_NAME}.tar.xz"
PCH52_CC_URL="http://releases.linaro.org/components/toolchain/binaries/5.2-2015.11-1/arm-linux-gnueabihf/${PCH52_CC_FILE}"

ALT_GIT_KERNEL_VERSION="4.1-ltsi-rt"
#ALT_GIT_KERNEL_VERSION="4.1.22-ltsi-rt"
#ALT_GIT_KERNEL_VERSION="4.7"

ALT_GIT_KERNEL_BRANCH="socfpga-${ALT_GIT_KERNEL_VERSION}"

QTDIR=/home/mib/qt-src/qt-everywhere-opensource-src-5.4.1

POLICY_FILE=${ROOTFS_MNT}/usr/sbin/policy-rc.d

#------------------------------------------------------------------------------------------------------
# Variables Custom settings
#------------------------------------------------------------------------------------------------------

#distro=sid
distro=jessie
#distro=stretch

## 2 part Expandable image
IMG_ROOT_PART=p2

BOARD=de0-nano-soc
#BOARD=de1-soc
#BOARD=sockit

UBOOT_VERSION="v2016.07"
#UBOOT_VERSION="v2016.05"
UBOOT_MAKE_CONFIG='u-boot-with-spl.sfp'
APPLY_UBOOT_PATCH=yes
#APPLY_UBOOT_PATCH=""

TOOLCHAIN_DIR=${HOME}/bin
#TOOLCHAIN_DIR=${CURRENT_DIR}

GIT_KERNEL_BRANCH=${ALT_GIT_KERNEL_BRANCH}

#KERNEL_LOCALVERSION="socfpga"
KERNEL_LOCALVERSION="socfpga-initrd"
KERNEL_REV="0.1"
# cross toolchains
#--------- 4.1 + kernels -------------------------------------------------------------------#
KERNEL_VERSION=${ALT_GIT_KERNEL_VERSION}
KERNEL_URL=${ALT_GIT_KERNEL_URL}

#-----  select global toolchain  ------#

CC_FOLDER_NAME=$PCH52_CC_FOLDER_NAME
CC_URL=$PCH52_CC_URL

EnableSystemdNetworkedLink='/etc/systemd/system/multi-user.target.wants/systemd-networkd.service'
EnableSystemdResolvedLink='/etc/systemd/system/multi-user.target.wants/systemd-resolved.service'

REPO_DIR="/var/www/repos/apt/debian"

#------------------------------------------------------------------------------------------------------
# Variables Postrequsites
#------------------------------------------------------------------------------------------------------
KERNEL_MIDDLE_NAME=${GIT_KERNEL_BRANCH}

SD_FILE_PRELUDE=mksocfpga_${distro}_${USER_NAME}_${KERNEL_VERSION}-${REL_DATE}
SD_IMG_NAME=${SD_FILE_PRELUDE}-${BOARD}_sd.img
SD_IMG_FILE=${CURRENT_DIR}/${SD_IMG_NAME}

#--------------  u-boot  --------------#

if [ "$BOARD" == "de0-nano-soc" ]; then
   UBOOT_BOARD='de0_nano_soc'
   BOOT_FILES_DIR=${MAIN_SCRIPT_DIR}/../boot_files/${nanofolder}
elif [ "$BOARD" == "de1-soc" ]; then
   UBOOT_BOARD='de0_nano_soc'
   BOOT_FILES_DIR=${MAIN_SCRIPT_DIR}/../boot_files/${de1folder}
elif [ "$BOARD" == "sockit" ]; then
   UBOOT_BOARD='sockit'
   BOOT_FILES_DIR=${MAIN_SCRIPT_DIR}/../boot_files/${sockitfolder}
fi

CC_DIR="bin/${CC_FOLDER_NAME}"
CC_FILE="${CC_FOLDER_NAME}.tar.xz"
CC="${CC_DIR}/bin/arm-linux-gnueabihf-"

COMP_REL=debian-${distro}_socfpga

KERNEL_PARENT_DIR=${CURRENT_DIR}/arm-linux-${KERNEL_MIDDLE_NAME}-gnueabifh-kernel

UBOOT_SPLFILE=${CURRENT_DIR}/uboot/${UBOOT_MAKE_CONFIG}

#KERNEL_TAG="${KERNEL_VERSION}-${KERNEL_LOCALVERSION}"
#KERNEL_TAG="${KERNEL_VERSION}.*-${KERNEL_LOCALVERSION}"
KERNEL_TAG="4.1.17-ltsi-rt17-${KERNEL_LOCALVERSION}"

#-----------------------------------------------------------------------------------
# local functions for external scripts
#-----------------------------------------------------------------------------------

extract_toolchain() {
    echo "MSG: using tar for xz extract"
    tar xf ${CC_FILE}
}

get_toolchain() {
# download linaro cross compiler toolchain
if [ ! -d ${CC_DIR} ]; then
    if [ ! -f ${CC_FILE} ]; then
        echo "MSG: downloading toolchain"
    	wget -c ${CC_URL}
    fi
# extract linaro cross compiler toolchain
    echo "MSG: extracting toolchain"
    extract_toolchain
# install linaro gcc crosstoolchain dependency:
	sudo ${apt_cmd} -y install lib32stdc++6
else
	echo ""
	echo "Script_MSG: Toolchain allready installed in -->"
	echo "Script_MSG: ${CC_DIR}"
	echo ""
fi
}

install_uboot_dep() {
# install deps for u-boot build
	sudo ${apt_cmd} -y install lib32z1 device-tree-compiler bc u-boot-tools
}

install_kernel_dep() {
# install deps for kernel build
	sudo ${apt_cmd} -y install build-essential fakeroot bc u-boot-tools
	sudo apt-get -y build-dep linux
}

install_deps() {
	get_toolchain
	install_uboot_dep
	install_kernel_dep
#	#sudo ${apt_cmd} install kpartx
	install_rootfs_dep
	sudo ${apt_cmd} install bmap-tools
	echo "MSG: deps installed"
}

#-----------------------------------------------------------------------------------			sudo chroot --userspec=root:root ${ROOTFS_MNT} /usr/bin/${apt_cmd} -y build-dep qt5-default

# external scripted functions
#-----------------------------------------------------------------------------------

build_uboot() {
	${SUB_SCRIPT_DIR}/build_uboot.sh ${CURRENT_DIR} ${TOOLCHAIN_DIR} ${MAIN_SCRIPT_DIR} ${UBOOT_VERSION} ${BOARD}  ${UBOOT_BOARD} ${UBOOT_MAKE_CONFIG} ${CC_FOLDER_NAME} ${APPLY_UBOOT_PATCH} | tee ${CURRENT_DIR}/build-uboot-log.txt
}

build_kernel() {
	rm -f ${KERNEL_PARENT_DIR}/*.deb
	${SUB_SCRIPT_DIR}/build_kernel.sh ${CURRENT_DIR} ${TOOLCHAIN_DIR} ${MAIN_SCRIPT_DIR} ${CC_FOLDER_NAME} ${KERNEL_MIDDLE_NAME} ${GIT_KERNEL_BRANCH} ${KERNEL_VERSION} ${KERNEL_URL} ${KERNEL_LOCALVERSION} ${KERNEL_REV}  ${PATCH_URL} | tee ${CURRENT_DIR}/build_kernel-log.txt
}

check_dpkg () {
	LC_ALL=C dpkg --list | awk '{print $2}' | grep "^${pkg}" >/dev/null || deb_pkgs="${deb_pkgs}${pkg} "
}

cross_build_dtc() {

	unset deb_pkgs
	pkg="bison"
	check_dpkg
	pkg="build-essential"
	check_dpkg
	pkg="flex"
	check_dpkg
	pkg="git-core"
	check_dpkg

	if [ "${deb_pkgs}" ] ; then
		echo "Installing: ${deb_pkgs}"
		sudo apt-get update
		sudo apt-get -y install ${deb_pkgs}
		sudo apt-get clean
	fi

	DTC_MAKEDIR=${CURRENT_DIR}/dtc/dtc
	CC_DIR="${TOOLCHAIN_DIR}/${CC_FOLDER_NAME}"
	CC="${CC_DIR}/bin/arm-linux-gnueabihf-"
	export CROSS_COMPILE=${CC}

	if [ ! -d ${DTC_MAKEDIR} ]; then
		echo "cloning dtc repo"
		mkdir ${CURRENT_DIR}/dtc
		cd ${CURRENT_DIR}/dtc
		git clone git://git.kernel.org/pub/scm/utils/dtc/dtc.git -b v1.4.1
	fi
	cd ${DTC_MAKEDIR}
	make clean
	make ARCH=arm CROSS_COMPILE=${CC}
}

create_image() {
	${SUB_SCRIPT_DIR}/create_img.sh ${CURRENT_DIR} ${IMG_PARTS} ${SD_IMG_FILE} | tee ${CURRENT_DIR}/create_img-log.txt
}

generate_rootfs_into_image() {
	sh -c "${SUB_SCRIPT_DIR}/MAKE_NEW_ROOTFS-qemu_2.5.sh ${CURRENT_DIR} ${ROOTFS_IMG} ${distro} ${ROOTFS_MNT} ${USER_NAME}" | tee ${CURRENT_DIR}/MAKE_NEW_ROOTFS-qemu_2.5-log.txt
}

inst_qt_build_deps(){
echo ""
echo "Script_MSG: Installing Qt Build Deps"
echo ""

# #sudo cp -f ${CURRENT_DIR}/sources.list ${ROOTFS_MNT}/etc/apt/sources.list-local
sudo cp -f ${ROOTFS_MNT}/etc/apt/sources.list-local ${ROOTFS_MNT}/etc/apt/sources.list

sudo rm -f ${ROOTFS_MNT}/etc/resolv.conf
sudo cp -f /etc/resolv.conf ${ROOTFS_MNT}/etc/resolv.conf

sudo chroot --userspec=root:root ${ROOTFS_MNT} /usr/bin/${apt_cmd} update
sudo chroot --userspec=root:root ${ROOTFS_MNT} /usr/bin/${apt_cmd} -y build-dep qt5-default
sudo chroot --userspec=root:root ${ROOTFS_MNT} /usr/bin/${apt_cmd} -y install libxcb-xinerama0-dev libc6-dev
sudo chroot --userspec=root:root ${ROOTFS_MNT} /usr/bin/${apt_cmd} -y install "^libxcb.*" libx11-xcb-dev libglu1-mesa-dev libxrender-dev libxi-dev
sudo chroot --userspec=root:root ${ROOTFS_MNT} /usr/bin/${apt_cmd} -y install libasound2-dev libgstreamer0.10-dev libgstreamer-plugins-base0.10-dev
sudo chroot --userspec=root:root ${ROOTFS_MNT} /usr/bin/${apt_cmd} -y install libxcb1 libxcb1-dev libx11-xcb1 libx11-xcb-dev libxcb-keysyms1 libxcb-keysyms1-dev libxcb-image0 libxcb-image0-dev libxcb-shm0 libxcb-shm0-dev libxcb-icccm4 libxcb-icccm4-dev libxcb-sync1 libxcb-sync0-dev libxcb-render-util0 libxcb-render-util0-dev libxcb-xfixes0-dev libxrender-dev libxcb-shape0-dev libxcb-randr0-dev libxcb-glx0-dev

echo ""
echo "Script_MSG: Installing Qt into rootfs.img "
echo ""
cd ${CURRENT_DIR}

sudo cp -f ${ROOTFS_MNT}/etc/apt/sources.list-final ${ROOTFS_MNT}/etc/apt/sources.list
sudo chroot --userspec=root:root ${ROOTFS_MNT} /bin/rm -f /etc/resolv.conf
sudo chroot --userspec=root:root ${ROOTFS_MNT} /bin/ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf
}

qt_build(){
echo ""
echo "Script_MSG: Running qt_build.sh script"
echo ""
sh -c "${SUB_SCRIPT_DIR}/build_qt.sh ${CURRENT_DIR}" | tee ${CURRENT_DIR}/build_qt-log.txt
}

#-----------------------------------------------------------------------------------
# local functions
#-----------------------------------------------------------------------------------

kill_ch_proc(){
FOUND=0

for ROOT in /proc/*/root; do
	LINK=$(sudo readlink ${ROOT})
	if [ "x${LINK}" != "x" ]; then
		if [ "x${LINK:0:${#KILL_PREFIX}}" = "x${KILL_PREFIX}" ]; then
			# this process is in the chroot...
			PID=$(basename $(dirname "${ROOT}"))
			sudo kill -9 "${PID}"
			FOUND=1
		fi
	fi
done
}

mount_sdimagefile(){
	sudo sync
	LOOP_DEV=`eval sudo losetup -f --show ${SD_IMG_FILE}`
	sudo mkdir -p ${ROOTFS_MNT}
	sudo mount ${LOOP_DEV}${IMG_ROOT_PART} ${ROOTFS_MNT}
	echo "#--------------------------------------------------------------------------------------#"
	echo "# Scr_MSG:                                                                             #"
	echo "# ${SD_IMG_FILE}"
	echo "# Is mounted in ---> ${LOOP_DEV}"
	echo "#                                                                                      #"
	echo "# ${LOOP_DEV}${IMG_ROOT_PART}"
	echo "# Is mounted in ---> ${ROOTFS_MNT}"
	echo "#                                                                                      #"
	echo "#--------------------------------------------------------------------------------------#"
}

mount_rootfs_imagefile(){
	sudo sync
	mkdir -p ${ROOTFS_MNT}
	sudo mount ${ROOTFS_IMG} ${ROOTFS_MNT}
	echo "#--------------------------------------------------------------------------------------#"
	echo "# Scr_MSG:                                                                             #"
	echo "# ${ROOTFS_IMG}"
	echo "# Is mounted in ---> ${ROOTFS_MNT}"
	echo "#                                                                                      #"
	echo "#--------------------------------------------------------------------------------------#"
}

unmount_sdimagefile(){
	echo ""
	echo "Scr_MSG: Unmounting ---> ${ROOTFS_MNT}"
	sudo umount -R ${ROOTFS_MNT}
	echo ""
	echo "Scr_MSG: Unmounting Imagefile in ---> ${LOOP_DEV}"
	sudo losetup -d ${LOOP_DEV}
	echo ""
}

unmount_rootfs_imagefile(){
	echo "Scr_MSG: Unmounting Imagefile in ---> ${ROOTFS_MNT}"
	sudo umount -R ${ROOTFS_MNT}
}

bind_rootfs(){
	sudo sync
	sudo mount --bind /dev ${ROOTFS_MNT}/dev
	sudo mount --bind /proc ${ROOTFS_MNT}/proc
	sudo mount --bind /sys ${ROOTFS_MNT}/sys

	echo "#--------------------------------------------------------------------------------------#"
	echo "# Scr_MSG: ${ROOTFS_MNT} Bind mounted                                                  #"
	echo "#                                                                                      #"
	echo "#--------------------------------------------------------------------------------------#"
}

bind_unmount_rootfs_imagefile(){
	cd ${CURRENT_DIR}
	CDR=`eval pwd`
	echo ""
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	echo ""
	echo "Scr_MSG: current dir is now: ${CDR}"
	echo ""
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	echo ""
	sudo sync
	if [ -d "${ROOTFS_MNT}/home" ]; then
		echo ""
		echo "Scr_MSG: Will now (unbind) ummount ${ROOTFS_MNT}"
		RES=`eval sudo umount -R ${ROOTFS_MNT}`
		echo ""
		echo "Scr_MSG: Unmont result = ${RES}"
		echo "Scr_MSG: Unmont return value = ${?}"
		echo ""
	else
		echo ""
		echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		echo ""
		echo "Scr_MSG: Rootfs was unmounted correctly"
		echo ""
		echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		echo ""
	fi

}

compress_rootfs(){
if [ ! -z "${COMP_PREFIX}" ]; then
	COMPNAME=${COMP_REL}_${COMP_PREFIX}
	echo "#---------------------------------------------------------------------------#"
	echo "#Scr_MSG:                                                                   #"
	echo "compressing latest rootfs from image into: -->   ---------------------------#"
	echo " ${CURRENT_DIR}/${COMPNAME}--rootfs.tar.bz2"
	cd ${ROOTFS_MNT}
	sudo tar -cjSf ${CURRENT_DIR}/${COMPNAME}-rootfs.tar.bz2 *
	cd ${CURRENT_DIR}
	echo "#                                                                           #"
	echo "#Scr_MSG:                                                                   #"
	echo "${COMPNAME}-rootfs.tar.bz2 rootfs compression finished ..."
	echo "#                                                                           #"
	echo "#---------------------------------------------------------------------------#"
fi
}

extract_rootfs(){

if [ ! -z "${COMP_PREFIX}" ]; then
	echo "Script_MSG: Extracting ${COMP_PREFIX}"
	echo "Script_MSG: Into imagefile"
	echo "Rootfs configured ... extracting  ${COMPNAME} rootfs into image...."
	## extract rootfs into image:
	COMPNAME=${COMP_REL}_${COMP_PREFIX}
	sudo tar xfj ${CURRENT_DIR}/${COMPNAME}-rootfs.tar.bz2 -C ${ROOTFS_MNT}
	echo "${CURRENT_DIR}/${COMPNAME}-rootfs.tar.bz2 rootfs extraction finished .."
fi
}

add_mk_repo(){
echo "ECHO: adding mk sources.list"
sudo chroot --userspec=root:root ${ROOTFS_MNT} /usr/bin/apt-key adv --keyserver keyserver.ubuntu.com --recv 43DDF224
echo "deb http://deb.machinekit.io/debian jessie main" > ${ROOTFS_MNT}/etc/apt/sources.list.d/'${USER_NAME}'.list
sudo chroot --userspec=root:root ${ROOTFS_MNT} /usr/bin/'${apt_cmd}' -y update
}


gen_add_user_sh() {
echo "------------------------------------------"
echo "generating add_user.sh chroot config script"
echo "------------------------------------------"
export DEFGROUPS="sudo,kmem,adm,dialout,${USER_NAME},video,plugdev"

sudo sh -c 'cat <<EOF > '${ROOTFS_MNT}'/home/add_user.sh
#!/bin/bash

set -x

export DEFGROUPS="sudo,kmem,adm,dialout,'${USER_NAME}',video,plugdev"
export LANG=C

'${apt_cmd}' -y update
'${apt_cmd}' -y --force-yes upgrade

echo "root:'${USER_NAME}'" | chpasswd

echo "ECHO: " "Will add user '${USER_NAME}' pw: '${USER_NAME}'"
/usr/sbin/useradd -s /bin/bash -d /home/'${USER_NAME}' -m '${USER_NAME}'
echo "'${USER_NAME}':'${USER_NAME}'" | chpasswd
adduser '${USER_NAME}' sudo
chsh -s /bin/bash '${USER_NAME}'

echo "ECHO: ""User Added"

echo "ECHO: ""Will now add user to groups"
usermod -a -G '${DEFGROUPS}' '${USER_NAME}'
sync

cat <<EOT >> /home/'${USER_NAME}'/.bashrc

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
EOT

cat <<EOT >> /home/'${USER_NAME}'/.profile

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
EOT

cat <<EOT >> /root/.bashrc

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
EOT

cat <<EOT >> /root/.profile

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
EOT


exit
EOF'

sudo chmod +x ${ROOTFS_MNT}/home/add_user.sh

sudo chroot ${ROOTFS_MNT} /bin/su -l root /usr/sbin/locale-gen en_GB.UTF-8 en_US.UTF-8

echo ""
echo "Scr_MSG: fix no sudo user ping:"
echo ""
sudo chmod u+s ${ROOTFS_MNT}/bin/ping ${ROOTFS_MNT}/bin/ping6

}

gen_initial_sh() {
echo "------------------------------------------"
echo "generating initial.sh chroot config script"
echo "------------------------------------------"

sudo sh -c 'cat <<EOF > '${ROOTFS_MNT}'/home/initial.sh
#!/bin/bash

set -x

ln -s /proc/mounts /etc/mtab

cat << EOT >/etc/fstab
# /etc/fstab: static file system information.
#
# <file system>    <mount point>   <type>  <options>       <dump>  <pass>
/dev/root          /               ext4    noatime,errors=remount-ro 0 1
tmpfs              /tmp            tmpfs   defaults                  0 0
none               /dev/shm        tmpfs   rw,nosuid,nodev,noexec    0 0
/sys/kernel/config /config         none    bind                      0 0
EOT


echo "ECHO: Will now run '${apt_cmd}' update, upgrade"
'${apt_cmd}' -y update
'${apt_cmd}' -y --force-yes upgrade

rm -f /etc/resolv.conf

# enable systemd-networkd
if [ ! -L '/lib/systemd/system/systemd-networkd.service' ]; then
	echo ""
	echo "ECHO:--> Enabling Systemd Networkd"
	echo ""
	ln -s /lib/systemd/system/systemd-networkd.service ${EnableSystemdNetworkedLink}
fi

enable systemd-resolved
if [ ! -L '/lib/systemd/system/systemd-resolved.service' ]; then
	echo ""
	echo "ECHO:--> Enabling Systemd Resolved"
	echo ""
	ln -s /lib/systemd/system/systemd-resolved.service ${EnableSystemdResolvedLink}
	rm -f /etc/resolv.conf
	ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf
fi

exit
EOF'

sudo chmod +x ${ROOTFS_MNT}/home/initial.sh
}

initial_rootfs_user_setup_sh() {
echo "------------------------------------------------------------"
echo "----  running initial_rootfs_user_setup_sh      ------------"
echo "------------------------------------------------------------"
set -e

sudo rm -f ${ROOTFS_MNT}/etc/resolv.conf
sudo cp /etc/resolv.conf ${ROOTFS_MNT}/etc/resolv.conf

echo "Script_MSG: Now adding user: ${USER_NAME}"
gen_add_user_sh
echo "Script_MSG: gen_add_user_sh finished ... will now run in chroot"

sudo chroot ${ROOTFS_MNT} /bin/bash -c /home/add_user.sh

echo "Script_MSG: installing apt-transport-https"
sudo chroot --userspec=root:root ${ROOTFS_MNT} /usr/bin/${apt_cmd} -y update
sudo chroot --userspec=root:root ${ROOTFS_MNT} /usr/bin/${apt_cmd} -y --force-yes upgrade
sudo chroot --userspec=root:root ${ROOTFS_MNT} /usr/bin/${apt_cmd} -y install apt-transport-https

if [[ "${USER_NAME}" == "machinekit" ]]; then
	add_mk_repo
fi

gen_initial_sh
echo "Script_MSG: gen_initial.sh finhed ... will now run in chroot"

sudo chroot ${ROOTFS_MNT} /bin/bash -c /home/initial.sh

sudo sync

cd ${CURRENT_DIR}
sudo cp -f ${ROOTFS_MNT}/etc/apt/sources.list-final ${ROOTFS_MNT}/etc/apt/sources.list

echo "Script_MSG: initial_rootfs_user_setup_sh finished .. ok .."

}

add_kernel2repo(){

echo "#--------------------------- Script start ------------------------------------#"
echo "#--->                        Add Kernel to Repo                           <---#"
echo "#--------------------------- Script start ------------------------------------#"
#sudo systemctl stop apache2

echo ""
echo "Scr_MSG: Repo content before -->"
echo ""
LIST1=`reprepro -b ${REPO_DIR} -C main -A armhf --list-format='''${package}\n''' list jessie`

JESSIE_LIST1=$"${LIST1}"

echo  "${JESSIE_LIST1}"

echo ""
if [[ ${CLEAN_KERNELREPO} == 'yes' ]]; then

	if [ ! -z "${JESSIE_LIST1}" ]; then
		echo ""
		echo "Scr_MSG: Will clean repo"
		echo ""
		reprepro -b ${REPO_DIR} -C main -A armhf remove jessie ${JESSIE_LIST1}
	else
		echo ""
		echo "Scr_MSG: Repo is empty"
		echo ""
	fi
	echo ""
fi

	reprepro -b ${REPO_DIR} -C main -A armhf includedeb jessie ${KERNEL_PARENT_DIR}/*.deb
	reprepro -b ${REPO_DIR} export jessie
	echo "Scr_MSG: Restarting web server"

	sudo systemctl restart apache2
reprepro -b ${REPO_DIR} export jessie
reprepro -b ${REPO_DIR} -C main -A armhf list jessie

LIST2=`reprepro -b ${REPO_DIR} -C main -A armhf --list-format='''${package}\n''' list jessie`
JESSIE_LIST2=$"${LIST2}"
echo ""
echo "Scr_MSG: Repo content After: -->"
echo ""
echo  "${JESSIE_LIST2}"
echo ""

echo "#--------------------------- Script end --------------------------------------#"
echo "#--->       Repo updated                                                  <---#"
echo "#--------------------------- Script end --------------------------------------#"

}

gen_uinitrd_script(){
echo ""
echo "Scr_MSG: Repo Creating postinstall mkimage script for uInitrd"
echo ""

sudo sh -c 'cat <<"EOF" > "'${ROOTFS_MNT}'/etc/kernel/postinst.d/zzz-socfpga-mkimage"
#!/bin/sh

version="$1"

echo "Installing new uInitrd to SD"

mkimage -A arm -O linux -T ramdisk -a 0x0 -e 0x0 -n /boot/initrd.img-"${version}" -d /boot/initrd.img-"${version}" /boot/uInitrd-"${version}"

EOF'
sudo chmod 755 "${ROOTFS_MNT}/etc/kernel/postinst.d/zzz-socfpga-mkimage"
}


inst_kernel_from_deb_repo(){

sudo cp -f ${ROOTFS_MNT}/etc/apt/sources.list-local ${ROOTFS_MNT}/etc/apt/sources.list

sudo rm -f ${ROOTFS_MNT}/etc/resolv.conf
sudo cp -f /etc/resolv.conf ${ROOTFS_MNT}/etc/resolv.conf

#${apt_cmd} -y install hm2reg-uio-dkms

#sudo chroot --userspec=root:root ${ROOTFS_MNT} /usr/bin/${apt_cmd} -y install apt-transport-https

#sudo sh -c 'echo "deb [arch=armhf] https://deb.mah.priv.at/ jessie socfpga" > '${ROOTFS_MNT}'/etc/apt/sources.list.d/debmah.list'
sudo sh -c 'echo "deb [arch=armhf] http://kubuntu16-ws.holotronic.lan/debian jessie main" > '${ROOTFS_MNT}'/etc/apt/sources.list.d/mibsocdeb.list'
echo ""
echo "Script_MSG: Will now add key to kubuntu16-ws"
echo ""
set +e
sudo sh -c 'wget -O - http://kubuntu16-ws.holotronic.lan/debian/socfpgakernel.gpg.key|apt-key add -'
sudo chroot --userspec=root:root ${ROOTFS_MNT} /usr/bin/${apt_cmd} -y update

# #sudo chroot --userspec=root:root ${ROOTFS_MNT} /usr/bin/apt-key adv --keyserver keyserver.ubuntu.com --recv 4FD9D713
# #sudo chroot --userspec=root:root ${ROOTFS_MNT} /usr/bin/${apt_cmd} -y update
sudo chroot --userspec=root:root ${ROOTFS_MNT} /usr/bin/${apt_cmd} -y --force-yes upgrade

# echo ""
# echo "# --------->       Removing qemu policy file          <--------------- ---------"
# echo ""
# if [ -f ${POLICY_FILE} ]; then
#     echo "removing ${POLICY_FILE}"
#     sudo rm -f ${POLICY_FILE}
# fi

echo ""
echo "Script_MSG: Will now install kernel packages"
echo ""
sudo chroot --userspec=root:root ${ROOTFS_MNT} /usr/bin/${apt_cmd} -y --force-yes install linux-headers-${KERNEL_TAG} linux-image-${KERNEL_TAG} linux-libc-dev

set -e

cd ${CURRENT_DIR}
sudo cp -f ${ROOTFS_MNT}/etc/apt/sources.list-final ${ROOTFS_MNT}/etc/apt/sources.list
sudo chroot --userspec=root:root ${ROOTFS_MNT} /bin/rm -f /etc/resolv.conf
sudo chroot --userspec=root:root ${ROOTFS_MNT} /bin/ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf

PREFIX=${ROOTFS_MNT}
kill_ch_proc

}

gen_hostname() {

sudo sh -c 'cat <<EOT > '$ROOTFS_MNT'/etc/hosts
127.0.0.1       localhost.localdomain       localhost   '${hostname}'
127.0.1.1       '${hostname}'.local            '${hostname}'

EOT'

sudo sh -c 'cat <<EOT > '$ROOTFS_MNT'/etc/hostname
'${hostname}'

EOT'

}

inst_dtbstuff(){
set -x
sudo mkdir -p ${ROOTFS_MNT}/lib/firmware/socfpga

sudo cp ${DTS_DIR}/uioreg_uio.sh ${ROOTFS_MNT}/etc/init.d/
sudo chmod +x ${ROOTFS_MNT}/etc/init.d/uioreg_uio.sh
sudo chroot --userspec=root:root ${ROOTFS_MNT} update-rc.d uioreg_uio.sh defaults

if [[ "${USER_NAME}" == "holosynth" ]]; then
	sudo dtc -I dts -O dtb -b 0 -@ -o ${ROOTFS_MNT}/lib/firmware/socfpga/uioreg_uio.dtbo ${DTS_DIR}/holosynth/uioreg_uio.dts
#	sudo cp ${DTS_DIR}/hsynth_fb.sh ${ROOTFS_MNT}/etc/init.d/
#	sudo chmod +x ${ROOTFS_MNT}/etc/init.d/hsynth_fb.sh
	sudo cp /home/mib/Developer/the-snowwhite_git/HolosynthV/QuartusProjects/HolosynthIV_DE1SoC-Q15.0_15-inch-lcd/output_files/DE1_SOC_Linux_FB.rbf ${ROOTFS_MNT}/lib/firmware/socfpga
	sudo cp /home/mib/Developer/the-snowwhite_git/HolosynthV/QuartusProjects/HolosynthIV_DE1SoC-Q15.0_15-inch-lcd/output_files/DE1_SOC_Linux_FB.rbf ${ROOTFS_MNT}/boot
#	sudo chroot --userspec=root:root ${ROOTFS_MNT} update-rc.d hsynth_fb.sh defaults
#	sudo dtc -I dts -O dtb -b 0 -@ -o ${ROOTFS_MNT}/lib/firmware/socfpga/hsynth_fb.dtbo ${DTS_DIR}/hsynth_fb.dts

elif [ "${USER_NAME}" == "machinekit" ]; then
	sudo dtc -I dts -O dtb -b 0 -@ -o ${ROOTFS_MNT}/lib/firmware/socfpga/uioreg_uio.dtbo ${DTS_DIR}/machinekit/hm2reg_uio-irq.dts
	sudo cp /home/mib/Developer/the-snowwhite_git/mksocfpga_hm3/HW/QuartusProjects/DE0_NANO_SOC_GHRD/output_files/DE0_NANO.rbf ${ROOTFS_MNT}/lib/firmware/socfpga
	sudo cp /home/mib/Developer/the-snowwhite_git/mksocfpga_hm3/HW/QuartusProjects/DE0_NANO_SOC_GHRD/output_files/DE0_NANO.rbf ${ROOTFS_MNT}/boot
fi
sudo sh -c 'echo "KERNEL==\"uio0\",MODE=\"666\"" > '$ROOTFS_MNT'/etc/udev/rules.d/10-local.rules'

}

finalize() {
echo "#-------------------------------------------------------------------------------#"
echo "#-------------------------------------------------------------------------------#"
echo "#-----------------------------          ----------------------------------------#"
echo "#----------------   +++      Customizing          +++  -------------------------#"
echo "#-----------------------------          ----------------------------------------#"
echo "#-------------------------------------------------------------------------------#"
echo "#-------------------------------------------------------------------------------#"

echo ""
echo "# --------- ------------ Customizing  -------- --------------- ---------"
echo ""
echo "# -----------------    Changing hostname to ${hostname}    -------------"
echo ""
gen_hostname

echo ""
echo "Script_MSG: Enabling uio driver and fixing user permissions"
echo ""
if [ "${USER_NAME}" == "machinekit" ]; then
	sudo sh -c 'echo options uio_pdrv_genirq of_id="hm2reg_io,generic-uio,ui_pdrv" > '$ROOTFS_MNT'/etc/modprobe.d/uiohm2.conf'
elif [ "${USER_NAME}" == "holosynth" ]; then
	sudo sh -c 'echo options uio_pdrv_genirq of_id="uioreg_io,generic-uio,ui_pdrv" > '$ROOTFS_MNT'/etc/modprobe.d/uioreg.conf'
fi
inst_dtbstuff
echo ""
echo "# --------->       Removing qemu policy file          <--------------- ---------"
echo ""

if [ -f ${POLICY_FILE} ]; then
    echo "removing ${POLICY_FILE}"
    sudo rm -f ${POLICY_FILE}
fi
echo ""
echo "# --------->       Restoring resolv.conf link         <--------------- ---------"
echo ""
sudo chroot --userspec=root:root ${ROOTFS_MNT} /bin/rm -f /etc/resolv.conf
sudo chroot --userspec=root:root ${ROOTFS_MNT} /bin/ln -s /lib/systemd/system/systemd-resolved.service /etc/resolv.conf

echo ""
echo "# --------- ------------>   Finalized    --- --------- --------------- ---------"
echo ""

}


#------------------............ config run functions section ..................-----------#

install_uboot() {
echo ""
echo "installing ${UBOOT_SPLFILE}"
echo ""
sudo dd bs=512 if=${UBOOT_SPLFILE} of=${SD_IMG_FILE} seek=2048 conv=notrunc
sudo sync
}

make_bmap_image() {
	echo ""
	echo "NOTE:  Will now make bmap image"
	echo ""
	cd ${CURRENT_DIR}
	bmaptool create -o ${SD_IMG_FILE}.bmap ${SD_IMG_FILE}
	tar -cjSf ${SD_IMG_FILE}.tar.bz2 ${SD_IMG_FILE}
	tar -cjSf ${SD_IMG_FILE}-bmap.tar.bz2 ${SD_IMG_FILE}.tar.bz2 ${SD_IMG_FILE}.bmap
	echo ""
	echo "NOTE:  Bmap image created"
	echo ""
}

format_rootfs(){
	ROOTFS_TYPE=ext4
	ROOTFS_LABEL=rootfs
	ext4_options="-O ^metadata_csum,^64bit"
	#mkfs_options="${ext4_options}"
	mkfs_options=""

	mkfs="mkfs.${ROOTFS_TYPE}"
	media_prefix=${LOOP_DEV}
	media_rootfs_partition=p2

	mkfs_partition="${media_prefix}${media_rootfs_partition}"
	mkfs_label="-L ${ROOTFS_LABEL}"

	sudo sh -c "LC_ALL=C ${mkfs} ${mkfs_options} ${ROOTFS_IMG} ${mkfs_label}"

#	sudo sh -c "LC_ALL=C ${mkfs} ${mkfs_partition} ${mkfs_label}"
}

inst_comp_prefis_rootfs(){
	mount_rootfs_imagefile
	extract_rootfs
	VIRGIN_IMAGE=""
	unmount_rootfs_imagefile
}

compress_prefix_rootfs(){
	mount_rootfs_imagefile
	compress_rootfs
	unmount_rootfs_imagefile
}

if [ ! -z "${WORK_DIR}" ]; then


echo "#---------------------------------------------------------------------------------- "
echo "#-----------+++     Full Image building process start       +++-------------------- "
echo "#---------------------------------------------------------------------------------- "
set -e


	if [[ ${BUILD_UBOOT} == 'yes' ]]; then
		build_uboot
	fi

	if [[ ${BUILD_KERNEL} == 'yes' ]]; then
		build_kernel
	fi

	if [[ ${KERNEL_2_REPO} == 'yes' ]]; then
		add_kernel2repo
	fi

	if [[ ${CROSS_BUILD_DTC} == 'yes' ]]; then
		cross_build_dtc
	fi

	if [[ ${GEN_ROOTFS_IMAGE} == 'yes' ]]; then ## Create a fresh image and replace old if existing:
		IMG_PARTS=0
		create_image
		VIRGIN_IMAGE="yes"
	fi

	COMP_PREFIX=raw

	if [[ ${MAKE_NEW_ROOTFS} == 'yes' ]]; then
		if [[ ${VIRGIN_IMAGE} != 'yes' ]]; then
			echo ""
			echo "Script_MSG: No new image generated formatting old image root partition"
			echo ""
			format_rootfs
		fi
		mount_rootfs_imagefile
		generate_rootfs_into_image #-> creates custom qumu debian rootfs -#
		unmount_rootfs_imagefile

		compress_prefix_rootfs
		VIRGIN_IMAGE=""
	fi

	COMP_PREFIX=final_${USER_NAME}

	if [[ ${ADD_SD_USER} == 'yes' ]]; then
		if [[ ${VIRGIN_IMAGE} == 'yes' ]]; then
			COMP_PREFIX=raw
			inst_comp_prefis_rootfs
			VIRGIN_IMAGE=""
		fi
		mount_rootfs_imagefile
		bind_rootfs
		initial_rootfs_user_setup_sh | tee ${CURRENT_DIR}/usr_setup-log.txt # --> creates custom user setup and archive of final rootfs ---#
		bind_unmount_rootfs_imagefile
		COMP_PREFIX=final_${USER_NAME}

		compress_prefix_rootfs
	fi

	if [[ ${INST_QT} == 'yes' ]]; then
		if [[ "${USER_NAME}" == "holosynth" ]]; then
			if [[ ${VIRGIN_IMAGE} == 'yes' ]]; then
				COMP_PREFIX=final_${USER_NAME}
				inst_comp_prefis_rootfs
				VIRGIN_IMAGE=""
			fi
			if [[ ${INST_QT_DEPS} == 'yes' ]]; then
				mount_rootfs_imagefile
				bind_rootfs
				inst_qt_build_deps | tee ${CURRENT_DIR}/inst_qt_build_deps-log.txt
				bind_unmount_rootfs_imagefile
			fi
 			qt_build | tee ${CURRENT_DIR}/qt_build-log.txt

			cp ${CURRENT_DIR}/rootfs.img ${CURRENT_DIR}/rootfs-qt-4.1.img
			COMP_PREFIX=final_${USER_NAME}_qt
			compress_prefix_rootfs
		fi
	fi

	if [ "${USER_NAME}" == "machinekit" ]; then
		COMP_PREFIX=final_${USER_NAME}
	elif  [ "${USER_NAME}" == "holosynth" ]; then
		COMP_PREFIX=final_${USER_NAME}_qt
	fi

	if [[ ${INST_LOCALKERNEL_DEBS} == 'yes' ]]; then
		if [[ ${VIRGIN_IMAGE} == 'yes' ]]; then
			inst_comp_prefis_rootfs
			VIRGIN_IMAGE=""
		fi
		mount_rootfs_imagefile
		bind_rootfs
		if [[ ${GEN_UINITRD_SCRIPT} == 'yes' ]]; then
			gen_uinitrd_script
		fi
		inst_kernel_from_local_deb | tee ${CURRENT_DIR}/local_kernel_install-log.txt
		bind_unmount_rootfs_imagefile
		COMP_PREFIX=${COMP_PREFIX}-with-kernel

		compress_prefix_rootfs
	else
		if [[ ${INST_REPOKERNEL_DEBS} == 'yes' ]]; then
			if [[ ${VIRGIN_IMAGE} == 'yes' ]]; then
				inst_comp_prefis_rootfs
				VIRGIN_IMAGE=""
			fi
			mount_rootfs_imagefile
			bind_rootfs
			if [[ ${GEN_UINITRD_SCRIPT} == 'yes' ]]; then
				gen_uinitrd_script
			fi
			inst_kernel_from_deb_repo | tee ${CURRENT_DIR}/deb_kernel_install-log.txt
			bind_unmount_rootfs_imagefile
			COMP_PREFIX=${COMP_PREFIX}-with-kernel

			compress_prefix_rootfs
		fi
	fi

	if [ "${USER_NAME}" == "machinekit" ]; then
		COMP_PREFIX=final_${USER_NAME}-with-kernel
	elif  [ "${USER_NAME}" == "holosynth" ]; then
		COMP_PREFIX=final_${USER_NAME}_qt-with-kernel
	fi

	if [ ! -z "${CUSTOM_PREFIX}" ]; then
		COMP_PREFIX=${CUSTOM_PREFIX}
	fi

	if [[ ${CREATE_BMAP} == 'yes' ]]; then ## replace old image with a fresh:
		IMG_PARTS=2
		create_image
		if [[ "${USER_NAME}" == "machinekit" ]]; then
			hostname="mksocfpga3"
		elif [[ "${USER_NAME}" == "holosynth" ]]; then
			hostname="holosynthv"
		fi

		mount_sdimagefile
		extract_rootfs

		finalize | tee ${CURRENT_DIR}/finalize-log.txt
		unmount_sdimagefile

		if [[ ${INST_UBOOT} == 'yes' ]]; then
			echo "NOTE:  Will now install u-boot --> onto sd-card-image:"
			echo "--> ${SD_IMG_FILE}"
			echo ""
			install_uboot | tee ${CURRENT_DIR}/u-boot_install-log.txt   # --> onto sd-card-image (.img)
		fi
		make_bmap_image | tee ${CURRENT_DIR}/make_bmap_image-log.txt
	fi

	echo "#---------------------------------------------------------------------------------- "
	echo "#-------             Image building process complete                       -------- "
	echo "#---------------------------------------------------------------------------------- "
else
	echo "#---------------------------------------------------------------------------------- "
	echo "#-------------     Unsuccessfull script not run      ------------------------------ "
	echo "#-------------  workdir parameter missing      ------------------------------------ "
	echo "#---------------------------------------------------------------------------------- "
fi
