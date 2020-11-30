---
title: matplotlib学习14之次坐标轴
date: 2017-12-28 21:56:52
tags: matplotlib
---
代码：
```python
# -*- coding: utf-8 -*-
import matplotlib.pyplot as plt
import numpy as np

x = np.arange(0,10,0.1)
y1 = 0.05*x**2
y2 = -1*y1

# 获取figure默认的坐标系 ax1
# fig,ax1 = plt.subplots()
ax1 = plt.subplot()
# 对ax1调用twinx()方法，生成如同镜面效果后的ax2
ax2 = ax1.twinx()
ax1.plot(x,y1,'g-')
ax2.plot(x,y2,'b--')

ax1.set_xlabel('X data')
ax1.set_ylabel('Y1',color='g')
ax2.set_ylabel('Y2',color='b')

plt.savefig("/home/xuleilx/workspace/github/github_pages/public/images/subaxes.png")
plt.show()
```
结果：
![subaxes](https://xuleilx.github.io/images/subaxes.png)