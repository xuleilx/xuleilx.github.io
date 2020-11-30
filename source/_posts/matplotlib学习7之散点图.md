---
title: matplotlib学习7之散点图
date: 2017-12-24 20:12:54
tags: matplotlib
---
代码：
```python
# -*- coding: utf-8 -*-
import matplotlib.pyplot as plt
import numpy as np

n = 1024
# 高斯分布 http://blog.csdn.net/lanchunhui/article/details/50163669
X = np.random.normal(0,1,n)
Y = np.random.normal(0,1,n)
T = np.arctan2(Y,X)# for color value

plt.scatter(X,Y,s=75,c=T,alpha=0.5)
#设置显示范围
plt.xlim(-1.5,1.5)
plt.ylim(-1.5,1.5)
# 去坐标
plt.xticks(())
plt.yticks(())

plt.savefig("/home/xuleilx/workspace/github/github_pages/public/images/dot_map.png")
plt.show()
```
结果：
![dot_map](https://xuleilx.github.io/images/dot_map.png)