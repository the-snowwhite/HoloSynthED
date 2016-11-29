#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/device.h>
#include <linux/platform_device.h>
#include <linux/uaccess.h>
//#include <asm/uaccess.h>
#include <linux/ioport.h>
#include <linux/io.h>

#define SYNTHREG_BASE 0xff200000
#define PAGE_SIZE 4096
#define SYNTHREG_SIZE PAGE_SIZE
#define SYNTHREG_OFFSET 0x00400

void *synthreg_mem;

static struct device_driver synthreg_driver = {
	.name = "synthreg",
	.bus = &platform_bus_type,
};

ssize_t synthreg_show(struct device_driver *drv, char *buf)
{
	u16 index;
	u8 data;
	for (index=0;index < 672;index++)
	{
		data = ioread8(synthreg_mem + index);
		buf[index] = data;
	}
//	return scnprintf(buf, PAGE_SIZE, "%s\n", drv->name);
	return 672;
}

ssize_t synthreg_store(struct device_driver *drv, const char *buf, size_t count)
{
	unsigned long indata;
	u8 data;
	u16 adr;

	if (buf == NULL) {
		pr_err("Error, string must not be NULL\n");
		return -EINVAL;
	}

	if (kstrtoul(buf, 10, &indata) < 0) {
		pr_err("Could not convert string to integer\n");
		return -EINVAL;
	}

	data = indata & 0xFF;
	if (data > 127) {
		pr_err("Invalid data value %d\n", data);
		return -EINVAL;
	}

	adr = indata >> 8;
	if (adr > 672) {
		pr_err("Invalid address value %d\n", adr);
		return -EINVAL;
	}


	iowrite8(data, synthreg_mem + adr);

	return count;
}

static DRIVER_ATTR(synthreg, (S_IWUSR | S_IRUSR), synthreg_show, synthreg_store);

MODULE_LICENSE("Dual BSD/GPL");

static int __init synthreg_init(void)
{
	int ret;
	struct resource *res;

	ret = driver_register(&synthreg_driver);
	if (ret < 0)
		return ret;

	ret = driver_create_file(&synthreg_driver, &driver_attr_synthreg);
	if (ret < 0) {
		driver_unregister(&synthreg_driver);
		return ret;
	}

	res = request_mem_region((SYNTHREG_BASE + SYNTHREG_OFFSET), SYNTHREG_SIZE, "synthreg");
	if (res == NULL) {
		driver_remove_file(&synthreg_driver, &driver_attr_synthreg);
		driver_unregister(&synthreg_driver);
		return -EBUSY;
	}

	synthreg_mem = ioremap((SYNTHREG_BASE + SYNTHREG_OFFSET), SYNTHREG_SIZE);
	if (synthreg_mem == NULL) {
		driver_remove_file(&synthreg_driver, &driver_attr_synthreg);
		driver_unregister(&synthreg_driver);
		release_mem_region(SYNTHREG_BASE, SYNTHREG_SIZE);
		return -EFAULT;
	}

	return 0;
}

static void __exit synthreg_exit(void)
{
	driver_remove_file(&synthreg_driver, &driver_attr_synthreg);
	driver_unregister(&synthreg_driver);
	release_mem_region((SYNTHREG_BASE + SYNTHREG_OFFSET), SYNTHREG_SIZE);
	iounmap(synthreg_mem);
}

module_init(synthreg_init);
module_exit(synthreg_exit);

MODULE_LICENSE("Dual BSD/GPL");
