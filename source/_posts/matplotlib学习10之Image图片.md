---
title: matplotlib学习9之Image图片
date: 2017-12-25 22:21:26
tags: matplotlib
---
代码：
```python
# -*- coding: utf-8 -*-
import matplotlib.pyplot as plt
import numpy as np

a = np.linspace(0,1,9).reshape(3,3)
# 三行三列的格子，a代表每一个值，图像右边有一个注释，白色代表值最大的地方，颜色越深值越小。
plt.imshow(a,interpolation='nearest',cmap='bone',origin='lower')
# 添加一个colorbar ，其中我们添加一个shrink参数，使colorbar的长度变短为原来的92%
plt.colorbar(shrink=.92)

plt.xticks(())
plt.yticks(())

plt.savefig("/home/xuleilx/workspace/github/github_pages/public/images/image.png")
plt.show()

```
结果：
![image](https://xuleilx.github.io/images/image.png)