---
title: matplotlib学习3之axis
date: 2017-12-24 12:50:16
tags: matplotlib
---
代码：
```python
# -*- coding: utf-8 -*-
import matplotlib.pyplot as plt
import numpy as np

# 产生数据
x = np.linspace(-3,3,50)

#绘制直线
y1 = x + 1

#绘制曲线
y2 = x**2

plt.figure()

# 单纯直线
plt.plot(x,y2)
# 指定线的颜色, 宽度和类型
plt.plot(x,y1,color='red',linewidth=5.0,linestyle='--')

# 设置坐标轴
plt.xlim(-1,2)
plt.ylim(-2,3)

plt.xlabel('I am x')
plt.ylabel('I am y')

new_ticks= np.linspace(-1,2,5)
# 设置坐标的粒度
plt.xticks(new_ticks)
# 用文字代替对应的数值
plt.yticks([-2,-1,0,1,3],
           ['very bad','bad','normal','good','very good'])

#显示
plt.show()
```
输出结果：
![image](https://xuleilx.github.io/images/axis_1.png)
