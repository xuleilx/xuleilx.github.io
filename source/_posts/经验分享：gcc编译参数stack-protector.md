---
title: 经验分享：gcc编译参数stack-protector
date: 2020-11-27 00:38:12
tags:
  - gdb
  - gcc
---
# 经验分享：gcc编译参数stack-protector

前言

## 1     目的

指导针对gcc编译选项stack-protector产生的core的解析，解决产品中的Bug。

## 2     适用范围

C/C++程序开发者。

## 3     职责与权限

针对 **stack smashing detected** 错误，使开发工程师在开发调试时明确调试与修改方向。

## 4     正文内容

### 4.1  stack-protector介绍

Stack overflow攻击是一种很常见的代码攻击，armcc和gcc等编译器都实现了stack protector来避免stack overflow攻击。虽然armcc和gcc在汇编代码生成有些不同，但其原理是相同的。这篇文章以armcc为例，看一看编译器的stack protector。




armcc提供了三个编译选项来打开/关闭stack protector。

-fno-stack-protector 关闭stack protector  man gcc没有找到，gcc版本相关？

-fstack-protector 为armcc认为危险的函数打开stack protector

-fstack-protector-all 为所有的函数打开stack protector



### 4.2  如何防止stack overflow攻击？

armcc在函数栈中的上下文和局部变量之间插入了一个数字来监控堆栈破坏，这个值一般被称作为canary word，在armcc中将这个值定义为__stack_chk_guard。当函数返回之前，函数会去检查canary word是否被修改，如果canary word被修改了，那么证明函数栈被破坏了，这个时候armcc就会去调用一个函数来处理这种栈破坏行为，armcc为我们提供了__stack_chk_fail这个回调函数来处理栈破坏。

因此，在armcc打开-fstack-protector之前需要在代码中设置__stack_chk_guard和__stack_chk_fail。我从ARM的官网上摘抄了一段它们的描述。
```c
void *__stack_chk_guard

You must provide this variable with a suitable value, such as a random value. The value can change during the life of the program. For example, a suitable implementation might be to have the value constantly changed by another thread.

void __stack_chk_fail(void)

It is called by the checking code on detection of corruption of the guard. In general, such a function would exit, possibly after reporting a fault.
 
```

### 4.3  stack protector产生了什么代码来防止stack overflow？

首先来看一下写的一个c代码片段， 代码很简单，__stack_chk_guard 设置为一个常数，当然这只是一个例子，最好的方法是设置这个值为随机数。然后重写了__stack_chk_fail这个回调接口。test_stack_overflow这个函数很简单，仅仅在函数栈上分配了i和c_arr这两个局部变量，并对部分成员赋值。
```c
#include<stdio.h>

void __stack_chk_fail()
{
    printf("__stack_chk_fail()\n");
    while(1);
}

void *__stack_chk_guard = (void *)0;

int test_stack_overflow(int a, int b, int c, int d, int e)
{
    int i;
    int c_arr[15];
    int *p = c_arr;
    i = 15;
    c_arr[0] = 2;
    c_arr[1] = 3;
    return 0;
}

int main(int argc,char* argv[]) 
{
    printf("before test_stack_overflow\n");
    test_stack_overflow(1, 2, 3, 4, 5);
    printf("after test_stack_overflow\n");
    return 0;
}
```


没有打开-fstack-protector选项时：
![img](file:///https://xuleilx.github.io/images/stack-protector-off.jpg) 
打开-fstack-protector选项时：
![img](file:///https://xuleilx.github.io/images/stack-protector-on.jpg) 

在函数返回的时候，检测__stack_chk_guard的值。

下图左边是没有打开-fstack-protector，右边是打开-fstack-protector的汇编代码：

![img](file:///https://xuleilx.github.io/images/stack-protector-asm.jpg)



4.4示例代码

test_overflow.c
```c
#include <stdio.h>
#include <string.h>

int check_password(char *password){
    int flag = 0;
    char buffer[20];
    strcpy(buffer, password);

    if(strcmp(buffer, "mypass") == 0){
        flag = 1;
    }
    if(strcmp(buffer, "yourpass") == 0){
        flag = 1;
    }
    return flag;
}

int main(int argc, char *argv[]){
    if(argc >= 2){
	    if(check_password(argv[1])){
	        printf("%s", "Access granted\n");
	    }else{
	        printf("%s", "Access denied\n");
	    }
    }else{
    	printf("%s", "Please enter password!\n");
    }
} 
```
编译：
```shll
# gcc test_overflow.c -g -fstack-protector
```
