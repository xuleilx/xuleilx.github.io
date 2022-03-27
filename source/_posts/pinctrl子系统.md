---
title: pinctrl子系统
date: 2022-03-12 11:09:23
tags:
  - 设备驱动
---
# pinctrl介绍

# pinctrl主要工作
pinctrl 子系统主要工作内容如下：

1. 获取设备树中 pin 信息。
2. 根据获取到的 pin 信息来设置 pin 的复用功能
3. 根据获取到的 pin 信息来设置 pin 的电气特性，比如上/下拉、速度、驱动能力等。

对于我们使用者来讲，只需要在设备树里面设置好某个 pin 的相关属性即可，其他的初始化工作均由 pinctrl 子系统来完成， pinctrl 子系统源码目录为 drivers/pinctrl。

# pinctrl工作详细
## 设备树
```dts
pinctrl: pin-controller@50002000 {
  #address-cells = <1>;
  #size-cells = <1>;
  compatible = "st,stm32mp157-pinctrl";
  ranges = <0 0x50002000 0xa400>;
  interrupt-parent = <&exti>;
  st,syscfg = <&exti 0x60 0xff>;
  hwlocks = <&hsem 0 1>;
  pins-are-numbered;
  ...
};
```

pinctrl 驱动流程如下：
1、 定义 pinctrl_desc 结构体。
2、 初始化结构体， 重点是 pinconf_ops、 pinmux_ops 和 pinctrl_ops 这三个结构体成员变量，但是这部分半导体厂商帮我们搞定。
3、 调用 devm_pinctrl_register 函数完成 PIN 控制器注册。

# pinctrl和gpio
定义
pinctrl
  ->gpiog
  ->sdmmc1_b4_pins_a
使用
sdmmc1
  -> pinctrl-0 
    ->sdmmc1_b4_pins_a
  -> cd-gpios
    -> gpiog