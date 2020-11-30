---
title: i.Max6移植Movidius
date: 2019-01-14 20:26:31
tags: 机器学习
---
0、概述
========
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;时隔半年有余，由于工作的原因没能更新机器学习方面的内容。
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;之间林林总总，看完了《UNIX网络编程卷1：套接字联网API（第3版）》，《Linux多线程服务端编程：使用muduo C++网络库》和《Netty权威指南》的部分章节，完成了Tbox Telemetics模块的设计和编码，在这之前其实已对网络编程有所了解，也尝试用MFC编写过类QQ的sample，只是功能简单，单客户端/单服务端之间的通信，然真正用于网络通信的协议未曾染指。网络编程方面的知识，在这次的开发工作中得以锻炼，略有心得一二。
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;更换项目的间隙，中间有空闲二周，正直双十一，遂购架构书籍数本，看完《架构整洁之道》开始对于软件架构有了进一步的了解，科室读书会分享之，感觉功力倍增。
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;新年交替之际，开始AI实验室的预研，主要针对边缘计算，驾驶行为分析。嵌入式的硬件限制，只能外挂计算棒，开始研究Intel的Movidius，接触到了OpenVINO工具套件。本篇主要就是介绍一下NCS2在树莓派上的移植。

1、环境搭建
=========
1. 树莓派。系统Raspbian* 9 OS，官网[下载](https://www.raspberrypi.org/downloads/raspbian/)最新版本即可。
2. The Intel™ Distribution of OpenVINO™ for Raspbian OS package to download is [here](https://download.01.org/openvinotoolkit/2018_R5/packages/l_openvino_toolkit_ie_p_2018.5.445.tgz) and the Installation document [here](https://software.intel.com/en-us/articles/OpenVINO-Install-RaspberryPI).

2、步骤
=======
Introduction
------------------
This guide applies to 32-bit Raspbian* 9 OS, which is an official OS for Raspberry Pi* boards.

>IMPORTANT:
>- All steps in this guide are required unless otherwise stated.
>- The Intel® Distribution of OpenVINO™ toolkit for Raspbian* OS includes the MYRIAD plugin >only. You can use it with the Intel® Movidius™ Neural Compute Stick (Intel® NCS) or the Intel® >Neural Compute Stick 2 plugged in one of USB ports.

###About the Intel® Distribution of OpenVINO™ Toolkit
The Intel® Distribution of OpenVINO™ toolkit quickly deploys applications and solutions that emulate human vision. Based on Convolutional Neural Networks (CNN), the toolkit extends computer vision (CV) workloads across Intel® hardware, maximizing performance. The Intel Distribution of OpenVINO toolkit includes the Intel® Deep Learning Deployment Toolkit (Intel® DLDT).

###Included in the Installation Package
The Intel Distribution of OpenVINO toolkit for Raspbian OS is an archive with pre-installed header files and libraries. The following components are installed by default:

| Component           | Description                              |
| :------------------ | :--------------------------------------- |
| Inference Engine    | This is the engine that runs the deep learning model. It includes a set of libraries for an easy inference integration into your applications. |
| OpenCV* version 4.0 | OpenCV* community version compiled for Intel® hardware. |
| Sample Applications | A set of simple console applications demonstrating how to use the Inference Engine in your applications. |
###System Requirements
###Hardware:

Raspberry Pi* board with ARMv7-A CPU architecture
One of Intel® Movidius™ Visual Processing Units (VPU):
Intel® Movidius™ Neural Compute Stick
Intel® Neural Compute Stick 2
###Operating Systems:

Raspbian* Stretch, 32-bit

Install the Package
------------
Open the Terminal* or your preferred console application.
Go to the directory in which you downloaded the Intel Distribution of OpenVINO toolkit. This document assumes this is your ~/Downloads directory. If not, replace ~/Downloads with the directory where the file is located.
>cd ~/Downloads/

By default, the package file is saved as l_openvino_toolkit_ie_p_<version>.tgz.
Unpack the archive:
>tar -xf l_openvino_toolkit_ie_p_<version>.tgz

Modify the setupvars.sh script by replacing <INSTALLDIR> with the absolute path to the installation folder:
>sed -i "s|<INSTALLDIR>|$(pwd)/inference_engine_vpu_arm|" 

inference_engine_vpu_arm/bin/setupvars.sh
Now the Intel Distribution of OpenVINO toolkit is ready to be used. Continue to the next sections to configure the environment and set up USB rules.

Set the Environment Variables
------------
You must update several environment variables before you can compile and run Intel Distribution of OpenVINO toolkit applications. Run the following script to temporarily set the environment variables:

>source inference_engine_vpu_arm/bin/setupvars.sh

(Optional) The Intel Distribution of OpenVINO environment variables are removed when you close the shell. As an option, you can permanently set the environment variables as follows:

Open the .bashrc file in <user_directory>:
>vi <user_directory>/.bashrc

Add this line to the end of the file:
>source ~/Downloads/inference_engine_vpu_arm/bin/setupvars.sh

Save and close the file: press Esc and type :wq.
To test your change, open a new terminal.
You will see the following:
>[setupvars.sh] OpenVINO environment initialized

Add USB Rules
------------
Add the current Linux user to the users group:
>sudo usermod -a -G users "$(whoami)"

Log out and log in for it to take effect.

To perform inference on the Intel® Movidius™ Neural Compute Stick or Intel® Neural Compute Stick 2, install the USB rules as follows:
>sh inference_engine_vpu_arm/install_dependencies/install_NCS_udev_rules.sh

Build and Run Object Detection Sample
--------------
Follow the next steps to run pre-trained Face Detection network using samples from Intel Distribution of OpenVINO toolkit:

Go to the folder with samples source code:
>cd inference_engine_vpu_arm/deployment_tools/inference_engine/samples

Create build directory:
>mkdir build && cd build

Build the Object Detection Sample:
>cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_FLAGS="-march=armv7-a"
>make -j2 object_detection_sample_ssd

Download the pre-trained Face Detection model or copy it from a host machine:
To download the .bin file with weights:
>wget --no-check-certificate https://download.01.org/openvinotoolkit/2018_R4/open_model_zoo/face-detection-adas-0001/FP16/face-detection-adas-0001.bin

To download the .xml file with the network topology:
>wget --no-check-certificate https://download.01.org/openvinotoolkit/2018_R4/open_model_zoo/face-detection-adas-0001/FP16/face-detection-adas-0001.xml

Run the sample with specified path to the model:
Copy Code
>./armv7l/Release/object_detection_sample_ssd -m face-detection-adas-0001.xml -d MYRIAD -i <path_to_image>

Run Face Detection Model Using OpenCV* API
--------------
To validate OpenCV* installation, you may try to run OpenCV's deep learning module with Inference Engine backend. Here is a Python* sample, which works with Face Detection model:

Download the pre-trained Face Detection model or copy it from a host machine:
To download the .bin file with weights:
>wget --no-check-certificate https://download.01.org/openvinotoolkit/2018_R4/open_model_zoo/face-detection-adas-0001/FP16/face-detection-adas-0001.bin

To download the .xml file with the network topology:
>wget --no-check-certificate https://download.01.org/openvinotoolkit/2018_R4/open_model_zoo/face-detection-adas-0001/FP16/face-detection-adas-0001.xml

Create a new Python file named as openvino_fd_myriad.py and copy the following script there:
```python
import cv2 as cv

# Load the model 
net = cv.dnn.readNet('face-detection-adas-0001.xml', 'face-detection-adas-0001.bin') 

# Specify target device 
net.setPreferableTarget(cv.dnn.DNN_TARGET_MYRIAD)
      
# Read an image 
frame = cv.imread('/path/to/image')
      
# Prepare input blob and perform an inference 
blob = cv.dnn.blobFromImage(frame, size=(672, 384), ddepth=cv.CV_8U) net.setInput(blob) 
out = net.forward()
      
# Draw detected faces on the frame 
for detection in out.reshape(-1, 7): 
    confidence = float(detection[2]) 
    xmin = int(detection[3] * frame.shape[1]) 
    ymin = int(detection[4] * frame.shape[0]) 
    xmax = int(detection[5] * frame.shape[1]) 
    ymax = int(detection[6] * frame.shape[0])

    if confidence > 0.5:
        cv.rectangle(frame, (xmin, ymin), (xmax, ymax), color=(0, 255, 0))

# Save the frame to an image file 
cv.imwrite('out.png', frame) 
```
Run the script:
>python3 openvino_fd_myriad.py

In this script, OpenCV* loads the Face Detection model in the Intermediate Representation (IR) format and an image. Then it runs the model and saves an image with detected faces.

3、i.Max6移植
======
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;理论上树莓派上编译的产物可以直接拷贝到相同处理器架构的i.Max6上(CPU都是ARMv7)，不过由于各个公司BSP对内核裁剪和集成编译的时候包含的软件包不同，需要修改的内容也不尽相同。这里写的是本司的开发板环境缺少的依赖：

>- python3
>- lsb_release
>- libstdc++  -> 3.4.22
>- vi inference_engine_vpu_arm/install_dependencies/install_NCS_udev_rules.sh
>  :%s/sudo//g  #删除所有的sudo
>- touch /etc/ld.so.conf


4、总结
======
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;初步了解OpenVINO发现其是一大宝藏，里面包含了几十种流行模型的，并且有大量sample可以参考学习，可以通过组合各个模型实现自己想要的功能。增加对机器学习的实战经验，加深对机器学习的理解。遗憾的是Intel的NCS2目前貌似只支持深度学习的预测，之于一般的机器学习模型是否也支持，有待考证。