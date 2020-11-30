---
title: matplotlib学习15之Animation动画
date: 2017-12-28 22:48:53
tags: matplotlib
---
代码：
```python
# -*- coding: utf-8 -*-
import matplotlib.pyplot as plt
import numpy as np
from matplotlib import animation

fig,ax = plt.subplots()

# 数据是一个0~2π内的正弦曲线
x = np.arange(0,2*np.pi,0.1)
y= np.sin(x)
line, = ax.plot(x,y)

# 采用np.pi*i/30 方式更新，更流畅
def animate(i):
    line.set_ydata(np.sin(x+np.pi*i/30))
    return line,

def init():
    line.set_ydata(np.sin(x))
    return line,

# https://matplotlib.org/api/animation_api.html
ani = animation.FuncAnimation(fig=fig,func=animate,frames=30,init_func=init,blit=True)

# https://stackoverflow.com/questions/25140952/matplotlib-save-animation-in-gif-error
ani.save('/home/xuleilx/workspace/github/github_pages/public/images/animation.gif', writer='imagemagick', fps=30)
plt.show()
```
结果：
![animation](https://xuleilx.github.io/images/animation.gif)