---
title: matplotlib学习9Contours等高线图
date: 2017-12-25 22:01:32
tags: matplotlib
---
代码：
```python
# -*- coding: utf-8 -*-
import matplotlib.pyplot as plt
import numpy as np

def f(x,y):
    # the height function
    return (1-x/2+x**5+y**3)*np.exp(-x**2-y**2)

n = 256
x = np.linspace(-3,3,n)
y = np.linspace(-3,3,n)
# 编织成栅格
X,Y = np.meshgrid(x,y)

# use plt.contourf to filling contours
# X,Y and value for (X,Y) point
plt.contourf(X,Y,f(X,Y),8,alpha=.75,cmap=plt.cm.hot)
C = plt.contour(X,Y,f(X,Y),8,colors='black',linewidth=.5)

# 添加label，隐藏坐标轴
plt.clabel(C,inline=True,fontsize=10)
plt.xticks(())
plt.yticks(())

plt.savefig("/home/xuleilx/workspace/github/github_pages/public/images/contours.png")
plt.show()
```
结果：
![contours](https://xuleilx.github.io/images/contours.png)