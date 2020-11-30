---
title: matplotlib学习1之直线曲线
date: 2017-12-24 10:34:56
tags: matplotlib
---

代码：

```
# -*- coding: utf-8 -*-
import matplotlib.pyplot as plt
import numpy as np

# 产生数据
x = np.linspace(-1,1,50)

#绘制直线
y = x + 1
plt.plot(x,y)

#绘制曲线
y = x**2
plt.plot(x,y)

#显示
plt.show()

```

显示结果：
![image](https://xuleilx.github.io/images/line_1.png)
