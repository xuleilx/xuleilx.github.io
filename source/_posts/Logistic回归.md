---
title: Logistic回归
date: 2018-05-29 22:00:25
mathjax: true
tags: 机器学习
categories:
 - 机器学习
---
0、概述
========
0.1、回归的含义
----------------------
        高尔顿（Frramcia Galton,1882-1911）早年在剑桥大学学习医学，但医生的职业对
    他并无吸引力，后来他接受了一笔遗产，这使他可以放弃医生的生涯，并与 1850－1852年期
    间去非洲考察，他所取得的成就使其在1853年获得英国皇家地理学会的金质奖章。此后他研究
    过多种学科（气象学、心理学、社会学、 教育学和指纹学等），在1865年后他的主要兴趣转
    向遗传学，这也许是受他表兄达尔文的影响。
       从19世纪80年代高尔顿就开始思考父代和子代相似，如身高、性格及其它种种特制的相似
    性问题。于是他选择了父母平均身高X与其一子身高Y的关系作为研究对象。他观察了1074对
    父母及每对父母的一个儿子，将结果描成散点图，发现趋势近乎一条直 线。总的来说是父母
    平均身高X增加时，其子的身高Y也倾向于增加，这是意料中的结果。但有意思的是高尔顿发现
    这1074对父母平均身高的平均值为68 英寸（英国计量单位，1 英寸=2.54cm）时，1074个
    儿子的平均身高为69 英寸，比父母平均身高大1 英寸 ，于是他推想，当父母平均身高为64 
    英寸时，1074个儿子的平均身高应为64+1=65 英寸；若父母的身高为72 英寸时，他们儿子
    的平均身高应为72=1=73 英寸，但观察结果确与此不符。高尔顿发现前一种情况是儿子的平
    均身高为67 英寸，高于父母平均值达3 英寸，后者儿子的平均身高为71英寸，比父母的平均
    身高低1 英寸。
        高尔顿对此研究后得出的解释是自然界有一种约束力，使人类身高在一定时期是相对稳定
    的。如果父 母身高（或矮了），其子女比他们更高（矮），则人类身材将向高、矮两个极端
    分化。自然界不这样做，它让身高有一种回归到中心的作用。例如，父母平均身高 72 英寸，
    这超过了平均值68英寸，表明这些父母属于高的一类，其儿子也倾向属于高的一类（其平均身
    高71 英寸 大于子代69 英寸），但不像父母离子代那么远（71-69<72-68）。反之，父母
    平均身高64 英寸，属于矮的一类，其儿子也倾向属于矮的一类（其平均67 英寸，小于子代
    的平均数69 英寸），但不像父母离中心那么远（69 -67< 68-64）。
        因此，身高有回归于中心的趋势，由于这个性质，高尔顿就把“回归”这个词引进到问题
    的讨论中，这就是“回归”名称的由来，逐渐背后人沿用成习了。
0.2、线性回归
-------------------
线性回归实际上就是找到一条直线 $$y = W^{T}x + b$$ ，使得该直线尽可能的拟合样本数据。
0.3、Logistic回归
-------------------------
Logistic回归其实不是线性回归求预测值的问题，而是二分类问题。首先我们的线性回归模型输出的
预测值，连续的数值，我们想用它解决分类问题，就需要让连续的数值转换到0/1就可以了,这里引入
一个新的函数sigmoid $$y=\frac{1}{1+e^{-z}}$$ 函数，其中 $$z = W^{T}x + b$$ 。
图像是这样的： 
![sigmoid](https://upload.wikimedia.org/wikipedia/commons/8/88/Logistic-curve.svg)

0.4、Softmax回归
-------------------------
In mathematics, the **softmax** function, or **normalized exponential** function,[1]:198 is a 
generalization of the logistic function that "squashes" a K-dimensional vector $$\mathbf {z}$$ of 
arbitrary real values to a K-dimensional vector $$\sigma (\mathbf {z} )$$ of real values, where each 
entry is in the range (0, 1), and all the entries adds up to 1. The function is given by
$$
{\displaystyle \sigma :\mathbb {R} ^{K}\to \left\{\sigma \in \mathbb {R} ^{K}|\sigma _{i}>0,\sum _{i=1}^{K}\sigma _{i}=1\right\}}
$$
$$
\sigma (\mathbf {z} )_{j}={\frac {e^{z_{j}}}{\sum _{k=1}^{K}e^{z_{k}}}}    for j = 1, …, K.
$$
举个栗子：
假设模型的输入样本是I，讨论一个3分类问题（类别用1，2，3表示），样本I的真实类别是2，那么这个样本I经过网络所有层到达 softmax 层之前就得到了 $$W^{T}x$$，也就是说 $$W^{T}x$$ 是一个3 * 1的向量，那么上面公式中的 $$a_{j}$$ 就表示这个3 * 1的向量中的第 j 个值; 而分母中的 $$a_{k}$$ 则表示3 * 1的向量中的3个值，所以会有个求和符号。 因为 $$e^{x}$$ 恒大于0，所以分子永远是正数，分母又是多个正数的和，所以分母也肯定是正数，因此 $$\sigma (\mathbf {z} )_{j}$$ 是正数，而且范围是(0,1)。如果现在不是在训练模型，而是在测试模型，那么当一个样本经过 softmax 层并输出一个K * 1的向量时，就会取这个向量中值最大的那个数的index作为这个样本的预测标签。

总结一下：
sigmoid将一个real value映射到（0,1）的区间（当然也可以是（-1,1）），这样可以用来做二分类。 
softmax把一个k维的real value向量（a1,a2,a3,a4….）映射成一个（b1,b2,b3,b4….）其中bi是一个0-1的常数，然后可以根据bi的大小来进行多分类的任务，如取权重最大的一维。 
1、介绍
=========

1.1、工作原理
-------------


1.2、优点，缺点，适用范围
------------------------
    优点：计算代价不高，易于理解和实现。
    缺点：容易欠拟合，分类精度可能不高。
    适用范围：标称型数据，标称型数据。
1.3、一般流程
-------------
    收集数据：可以使用任何方法。
    准备数据：由于需要进行距离计算，因此要求数据类型为数值型。另外，结构化数据格式则最佳。
    分析数据：采用任意方法对数据进行分析。
    训练算法：大部分时间用于训练，训练的目的是为了找到最佳的分类回归系数。
    测试算法：一旦训练步骤完成，分类将会很快。
    使用算法：首先，我们需要输入一些数据，并将其装换成对应的结构化数字；接着基于训练好的回归系数就可以对这些数据进行简单的回归计算，判定它们属于哪个类别；在此之后，我们就可以在输出的类别上做一些其他分析工作。
2、实现
=======
2.1、梯度下降
-------------------
梯度：对于可微的数量场f(x,y,z)，以 $$\left ( \partial f /\partial x, \partial f /\partial y, \partial f /\partial z\right )$$ 为分量的向量场称为f的梯度或斜量。
梯度下降法(gradient descent)是一个最优化算法，常用于机器学习和人工智能当中用来递归性地逼近最小偏差模型。

对于只含有一组数据的训练样本，我们可以得到更新weights的规则为：
$$
\theta _{j} := \theta _{j} + \alpha ( y^{i} - h_{\theta }(x^{i}))x_{j}^{(i)}
$$
扩展到多组数据样本，更新公式为：
Repeat until convergence {
$$
\theta _{j} := \theta _{j} + \alpha \sum_{i=1}^{m}  ( y^{i} - h_{\theta }(x^{i}))x_{j}^{(i)}        (for every j)
$$
}
称为批处理梯度下降算法，这种更新算法所需要的运算成本很高，尤其是数据量较大时。考虑下面的更新算法：
Loop {
    for i=1 to m,{
$$
\theta _{j} := \theta _{j} + \alpha ( y^{i} - h_{\theta }(x^{i}))x_{j}^{(i)}        (for every j)
$$
​    }
}
该算法又叫做随机梯度下降法，这种算法不停的更新weights，每次使用一个样本数据进行更新。当数据量较大时，一般使用后者算法进行更新。

2.2、伪代码
-----------
```
	#随机梯度上升算法可以写成如下的伪代码：
	所有回归系数初始化为1
	对数据集中每个样本
		计算该样本的梯度
		使用alpha * gradient更新回归系数
	返回回归系数
```
2.3、python实现
---------------
```python
# 梯度上升算法
def gradAscent(dataMatIn,classLabels):
    '''

    :param dataMatIn: 输入数据
    :param classLabels: 每行数据对应的标签
    :return:
    '''
    dataMatrix = mat(dataMatIn)
    labelMat = mat(classLabels).transpose()
    # m*n 矩阵
    m,n = shape(dataMatrix)
    alpha = 0.001
    maxCycles = 500
    # n所有的Feature，都有weight
    weights = ones((n,1))
    for k in range(maxCycles):
        h = sigmoid(dataMatrix*weights)
        # 计算实际值与预测值之间的差值
        error = (labelMat - h)
        # 梯度上升，对sigmoid函数一阶偏导
        weights = weights + alpha*dataMatrix.transpose()*error
    return weights

# 随机梯度上升算法
def stocGradAscent1(dataMatrix, classLabels, numIter=150):
    m,n = shape(dataMatrix)
    weights = ones(n)   #initialize to all ones
    for j in range(numIter):
        dataIndex = list(range(m))
        for i in range(m):
            alpha = 4/(1.0+j+i)+0.0001    #apha decreases with iteration
            randIndex = int(random.uniform(0,len(dataIndex)))#Does not go to 0 because of the constant
            h = sigmoid(sum(dataMatrix[randIndex]*weights))
            error = classLabels[randIndex] - h # 梯度下降是预测值-实际值，h - y
            weights = weights + alpha * error * float64(dataMatrix[randIndex])
            del(dataIndex[randIndex])
    return weights

```
3、总结
======
本算法接触到了机器学习的一个核心算法，梯度下降(上升)算法，改算法贯穿机器学习的各种算法，使用该算法可以快速求得最小偏差，得到我们建模的参数(w,b)。Logistic回归(逻辑回归)是个分类问题，使用微分知识对函数sigmoid $$y=\frac{1}{1+e^{-z}}$$ 求偏微分，不需要直接求导，而是用偏微分计算。
