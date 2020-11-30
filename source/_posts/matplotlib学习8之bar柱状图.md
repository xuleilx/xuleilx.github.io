---
title: matplotlib学习8之bar柱状图
date: 2017-12-24 20:45:59
tags: matplotlib
---
代码：
```python
# -*- coding: utf-8 -*-
import matplotlib.pyplot as plt
import numpy as np

n = 10
X = np.arange(n)
# 均匀分布
Y1 = (1-X/float(n))*np.random.uniform(0.5,1,n)
Y2 = (1-X/float(n))*np.random.uniform(0.5,1,n)

plt.bar(X,+Y1,facecolor='#9999ff',edgecolor='white')
plt.bar(X,-Y2,facecolor='#ff9999',edgecolor='white')

for x,y in zip(X,Y1):
    # ha: horizontal alignment
    # va: vertical alignment
    plt.text(x,y,'%.2f'%y,ha='center',va='bottom')

for x,y in zip(X,Y2):
    plt.text(x,-y,'%.2f'%y,ha='center',va='top')

#设置显示范围
plt.xlim(-.5,n)
plt.ylim(-1.25,1.25)
plt.xticks(())
plt.yticks(())

plt.savefig("/home/xuleilx/workspace/github/github_pages/public/images/bar_map.png")
plt.show()
```
结果：
![bar_map](https://xuleilx.github.io/images/bar_map.png)