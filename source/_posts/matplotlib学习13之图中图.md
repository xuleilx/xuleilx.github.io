---
title: matplotlib学习13之图中图
date: 2017-12-28 21:41:33
tags: matplotlib
---
代码：
```python
# -*- coding: utf-8 -*-
import matplotlib.pyplot as plt

fig = plt.figure()
x = [1,2,3,4,5,6,7]
y = [1,3,4,2,5,8,6]

# 4个值都是占整个figure坐标系的百分比。在这里，假设figure的大小是10x10，
# 那么大图就被包含在由(1, 1)开始，宽8，高8的坐标系内。
left,bottom,width,height=0.1,0.1,0.8,0.8
ax1 = fig.add_axes([left,bottom,width,height])
ax1.plot(x,y,'r')
ax1.set_xlabel('X')
ax1.set_ylabel('Y')
ax1.set_title('title')

left,bottom,width,height=0.2,0.6,0.25,0.25
ax2 = fig.add_axes([left,bottom,width,height])
ax2.plot(y,x,'b--')
ax2.set_xlabel('X')
ax2.set_ylabel('Y')
ax2.set_title('title inside 1')

# 采用一种更简单方法，即直接往plt里添加新的坐标系
left,bottom,width,height=0.6,0.2,0.25,0.25
plt.axes([left,bottom,width,height])
plt.plot(y[::-1],x,'g-.')  # 注意对y进行了逆序处理
plt.xlabel('X')
plt.ylabel('Y')

plt.savefig("/home/xuleilx/workspace/github/github_pages/public/images/plotinplot.png")
plt.show()
```
结果：
![plotinplot](https://xuleilx.github.io/images/plotinplot.png)