---
title: matplotlib学习11之3D图像
date: 2017-12-25 22:47:47
tags: matplotlib
---
代码：
```python
# -*- coding: utf-8 -*-
import matplotlib.pyplot as plt
import numpy as np
from mpl_toolkits.mplot3d import Axes3D

fig = plt.figure()
ax = Axes3D(fig)
# X,Y value
x = np.arange(-4,4,0.25)
y = np.arange(-4,4,0.25)
X,Y = np.meshgrid(x,y)# x-y 平面的网格
R = np.sqrt(X**2+Y**2)
# height value
Z = np.sin(R)

# rstride 和 cstride 分别代表 row 和 column 的跨度
ax.plot_surface(X,Y,Z,rstride=1,cstride=1,cmap='rainbow',edgecolor='black')
# 添加 XY 平面的等高线
ax.contourf(X,Y,Z,zdir='z',offset=-2,cmap='rainbow')

ax.set_zlim(-2,2)

plt.savefig("/home/xuleilx/workspace/github/github_pages/public/images/3d_data.png")
plt.show()
```
结果：
![3d_data](https://xuleilx.github.io/images/3d_data.png)