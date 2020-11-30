---
title: Linux内核完全注释_第三章 内核编程语言和环境
date: 2020-08-21 07:25:28
tags: os
---

## 一、目标文件
### 1.1 目标文件格式
![目标文件格式](https://xuleilx.github.io/images/目标文件格式.png)

**a.out格式7个区的基本定义和用途：**
**执行头（exec header）：**该部分中含有一些参数（exec结构），是有关目标文件的整体结构信息。例如代码和数据区的长度、未初始化数据区的长度、对应源程序文件名以及目标文件创建时间等。内核使用这些参数把执行文件加载到内存中并执行，而链接程序（ld）使用这些参数将一些模块文件组合成一个可执行文件。这是目标文件唯一必要的组成部分。

**执行头结构体 **

```C
struct exec {
	unsigned long a_magic // 执行文件魔数。使用 N_MAGIC 等宏访问。
	unsigned a_text // 代码长度，字节数。
	unsigned a_data // 数据长度，字节数。
	unsigned a_bss // 文件中的未初始化数据区长度，字节数。
	unsigned a_syms // 文件中的符号表长度，字节数。
	unsigned a_entry // 执行开始地址。
	unsigned a_trsize // 代码重定位信息长度，字节数。
	unsigned a_drsize // 数据重定位信息长度，字节数。
}
```
**代码区（text segment）：**由编译器或汇编器生成的二进制指令代码和数据信息，含有程序执行时被加载到内存中的指令和相关数据。可以以只读形式被加载。

**数据区（data segment）：**由编译器或汇编器生成的二进制指令代码和数据信息，这部分含有已经初始化过的数据，总是被加载到可读写的内存中。

**代码重定位（text relocations）：**这部分含有供链接程序使用的记录数据。在组合目标模块文件时用于定位代码段中的指针或地址。当链接程序需要该表目标代码的地址时就需要修正和维护这些地方。

**数据重定位（data relocations）：**类似于代码重定位部分的作用，但是用于数据段中指针的重定位。

**重定位结构体 :**

```C
struct relocation_info
{
	int r_address; // 段内需要重定位的地址。
	unsigned int r_symbolnum:24; // 含义与 r_extern 有关。指定符号表中一个符号或者一个段。
	unsigned int r_pcrel:1; // 1 比特。 PC 相关标志。
	unsigned int r_length:2; // 2 比特。指定要被重定位字段长度（2 的次方）。
	unsigned int r_extern:1; // 外部标志位。 1 - 以符号的值重定位。 0 - 以段的地址重定位。
	unsigned int r_pad:4; // 没有使用的 4 个比特位，但最好将它们复位掉。
};
```
**符号表（symbol table）：**这部分同样含有供链接程序使用的记录数据。这些记录数据保保存着模块文件中定义的全局符号以及需要从其他模块文件中输入的符号，或者是由链接器定义的符号，用于在模块文件之间对命名的变量和函数（符号）进行交叉引用。

**字符串表（string table）：**该部分含有与符号名相对应的字符串。用于调试程序调试目标代码，与连接过程无关。这些信息科包含源程序代码和行号、局部符号以及数据结构描述信息等。
```C
struct nlist {
	union {
		char *n_name; // 字符串指针，
		struct nlist *n_next; // 或者是指向另一个符号项结构的指针，
		long n_strx; // 或者是符号名称在字符串表中的字节偏移值。
	} n_un;
	unsigned char n_type; // 该字节分成 3 个字段，参见 a.out.h 文件 146-154 行。
	char n_other; // 通常不用。
	short n_desc; //
	unsigned long n_value; // 符号的值。
};
```


对于一个指定的目标文件并非一定会包含所有以上信息。  
### 1.2 可执行文件映射到进程逻辑地址空间

![目标文件地址空间映射](https://xuleilx.github.io/images/目标文件地址空间映射.png)

### 1.3 目标文件的链接操作

![目标文件的链接](https://xuleilx.github.io/images/目标文件的链接.png)

### 1.4 System.map文件
链接（ld）时使用“-M”选项，或者使用nm，可以生成链接映像（link map）信息，即连接程序产生的目标程序内存地址映像信息。其中列出了程序段装入内存中的位置信息。有如下信息：
-  目标文件及符号信息映射到内存中的位置
-  公共符号如何放置
-  链接中包含的所有文件成员及其应用的符号

一般存放在：
> /boot/System.map
> /System.map
> /usr/src/linux/System.map

表 3-5 目标文件符号列表文件中的符号类型

| 符号类型 | 名称        | 说明                                       |
| ---- | --------- | ---------------------------------------- |
| A    | Absolute  | 符号的值是绝对值，并且在进一步链接过程中不会被改变。               |
| B    | BSS       | 符号在未初始化数据区或区（section） 中，即在 BSS 段中        |
| C    | Common    | 符号是公共的。公共符号是未初始化的数据。在链接时，多个公共符号可能具 有同一名称。如果该符号定义在其他地方，则公共符号被看作是未定义的引用。 |
| D    | Data      | 符号在已初始化数据区中。                             |
| G    | Global    | 符号是在小对象已初始化数据区中的符号。某些目标文件的格式允许对小数据 对象（例如一个全局整型变量）可进行更有效的访问 |
| I    | Inderect  | 符号是对另一个符号的间接引用                           |
| N    | Debugging | 符号是一个调试符号                                |
| R    | Read only | 符号在一个只读数据区中                              |
| S    | Small     | 符号是小对象未初始化数据区中的符号                        |
| T    | Text      | 符号是代码区中的符号                               |
| U    | Undefined | 符号是外部的，并且其值为 0（未定义）                      |
| -    | Stabs     | 符号是 a.out 目标文件中的一个 stab 符号，用于保存调试信息      |
| ?    | Unknwon   | 符号的类型未知，或者是与具体文件格式有关                     |

## 二、MakeFile
### 2.1 Makefile 文件中的规则
```MakeFile
target（目标）...： prerequisites（先决条件）...
				command（命令）
```
**prerequisite（先决条件或称依赖对象）**是用以创建 target 所必要或者依赖的一系列文件或其他目标。target 通常依赖于多个这样的必要文件或目标文件。

**command（命令）**是指 make 所执行的操作，通常就是一些 shell 命令，是生成 target 需要执行的操作。当先决条件中一个或多个文件的最后修改时间比 target 文件的要新时，规则的命令就会被执行。另外，一个规则中可以有多个命令，每个命令占用规则中单独一行。请注意，我们需要在写每个命令之前键入一个制表符（按 Tab 键产生）！
```MakeFile
edit : main.o files.o utils.o
	cc -o edit main.o files.o utils.o
main.o : main.c defs.h
	cc -c main.c
files.o : files.c defs.h buffer.h command.h
	cc -c files.c
utils.o : utils.c defs.h
	cc -c utils.c
clean :
	rm edit main.o files.o utils.o
```
### 2.2 让MakeFile自动推断命令
```MakeFile
objects = main.o files.o utils.o #变量
edit : $(objects) #自动推断命令
	cc -o edit $(objects)
main.o : defs.h
files.o : defs.h buffer.h command.h
utils.o : defs.h
clean :
	rm edit $(objects)
```
### 2.3 隐含规则中的自动变量
```MakeFile
#        ↓ 第一个先决条件
foo.o : foo.c defs.h hack.h
	cc -c $(CFLAGS) $< -o $@
```
**$^**: 表示规则的所有先决条件，包括它们所处目录的名称；代表所有通过目录搜索得到的依赖文件的完整路径名（目录 + 一般文件名）列表 ；
**$<**: 表示规则中的第一个先决条件；如：替换成 foo.c 
**$@**: 表示目标对象；如：被替换为 foo.o  

参考：GNU make中文手册 

## 三、小结
学习可执行文件的内存结构，复习MakeFile的语法。