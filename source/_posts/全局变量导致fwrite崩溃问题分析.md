---
title: 全局变量导致fwrite崩溃问题分析
date: 2020-11-26 23:32:59
tags: gdb
categories:
 - 经验分享
---
# ■问题描述
项目Carlife语音识别率不高，录音有卡顿，偶发程序崩溃。
# ■原因
**直接原因：**
fwrite的文件句柄被覆盖，写文件的时候引发程序崩溃。

**根本原因：**
函数重入导致全局变量设定不正确。引起memcpy拷贝数据的时候将buffer数组写穿，内存越界。

# ■分析过程
好久没有Dump解析了，用这次机会来练练手，废话不多说，开搞。

1.解析Dump的第一步，不用说bt查看栈的回溯。
```shell
(gdb) bt
#0  __GI__IO_fwrite (buf=0x6ab18 <VrPackageBuffer>, size=1, count=1024, 
    fp=0xfb0afbc4) at iofwrite.c:41
#1  0x0003200a in CarlifeMicComponent::CaptureCallBack (
    pAppleHandle=<optimized out>, inBuffer=0xaf641050, inLen=4000)
    at /home/dingyu/Workspace/CarLifeDaemon/src/CarlifeMicComponent.cpp:84
#2  0xb6d32e0a in ?? ()
Backtrace stopped: previous frame identical to this frame (corrupt stack?)
```
这个结果看，fp=0xfb0afbc4很可疑，哪有文件句柄这么大的。

2.接下来我们看一下当前栈帧的寄存器信息。
```shell
(gdb) info r
r0             0x6ab18	437016
r1             0x1	1
r2             0x400	1024
r3             0xfb0afbc4	4211801028
r4             0xfb0afbc4	4211801028
r5             0x400	1024
r6             0x0	0
r7             0x6aa08	436744
r8             0xfa0	4000
r9             0xaf641050	2942570576
r10            0x6ab18	437016
r11            0x0	0
r12            0x6a5c8	435656
sp             0xab5ce6c0	0xab5ce6c0
lr             0x3200b	204811
pc             0xb6865bd4	0xb6865bd4 <__GI__IO_fwrite+16>
cpsr           0x200f0030	537854000
r12            0x6a5c8	435656
sp             0xab5ce6c0	0xab5ce6c0
lr             0x3200b	204811
#pc             0xb6865bd4	0xb6865bd4 <__GI__IO_fwrite+16>
cpsr           0x200f0030	537854000
```
3.下一跳是什么导致崩溃的。
```shell
(gdb) disassemble 0xb6865bd4
Dump of assembler code for function __GI__IO_fwrite:
   0xb6865bc4 <+0>:	stmdb	sp!, {r4, r5, r6, r7, r8, r9, lr}
   0xb6865bc8 <+4>:	mul.w	r5, r2, r1
   0xb6865bcc <+8>:	sub	sp, #12
   0xb6865bce <+10>:	cmp	r5, #0
   0xb6865bd0 <+12>:	beq.n	0xb6865cb2 <__GI__IO_fwrite+238>
   0xb6865bd2 <+14>:	mov	r4, r3
#=> 0xb6865bd4 <+16>:	ldr	r3, [r3, #0]
   0xb6865bd6 <+18>:	mov	r6, r0
   0xb6865bd8 <+20>:	mov	r8, r2
   0xb6865bda <+22>:	mov	r7, r1
   0xb6865bdc <+24>:	ands.w	r3, r3, #32768	; 0x8000
   0xb6865be0 <+28>:	bne.n	0xb6865c22 <__GI__IO_fwrite+94>
```
这句话的意思是: 将存储器地址为r3+0的字数据读入寄存器r3

4.我们来访问一下寄存器r3中地址存放的东西。
```shell
(gdb) x/x 0xfb0afbc4
0xfb0afbc4:	Cannot access memory at address 0xfb0afbc4
```
尼玛，居然不能访问，看来是文件句柄被什么覆盖了。

5.被什么覆盖了呢？这下我们要看一下文件句柄在代码里面的位置，无非是被它的邻居覆盖了。
CarlifeMicComponent.cpp
```cpp
static char SpeakerInBuffer[MIC_VCP_BUFFER_SIZE + 1];
static char MicInBuffer[MIC_VCP_BUFFER_SIZE + 1];
static char AecOutBuffer[MIC_VCP_BUFFER_SIZE + 1];
static char VrPackageBuffer[DEF_VR_PACKAGE_LENTH + MIC_VCP_BUFFER_SIZE + 1];

static FILE *fpMicOrg = NULL;
static FILE *fpMicOut = NULL;

static const char *pEnv = NULL;
```
文件句柄是全局静态变量，应该是全局区域的东西把它覆盖了，基本可以排除堆和栈上的数据覆盖文件句柄。上面4个静态全局数组的嫌疑最大。

6.接下来该干什么呢？毫无疑问，把内存中全局变量区域的内容都打印出来。
怎么打印呢？还记得bt打印栈回溯额时候fwrite的入参吗？
```shell
#0  __GI__IO_fwrite (buf=0x6ab18 <VrPackageBuffer>, size=1, count=1024, 
    fp=0xfb0afbc4) at iofwrite.c:41
```
这个不就是全局变量区域的地址嘛。好的，我们一步步吧所有变量的值都打印出来，方法比较死板，就是不停的打。往0x6ab18这块内存的上面，下面都打印出来看看。

打印出来整理一下，大概是这样的：(为了看的更清楚，字体隔行变灰)
```shell
0x6aa08 <_ZL11MicInBuffer>:	0xfc98fda2
......
0x6ab08 <_ZL11MicInBuffer+256>:	0x00000100
#0x6ab0c <_ZL8fpMicOrg>:	0xb0113b50
0x6ab10 <_ZL11bECNREnable>:	0x00000000
#0x6ab14 <_ZZN19CarlifeMicComponent15CaptureCallBackEPvPKviE12iVrDataIndex>:	0x00000600
0x6ab18 <_ZL15VrPackageBuffer>:		0xfe32fa9f	0xfb05ff0b	0xfbdbfe75	0xfd14fdf7
.......
0x6b018 <_ZL15VrPackageBuffer+1280>:	0xfc98fda2	0xfd12fd81	0xfb0afbc4	0xfd94fbfe
#0x6b020 <_ZL8fpMicOut>:	0xfb0afbc4
0x6b024 <_ZZN19CarlifeMicComponent15CaptureCallBackEPvPKviE15iValidDataIndex>:	0xfd94fbfe
#0x6b028 <_ZL15RecodeStartFlag>:	0xfee7fc7e
0x6b02c <_ZL15pCarlifeService>:	0xfff90124
#0x6b030 <_ZL4pEnv>:	0xffc000e7
0x6b034 <_ZL15SpeakerInBuffer>:	0x00a50016
......
0x6b134 <_ZL15SpeakerInBuffer+256>:	0x00000000
```
凶手出来了iVrDataIndex 看代码这个变量不应该超过1024个字节，代码里面只有一处赋值，并且一到1024个字节就至0了。
```cpp
{
    //DEBUG("cpn: %d\n", MIC_VCP_BUFFER_SIZE);
    memcpy(VrPackageBuffer + iVrDataIndex, MicInBuffer, MIC_VCP_BUFFER_SIZE);
}

iVrDataIndex += MIC_VCP_BUFFER_SIZE;
if(iVrDataIndex >= DEF_VR_PACKAGE_LENTH)
{
    DEBUG("%s: %d!\n", bECNREnable?"cpe":"cpn", DEF_VR_PACKAGE_LENTH);
    pTempInstance->sendVRRecordData(VrPackageBuffer, DEF_VR_PACKAGE_LENTH, 0);

    if((true == bSavePcmEnable) && (NULL != fpMicOut))
    {
    	PRINT("fp_write:%p\n",fpMicOut);
        fwrite(VrPackageBuffer, 1, DEF_VR_PACKAGE_LENTH, fpMicOut);
        //fwrite(MicInBuffer, 1, MIC_VCP_BUFFER_SIZE, fpMicOut);
    }

    iVrDataIndex = 0;
}
```
唯一的可能性是这个函数被同时多次调用，又是全局变量惹的祸。

其实后面还有很多工作要做，比如证实iVrDataIndex变量没有问题，没有被覆盖。
算一下0x00000600的十进制1536，正好是256的6倍。这下放心了。
如果你是个完美主义者，可以这样做，打印从0x6ab18 <_ZL15VrPackageBuffer>
地址往后打印1535个字节。你会发现最后停在SpeakerInBuffer数组中，之后的数据都是0，完全符合代码逻辑。

0x6ab14 <_ZZN19CarlifeMicComponent15CaptureCallBackEPvPKviE12iVrDataIndex>:	0x00000600


