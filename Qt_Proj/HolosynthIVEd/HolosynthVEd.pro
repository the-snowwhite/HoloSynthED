#-------------------------------------------------
#
# Project created by QtCreator 2014-06-07T15:43:59
#
#-------------------------------------------------

exists($$GUI_ONLY){
message("GUI_ONLY exists")
message("Gui only")
}else{
message("GUI_ONLY not found")
message("Compiling Gui + synth io")
include ( /usr/lib/aarch64-linux-gnu/qt5/mkspecs/features/qwt.prf )
#include ( /usr/lib/arm-linux-gnueabihf/qt5/mkspecs/features/qwt.prf )
unix:!macx: LIBS += -L/usr/lib -lqwt-qt5
#INCLUDEPATH += /home/mib/Development/gcc-linaro-arm-linux-gnueabihf-4.9-2014.09_linux/arm-linux-gnueabihf/libc/usr/include
#DEPENDPATH += /home/mib/Development/gcc-linaro-arm-linux-gnueabihf-4.9-2014.09_linux/arm-linux-gnueabihf/libc/usr/include
#INCLUDEPATH += /home/mib/intelFPGA/17.1/embedded/ip/altera/hps/altera_hps/hwlib/include
#DEPENDPATH += /home/mib/intelFPGA/17.1/embedded/ip/altera/hps/altera_hps/hwlib/include
#INCLUDEPATH += /tmp/qt_5.7.1-img/usr/local/lib/qwt-6.3.0-svn/include
#DEPENDPATH += /tmp/qt_5.7.1-img/usr/local/lib/qwt/include
}

QT       += core gui

greaterThan(QT_MAJOR_VERSION, 4): QT += widgets

TARGET = HolosynthVEd
TEMPLATE = app


SOURCES += main.cpp\
        mainwindow.cpp \
    keyboard/QKeyPushButton.cpp \
    keyboard/widgetKeyBoard.cpp \
    examplemyfocus.cpp \
    fpgafs.cpp

HEADERS  += mainwindow.h \
    sliderproxy.h \
    fpga.h \
    synth1tab.h \
    filetab.h \
    keyboard/QKeyPushButton.h \
    keyboard/widgetKeyBoard.h \
    examplemyfocus.h

FORMS    += mainwindow.ui

QMAKE_CXXFLAGS += -std=c++0x
QMAKE_CXXFLAGS += -Wno-psabi

target.path = /home/holosynth/prg
mypackage.files = syx
mypackage.path = /home/holosynth/prg
INSTALLS += target mypackage

RESOURCES += virtualboard.qrc
