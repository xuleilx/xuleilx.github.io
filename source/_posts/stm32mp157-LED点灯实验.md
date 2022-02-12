---
title: stm32mp157-LED点灯实验
date: 2022-02-09 23:09:38
tags: stm32mp157
categories:
 - 设备驱动
---

# 实验内容
1. 内核态编写字符驱动，实现对GPIO输出高低电平控制
2. 用户态实现对字符设备读写，完成最终的点灯
# 实验环境
正点原子stm32mp157开发板
# 实验步骤
## 硬件原理图
![硬件原理图](https://xuleilx.github.io/images/LED点灯实验-硬件原理图.png)

可以看出， LED0 接到了 PI0 上， PI0 就是 GPIOI 组的第 0 个引脚，当 PI0 输出低电平(0)的时候发光二极管 LED0 就会导通点亮，当 PI0 输出高电平(1)的时候发光二极管LED0 不会导通，因此 LED0 也就不会点亮。所以 LED0 的亮灭取决于 PI0 的输出电平，输出 0 就亮，输出 1 就灭。

注意：PI0不要看错了，这个是GPIOI0
## 实验程序编写
### 目录结构
    tree
    .
    ├── ledApp.c
    ├── led.c
    └── Makefile
### 代码
```c
#include <linux/types.h>
#include <linux/kernel.h>
#include <linux/delay.h>
#include <linux/ide.h>
#include <linux/init.h>
#include <linux/module.h>
#include <linux/errno.h>
#include <linux/gpio.h>
#include <asm/mach/map.h>
#include <asm/uaccess.h>
#include <asm/io.h>
/***************************************************************
Copyright © ALIENTEK Co., Ltd. 1998-2029. All rights reserved.
文件名		: led.c
作者	  	: 正点原子
版本	   	: V1.0
描述	   	: LED驱动文件。
其他	   	: 无
论坛 	   	: www.openedv.com
日志	   	: 初版V1.0 2020/11/23 正点原子团队创建
***************************************************************/
#define LED_MAJOR 200  /* 主设备号 */
#define LED_NAME "led" /* 设备名字 */

#define LEDOFF 0 /* 关灯 */
#define LEDON 1	 /* 开灯 */

/* 寄存器物理地址 */
#define PERIPH_BASE (0x40000000)
#define MPU_AHB4_PERIPH_BASE (PERIPH_BASE + 0x10000000)
#define RCC_BASE (MPU_AHB4_PERIPH_BASE + 0x0000)
#define RCC_MP_AHB4ENSETR (RCC_BASE + 0XA28)
#define GPIOI_BASE (MPU_AHB4_PERIPH_BASE + 0xA000)
#define GPIOI_MODER (GPIOI_BASE + 0x0000)
#define GPIOI_OTYPER (GPIOI_BASE + 0x0004)
#define GPIOI_OSPEEDR (GPIOI_BASE + 0x0008)
#define GPIOI_PUPDR (GPIOI_BASE + 0x000C)
#define GPIOI_BSRR (GPIOI_BASE + 0x0018)

/* 映射后的寄存器虚拟地址指针 */
static void __iomem *MPU_AHB4_PERIPH_RCC_PI;
static void __iomem *GPIOI_MODER_PI;
static void __iomem *GPIOI_OTYPER_PI;
static void __iomem *GPIOI_OSPEEDR_PI;
static void __iomem *GPIOI_PUPDR_PI;
static void __iomem *GPIOI_BSRR_PI;

/*
 * @description		: LED打开/关闭
 * @param - sta 	: LEDON(0) 打开LED，LEDOFF(1) 关闭LED
 * @return 			: 无
 */
void led_switch(u8 sta)
{
	u32 val = 0;
	if (sta - '0' == LEDON)
	{
		printk("LEDON\n");
		val = readl(GPIOI_BSRR_PI);
		val |= (1 << 16);
		writel(val, GPIOI_BSRR_PI);
	}
	else if (sta - '0' == LEDOFF)
	{
		printk("LEDOFF\n");
		val = readl(GPIOI_BSRR_PI);
		val |= (1 << 0);
		writel(val, GPIOI_BSRR_PI);
	}
}

/*
 * @description		: 取消映射
 * @return 			: 无
 */
void led_unmap(void)
{
	/* 取消映射 */
	iounmap(MPU_AHB4_PERIPH_RCC_PI);
	iounmap(GPIOI_MODER_PI);
	iounmap(GPIOI_OTYPER_PI);
	iounmap(GPIOI_OSPEEDR_PI);
	iounmap(GPIOI_PUPDR_PI);
	iounmap(GPIOI_BSRR_PI);
}

/*
 * @description		: 打开设备
 * @param - inode 	: 传递给驱动的inode
 * @param - filp 	: 设备文件，file结构体有个叫做private_data的成员变量
 * 					  一般在open的时候将private_data指向设备结构体。
 * @return 			: 0 成功;其他 失败
 */
static int led_open(struct inode *inode, struct file *filp)
{
	return 0;
}

/*
 * @description		: 从设备读取数据
 * @param - filp 	: 要打开的设备文件(文件描述符)
 * @param - buf 	: 返回给用户空间的数据缓冲区
 * @param - cnt 	: 要读取的数据长度
 * @param - offt 	: 相对于文件首地址的偏移
 * @return 			: 读取的字节数，如果为负值，表示读取失败
 */
static ssize_t led_read(struct file *filp, char __user *buf, size_t cnt, loff_t *offt)
{
	return 0;
}

/*
 * @description		: 向设备写数据
 * @param - filp 	: 设备文件，表示打开的文件描述符
 * @param - buf 	: 要写给设备写入的数据
 * @param - cnt 	: 要写入的数据长度
 * @param - offt 	: 相对于文件首地址的偏移
 * @return 			: 写入的字节数，如果为负值，表示写入失败
 */
static ssize_t led_write(struct file *filp, const char __user *buf, size_t cnt, loff_t *offt)
{
	int retvalue;
	unsigned char databuf[128];
	unsigned char ledstat;

	retvalue = copy_from_user(databuf, buf, cnt);
	if (retvalue < 0)
	{
		printk("kernel write failed!\r\n");
		return -EFAULT;
	}

	ledstat = databuf[0]; /* 获取状态值 */

	led_switch(ledstat);

	return retvalue;
}

/*
 * @description		: 关闭/释放设备
 * @param - filp 	: 要关闭的设备文件(文件描述符)
 * @return 			: 0 成功;其他 失败
 */
static int led_release(struct inode *inode, struct file *filp)
{
	return 0;
}

/* 设备操作函数 */
static struct file_operations led_fops = {
	.owner = THIS_MODULE,
	.open = led_open,
	.read = led_read,
	.write = led_write,
	.release = led_release,
};

/*
 * @description	: 驱动出口函数
 * @param 		: 无
 * @return 		: 无
 */
static int __init led_init(void)
{
	int retvalue = 0;
	u32 val = 0;

	/* 初始化LED */
	/* 1、寄存器地址映射 */
	MPU_AHB4_PERIPH_RCC_PI = ioremap(RCC_MP_AHB4ENSETR, 4);
	GPIOI_MODER_PI = ioremap(GPIOI_MODER, 4);
	GPIOI_OTYPER_PI = ioremap(GPIOI_OTYPER, 4);
	GPIOI_OSPEEDR_PI = ioremap(GPIOI_OSPEEDR, 4);
	GPIOI_PUPDR_PI = ioremap(GPIOI_PUPDR, 4);
	GPIOI_BSRR_PI = ioremap(GPIOI_BSRR, 4);

	/* 2、使能PI时钟 */
	val = readl(MPU_AHB4_PERIPH_RCC_PI);
	val &= ~(0X1 << 8); /* 清除以前的设置 */
	val |= (0X1 << 8);	/* 设置新值 */
	writel(val, MPU_AHB4_PERIPH_RCC_PI);

	/* 3、设置PI0通用的输出模式。*/
	val = readl(GPIOI_MODER_PI);
	val &= ~(0X3 << 0); /* bit0:1清零 */
	val |= (0X1 << 0);	/* bit0:1设置01 */
	writel(val, GPIOI_MODER_PI);

	/* 3、设置PI0为推挽模式。*/
	val = readl(GPIOI_OTYPER_PI);
	val &= ~(0X1 << 0); /* bit0清零，设置为上拉*/
	writel(val, GPIOI_OTYPER_PI);

	/* 4、设置PI0为高速。*/
	val = readl(GPIOI_OSPEEDR_PI);
	val &= ~(0X3 << 0); /* bit0:1 清零 */
	val |= (0x2 << 0);	/* bit0:1 设置为10*/
	writel(val, GPIOI_OSPEEDR_PI);

	/* 5、设置PI0为上拉。*/
	val = readl(GPIOI_PUPDR_PI);
	val &= ~(0X3 << 0); /* bit0:1 清零*/
	val |= (0x1 << 0);	/*bit0:1 设置为01*/
	writel(val, GPIOI_PUPDR_PI);

	/* 6、默认关闭LED */
	val = readl(GPIOI_BSRR_PI);
	val |= (0x1 << 0);
	writel(val, GPIOI_BSRR_PI);

	/* 6、注册字符设备驱动 */
	retvalue = register_chrdev(LED_MAJOR, LED_NAME, &led_fops);
	if (retvalue < 0)
	{
		printk("register chrdev failed!\r\n");
		goto fail_map;
	}
	return 0;

fail_map:
	led_unmap();
	return -EIO;
}

/*
 * @description	: 驱动出口函数
 * @param 		: 无
 * @return 		: 无
 */
static void __exit led_exit(void)
{
	/* 取消映射 */
	led_unmap();

	/* 注销字符设备驱动 */
	unregister_chrdev(LED_MAJOR, LED_NAME);
}

module_init(led_init);
module_exit(led_exit);
MODULE_LICENSE("GPL");
MODULE_AUTHOR("ALIENTEK");
MODULE_INFO(intree, "Y");
```
### Makefile
```Makefile
KERNELDIR := /home/alex/study/stm32mp157/01_Source_Code/01、正点原子Linux出厂系统源码/linux-5.4.31
CURRENT_PATH := $(shell pwd)

obj-m := led.o

build: kernel_modules

kernel_modules:
	$(MAKE) -C $(KERNELDIR) M=$(CURRENT_PATH) modules

clean:
	$(MAKE) -C $(KERNELDIR) M=$(CURRENT_PATH) clean

```
### 编译
make
make clean

## 运行测试
将上一小节编译出来的 led.ko和 ledApp这两个文件拷贝到 rootfs/lib/modules/5.4.31 目录中，重启开发板，进入到目录 lib/modules/5.4.31 中，输入如下命令加载 led.ko 驱动模块：
```shell
depmod //第一次加载驱动的时候需要运行此命令
modprobe led //加载驱动
```
驱动加载成功以后创建”/dev/led”设备节点，命令如下：
```shell
mknod /dev/led c 200 0
```
驱动节点创建成功以后就可以使用 ledApp 软件来测试驱动是否工作正常，输入如下命令打开 LED 灯：
```shell
echo 1 > /dev/led  //打开 LED 灯
```
输入上述命令以后观察开发板上的红色 LED 灯，也就是 LED0 是否点亮，如果点亮的话说明驱动工作正常。在输入如下命令关闭 LED 灯：
```shell
echo 0 > /dev/led  //关闭 LED 灯
```
输入上述命令以后观察开发板上的红色 LED 灯是否熄灭，如果熄灭的话说明我们编写的LED 驱动工作完全正常！至此，我们成功编写了第一个真正的 Linux 驱动设备程序。
如果要卸载驱动的话输入如下命令即可：
```shell
modprobe -r led
```
# 经验总结
难点主要在如何看《STM32MP157参考手册.pdf》，首先要找到外设基地址(0x40000000)，然后找到GPIOI(0x5000A000 - 0x5000A3FF)，需要了解STM32的GPIO的每个寄存器作用，如何控制高低电平输出。
GPIO控制时序：
1. 使能PI时钟
2. 设置PI0通用的输出模式
3. 设置PI0为推挽模式
4. 设置PI0为高速
5. 设置PI0为上拉
6. 打开关闭LED

这些初始化时序可以百度STM32 GPIO寄存器操作时序，可以看厂商提供的源码中GPIO相关的内容