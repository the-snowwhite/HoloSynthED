#include "fpga.h"
#include <QDebug>
#include <QFile>

//#include <unistd.h>
#include <stdint.h>
//#include <sys/ioctl.h>
//#include <linux/i2c-dev.h>
//#include <fcntl.h>


//#include <sys/mman.h>
//#include "socal/socal.h"
//#include "socal/hps.h"
//#include "socal/alt_gpio.h"

//#define SYNTHREG_OFFSET 0x00400
//#define PAGE_SIZE 4096
//volatile unsigned char *synthreg_mem;
// ///////////////////////////////////////// memory map

//#define HW_REGS_BASE ( ALT_STM_OFST )
//#define HW_REGS_SPAN ( 0x04000000 )
//#define HW_REGS_MASK ( HW_REGS_SPAN - 1 )
#define FILE_DEV "/sys/bus/platform/drivers/synthreg/synthreg"

FPGAFS::FPGAFS()// :
//    m_bIsVideoEnabled(false)
{
    m_bInitSuccess = Init();
    if (!m_bInitSuccess )
        qDebug() << "FPGAFS init failed!!!\r\n";
    else
        qDebug() << "FPGAFS init success \r\n";
}

FPGAFS::~FPGAFS()
{
    close(fd);
}

bool FPGAFS::Init()
{
    bool bSuccess = false;
    QFile fileB(FILE_DEV);
    if (fileB.open(QIODevice::ReadOnly)){
        bSuccess = true;
        fileB.close();
    }
    return bSuccess;
}

bool FPGAFS::SynthregSet(unsigned int regadr, u_int8_t value){
    if (!m_bInitSuccess)
        return false;
    QByteArray Buffer;
    Buffer.append(QString::number((regadr << 8) + value));
    QFile fileB(FILE_DEV);//
    if (!fileB.open(QIODevice::WriteOnly))
    {
        qDebug() << "Failed to open /sys/bus/platform/drivers/synthreg/synthreg for writing\r\n";
        return false;
    }
    fileB.write(Buffer);
    fileB.close();
//   alt_write_byte((void *) ( (u_int8_t *)synthreg_mem + ( ( uint32_t )( regadr + SYNTHREG_OFFSET) & ( uint32_t )( HW_REGS_MASK ) )) , value );
    return true;
}

u_int8_t FPGAFS::SynthregGet(unsigned int regaddr){
    u_int8_t value = 0;
    QByteArray Buffer;
    if (m_bInitSuccess){
        QFile fileB(FILE_DEV);//
        if (!fileB.open(QIODevice::ReadOnly))
        {
            qDebug() << "Failed to open /sys/bus/platform/drivers/synthreg/synthreg for reading\r\n";
            return false;
        }
        Buffer=fileB.readAll();
        fileB.close();
        value = Buffer.at(regaddr);
//        value = alt_read_byte((void *) ( (u_int8_t *)synthreg_mem + ( ( uint32_t )( regaddr + SYNTHREG_OFFSET) & ( uint32_t )( HW_REGS_MASK ) )) );
    }
    return value;
}



