obj-m := synthreg.o

KERNEL_SRC_DIR=~/Development/Rev_2-beta/arm-linux-socfpga-4.1-ltsi-rt-gnueabifh-kernel/linux
PWD=$(shell pwd)
CROSS_C="~/Development/Rev_2-beta/gcc-linaro-5.2-2015.11-1-x86_64_arm-linux-gnueabihf/bin/arm-linux-gnueabihf-"
INST=/mnt/rootfs
all:
	make ARCH=arm CROSS_COMPILE=$(CROSS_C) -C $(KERNEL_SRC_DIR) \
		M=$(PWD) modules

install:
	make ARCH=arm CROSS_COMPILE=$(CROSS_C) -C $(KERNEL_SRC_DIR) \
		M=$(PWD) INSTALL_MOD_PATH=$(INST) modules_install


clean:
	make ARCH=arm CROSS_COMPILE=$(CROSS_C) -C $(KERNEL_SRC_DIR) \
		M=$(PWD) clean
