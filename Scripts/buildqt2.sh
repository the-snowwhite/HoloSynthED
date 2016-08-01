#!/bin/bash



#------------------------------------------------------------------------------------------------------
# Variables Prerequsites
#apt_cmd=apt
apt_cmd="apt-get"
#------------------------------------------------------------------------------------------------------
WORK_DIR=${1}

#distro=sid
distro=jessie
#distro=stretch

MAIN_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SUB_SCRIPT_DIR=${MAIN_SCRIPT_DIR}/subscripts
CURRENT_DIR=`pwd`
#ROOTFS_MNT=/mnt/rootfs
ROOTFS_MNT=/tmp/myimage

ROOTFS_IMG=${CURRENT_DIR}/rootfs.img

CURRENT_DATE=`date -I`
REL_DATE=${CURRENT_DATE}
#REL_DATE=2016-03-07

NCORES=`nproc`

QTDIR=//home/mib/qt-src/qt-everywhere-opensource-src-5.4.1

#--------- 4.9 Gcc Toolchain --------------------------------------------------------------#
GCC49_CC_FOLDER_NAME="gcc-linaro-arm-linux-gnueabihf-4.9-2014.09_linux"
GCC49_CC_URL="https://releases.linaro.org/14.09/components/toolchain/binaries/gcc-linaro-arm-linux-gnueabihf-4.9-2014.09_linux.tar.xz"

#--------- 5.2 Gcc Toolchain --------------------------------------------------------------#
## http://releases.linaro.org/components/toolchain/binaries/5.2-2015.11-1/arm-linux-gnueabihf/gcc-linaro-5.2-2015.11-1-x86_64_arm-linux-gnueabihf.tar.xz
PCH52_CC_FOLDER_NAME="gcc-linaro-5.2-2015.11-1-x86_64_arm-linux-gnueabihf"
PCH52_CC_FILE="${PCH52_CC_FOLDER_NAME}.tar.xz"
PCH52_CC_URL="http://releases.linaro.org/components/toolchain/binaries/5.2-2015.11-1/arm-linux-gnueabihf/${PCH52_CC_FILE}"

#-----  select global toolchain  ------#

# CC_FOLDER_NAME=$GCC49_CC_FOLDER_NAME
# CC_URL=$GCC49_CC_URL
CC_FOLDER_NAME=$PCH52_CC_FOLDER_NAME
CC_URL=$PCH52_CC_URL

CC_DIR="${CURRENT_DIR}/${CC_FOLDER_NAME}"
CC_FILE="${CC_FOLDER_NAME}.tar.xz"
CC="${CC_DIR}/bin/arm-linux-gnueabihf-"

COMP_REL=debian-${distro}_socfpga


#-----------------------------------------------------------------------------------
# local functions for external scripts
#-----------------------------------------------------------------------------------


install_deps() {
	get_toolchain
	install_uboot_dep
	install_kernel_dep
#	#sudo ${apt_cmd} install kpartx
	install_rootfs_dep
	sudo ${apt_cmd} install bmap-tools
	echo "MSG: deps installed"
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

unmount_rootfs_imagefile(){
	echo "Scr_MSG: Unmounting Imagefile in ---> ${ROOTFS_MNT}"
	sudo umount -R ${ROOTFS_MNT}
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
	echo "${COMPNAME} rootfs extraction finished .."
fi
}

gen_mkspec(){

	mkdir -p ${QTDIR}/qtbase/mkspecs/linux-arm-gnueabihf-g++
	cp -f -R ${QTDIR}/qtbase/mkspecs/linux-arm-gnueabi-g++/* ${QTDIR}/qtbase/mkspecs/linux-arm-gnueabihf-g++/

# qmake.conf contents:
cat <<EOF > "${QTDIR}/qtbase/mkspecs/linux-arm-gnueabihf-g++/qmake.conf"
#
# qmake configuration for linux-arm-gnueabihf-g++
#

MAKEFILE_GENERATOR      = UNIX
CONFIG                 += incremental gdb_dwarf_index
QMAKE_INCREMENTAL_STYLE = sublib

include(../common/linux.conf)
include(../common/gcc-base-unix.conf)
include(../common/g++-unix.conf)

QMAKE_CC=${CC_DIR}/bin/arm-linux-gnueabihf-gcc
QMAKE_CXX=${CC_DIR}/bin/arm-linux-gnueabihf-g++ -fPIC
QMAKE_LINK=${CC_DIR}/bin/arm-linux-gnueabihf-g++
QMAKE_LINK_SHLIB=${CC_DIR}/bin/arm-linux-gnueabihf-g++
QMAKE_AR=${CC_DIR}/bin/arm-linux-gnueabihf-ar cr
QMAKE_OBJCOPY=${CC_DIR}/bin/arm-linux-gnueabihf-objcopy
QMAKE_STRIP=${CC_DIR}/bin/arm-linux-gnueabihf-strip
QMAKE_LFLAGS_RELEASE=-"Wl,-O1,-rpath,${ROOTFS_MNT}/usr/lib,-rpath,${ROOTFS_MNT}/usr/lib/arm-linux-gnueabihf,-rpath,${ROOTFS_MNT}/lib/arm-linux-gnueabihf"
QMAKE_LFLAGS_DEBUG += "-Wl,-rpath,${ROOTFS_MNT}/usr/lib,-rpath,${ROOTFS_MNT}/usr/lib/arm-linux-gnueabihf,-rpath,${ROOTFS_MNT}/lib/arm-linux-gnueabihf"

QMAKE_INCDIR=${ROOTFS_MNT}/usr/include
QMAKE_LIBDIR=${ROOTFS_MNT}/usr/lib
QMAKE_LIBDIR+=${ROOTFS_MNT}/usr/lib/arm-linux-gnueabihf
QMAKE_LIBDIR+=${ROOTFS_MNT}/lib/arm-linux-gnueabihf
QMAKE_INCDIR_X11=${ROOTFS_MNT}/usr/include
QMAKE_LIBDIR_X11=${ROOTFS_MNT}/usr/lib
QMAKE_INCDIR_OPENGL=${ROOTFS_MNT}/usr/include
QMAKE_LIBDIR_OPENGL=${ROOTFS_MNT}/usr/lib

load(qt_config)
EOF
}

# # # # CXX=g++  -fPIC
# # # # CXXFLAGS= -g -O3 -Wall

#------------------............ config run functions section ..................-----------#
# 
# ------- install following libs for qt x11: ----------
# apt-get install libfontconfig1-dev libfreetype6-dev libx11-dev libxext-dev libxfixes-dev libxi-dev libxrender-dev libxcb1-dev libx11-xcb-dev libxcb-glx0-dev 
# --- configure with -qt-xcb ----------
# --- non shadow build ---
# 
# 
# git git clone https://code.qt.io/qt/qt5.git qt5
# 
# 
# export PATH=/home/mib/Development/hm3-beta2/gcc-linaro-arm-linux-gnueabihf-4.9-2014.09_linux/bin:$PATH
# 
# sudo mount -o loop rootfs.img /tmp/myimage
# 
# cd ~/
# git clone https://code.qt.io/cross-compile-tools/cross-compile-tools.git
# 
# sudo ./fixQualifiedLibraryPaths /tmp/myimage gcc-linaro-arm-linux-gnueabihf-4.9-2014.09_linux/bin/arm-linux-gnueabihf-gcc
# 
# wget https://raw.githubusercontent.com/riscv/riscv-poky/master/scripts/sysroot-relativelinks.py
# chmod +x sysroot-relativelinks.py
# ./sysroot-relativelinks.py /tmp/myimage
# 
# cd /home/mib/Qt5/qt-everywhere-opensource-src-5.4.1/qtbase
# 
# 
# 
# ../configure -prefix /usr/local/qt-5.4.1-soc -opensource -confirm-license -release -shared -make examples -nomake tools -xplatform linux-arm-gnueabihf-g++  -qreal float -no-pch -v
# 
# ----- or soc x11 -----
# 
# ../configure -release -opensource -confirm-license -qt-xcb -optimized-qmake -no-pch -make libs -make tools -reduce-exports -shared -sysroot /tmp/myimage -xplatform linux-arm-gnueabihf-g++ -qreal float -no-dbus -v -gui -widgets -device-option CROSS_COMPILE=/home/mib/Development/hm3-beta2/gcc-linaro-arm-linux-gnueabihf-4.9-2014.09_linux/bin/arm-linux-gnueabihf- -prefix /usr/local/qt-5.4.1-soc-xcb
# 
# ----- or -----

configure_1(){
# -make examples-no-gtkstyle -make tools -reduce-exports  -no-dbus  
#  -directfb 
	../configure -release -opensource -confirm-license -no-c++11 -no-xcb -no-pch -optimized-qmake -make libs -shared -sysroot ${ROOTFS_MNT} -xplatform linux-arm-gnueabihf-g++ -qreal float -gui -linuxfb -widgets -device-option CROSS_COMPILE=/home/mib/Development/hm3-beta2/gcc-linaro-arm-linux-gnueabihf-4.9-2014.09_linux/bin/arm-linux-gnueabihf- -qt-zlib -prefix /usr/local/lib/qt-5.4.1-altera-soc
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

}

#----------------------------- Run -------------------------------------------------------#
export PKG_CONFIG_SYSROOT_DIR=${ROOTFS_MNT}
export CROSS_COMPILE=${CC}


PREP="yes";
# CONFIGURE="yes";
# 
# BUILD="yes";
# 
# INSTALL="yes";

mkdir -p ${CURRENT_DIR}/Qt_logs

if [[ ${PREP} == 'yes' ]]; then ## Create a fresh image and replace old if existing:
	echo ""
	echo "Script_MSG: Formatting old image root partition"
	echo ""
	format_rootfs | tee ${CURRENT_DIR}/Qt_logs/format_rootfs-log.txt
fi

mount_rootfs_imagefile

if [[ ${PREP} == 'yes' ]]; then ## Create a fresh image and replace old if existing:
#	COMP_PREFIX=final-kernel-from-repo-deb
	COMP_PREFIX=qt-final
	extract_rootfs | tee ${CURRENT_DIR}/Qt_logs/extract_rootfs-log.txt

#	gen_mkspec | tee ${CURRENT_DIR}/Qt_logs/gen_mkspec-log.txt 
# 	sudo ~/sysroot-relativelinks.py ${ROOTFS_MNT}
fi

cd ${QTDIR}/build

if [[ ${CONFIGURE} == 'yes' ]]; then ## Create a fresh image and replace old if existing:
	mkdir -p ${QTDIR}/build
	rm -r -f ${QTDIR}/build/*
	configure_1 | tee ${CURRENT_DIR}/Qt_logs/configure_1-log.txt
fi

if [[ ${BUILD} == 'yes' ]]; then ## Create a fresh image and replace old if existing:
	make -j${NCORES} | tee ${CURRENT_DIR}/Qt_logs/make-log.txt
fi

if [[ ${INSTALL} == 'yes' ]]; then ## Create a fresh image and replace old if existing:
	sudo make install | tee ${CURRENT_DIR}/Qt_logs/install-log.txt
	sudo cp -R '/usr/local/lib/qt-5.4.1-altera-soc' ''${ROOTFS_MNT}'/usr/local/lib' 
	cd ${CURRENT_DIR}
	COMP_PREFIX=qt-final
	compress_rootfs | tee ${CURRENT_DIR}/Qt_logs/compress_rootfs-log.txt
fi

##### #  #sudo gedit '/media/ac4e5a85-5e37-401f-8474-20d4316e4dee/etc/profile' 

unmount_rootfs_imagefile




# 
# ----- or soc FB -----
# 
# ./configure -release -opensource -confirm-license -no-xcb -optimized-qmake -no-pch -make libs -make tools -reduce-exports -shared -sysroot /mnt/soc-rootfs -xplatform linux-arm-gnueabihf-g++ -qreal float -no-dbus -v -gui -no-gtkstyle -linuxfb -widgets -device-option CROSS_COMPILE=/home/mib/altera/14.0/embedded/ds-5/bin/arm-linux-gnueabihf -prefix /usr/local/qt-5.3.1-soc
# 
# ----- or soc FB -----
# 
# ./configure -release -opensource -confirm-license -xplatform linux-arm-gnueabihf-g++ -gui -linuxfb -widgets -make examples -nomake tools  -qreal float -sysroot /mnt/soc-rootfs -device-option CROSS_COMPILE=/home/mib/altera/14.0/embedded/ds-5/bin/arm-linux-gnueabihf -prefix /usr/local/qt-5.3.1-soc
# 
# ----- or soc FB (linux-altera-soc-g++) -----
# --- Copy mkspecs + devices ---
# cd /home/mib/Downloads/QT_Src/qt-everywhere-opensource-src-5.4.1
# 
# ./configure -prefix /usr/local/qt-5.4.1-soc -opensource -confirm-license -release -shared -make examples -make tools -make libs -gui -linuxfb -mtdev -widgets -xplatform linux-arm-gnueabihf-g++ -device linux-altera-soc-g++ -device-option CROSS_COMPILE=/usr/local/linaro/bin/arm-linux-gnueabihf- -qreal float -no-pch -v -qt-zlib -optimized-qmake -reduce-exports
# 
# ----- or host -----
# 
# # ../configure -prefix /usr/local/lib/qt-5.3.1-altera-soc_xcb -opensource -confirm-license -release -shared -nomake examples -make tools  -xplatform linux-arm-gnueabihf-g++ -qreal float -no-pch -v -qt-zlib -optimized-qmake -reduce-exports -make libs -gui -widgets -device-option






#export CROSS_COMPILE=/home/mib/altera/13.1/embedded/ds-5/bin/arm-linux-gnueabihf

#export CROSS_COMPILE=${CC_DIR}/bin/arm-linux-gnueabihf
#export ROOTFS=/sdmnt
#export QMAKESPEC=${QTDIR}/qtbase/mkspecs/linux-arm-gnueabihf-g++
#export QMAKESPEC=${CC_DIR}/bin/arm-linux-gnueabihf-g++

# 
# export ROOTFS=${ROOTFS_MNT}
# 
# export PKG_CONFIG_PATH=${ROOTFS_MNT}/usr/lib/pkgconfig
# 
# export PKG_CONFIG_SYSROOT=${ROOTFS_MNT}
# 
# #----------------------------- Run -------------------------------------------------------#
# 
# mount_rootfs_imagefile
# 
# gen_mkspec
# 
# unmount_rootfs_imagefile

# 
# ${QTDIR}/configure -arch armhf -release -prefix /usr/local/altera_soc_5.4.1 -opensource -confirm-license -xplatform linux-arm-gnueabihf-g++ -gui -linuxfb -gtkstyle -no-xcb -widgets -nomake examples -nomake tools  -qreal float -v
# 
# #${QTDIR}/configure -arch arm -release -prefix /usr/local/altera_soc_5.4.1 -opensource -confirm-license -xplatform linux-arm-gnueabihf-g++ -force-pkg-config -gui -linuxfb -gtkstyle -no-xcb -widgets -nomake examples -nomake tools  -qreal float -v
# 
# #$QTDIR/configure -debug -opensource -confirm-license -xplatform linux-arm-g++ -gui -qt-xcb -force-pkg-config -no-gtkstyle -widgets -make examples -make libs -nomake tools -qreal float -prefix /usr/local/qt5_sockit -sysroot $ROOTFS -v
# #$QTDIR/configure -debug -opensource -confirm-license -static -optimized-qmake -xplatform linux-arm-g++ -gui -qt-xcb -force-pkg-config -widgets -make examples -make libs -nomake tools -qreal float -prefix /usr/local/qt5_sockit -sysroot $ROOTFS -v
# #$QTDIR/configure -debug -opensource -confirm-license -optimized-qmake -xplatform linux-arm-gnueabihf-g++ -gui -qt-xcb -force-pkg-config -widgets -no-gtkstyle -make examples -make libs -nomake tools -qreal float -prefix /usr/local/qt5_sockit -sysroot $ROOTFS -v 
# # $QTDIR/configure -xplatform linux-arm-g++ -force-pkg-config -LinuxFB -opensource -confirm-license -make examples -nomake tools
# 
# cd ${QTDIR}
# 
# #mkdir -p build
# #cd build
# #unset QMAKESPEC
# 
# #../make clean
# 
# #../make -j${NCORES}
# 
# #cd ..
