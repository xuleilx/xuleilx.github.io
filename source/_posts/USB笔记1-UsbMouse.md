---
title: USB笔记1_UsbMouse
date: 2020-08-11 20:34:38
tags:
---

# USB笔记1_UsbMouse

本篇主要来自《圈圈教你玩usb》的UsbMouse实例

## 一、USB枚举过程
### 1.1 Device设备端代码片段
```c
while(1)  //死循环
{
  if(D12GetIntPin()==0) //如果有中断发生
  {
   D12WriteCommand(READ_INTERRUPT_REGISTER);  //写读中断寄存器的命令
   InterruptSource=D12ReadByte(); //读回第一字节的中断寄存器
   if(InterruptSource&0x80)UsbBusSuspend(); //总线挂起中断处理
   if(InterruptSource&0x40)UsbBusReset();   //总线复位中断处理
   if(InterruptSource&0x01)UsbEp0Out();     //端点0输出中断处理
   if(InterruptSource&0x02)UsbEp0In();      //端点0输入中断处理
   if(InterruptSource&0x04)UsbEp1Out();     //端点1输出中断处理
   if(InterruptSource&0x08)UsbEp1In();      //端点1输入中断处理
   if(InterruptSource&0x10)UsbEp2Out();     //端点2输出中断处理
   if(InterruptSource&0x20)UsbEp2In();      //端点2输入中断处理
  }
}
```
### 1.2 Device设备端日志
#### 1.2.1 SETUP数据包，获取设备描述符
```text
USB端点0输出中断。					// host端带返回值的请求，device需要知道输出什么，所以先读8字节
读端点0缓冲区8字节。
0x80 0x06 0x00 0x01 0x00 0x00 0x40 0x00 
USB标准输入请求：获取描述符——设备描述符。	// 设备描述符有18个字节
写端点0缓冲区16字节。				// PDIUSBD12的端点0大小的16字节
0x12 0x01 0x10 0x01 0x00 0x00 0x00 0x10 0x88 0x88 0x01 0x00 0x00 0x01 0x01 0x02 
USB端点0输入中断。
写端点0缓冲区2字节。					// 发送剩余的2个字节
0x03 0x01 
```

日志显示已经成功接收到主机发送过来的8字节数据。在第一次接收到数据后，会停顿一段时间。这段时间主机一直在请求输入。
但是目前还没有返回数据，所以D12一直在回答NAK，即没有数据准备好。结果USB主机经过一段时间的等待之后，终于不耐烦了，
发送了一次总线复位，然后又重新输出这8个字节的数据，然后又是等待输入数据。尝试几次后主机只好无奈的放弃了。
这是改USB端口上不再有数据活动，从而D12进入了挂起状态。同时在计算机端弹出无法识别的USB设备对话框。

主机端内核日志：

    [ 9536.933549] usb 2-1: new full-speed USB device number 16 using ci_hdrc
    [ 9542.053622] usb 2-1: device descriptor read/64, error -110
    
    #define ETIMEDOUT       110     /* Connection timed out */

#### 1.2.2 设置地址
```text
USB总线复位。
USB端点0输出中断。
读端点0缓冲区8字节。
0x00 0x05 0x06 0x00 0x00 0x00 0x00 0x00 
USB标准输出请求：设置地址。地址为：0x06 
写端点0缓冲区0字节。
USB端点0输入中断。
```

#### 1.2.3 SETUP数据包，基于新地址，重新获取设备描述符
```text
USB端点0输出中断。
读端点0缓冲区8字节。
0x80 0x06 0x00 0x01 0x00 0x00 0x12 0x00 
USB标准输入请求：获取描述符——设备描述符。
写端点0缓冲区16字节。
0x12 0x01 0x10 0x01 0x00 0x00 0x00 0x10 0x88 0x88 0x01 0x00 0x00 0x01 0x01 0x02 
USB端点0输入中断。
写端点0缓冲区2字节。
0x03 0x01 
```
### 二、描述符
### 2.1 各描述符之间的关系
	设备描述符（Device Descriptor）
		配置描述符（Configuration Descriptor）
			接口描述符（Interface Descriptor）
				HID描述符（HID Device Descriptor）
					报告描述符（Report Descriptor）

一个设备描述符可以包含多个配置描述符，通常1个
一个配置描述符可以包含多个接口描述符。
一个接口描述符可以包含多个端点描述符。

接口描述符跟着配置描述符走的，无法单独存在。

### 2.2 各描述符简介：
#### 2.2.1 设备描述符（Device Descriptor）
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

```C
//USB设备描述符的定义
code uint8 DeviceDescriptor[]=  //设备描述符为18字节
{
//bLength字段。设备描述符的长度为18(0x12)字节
 0x12,

//bDescriptorType字段。设备描述符的编号为0x01
 0x01,

//bcdUSB字段。这里设置版本为USB1.1，即0x0110。
//由于是小端结构，所以低字节在先，即0x10，0x01。
 0x10,
 0x01,

//bDeviceClass字段。我们不在设备描述符中定义设备类，
//而在接口描述符中定义设备类，所以该字段的值为0。
 0x00,

//bDeviceSubClass字段。bDeviceClass字段为0时，该字段也为0。
 0x00,

//bDeviceProtocol字段。bDeviceClass字段为0时，该字段也为0。
 0x00,

//bMaxPacketSize0字段。PDIUSBD12的端点0大小的16字节。
 0x10,

//idVender字段。厂商ID号，我们这里取0x8888，仅供实验用。
//实际产品不能随便使用厂商ID号，必须跟USB协会申请厂商ID号。
//注意小端模式，低字节在先。
 0x88,
 0x88,

//idProduct字段。产品ID号，由于是第一个实验，我们这里取0x0001。
//注意小端模式，低字节应该在前。
 0x01,
 0x00,

//bcdDevice字段。我们这个USB鼠标刚开始做，就叫它1.0版吧，即0x0100。
//小端模式，低字节在先。
 0x00,
 0x01,

//iManufacturer字段。厂商字符串的索引值，为了方便记忆和管理，
//字符串索引就从1开始吧。
 0x01,

//iProduct字段。产品字符串的索引值。刚刚用了1，这里就取2吧。
//注意字符串索引值不要使用相同的值。
 0x02,

//iSerialNumber字段。设备的序列号字符串索引值。
//这里取3就可以了。
 0x03,

//bNumConfigurations字段。该设备所具有的配置数。
//我们只需要一种配置就行了，因此该值设置为1。
 0x01
};
```
#### 2.2.2 配置描述符（Configuration Descriptor）- 接口描述符（Interface Descriptor） - HID描述符（HID Device Descriptor）
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
	  
	Report Descriptor: (length is 52)
	  略

```C
//USB配置描述符集合的定义
//配置描述符总长度为9+9+9+7字节
code uint8 ConfigurationDescriptor[9+9+9+7]=
{
 /***************配置描述符***********************/
 //bLength字段。配置描述符的长度为9字节。
 0x09,
 
 //bDescriptorType字段。配置描述符编号为0x02。
 0x02,
 
 //wTotalLength字段。配置描述符集合的总长度，
 //包括配置描述符本身、接口描述符、类描述符、端点描述符等。
 sizeof(ConfigurationDescriptor)&0xFF, //低字节
 (sizeof(ConfigurationDescriptor)>>8)&0xFF, //高字节
 
 //bNumInterfaces字段。该配置包含的接口数，只有一个接口。
 0x01,
 
 //bConfiguration字段。该配置的值为1。
 0x01,
 
 //iConfigurationz字段，该配置的字符串索引。这里没有，为0。
 0x00,
 
 //bmAttributes字段，该设备的属性。由于我们的板子是总线供电的，
 //并且我们不想实现远程唤醒的功能，所以该字段的值为0x80。
 0x80,
 
 //bMaxPower字段，该设备需要的最大电流量。由于我们的板子
 //需要的电流不到100mA，因此我们这里设置为100mA。由于每单位
 //电流为2mA，所以这里设置为50(0x32)。
 0x32,
 
 /*******************接口描述符*********************/
 //bLength字段。接口描述符的长度为9字节。
 0x09,
 
 //bDescriptorType字段。接口描述符的编号为0x04。
 0x04,
 
 //bInterfaceNumber字段。该接口的编号，第一个接口，编号为0。
 0x00,
 
 //bAlternateSetting字段。该接口的备用编号，为0。
 0x00,
 
 //bNumEndpoints字段。非0端点的数目。由于USB鼠标只需要一个
 //中断输入端点，因此该值为1。
 0x01,
 
 //bInterfaceClass字段。该接口所使用的类。USB鼠标是HID类，
 //HID类的编码为0x03。
 0x03,
 
 //bInterfaceSubClass字段。该接口所使用的子类。在HID1.1协议中，
 //只规定了一种子类：支持BIOS引导启动的子类。
 //USB键盘、鼠标属于该子类，子类代码为0x01。
 0x01,
 
 //bInterfaceProtocol字段。如果子类为支持引导启动的子类，
 //则协议可选择鼠标和键盘。键盘代码为0x01，鼠标代码为0x02。
 0x02,
 
 //iConfiguration字段。该接口的字符串索引值。这里没有，为0。
 0x00,
 
 /******************HID描述符************************/
 //bLength字段。本HID描述符下只有一个下级描述符。所以长度为9字节。
 0x09,
 
 //bDescriptorType字段。HID描述符的编号为0x21。
 0x21,
 
 //bcdHID字段。本协议使用的HID1.1协议。注意低字节在先。
 0x10,
 0x01,
 
 //bCountyCode字段。设备适用的国家代码，这里选择为美国，代码0x21。
 0x21,
 
 //bNumDescriptors字段。下级描述符的数目。我们只有一个报告描述符。
 0x01,
 
 //bDescritporType字段。下级描述符的类型，为报告描述符，编号为0x22。
 0x22,
 
 //bDescriptorLength字段。下级描述符的长度。下级描述符为报告描述符。
 sizeof(ReportDescriptor)&0xFF,
 (sizeof(ReportDescriptor)>>8)&0xFF,
 
 /**********************端点描述符***********************/
 //bLength字段。端点描述符长度为7字节。
 0x07,
 
 //bDescriptorType字段。端点描述符编号为0x05。
 0x05,
 
 //bEndpointAddress字段。端点的地址。我们使用D12的输入端点1。
 //D7位表示数据方向，输入端点D7为1。所以输入端点1的地址为0x81。
 0x81,
 
 //bmAttributes字段。D1~D0为端点传输类型选择。
 //该端点为中断端点。中断端点的编号为3。其它位保留为0。
 0x03,
 
 //wMaxPacketSize字段。该端点的最大包长。端点1的最大包长为16字节。
 //注意低字节在先。
 0x10,
 0x00,
 
 //bInterval字段。端点查询的时间，我们设置为10个帧时间，即10ms。
 0x0A
};
```
#### 2.2.3 报告描述符（Report Descriptor）
```C
//USB报告描述符的定义
code uint8 ReportDescriptor[]=
{
 //每行开始的第一字节为该条目的前缀，前缀的格式为：
 //D7~D4：bTag。D3~D2：bType；D1~D0：bSize。以下分别对每个条目注释。
 
 //这是一个全局（bType为1）条目，选择用途页为普通桌面Generic Desktop Page(0x01)
 //后面跟一字节数据（bSize为1），后面的字节数就不注释了，
 //自己根据bSize来判断。
 0x05, 0x01, // USAGE_PAGE (Generic Desktop)
 
 //这是一个局部（bType为2）条目，说明接下来的应用集合用途用于鼠标
 0x09, 0x02, // USAGE (Mouse)
 
 //这是一个主条目（bType为0）条目，开集合，后面跟的数据0x01表示
 //该集合是一个应用集合。它的性质在前面由用途页和用途定义为
 //普通桌面用的鼠标。
 0xa1, 0x01, // COLLECTION (Application)
 
 //这是一个局部条目。说明用途为指针集合
 0x09, 0x01, //   USAGE (Pointer)
 
 //这是一个主条目，开集合，后面跟的数据0x00表示该集合是一个
 //物理集合，用途由前面的局部条目定义为指针集合。
 0xa1, 0x00, //   COLLECTION (Physical)
 
 //这是一个全局条目，选择用途页为按键（Button Page(0x09)）
 0x05, 0x09, //     USAGE_PAGE (Button)
 
 //这是一个局部条目，说明用途的最小值为1。实际上是鼠标左键。
 0x19, 0x01, //     USAGE_MINIMUM (Button 1)
 
 //这是一个局部条目，说明用途的最大值为3。实际上是鼠标中键。
 0x29, 0x03, //     USAGE_MAXIMUM (Button 3)
 
 //这是一个全局条目，说明返回的数据的逻辑值（就是我们返回的数据域的值啦）
 //最小为0。因为我们这里用Bit来表示一个数据域，因此最小为0，最大为1。
 0x15, 0x00, //     LOGICAL_MINIMUM (0)
 
 //这是一个全局条目，说明逻辑值最大为1。
 0x25, 0x01, //     LOGICAL_MAXIMUM (1)
 
 //这是一个全局条目，说明数据域的数量为三个。
 0x95, 0x03, //     REPORT_COUNT (3)
 
 //这是一个全局条目，说明每个数据域的长度为1个bit。
 0x75, 0x01, //     REPORT_SIZE (1)
 
 //这是一个主条目，说明有3个长度为1bit的数据域（数量和长度
 //由前面的两个全局条目所定义）用来做为输入，
 //属性为：Data,Var,Abs。Data表示这些数据可以变动，Var表示
 //这些数据域是独立的，每个域表示一个意思。Abs表示绝对值。
 //这样定义的结果就是，第一个数据域bit0表示按键1（左键）是否按下，
 //第二个数据域bit1表示按键2（右键）是否按下，第三个数据域bit2表示
 //按键3（中键）是否按下。
 0x81, 0x02, //     INPUT (Data,Var,Abs)
 
 //这是一个全局条目，说明数据域数量为1个
 0x95, 0x01, //     REPORT_COUNT (1)
 
 //这是一个全局条目，说明每个数据域的长度为5bit。
 0x75, 0x05, //     REPORT_SIZE (5)
 
 //这是一个主条目，输入用，由前面两个全局条目可知，长度为5bit，
 //数量为1个。它的属性为常量（即返回的数据一直是0）。
 //这个只是为了凑齐一个字节（前面用了3个bit）而填充的一些数据
 //而已，所以它是没有实际用途的。
 0x81, 0x03, //     INPUT (Cnst,Var,Abs)
 
 //这是一个全局条目，选择用途页为普通桌面Generic Desktop Page(0x01)
 0x05, 0x01, //     USAGE_PAGE (Generic Desktop)
 
 //这是一个局部条目，说明用途为X轴
 0x09, 0x30, //     USAGE (X)
 
 //这是一个局部条目，说明用途为Y轴
 0x09, 0x31, //     USAGE (Y)
 
 //这是一个局部条目，说明用途为滚轮
 0x09, 0x38, //     USAGE (Wheel)
 
 //下面两个为全局条目，说明返回的逻辑最小和最大值。
 //因为鼠标指针移动时，通常是用相对值来表示的，
 //相对值的意思就是，当指针移动时，只发送移动量。
 //往右移动时，X值为正；往下移动时，Y值为正。
 //对于滚轮，当滚轮往上滚时，值为正。
 0x15, 0x81, //     LOGICAL_MINIMUM (-127)
 0x25, 0x7f, //     LOGICAL_MAXIMUM (127)
 
 //这是一个全局条目，说明数据域的长度为8bit。
 0x75, 0x08, //     REPORT_SIZE (8)
 
 //这是一个全局条目，说明数据域的个数为3个。
 0x95, 0x03, //     REPORT_COUNT (3)
 
 //这是一个主条目。它说明这三个8bit的数据域是输入用的，
 //属性为：Data,Var,Rel。Data说明数据是可以变的，Var说明
 //这些数据域是独立的，即第一个8bit表示X轴，第二个8bit表示
 //Y轴，第三个8bit表示滚轮。Rel表示这些值是相对值。
 0x81, 0x06, //     INPUT (Data,Var,Rel)
 
 //下面这两个主条目用来关闭前面的集合用。
 //我们开了两个集合，所以要关两次。bSize为0，所以后面没数据。
 0xc0,       //   END_COLLECTION
 0xc0        // END_COLLECTION
};
//通过上面的报告描述符的定义，我们知道返回的输入报告具有4字节。
//第一字节的低3位用来表示按键是否按下的，高5位为常数0，无用。
//第二字节表示X轴改的变量，第三字节表示Y轴的改变量，第四字节表示
//滚轮的改变量。我们在中断端点1中应该要按照上面的格式返回实际的
//鼠标数据。
```

## 三、QA
**Q:lsusb获取Report Descriptor异常**
A:Report Descriptors: 
	** UNAVAILABLE **

获取Report Descriptors
http://www.slashdev.ca/2010/05/08/get-usb-report-descriptor-with-linux/