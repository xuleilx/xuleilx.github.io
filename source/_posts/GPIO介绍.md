---
title: GPIO介绍
date: 2022-03-06 16:14:32
tags:
  - 设备驱动
---

# GPIO基本结构和工作方式
## 工作方式
### 4种输入模式
1. 输入浮空
2. 输入上拉
3. 输入下拉
4. 模拟输入
### 4种输出模式
1. 开漏输出
2. 开漏复用
3. 推挽输出
4. 推挽复用
### 3种翻转速度
1. 2MHz
2. 10MHz
3. 50MHz
## GPIO硬件原理图
![image-20220306142017899](/home/alex/.config/Typora/typora-user-images/image-20220306142017899.png)

选用IO模式：

1. 浮空输入_IN_FLOATING -- 可以做KEY识别，RX1
2. 上拉输入_IPU -- IO内部上拉电阻输入
3. 下拉输入_IPD -- IO内部下拉电阻输入
4. 模拟输入_AIN -- 应用ADC模拟输入，或者低功耗下省电
5. 开漏输出_OUT_OD -- IO输出0接GND，IO输出1，悬空，需要外接上拉电阻，才能实现输出高电平。当输出为1时，IO口的状态由上拉电阻拉高电平，但由于是开漏输出模式，这样IO口也就可以由外部电路改变为低电平或不变。可以读IO输入电平变化，实现C51的IO双向功能
6. 推挽输出_OUT_PP -- IO输出0，接GND；IO输出1，接VCC，读输入值是未知的
7. 复用功能的推挽输出_AF_PP -- 片内外设功能(I2c的SCL，SDA)
8. 复用功能的开漏输出_AF_OD -- 片内外设功能(TX1,MOSI,MISO,SCK,SS)

# GPIO寄存器说明

- 两个32位配置寄存器(GPIOx_CRL，GPIOx_CRH)
- 两个32位数据寄存器(GPIOx_IDR和GPIOx_ODR)
- 一个32位置位/复位寄存器(GPIOx_BSRR)
- 一个16位复位寄存器(GPIOx_BRR)
- 一个32位锁定寄存器(GPIOx_LCKR)

# GPIO初始化时序
1. GPIO时钟设置。RCC寄存器
1. 设置GPIO通用输出模式。MODER寄存器
1. 设置GPIO为推挽模式。OTYPER寄存器
1. 设置GPIO位高速。OSPEEDR寄存器
1. 设置GPIO位上拉。PUPDR寄存器
1. 设置/清除寄存器。BSRR寄存器
