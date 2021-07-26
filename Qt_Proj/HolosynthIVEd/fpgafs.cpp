#include "fpga.h"

#include <stdio.h>
#include <stdlib.h>

#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>

#include <QDebug>

#include <stdint.h>

#include <dirent.h> 
//#include <sys/ioctl.h>
//#include <linux/i2c-dev.h>
//#include <fcntl.h>


//#include "socal/socal.h"
//#include "socal/hps.h"
//#include "socal/alt_gpio.h"

// ///////////////////////////////////////// memory map

//#define HW_REGS_BASE ( ALT_STM_OFST )
#define HW_REGS_SPAN ( 4096 )
//#define FILE_DEV "/dev/uio0"
#define FILE_DEV "/dev/uio1"

FPGAFS::FPGAFS()// :
//    m_bIsVideoEnabled(false)
{
    m_bInitSuccess = Init();
    if (!m_bInitSuccess )
        qDebug() << "UIO0 FPGAFS init failed!!!\r\n";
    else
        qDebug() << "UIO0 FPGAFS init success \r\n";
}

FPGAFS::~FPGAFS()
{
    close(fd);
}

bool FPGAFS::Init()
{
    bool bSuccess = true;
    // Open /dev/uio0
    char buf[1024],str[32], uio_dev[16];
    ssize_t len;
    DIR *d;
    struct dirent *dir;
    d = opendir("/sys/class/uio");
    if (d) {
            while ((dir = readdir(d)) != NULL) {
            if( dir->d_type == DT_LNK) {
                sprintf(str, "/sys/class/uio/%s", dir->d_name);

                if ((len = readlink(str, buf, sizeof(buf)-1)) != -1){
                    buf[len] = '\0';
                }
                if(strstr(buf,"a0040000.hm2_axilite_int") || strstr(buf,"ff240000.holosynth_sysex") != NULL) {
                    qDebug() << "\n Found string in " << dir->d_name << "\n";
                    sprintf(uio_dev, "/dev/%s", dir->d_name);
                    qDebug() << buf << "\n\n";
                    qDebug() << uio_dev << "\n";
                }
            }
        }
        closedir(d);
    }
    if ( ( fd = open ( uio_dev, ( O_RDWR | O_SYNC ) ) ) == -1 ) {
        bSuccess = false;
        close ( fd );
    }

    virtual_base = mmap( NULL, HW_REGS_SPAN, ( PROT_READ | PROT_WRITE ), MAP_SHARED, fd, 0);

    if ( virtual_base == MAP_FAILED ) {
        bSuccess = false;
        close ( fd );
    }
    uio_mem_addr=(uint32_t *)virtual_base;
    return bSuccess;
}

bool FPGAFS::SynthregSet(unsigned int regadr, u_int8_t value){
    if (!m_bInitSuccess)
        return false;
    *((uint32_t *)(uio_mem_addr + regadr)) = value;
    return true;
}

u_int8_t FPGAFS::SynthregGet(unsigned int regaddr){
    u_int8_t value = 0;
    value = (*((uint32_t *)(uio_mem_addr + regaddr)) & 0xFF);
    return value;
}



