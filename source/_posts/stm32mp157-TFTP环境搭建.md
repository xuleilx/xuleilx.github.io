---
title: stm32mp157-TFTP环境搭建
date: 2022-02-11 11:23:46
tags: stm32mp157
categories:
 - 设备驱动
---

# 目的
嵌入式开发，免不了需要修改kernel代码和设备树。如果每次更新都要重新烧录，既费时又费力。通常我们不需要修改uboot的代码，可以让uboot通过tftp下载我们的kernel和设备树到指定的地址然后启动Linux。
# 开发板网络环境搭建
## 准备工作
1. 电脑
2. 开发板
3. 网线
4. USB转网口
## 网络拓扑结构
![网络拓扑结构](https://xuleilx.github.io/images/TFTP环境搭建-网络拓扑结构.png)
## VMWare设置
USB转网口设备的连接状态，让设备连接到虚拟机
# TFTP 环境搭建
## TFTP 简介
TFTP（Trivial File Transfer Protocol,简单文件传输协议）是 TCP/IP 协议族中的一个用来在客户机与服务器之间进行简单文件传输的协议，提供不复杂、开销不大的文件传输服务。我们可以使用 TFTP 来加载内核 zImage、设备树和其他较小的文件到开发板 DDR 上，从而实现网络挂载。
## 搭建 TFTP
### 安装和配置 xinetd
执行以下指令，安装 xinetd。
```shell
$ sudo apt-get install xinetd
$ sudo vi /etc/xinetd.conf
$ cat /etc/xinetd.conf

# Simple configuration file for xinetd
#
# Some defaults, and include /etc/xinetd.d/

defaults
{

# Please note that you need a log_type line to be able to use log_on_success
# and log_on_failure. The default is the following :
# log_type = SYSLOG daemon info

}

includedir /etc/xinetd.d

```
### TFTP 目录
```shell
$ mkdir -p /home/alex/linux/tftpboot
#$ chmod 777 /home/alex/study/stm32mp157/tftpboot
$ cd /home/alex/linux/
```
### tftp-hpa 和 tftpd-hpa 服务程序
```shell
$ sudo apt-get install tftp-hpa tftpd-hpa
$ sudo vi /etc/default/tftpd-hpa
$ cat /etc/default/tftpd-hpa
# /etc/default/tftpd-hpa

TFTP_USERNAME="tftp"
TFTP_DIRECTORY="/home/alex/study/stm32mp157/tftpboot"
TFTP_ADDRESS=":69"
TFTP_OPTIONS="--secure"
$ sudo vi /etc/xinetd.d/tftp -p
$ cat /etc/xinetd.d/tftp

service tftp
{
protocol = udp
port = 69
socket_type = dgram
wait = yes
user = root
server = /usr/sbin/in.tftpd
server_args = -s /home/alex/study/stm32mp157/tftpboot -c
disable = no
per_source = 11
cps =100 2
flags =IPv4
}

$ sudo service tftpd-hpa restart
$ sudo service xinetd restart
```
### 网络环境
    确保网络环境正常， Ubuntu和开发板能相互 ping 通。
    开发板 IP： 192.168.10.50
    虚拟机 IP： 192.168.10.100
    电脑网口的 IP： 192.168.10.200
### TFTP 测试
在开发板文件系统执行以下指令设置开发板 IP，将虚拟机（192.168.10.100） TFTP 工作目录下的 test.c 文件拷贝到开发板中。
```shell
ifconfig eth0 192.168.10.50
tftp -g -r test.c 192.168.10.100
cat test.c
```
## TFTP 挂载内核和设备树
启动开发板，进入 uboot 命令行界面，设置网络相关信息。 这里笔者 Ubuntu 的 IP 是
192.168.1.208，给开发板设置的 IP 是 192.168.1.250，使用的是交换机连接开发板和电脑。
```shell
setenv ipaddr 192.168.1.250
setenv ethaddr 00:04:9f:04:d2:35
setenv gatewayip 192.168.1.1
setenv netmask 255.255.255.0
setenv serverip 192.168.1.208
saveenv
```
设置完后测试开发板和虚拟机的连接。
```shell
ping 192.168.1.208
```
确保网络正常后，设置 uboot 环境变量来挂载 Ubuntu 里 TFTP 目录下的内核和设备树。
注意 - 符号为英文的，两边各有一个空格。（以下排版中用绿色着重空格，红色着重符号）
```shell
setenv bootcmd 'tftp c2000000 uImage;tftp c4000000 stm32mp157d-atk.dtb;bootm c2000000 - c4000000'
setenv bootargs 'console=ttySTM0,115200 root=/dev/mmcblk2p3 rootwait rw'
saveenv
boot
```
Uboot恢复默认设置
```shell
env default -a
saveenv
```