---
title: 关于Pop音解决方案
date: 2020-11-27 00:53:26
tags: Media
categories:
 - 经验分享
---

## 现象分析

先来看一个典型的爆音音频示例，播放一个1k hz的正玄波，由于播放的正弦波的起始点不是0开始的完整的正弦波，第一个音频frame跳变。

![img](https://xuleilx.github.io/images/pop1.png)

由于幅度跳变，过渡不连续，造成爆音，从频谱图来看这条竖直的亮线处，就是产生爆音的位置

![img](https://xuleilx.github.io/images/pop2.png)


## 数据源线性变换

针对数据源，做梯度上升

![img](https://xuleilx.github.io/images/pop3.png)

频谱来看，爆破音减弱了很多。

300ms线性变化的频谱

![img](https://xuleilx.github.io/images/pop4.png)

500ms线性变化的频谱

![img](https://xuleilx.github.io/images/pop5.png)

线性变换的梯度越缓，消除pop音的效果越好，不过实际测下来10ms的渐变就可以达到比较良好的水平。当然网上有更为优秀的算法，可以实现完全消除的。

 

## 伪代码
![img](https://xuleilx.github.io/images/pop6.png)

 

## 参考实现

首先我们得弄清楚buffer/period/frame/sample之间的关系，下面一张图直观的表示buffer/period/frame/sample之间的关系：
![img](https://xuleilx.github.io/images/pop7.png)

对于底层来说是以frame为单位进行播放的，所以我们应该以frame为单位，针对的sample做线性变换。以下是渐入的代码参考实现：
![image-20201127164449858](https://xuleilx.github.io/images/pop8.png)
