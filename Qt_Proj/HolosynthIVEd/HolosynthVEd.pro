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
include ( /usr/local/qwt-6.1.3/features/qwt.prf )
unix:!macx: LIBS += -L/usr/local/lib/qwt-6.1.3/lib -lqwt
INCLUDEPATH += /home/mib/Development/gcc-linaro-arm-linux-gnueabihf-4.9-2014.09_linux/arm-linux-gnueabihf/libc/usr/include
DEPENDPATH += /home/mib/Development/gcc-linaro-arm-linux-gnueabihf-4.9-2014.09_linux/arm-linux-gnueabihf/libc/usr/include
INCLUDEPATH += /home/mib/altera/16.0/embedded/ip/altera/hps/altera_hps/hwlib/include
DEPENDPATH += /home/mib/altera/16.0/embedded/ip/altera/hps/altera_hps/hwlib/include
INCLUDEPATH += /usr/local/lib/qwt-6.1.3/include
DEPENDPATH += /usr/local/lib/qwt-6.1.3/include
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
INSTALLS += target

RESOURCES += virtualboard.qrc
