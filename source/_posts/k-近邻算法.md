---
title: k-近邻算法
date: 2018-04-12 21:26:31
tags: 机器学习
categories:
 - 机器学习
---
<!--ts-->
   * [0、概述](#0概述)
   * [1、介绍](#1介绍)
      * [1.1、工作原理](#11工作原理)
      * [1.2、优点，缺点，适用范围](#12优点缺点适用范围)
      * [1.3、一般流程](#13一般流程)
   * [2、实现](#2实现)
      * [2.1、伪代码](#21伪代码)
      * [2.2、python实现](#22python实现)
   * [3、总结](#3总结)

<!-- Added by: xuleilx, at: 2018-04-12T22:12+08:00 -->

<!--te-->
0、概述
========
    简单的说，k-近邻算法是一种分类算法，采用测量测试用例与样本用例不同特征值之间的距离，选取距离最小的样本所属的分类作为测试用例的分类。

1、介绍
===
1.1、工作原理
---
    工作原理：存在一个样本数据集，也称作训练样本集，并且样本集中每个数据都存在标签，即我们都知道样本集中每个数据与所属分类的对应关系。
    输入没有标签的新数据后，将新数据的每个特征与样本集中的数据对应的特征比较，然后算法提取样本集中特征最相似数据(最近邻)的分类标签。
    一般来说，我们只选择样本数据集中前K个最相似的数据，这就是k-近邻算法中的k的出处，通常k是不大于20的整数。
    最后选择k个最相似数据中出现次数最多的分类，作为新数据的分类
1.2、优点，缺点，适用范围
---
    优点：精度高、对异常值不敏感、无数据输入假定。
    缺点：计算复杂度高、空间复杂度高。（每个测试用例都要计算与所有样本用例的每个特征值的距离）
    适用范围：数值型和标称型
1.3、一般流程
---
    收集数据：可以使用任何方法。
    准备数据：距离计算所需要的数值，最好是结构化的数据格式。
    分析数据：可以使用任何方法。
    训练算法：N/A
    测试算法：计算错误率。
    使用算法：首先需要输入样本数据和结构化的输出结果，然后运行k-近邻算法判定输入数据分别属于哪个分类，
             最后应用对计算出的分类执行后续的处理。
2、实现
===
2.1、伪代码
---
	N/A

2.2、python实现
---

```python
from numpy import *
import operator
from os import listdir

def classify0(inX, dataSet, labels, k):
    '''
    kNN: k Nearest Neighbors
    Input:      inX: vector to compare to existing dataset (1xN)
                dataSet: size m data set of known vectors (NxM)
                labels: data set labels (1xM vector)
                k: number of neighbors to use for comparison (should be an odd number)

    Output:     the most popular class label
    '''
    # 获取样本数，即M
    dataSetSize = dataSet.shape[0]
    # 将单个样本拉成M行矩阵，矩阵相减，得到测试用例特征值与每个样本用例的特征值的差
    diffMat = tile(inX, (dataSetSize,1)) - dataSet
    # 特征值差的平方。此处是array
    sqDiffMat = diffMat**2
    # 每个样本所有特征值差和
    sqDistances = sqDiffMat.sum(axis=1)
    distances = sqDistances**0.5
    # 排序，按照数组所在的编号输出
    sortedDistIndicies = distances.argsort()
    classCount={}
    for i in range(k):
        # 获取前k个的标签
        voteIlabel = labels[sortedDistIndicies[i]]
        # 计算相同标签数
        classCount[voteIlabel] = classCount.get(voteIlabel,0) + 1
    # 按照标签个数排序
    sortedClassCount = sorted(classCount.iteritems(), key=operator.itemgetter(1), reverse=True)
    return sortedClassCount[0][0]
```

3、总结
===
    k-近邻算法是分类数据最简单最有效的算法。
