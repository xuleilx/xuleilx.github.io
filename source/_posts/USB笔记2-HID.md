---
title: USB笔记2_HID
date: 2020-08-17 20:31:22
tags: USB
categories:
 - 设备驱动
---

# USB笔记2_HID
本篇主要浅谈HID Report

## 一、报告描述符简介
### 1.1 Item介绍
报告描述符比较复杂，它是以item形式排列组合而成，无固定长度，用户可以自定义长度以及每一bit的含义。item类型分三种：main，global和local，每种类型又可以分为多个tag：

**main：**

Input、Output、Feature、Collection、End Collection

**global：**

Usage Page、Logical Minimum、Logical Maximum、Physical Minimum、Physical Maximum、
Unit Exponent、Unit、Report Size、Report ID、Report Count、Push、Pop

**local：**

Usage、Usage Minimum、Usage Maximum、Designator Index、Designator Minimum、
Designator Maximum、String Index、String Minimum、String Maximum、Delimiter、Reserved

### 1.2 Item之间的关系
Main项目中的 input,ouput,feature三个卷标用来表示报告中数据的种类，这些是报告描述符中最主要的项目，其他项目都是用来修饰这三种项目。

>> Input 项：表示设备操作输入到主机的数据模式。这个数据格式就形成一个输入报告，虽然输入报告可以用控制型管线以get report（input）来传输，但是通常用中断型输入管线来传输以确保在每一固定周期内都能将更新的输入报告传给主机。

>> Output 项：表示由主机输出到装置操作的数据格式。这个数据格式就形成一个输出报告。输出报告通常不适用轮询的方式来传送给设备，而是由应用软件依实际需求以传令方式要求送出输出报告，所以大多用控制型管线以set report(output)指令来将报告送到设备。当然也可以选择用中断型输出管线来传送，只是通常不建议这样用。

>> Feature 项：表示由主机送到设备的组态所需数据的数据格式。这个数据模式就形成一个特征报告。特征报告只能用控制型管线以get report(feature)和set report(feature)指令分别来取得和设定设备的特征值

主项目用来定义报告中数据的种类和格式，而说明主项目之意义与用途为全局项目和区域项目。
顾名思义，区域性项目只能适用于列于其下的第一个主项目，不适用于其他主项目，若一个主项目之上有几个不同的卷标的区域性项目，则这些区域性项目皆适用于描述该主项目。
相反，全局性项目适用于其下方的所有主项目，除非另一个相同卷标的全局性项目出现！！！

### 1.3 实例
以下是单点触摸屏的示例报告描述符和格式：
```text
0x05, 0x0D, // Usage Page (Digitizer)
0x09, 0x04, // Usage (Touch Screen)
0xA1, 0x01, // Collection (Application)
0x05, 0x0D, // Usage Page (Digitizer)
0x09, 0x22, // Usage (Finger)
0xA1, 0x02, // Collection (Logical)
0x05, 0x0D, // Usage Page (Digitizer)
0x09, 0x33, // Usage (Touch)
0x15, 0x00, // Logical Minimum......... (0)
0x25, 0x01, // Logical Maximum......... (1)
0x75, 0x01, // Report Size............. (1)
0x95, 0x01, // Report Count............ (1)
0x81, 0x02, // Input...................(Data, Variable, Absolute)
0x75, 0x07, // Report Size............. (7)
0x95, 0x01, // Report Count............ (1)
0x81, 0x01, // Input...................(Constant)
0x05, 0x01, // Usage Page (Generic Desktop)
0x09, 0x30, // Usage (X)
0x15, 0x00, // Logical Minimum......... (0)
0x26, 0x20, 0x03, // Logical Maximum......... (800)
0x75, 0x10, // Report Size............. (16)
0x95, 0x01, // Report Count............ (1)
0x81, 0x02, // Input...................(Data, Variable, Absolute)
0x09, 0x31, // Usage (Y)
0x15, 0x00, // Logical Minimum......... (0)
0x26, 0xE0, 0x01, // Logical Maximum......... (480)
0x75, 0x10, // Report Size............. (16)
0x95, 0x01, // Report Count............ (1)
0x81, 0x02, // Input...................(Data, Variable, Absolute)
0xC0, // End Collection
0xC0, // End Collection
```
单点触摸屏的输入报告布局示例：
```text
|Touch          |             X                 |             Y                 |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|0|1|2|3|4|5|6|7|0|1|2|3|4|5|6|7|0|1|2|3|4|5|6|7|0|1|2|3|4|5|6|7|0|1|2|3|4|5|6|7|
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|       0       |       1       |      2        |       3       |       4       |
```


## 二、主机和设备之间的通信
### 2.1 获取报告描述符
  **HID类请求（命令）包格式**

| 偏移量  | 域             | 大小   | 说明                                       |
| ---- | ------------- | ---- | ---------------------------------------- |
| 0    | bmRequestType | 1    | HID设备类请求特性如下： 位7： 0＝从USB HOST到USB设备 1＝从USB设备到USB HOST 位6~5： 01＝请求类型为设备类请求 位4~0： 0001＝请求对象为接口（interface）因而，针对HID的设备类请求，仅仅10100001和00100001有效 |
| 1    | bRequest      | 1    | HID类请求（参考下表）                             |
| 2    | wValue        | 2    | 高字节说明描述符的类型0x21：HID描述符 0x22：报告描述符 0x23：物理描述符低字节为非0值时被用来选定实体描述符。 |
| 4    | wIndex        | 2    | 2字节数值，根据不同的bRequest有不同的意义                |
| 6    | wLength       | 2    | 该请求的数据段长度                                |

### 2.2 实例
#### 2.2.1 主机端获取报告描述符（该描述符来自UsbMouse）
```text
USB端点0输出中断。
读端点0缓冲区8字节。
0x81 0x06 0x00 0x22 0x00 0x00 0x34 0x00 // 来自主机端的请求，HID类请求（命令）包，8个字节
USB标准输入请求：获取描述符——报告描述符。		 // 报告描述符 52个字节
写端点0缓冲区16字节。
0x05 0x01 0x09 0x02 0xA1 0x01 0x09 0x01 0xA1 0x00 0x05 0x09 0x19 0x01 0x29 0x03 
USB端点0输入中断。
写端点0缓冲区16字节。
0x15 0x00 0x25 0x01 0x95 0x03 0x75 0x01 0x81 0x02 0x95 0x01 0x75 0x05 0x81 0x03 
USB端点0输入中断。
写端点0缓冲区16字节。
0x05 0x01 0x09 0x30 0x09 0x31 0x09 0x38 0x15 0x81 0x25 0x7F 0x75 0x08 0x95 0x03 
USB端点0输入中断。
写端点0缓冲区4字节。
0x81 0x06 0xC0 0xC0 
```
描述符相关的操作是通过端点0进行通信的，也是USB协议中必须要存在的端点。

#### 2.2.2 设备端输入HID Report

```text
USB端点1输入中断。
写端点1缓冲区4字节。
0x00 0x00 0x01 0x00 
```
#### 2.2.2 设备端输入HID Report
```text
USB端点1输出中断。
读端点1缓冲区4字节。
0x00 0x00 0x01 0x00 
```
Host端如果是Linux，调用接口libusb_interrupt_transfer()。可以看出HID控制消息是通过端点1来通信的。

这里的端点1是之前配置描述符中定义的，用于传输真实数据的端点。主机端通过lsusb也可以看到对应的消息：
```text
root@atlas7-arm:~# lsusb -vd 8888:0001
Bus 002 Device 004: ID 8888:0001  
Device Descriptor:
  bLength                18
  bDescriptorType         1
  bcdUSB               1.10
  bDeviceClass            0 (Defined at Interface level)
  bDeviceSubClass         0 
  bDeviceProtocol         0 
  bMaxPacketSize0        16
  idVendor           0x8888 
  idProduct          0x0001 
  bcdDevice            1.00
  iManufacturer           1
  iProduct                2
  iSerial                 3
  bNumConfigurations      1
  Configuration Descriptor:
    bLength                 9
    bDescriptorType         2
    wTotalLength           34
    bNumInterfaces          1
    bConfigurationValue     1
    iConfiguration          0 
    bmAttributes         0x80
      (Bus Powered)
    MaxPower              100mA
    Interface Descriptor:
      bLength                 9
      bDescriptorType         4
      bInterfaceNumber        0
      bAlternateSetting       0
      bNumEndpoints           1
      bInterfaceClass         3 Human Interface Device
      bInterfaceSubClass      1 Boot Interface Subclass
      bInterfaceProtocol      2 Mouse
      iInterface              0 
        HID Device Descriptor:
          bLength                 9
          bDescriptorType        33
          bcdHID               1.10
          bCountryCode           33 US
          bNumDescriptors         1
          bDescriptorType        34 Report
          wDescriptorLength      52
         Report Descriptors: 
           ** UNAVAILABLE **
      Endpoint Descriptor:
        bLength                 7
        bDescriptorType         5
        bEndpointAddress     0x81  EP 1 IN
        bmAttributes            3
          Transfer Type            Interrupt
          Synch Type               None
          Usage Type               Data
        wMaxPacketSize     0x0010  1x 16 bytes
        bInterval              10
Device Status:     0x1fd8
  (Bus Powered)
  Debug Mode
```

## 三、QA
**Q:内核报错usb 1-1: can't set config #1, error -110**
A:设备端没有处理主机端发送过来的消息，收到消息需要回复ack

SETUP数据包（SET_CONFIGURATION）

正常：

0x00 0x09 0x01 0x00 0x00 0x00 0x00 0x00 

异常：

0xC0 0x33 0x00 0x00 0x00 0x00 0x02 0x00 
