---
title: HelloWorld驱动模块
date: 2018-09-17 16:26:31
tags: Driver
---
0、概述
========
	本章主要通过一个简单的实例，实现驱动模块的加载和卸载，并不实现具体的功能。
1、介绍
=========
1.1、编写hello.c
------------------
```c
#include <linux/init.h>
#include <linux/module.h>

MODULE_LICENSE("Dual BSD/GPL");

static int hello_init(void)
{
    printk(KERN_ALERT "Hello, world\n");
}

static void hello_exit(void)
{
    printk(KERN_ALERT "Goodbye, cruel world\n");
}

module_init(hello_init);
module_exit(hello_exit);
```
        这个模块定义了两个函数，一个在模块加载到内核时被调用（hello_init），一个在模块去除时被调用（hello_exit）。module_init和module_exit这几行使用了特别的内核宏来指出这两个函数的角色。另一个特别的宏（MODULE_LICENSE）是用来告知内核，该模块带有一个自由的许可证，没有这样的说明，在模块加载时内核会报错。
    	printk函数在Linux内核中定义并且对模块可用，它与标准C库函数printf的行为相似。内核需要它自己的打印函数，因为没有C库的支持。字串KERN_ALERT是消息的优先级。在此模块中指定了一个高优先级，因为使用默认优先级的消息可能不会直接显示，这依赖于运行的内核版本、klogd守护进程的版本以及配置。
1.2、编写Makefile
------------------
为了编译模块文件，有两种方法创建Makefile文件可以实现:
1、只需一行即可，命令如下：
>obj-m := hello.o

obj-m指出将要编译成的内核模块列表。*.o 格式文件会自动地由相应的 *.c 文件生成（不需要显式地罗列所有源代码文件）
如果要把上述程序编译为一个运行时加载和删除的模块，则编译命令如下所示。
>make -C /usr/src/kernels/2.6.25-14.fc9.i686 M=$PWD modules

这个命令首先是改变目录到用 -C 选项指定的位置（即内核源代码目录，这个参数要根据自己的情况而定）。这个 M= 选项使Makefile在构造modules目标前，返回到模块源码目录。然后，modules目标指向obj-m变量中设定的模块。这里的编译规则的意思是：在包含内核源代码位置的地方进行make，然后再编译 $PWD （当前）目录下的modules。这里允许我们使用所有定义在内核源代码树下的所有规则来编译我们的内核模块。

2、使用下面的Makefile来实现：
```makefile
ifneq ($(KERNELRELEASE),)
	obj-m := hello.o
else 
	KERNELDIR ?= /lib/modules/$(shell uname -r)/build
	PWD :=$(shell pwd)
default:
	$(MAKE) -C $(KERNELDIR) M=$(PWD) modules
endif
```
然后保存后，使用make命令。编译完毕之后，就会在源代码目录下生成hello.ko文件，这就是内核驱动模块了。我们使用下面的命令来加载hello模块。

1.3、效果
------------------
>dmesg | tail

这时，在终端里就会打印出内核信息了。同时，也可以使用lsmod命令来查看是否有加载了
>xuleilx@xuleilx-MS-7817:/opt# lsmod
>Module                  Size  Used by
>helloworld             12448  0 

至此，一个最简单的内核模块驱动程序就完成了。^_^

2、总结
======
	至此，打开通往内核的大门。
	下一步计划：编写字符设备驱动，可以存放一些数值。