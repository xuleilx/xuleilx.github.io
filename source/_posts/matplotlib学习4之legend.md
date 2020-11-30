---
title: matplotlib学习4之legend
date: 2017-12-24 14:53:35
tags: matplotlib
---
代码：
````python
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

# 单纯直线
l1, = plt.plot(x,y2,label='up')
# 指定线的颜色, 宽度和类型
l2, = plt.plot(x,y1,color='red',linewidth=5.0,linestyle='--',label='bottom')

plt.legend(handles=[l1,l2],labels=['aaa','bbb'],loc='best')

plt.savefig("/home/xuleilx/workspace/github/github_pages/public/images/legend.png")
#显示
plt.show()
````
结果：
![legend](https://xuleilx.github.io/images/legend.png)