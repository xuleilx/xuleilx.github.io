---
title: matplotlib学习12之Subplot多合一显示2
date: 2017-12-28 21:16:07
tags: matplotlib
---
代码：
```python
# -*- coding: utf-8 -*-
import matplotlib.pyplot as plt
import matplotlib.gridspec as gridspec

# method 1:subplot2grid
#############################
plt.figure()
ax1 = plt.subplot2grid((3,3),(0,0),colspan=3,rowspan=1)
ax1.plot([1,2],[1,2])
ax1.set_title('ax1_title')
ax2 = plt.subplot2grid((3,3),(1,0),colspan=2)
ax3 = plt.subplot2grid((3,3),(1,2),rowspan=2)
ax4 = plt.subplot2grid((3,3),(2,0))
ax5 = plt.subplot2grid((3,3),(2,1))

# method 2:gridspec
#############################
# plt.figure()
# gs = gridspec.GridSpec(3,3)
# ax1 = plt.subplot(gs[0,:])
# ax2 = plt.subplot(gs[1,:2])
# ax3 = plt.subplot(gs[1:,2])
# ax4 = plt.subplot(gs[2,0])
# ax5 = plt.subplot(gs[2,1])

# method 3:easy to define structure
#############################
# f,axes = plt.subplots(2,2,sharex=True)
# axes[0,0].scatter([1,2],[1,2])

plt.savefig("/home/xuleilx/workspace/github/github_pages/public/images/subplot_method1.png")
plt.tight_layout()
plt.show()
```
结果：
Method1:
![subplot_method1](https://xuleilx.github.io/images/subplot_method1.png)
Method2:
![subplot_method2](https://xuleilx.github.io/images//subplot_method2.png)
Method3:
![subplot_method3](https://xuleilx.github.io/images/subplot_method3.png)
