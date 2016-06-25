#ifndef FPGA_H
#define FPGA_H

#include <unistd.h>
#include <stdbool.h>
#include <stdint.h>

class FPGAFS
{
public:
    FPGAFS();
    ~FPGAFS();

    bool SynthregSet(unsigned int regadr, uint8_t value);
    uint8_t SynthregGet(unsigned int regadr);


protected:
    bool m_bInitSuccess;
    int fd;
//    bool m_bIsVideoEnabled;
//    uint8_t *s_synthreg_base;
    bool Init();

};

#endif // FPGA_H
