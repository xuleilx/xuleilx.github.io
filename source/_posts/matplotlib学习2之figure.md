---
title: matplotlib学习2之figure
date: 2017-12-24 12:17:26
tags: matplotlib
---
代码：
```
# -*- coding: utf-8 -*-
import matplotlib.pyplot as plt
import numpy as np

# 产生数据
x = np.linspace(-3,3,50)

#绘制直线
y1 = x + 1

#绘制曲线
y2 = x**2

# figure 3，指定figure的编号并指定figure的大小
plt.figure(num=3,figsize=(8,5))
plt.plot(x,y1)

plt.figure("f2")
plt.plot(x,y2)
# 指定线的颜色, 宽度和类型
plt.plot(x,y1,color='red',linewidth=5.0,linestyle='--')

#显示
plt.show()

```
结果：
![image](https://xuleilx.github.io/images/figure3.png)
![image](https://xuleilx.github.io/images/figure2.png)

