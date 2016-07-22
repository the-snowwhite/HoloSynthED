#!/bin/bash


#------------------------------------------------------------------------------------------------------
# Variables Custom settings
#------------------------------------------------------------------------------------------------------



#BOARD=nano
#BOARD=de1
BOARD=sockit


#------------------------------------------------------------------------------------------------------
# Variables Static settings
#------------------------------------------------------------------------------------------------------


sockitfolder=SoCkit_GHRD
SCRIPT_ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CURRENT_DIR=`pwd`
WORKSPACE_DIR=${CURRENT_DIR}
WORK_DIR=${1}


CURRENT_DATE=`date -I`
REL_DATE=${CURRENT_DATE}
#REL_DATE=2016-03-07

ROOTFS_DIR=${CURRENT_DIR}/rootfs

nanofolder=DE0_NANO_SOC_GHRD
sockitfolder=SoCkit_GHRD
de1folder=DE1_SOC_GHRD

IMG_ROOT_PART=p2

# cross toolchains
#--------- 4.9  --------------------------------------------------------------------------------------#
GCC49_CROSS_FOLDER_NAME="gcc-linaro-arm-linux-gnueabihf-4.9-2014.09_linux"
GCC49_CROSS_FILE="${GCC49_CROSS_FOLDER_NAME}.tar.xz"
GCC49_CROSS_URL="https://releases.linaro.org/14.09/components/toolchain/binaries/${GCC49_CROSS_FILEE}"

#--------- 5.2  --------------------------------------------------------------------------------------#
## http://releases.linaro.org/components/toolchain/binaries/5.2-2015.11-1/arm-linux-gnueabihf/gcc-linaro-5.2-2015.11-1-x86_64_arm-linux-gnueabihf.tar.xz
GCC52_CROSS_FOLDER_NAME="gcc-linaro-5.2-2015.11-1-x86_64_arm-linux-gnueabihf"
GCC52_CROSS_FILE="${GCC52_CROSS_FOLDER_NAME}.tar.xz"
GCC52_CROSS_URL="http://releases.linaro.org/components/toolchain/binaries/5.2-2015.11-1/arm-linux-gnueabihf/${GCC52_CROSS_FILE}"


#----- select global toolchain ------#
CC_FOLDER_NAME=${GCC49_CROSS_FOLDER_NAME}
CC_URL=${GCC49_CROSS_URL}

CC_DIR="${CURRENT_DIR}/${CC_FOLDER_NAME}"
CC_FILE="${CC_FOLDER_NAME}.tar.xz"
CC="${CC_DIR}/bin/arm-linux-gnueabihf-"

IMG_NAME=${FILE_PRELUDE}-${BOARD}_sd.img
#IMG_NAME=debian-8.4-machinekit-de0-armhf-2016-04-27-4gb_mib.img
IMG_FILE=${CURRENT_DIR}/${IMG_NAME}

MK_RIPROOTFS_NAME=${CURRENT_DIR}/${FILE_PRELUDE}_mk-rip-rootfs-final.tar.bz2

COMP_REL=${distro}_${KERNEL_FOLDER_NAME}

KERNEL_PARENT_DIR=${CURRENT_DIR}/arm-linux-${KERNEL_FOLDER_NAME}-gnueabifh-kernel

KERNEL_DIR=${KERNEL_PARENT_DIR}/linux

HEADERS_DIR=/usr/src/${KERNEL_FOLDER_NAME}

#-------- Internal variables --------------------------------------------------------#

NCORES=`nproc`


install_kernel_dep() {
# install deps for kernel build
sudo apt -y install build-essential fakeroot bc u-boot-tools
sudo apt-get -y build-dep linux
# install linaro gcc 4.9 crosstoolchain dependency:
sudo apt -y install lib32stdc++6
}


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
fi
}

install_deps() {
	install_kernel_dep
	sudo apt install bmap-tools
	echo "MSG: deps installed"
}



mount_imagefile_and_rootfs(){
	sudo sync
	LOOP_DEV=`eval sudo losetup -f --show ${IMG_FILE}`
	sudo mkdir -p ${ROOTFS_MNT}
	sudo mount ${LOOP_DEV}${IMG_ROOT_PART} ${ROOTFS_MNT}
	echo "#--------------------------------------------------------------------------------------#"
	echo "# Scr_MSG:                                                                             #"
	echo "# ${IMG_FILE}"
	echo "# Is mounted in ---> ${LOOP_DEV}"
	echo "#                                                                                      #"
	echo "# ${LOOP_DEV}${IMG_ROOT_PART}"
	echo "# Is mounted in ---> ${ROOTFS_MNT}"
	echo "#                                                                                      #"
	echo "#--------------------------------------------------------------------------------------#"
}

unmount_imagefile_and_rootfs(){
#	sudo kpartx -d -s -v ${IMG_FILE}
	echo "Scr_MSG: Unmounting ---> ${ROOTFS_MNT}"
	PREFIX=${ROOTFS_MNT}
	sudo umount -R ${ROOTFS_MNT}
	echo "Scr_MSG: Unmounting Imagefile in ---> ${LOOP_DEV}"
	sudo losetup -d ${LOOP_DEV}
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
	echo "${COMPNAME} rootfs compressed finish ... unmounting"
fi
}

make_bmap_image() {
	echo ""
	echo "NOTE:  Will now make bmap image"
	echo ""
	cd ${CURRENT_DIR}
	bmaptool create -o ${IMG_NAME}.bmap ${IMG_NAME}
	tar -cjSf ${IMG_NAME}.tar.bz2 ${IMG_NAME}
	tar -cjSf ${IMG_NAME}-bmap.tar.bz2 ${IMG_NAME}.tar.bz2 ${IMG_NAME}.bmap
	echo ""
	echo "NOTE:  Bmap image created"
	echo ""
}


#------------------............ config run functions section ..................-----------#
echo "#---------------------------------------------------------------------------------- "
echo "#-----------+++     Full Image building process start       +++-------------------- "
echo "#---------------------------------------------------------------------------------- "
set -e

get_toolchain

# http://ftp.gnome.org/mirror/qt.io/qtproject/archive/qt/5.3/5.3.2/qt-opensource-linux-x64-5.3.2.run


