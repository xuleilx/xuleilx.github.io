---
title: OTG_roleswitch
date: 2020-11-26 23:15:39
tags: USB
---

# OTG roleswitch(Apple CarPlay)
## 关于roleswitch驱动层状态机变化流程
### 插入时的状态
1. 车机作为 a_host
2. 手机作为 b_peripheral
3. 车机枚举手机，完成正常的USB枚举。

### roleswitch时的状态
1. 车机发送私有协议（见下图）给手机，通知手机切成 b_host。 

   此时VBUS仍然是车机供电。手机会一直枚举车机。只要车机状态变更到 a_peripheral，就能枚举成功。

2. 车机触发状态机进行状态机变换，最终切到 a_periphera l状态。

3. 手机枚举车机，完成一次正常的USB枚举。

### 拔出后的状态
1. 车机切回 a_wait_bcon 状态。
2. 手机切回 b_wait_acon 状态。

## OTG 状态机转换
### A Device状态机

![A_Device](https://xuleilx.github.io/images/A_Device.png)

### B Device状态机

![B_Device](https://xuleilx.github.io/images/B_Device.png)

## 其他
### 苹果roleswitch私有协议
#### 文档说明
![requestAppleToHost](https://xuleilx.github.io/images/requestAppleToHost.png)
#### ATS 抓包数据
![requestAppleToHost2](https://xuleilx.github.io/images/requestAppleToHost2.jpg)

### 内核状态机日志开关

![内核状态机日志开关](https://xuleilx.github.io/images/内核状态机日志开关.png)

### 一次完整的roleswitch过程日志
```shell
# 插入手机前
[ 2318.493379] Set state: a_wait_bcon
[ 2318.496097] usb 1-1: USB disconnect, device number 12

# 插入手机
[ 2321.151592] Set state: a_host
[ 2321.424758] usb 1-1: new high-speed USB device number 13 using ci_hdrc
[ 2321.578095] usb 1-1: New USB device found, idVendor=05ac, idProduct=12a8
[ 2321.581955] usb 1-1: New USB device strings: Mfr=1, Product=2, SerialNumber=3
[ 2321.593696] usb 1-1: Product: iPhone
[ 2321.594498] usb 1-1: Manufacturer: Apple Inc.
[ 2321.603727] usb 1-1: SerialNumber: 2330bb40ef6c37782d9675fe9d086467f49f031e
[ 2321.610365] usb 1-1: Second configuration choosed for Apple MFi device.
[ 2321.627515] usb 1-1: 1:1: cannot get freq at ep 0x81
[ 2321.650139] hid-generic 0003:05AC:12A8.000C: device has no listeners, quitting

# 触发roleswitch
[ 2348.700349] Set state: a_suspend
[ 2348.700929] usb 1-1: USB disconnect, device number 13                       q
[ 2348.825643] Set state: a_peripherallatform/devices/ci_hdrc.0/inputs/a_bus_req 
[ 2348.826318] ci_hdrc ci_hdrc.0: remove, state 1
[ 2348.830757] usb usb1: USB disconnect, device number 1
[ 2348.847613] ci_hdrc ci_hdrc.0: USB bus 1 deregistered
[ 2348.849891] ci_otg_start_host  off 
[ 2348.853548] ci_otg_start_gadget  on 
[ 2349.038270] g_ncm gadget: high-speed config #1: CDC Ethernet (NCM)
[ 2349.041631] g_ncm gadget: source/sink enabled, alt intf 0
[ 2349.046989] g_ncm gadget: init ncm ctrl 1
[ 2349.050985] g_ncm gadget: notify speed 425984000

# 拔出手机
[ 2867.624758] g_ncm gadget: suspend
[ 2868.123519] Set state: a_wait_bcon
[ 2868.124092] g_ncm gadget: reset config
[ 2868.127819] g_ncm gadget: ncm deactivated
[ 2868.131941] ci_otg_start_gadget  off 
[ 2868.136118] ci_hdrc ci_hdrc.0: EHCI Host Controller
[ 2868.140452] ci_hdrc ci_hdrc.0: new USB bus registered, assigned bus number 1
[ 2868.164755] ci_hdrc ci_hdrc.0: USB 2.0 started, EHCI 1.00
[ 2868.167567] usb usb1: New USB device found, idVendor=1d6b, idProduct=0002
[ 2868.174095] usb usb1: New USB device strings: Mfr=3, Product=2, SerialNumber=1
[ 2868.181399] usb usb1: Product: EHCI Host Controller
[ 2868.186288] usb usb1: Manufacturer: Linux 3.18.41 ehci_hcd
[ 2868.191621] usb usb1: SerialNumber: ci_hdrc.0
[ 2868.198254] hub 1-0:1.0: USB hub found
[ 2868.199797] hub 1-0:1.0: 1 port detected
[ 2868.206021] ci_otg_start_host  on 

```
### 内核各种状态的查询方法
```shell
root@atlas7-arm:/sys/kernel/debug/ci_hdrc.0# cat otg 
OTG state: a_host

a_bus_drop: 0
a_bus_req: 1
a_srp_det: 0
a_vbus_vld: 1
b_conn: 1
adp_change: 0
power_up: 0
a_bus_resume: 0
a_bus_suspend: 0
a_conn: 0
b_bus_req: 0
b_bus_suspend: 0
b_se0_srp: 0
b_ssend_srp: 0
b_sess_vld: 0
b_srp_done: 0
drv_vbus: 1
loc_conn: 0
loc_sof: 1
adp_prb: 0
id: 0
protocol: 1

```
### 内核个节点含义
```text
https://www.kernel.org/doc/Documentation/ABI/testing/sysfs-platform-chipidea-usb-otg

What:		/sys/bus/platform/devices/ci_hdrc.0/inputs/a_bus_req
Date:		Feb 2014
Contact:	Li Jun <jun.li@nxp.com>
Description:
		Can be set and read.
		Set a_bus_req(A-device bus request) input to be 1 if
		the application running on the A-device wants to use the bus,
		and to be 0 when the application no longer wants to use
		the bus(or wants to work as peripheral). a_bus_req can also
		be set to 1 by kernel in response to remote wakeup signaling
		from the B-device, the A-device should decide to resume the bus.

		Valid values are "1" and "0".

		Reading: returns 1 if the application running on the A-device
		is using the bus as host role, otherwise 0.

What:		/sys/bus/platform/devices/ci_hdrc.0/inputs/a_bus_drop
Date:		Feb 2014
Contact:	Li Jun <jun.li@nxp.com>
Description:
		Can be set and read
		The a_bus_drop(A-device bus drop) input is 1 when the
		application running on the A-device wants to power down
		the bus, and is 0 otherwise, When a_bus_drop is 1, then
		the a_bus_req shall be 0.

		Valid values are "1" and "0".

		Reading: returns 1 if the bus is off(vbus is turned off) by
			 A-device, otherwise 0.

What:		/sys/bus/platform/devices/ci_hdrc.0/inputs/b_bus_req
Date:		Feb 2014
Contact:	Li Jun <jun.li@nxp.com>
Description:
		Can be set and read.
		The b_bus_req(B-device bus request) input is 1 during the time
		that the application running on the B-device wants to use the
		bus as host, and is 0 when the application no longer wants to
		work as host and decides to switch back to be peripheral.

		Valid values are "1" and "0".

		Reading: returns if the application running on the B device
		is using the bus as host role, otherwise 0.

What:		/sys/bus/platform/devices/ci_hdrc.0/inputs/a_clr_err
Date:		Feb 2014
Contact:	Li Jun <jun.li@nxp.com>
Description:
		Only can be set.
		The a_clr_err(A-device Vbus error clear) input is used to clear
		vbus error, then A-device will power down the bus.

		Valid value is "1"
```
