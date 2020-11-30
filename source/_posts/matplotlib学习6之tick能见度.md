---
title: matplotlib学习6之tick能见度
date: 2017-12-24 19:51:00
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
y = 0.1*x

plt.figure(num=1,figsize=(8,5))

# 单纯直线
plt.plot(x,y,linewidth=10,zorder=1)

plt.ylim(-2,2)

# gca = 'get current axis'
# 移动坐标轴位置
ax = plt.gca()
ax.spines['right'].set_color('none')
ax.spines['top'].set_color('none')
ax.xaxis.set_ticks_position("bottom")
ax.yaxis.set_ticks_position("left")
ax.spines['bottom'].set_position(('data',0))
ax.spines['left'].set_position(('data',0))

# 当坐标轴的数字被遮挡时，调整线的透明度
for label in ax.get_xticklabels() + ax.get_yticklabels():
    label.set_fontsize(12)
    label.set_bbox(dict(facecolor='white',
                        edgecolor='None',
                        alpha=0.7,
                        zorder=2))

plt.savefig("/home/xuleilx/workspace/github/github_pages/public/images/tick.png")
#显示
plt.show()
```
![annotate](https://xuleilx.github.io/images/tick.png)