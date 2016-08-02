#include "fpga.h"

#include <stdio.h>
#include <stdlib.h>

#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>

#include <QDebug>
#include <QFile>

#include <stdint.h>
//#include <sys/ioctl.h>
//#include <linux/i2c-dev.h>
//#include <fcntl.h>


//#include "socal/socal.h"
//#include "socal/hps.h"
//#include "socal/alt_gpio.h"

// ///////////////////////////////////////// memory map

//#define HW_REGS_BASE ( ALT_STM_OFST )
#define HW_REGS_SPAN ( 4096 )
#define FILE_DEV "/dev/uio0"

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
    if ( ( fd = open ( FILE_DEV, ( O_RDWR | O_SYNC ) ) ) == -1 ) {
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
//    QByteArray Buffer;
//    Buffer.append(QString::number((regadr << 8) + value));
//    QFile fileB(FILE_DEV);//
//    if (!fileB.open(QIODevice::WriteOnly))
//    {
//        qDebug() << "Failed to open /dev/uio0 for writing\r\n";
//        return false;
//    }
//    fileB.write(Buffer);
//    fileB.close();
//   alt_write_byte((void *) ( (u_int8_t *)synthreg_mem + ( ( uint32_t )( regadr + SYNTHREG_OFFSET) & ( uint32_t )( HW_REGS_MASK ) )) , value );
    return true;
}

u_int8_t FPGAFS::SynthregGet(unsigned int regaddr){
    u_int8_t value = 0;
//    QByteArray Buffer;
//    if (m_bInitSuccess){
//        QFile fileB(FILE_DEV);//
//        if (!fileB.open(QIODevice::ReadOnly))
//        {
//            qDebug() << "Failed to open /dev/uio0 for reading\r\n";
//            return false;
//        }
//        Buffer=fileB.readAll();
//        fileB.close();
        value = *((uint32_t *)(uio_mem_addr + regaddr));
//        value = alt_read_byte((void *) ( (u_int8_t *)synthreg_mem + ( ( uint32_t )( regaddr + SYNTHREG_OFFSET) & ( uint32_t )( HW_REGS_MASK ) )) );
//    }
    return value;
}



