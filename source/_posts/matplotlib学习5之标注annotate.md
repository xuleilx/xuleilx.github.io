---
title: matplotlib学习5之标注annotate
date: 2017-12-24 19:23:00
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
y = 2*x + 1

plt.figure(num=1,figsize=(8,5))

# 单纯直线
plt.plot(x,y)

# gca = 'get current axis'
# 移动坐标轴位置
ax = plt.gca()
ax.spines['right'].set_color('none')
ax.spines['top'].set_color('none')
ax.xaxis.set_ticks_position("bottom")
ax.yaxis.set_ticks_position("left")
ax.spines['bottom'].set_position(('data',0))
ax.spines['left'].set_position(('data',0))

x0 = 1
y0 = 2*x0+1
# x:[x0,x0],y:[0,y0] 矩阵运算
plt.plot([x0,x0],[0,y0],'k--',linewidth=2.5)
# set dot styles
plt.scatter([x0,],[y0,],s=50,color='b')

# 添加标注
# method1
plt.annotate(r'$2x+1=%s$'%y0,
             xy=(x0,y0),
             xycoords='data',
             xytext=(+30,-30),
             textcoords='offset points',
             fontsize=16,
             arrowprops=dict(arrowstyle='->',
                             connectionstyle='arc3,rad=.2'))

# method2
plt.text(-1,3,
         r'$\mu\ \sigma_i\ \alpha_t$',
         fontdict={'size':16,'color':'r'})

plt.savefig("/home/xuleilx/workspace/github/github_pages/public/images/annotation.png")
#显示
plt.show()
```
结果：
![annotate](https://xuleilx.github.io/images/annotation.png)