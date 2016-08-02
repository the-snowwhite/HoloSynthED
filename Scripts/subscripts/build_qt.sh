#!/bin/bash

#------------------------------------------------------------------------------------------------------
# Variables Prerequsites
set -e

CURRENT_DIR=${1}

#QT_ROOTFS_MNT="/tmp/myimage"

QT_ROOTFS_MNT="/tmp/qt_4.1-img"
ROOTFS_IMG="${CURRENT_DIR}/rootfs.img"

QTDIR="/home/mib/qt-src/qt-everywhere-opensource-src-5.4.1"

NCORES=`nproc`
#NCORES=4
QT_CC_FOLDER_NAME="gcc-linaro-arm-linux-gnueabihf-4.9-2014.09_linux"
#QT_CC_FOLDER_NAME="gcc-linaro-5.2-2015.11-1-x86_64_arm-linux-gnueabihf"

QT_CC_DIR="/home/mib/Development/${QT_CC_FOLDER_NAME}"
#QT_CC_FILE="${QT_CC_FOLDER_NAME}.tar.xz"
QT_CC="${QT_CC_DIR}/bin/arm-linux-gnueabihf-"


CFLAGS="-march=armv7-a -mtune=cortex-a8 -mfpu=neon -mfloat-abi=hard"


#-----------------------------------------------------------------------------------
# local functions
#-----------------------------------------------------------------------------------

mount_rootfs_imagefile(){
	sudo sync
	mkdir -p ${QT_ROOTFS_MNT}
	sudo mount ${ROOTFS_IMG} ${QT_ROOTFS_MNT}
	echo "#--------------------------------------------------------------------------------------#"
	echo "# Scr_MSG:                                                                             #"
	echo "# ${ROOTFS_IMG}"
	echo "# Is mounted in ---> ${QT_ROOTFS_MNT}"
	echo "#                                                                                      #"
	echo "#--------------------------------------------------------------------------------------#"
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

unmount_rootfs_imagefile(){
	echo "Scr_MSG: Unmounting Imagefile in ---> ${QT_ROOTFS_MNT}"
	sudo umount -R ${QT_ROOTFS_MNT}
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

gen_mkspec(){

	rm -R -f ${QTDIR}/qtbase/mkspecs/linux-arm-gnueabihf-g++
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

QMAKE_QT_CC=${QT_CC_DIR}/bin/arm-linux-gnueabihf-gcc
QMAKE_CXX=${QT_CC_DIR}/bin/arm-linux-gnueabihf-g++ -fPIC
QMAKE_LINK=${QT_CC_DIR}/bin/arm-linux-gnueabihf-g++
QMAKE_LINK_SHLIB=${QT_CC_DIR}/bin/arm-linux-gnueabihf-g++
QMAKE_AR=${QT_CC_DIR}/bin/arm-linux-gnueabihf-ar cr
QMAKE_OBJCOPY=${QT_CC_DIR}/bin/arm-linux-gnueabihf-objcopy
QMAKE_STRIP=${QT_CC_DIR}/bin/arm-linux-gnueabihf-strip
QMAKE_LFLAGS_RELEASE=-"Wl,-O3, -march=armv7-a -mtune=cortex-a8 -mfpu=neon -mfloat-abi=hard -rpath,${QT_ROOTFS_MNT}/usr/lib,-rpath,${QT_ROOTFS_MNT}/usr/lib/arm-linux-gnueabihf,-rpath,${QT_ROOTFS_MNT}/lib/arm-linux-gnueabihf"
QMAKE_LFLAGS_DEBUG += "-Wl,-rpath,${QT_ROOTFS_MNT}/usr/lib,-rpath,${QT_ROOTFS_MNT}/usr/lib/arm-linux-gnueabihf,-rpath,${QT_ROOTFS_MNT}/lib/arm-linux-gnueabihf"

QMAKE_INCDIR=${QT_ROOTFS_MNT}/usr/include
QMAKE_LIBDIR=${QT_ROOTFS_MNT}/usr/lib
QMAKE_LIBDIR+=${QT_ROOTFS_MNT}/usr/lib/arm-linux-gnueabihf
QMAKE_LIBDIR+=${QT_ROOTFS_MNT}/lib/arm-linux-gnueabihf
QMAKE_INCDIR_X11=${QT_ROOTFS_MNT}/usr/include
QMAKE_LIBDIR_X11=${QT_ROOTFS_MNT}/usr/lib
QMAKE_INCDIR_OPENGL=${QT_ROOTFS_MNT}/usr/include
QMAKE_LIBDIR_OPENGL=${QT_ROOTFS_MNT}/usr/lib

load(qt_config)
EOF
}
#QMAKE_LFLAGS_RELEASE=-"Wl,-O1,-rpath,${QT_ROOTFS_MNT}/usr/lib,-rpath,${QT_ROOTFS_MNT}/usr/lib/arm-linux-gnueabihf,-rpath,${QT_ROOTFS_MNT}/lib/arm-linux-gnueabihf"


new_gen_mkspec(){

	rm -R -f ${QTDIR}/qtbase/mkspecs/linux-arm-gnueabihf-g++
	mkdir -p ${QTDIR}/qtbase/mkspecs/linux-arm-gnueabihf-g++
	cp -f -R ${QTDIR}/qtbase/mkspecs/linux-arm-gnueabi-g++/* ${QTDIR}/qtbase/mkspecs/linux-arm-gnueabihf-g++/

# qmake.conf contents:
#sh -c 'cat <<EOF > "${QTDIR}/qtbase/mkspecs/linux-arm-gnueabihf-g++/qmake.conf"
sh -c 'cat <<EOF > '${QTDIR}'/qtbase/mkspecs/linux-arm-gnueabihf-g++/qmake.conf
#
# qmake configuration for building with arm-linux-gnueabihf-g++
#

MAKEFILE_GENERATOR      = UNIX
CONFIG                 += incremental gdb_dwarf_index
QMAKE_INCREMENTAL_STYLE = sublib

include(../common/linux.conf)
include(../common/gcc-base-unix.conf)
include(../common/g++-unix.conf)


QT_QPA_DEFAULT_PLATFORM = linuxfb

# modifications to g++.conf
QMAKE_CC                = '${QT_CC}'gcc
QMAKE_CXX               = '${QT_CC}'g++ -fPIC
QMAKE_LINK              = '${QT_CC}'g++ -fPIC
QMAKE_LINK_SHLIB        = '${QT_CC}'g++ -fPIC

# modifications to linux.conf
QMAKE_AR                = '${QT_CC}'ar cqs
QMAKE_OBJCOPY           = '${QT_CC}'objcopy
QMAKE_NM                = '${QT_CC}'nm -P
QMAKE_STRIP             = '${QT_CC}'strip

#modifications to gcc-base.conf
QMAKE_CFLAGS           += '"${CFLAGS}"'
QMAKE_CXXFLAGS         += '"${CFLAGS}"'
QMAKE_CXXFLAGS_RELEASE += -O3

QMAKE_LIBS             += -lrt -lpthread -ldl


#QMAKE_LFLAGS_RELEASE=-"Wl,-O1,-rpath,'${QT_ROOTFS_MNT}'/usr/lib,-rpath,'${QT_ROOTFS_MNT}'/usr/lib/arm-linux-gnueabihf,-rpath,'${QT_ROOTFS_MNT}'/lib/arm-linux-gnueabihf"
#QMAKE_LFLAGS_DEBUG += "-Wl,-rpath,'${QT_ROOTFS_MNT}'/usr/lib,-rpath,'${QT_ROOTFS_MNT}'/usr/lib/arm-linux-gnueabihf,-rpath,'${QT_ROOTFS_MNT}'/lib/arm-linux-gnueabihf"

# QMAKE_INCDIR='${QT_ROOTFS_MNT}'/usr/include
# QMAKE_LIBDIR='${QT_ROOTFS_MNT}'/usr/lib
# QMAKE_LIBDIR+='${QT_ROOTFS_MNT}'/usr/lib/arm-linux-gnueabihf
# QMAKE_LIBDIR+='${QT_ROOTFS_MNT}'/lib/arm-linux-gnueabihf
# QMAKE_INCDIR_X11='${QT_ROOTFS_MNT}'/usr/include
# QMAKE_LIBDIR_X11='${QT_ROOTFS_MNT}'/usr/lib
# QMAKE_INCDIR_OPENGL='${QT_ROOTFS_MNT}'/usr/include
# QMAKE_LIBDIR_OPENGL='${QT_ROOTFS_MNT}'/usr/lib

load(qt_config)

EOF'
}


qt_configure(){
# # -make examples -reduce-exports  -no-dbus -developer-build -no-gtkstyle
#  -directfb -no-xcb  -make libs -make tools
# # obsolete:  -no-zlib
	../configure -release -opensource -confirm-license -nomake examples -no-c++11 -nomake tests -qt-xcb -no-pch -shared -sysroot ${QT_ROOTFS_MNT} -xplatform linux-arm-gnueabihf-g++ -qreal float -gui -linuxfb -widgets -device-option CROSS_COMPILE=${QT_CC} -prefix /usr/local/lib/qt-5.4.1-altera-soc
}


qt_install_qwt(){
sudo cp -R /usr/local/qwt-6.1.3 ${QT_ROOTFS_MNT}/usr/local/lib
sudo sh -c 'echo "/usr/local/lib/qwt-6.1.3/lib" > '${QT_ROOTFS_MNT}'/etc/ld.so.conf.d/qt.conf'
sudo chroot --userspec=root:root ${QT_ROOTFS_MNT} /sbin/ldconfig
}


qt_build(){
echo ""
echo "Script_MSG: Running qt_build"
echo ""

export PKG_CONFIG_SYSROOT_DIR=${QT_ROOTFS_MNT}
export CROSS_COMPILE=${QT_CC}


PREP_QT="yes";
CONFIGURE_QT="yes";
# 
BUILD_QT="yes";
# 
INSTALL_QT="yes";
INSTALL_QWT="yes";

mkdir -p ${CURRENT_DIR}/Qt_logs

if [[ ${PREP_QT} == 'yes' ]]; then 
#	gen_mkspec | tee ${CURRENT_DIR}/Qt_logs/gen_mkspec-log.txt 
	new_gen_mkspec | tee ${CURRENT_DIR}/Qt_logs/new_gen_mkspec-log.txt 
	sudo ~/sysroot-relativelinks.py ${QT_ROOTFS_MNT} | tee ${CURRENT_DIR}/Qt_logs/sysroot-relativelinks_py-log.txt
fi


if [[ ${CONFIGURE_QT} == 'yes' ]]; then 
	mkdir -p ${QTDIR}/build
	rm -r -f ${QTDIR}/build/*
	cd ${QTDIR}/build
	qt_configure | tee ${CURRENT_DIR}/Qt_logs/qt_configure-log.txt
fi

if [[ ${BUILD_QT} == 'yes' ]]; then 
	cd ${QTDIR}/build
	make -j${NCORES} | tee ${CURRENT_DIR}/Qt_logs/qt_build-log.txt
fi

if [[ ${INSTALL_QT} == 'yes' ]]; then 
	cd ${QTDIR}/build
	sudo make install | tee ${CURRENT_DIR}/Qt_logs/qt_install-log.txt
	sudo cp -R '/usr/local/lib/qt-5.4.1-altera-soc' ''${QT_ROOTFS_MNT}'/usr/local/lib' 
fi

if [[ ${INSTALL_QWT} == 'yes' ]]; then 
	qt_install_qwt
fi

}

#---------------------------------------------------------------------------------- #
#-----------+++     Full Flow Control                       +++-------------------- #
#---------------------------------------------------------------------------------- #

mount_rootfs_imagefile
#bind_rootfs

qt_build

unmount_rootfs_imagefile
