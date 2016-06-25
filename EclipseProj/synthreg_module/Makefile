obj-m := synthreg.o

KERNEL_SRC_DIR=~/Development/Rev_2-beta/arm-linux-socfpga-4.1-ltsi-rt-gnueabifh-kernel/linux
PWD=$(shell pwd)

CROSS_C="~/Development/Rev_2-beta/gcc-linaro-5.2-2015.11-1-x86_64_arm-linux-gnueabihf/bin/arm-linux-gnueabihf-"
//NCORES=`nproc`
NCORES=1

all:
	make -j$(NCORES) ARCH=arm CROSS_COMPILE=$(CROSS_C) -C $(KERNEL_SRC_DIR) \
		M=$(PWD) modules

clean:
	make -j$(NCORES) ARCH=arm CROSS_COMPILE=$(CROSS_C) -C $(KERNEL_SRC_DIR) \
		M=$(PWD) clean
