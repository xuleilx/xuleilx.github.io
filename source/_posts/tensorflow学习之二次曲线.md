---
title: tensorflow学习之二次曲线
date: 2017-12-17 20:59:17
tags: tensorflow
---
代码：

```python
#coding:utf-8
import tensorflow as tf
import numpy as np
import matplotlib.pyplot as plt

# 构造添加神经层的函数
def add_layer(inputs,in_size,out_size,activation_function=None):
    # 权重，in_size*out_size随机变量矩阵
    Weights = tf.Variable(tf.random_normal([in_size,out_size]))
    # 偏差，1*out_size数组。
    # 在机器学习中，biases的推荐值不为0，这里是在0向量的基础上+0.1
    biases = tf.Variable(tf.zeros([1,out_size])+0.1)
    # y = Weights*x+biases 。 tf.matmul()是矩阵的乘法
    Wx_plus_b = tf.matmul(inputs,Weights)+biases
    # 如果没有定义激励函数就是线性函数
    if activation_function is None:
        outputs = Wx_plus_b
    else:
        outputs = activation_function(Wx_plus_b)
    return outputs

# 生成x的值,类似
# [[-1. ]
#  [-0.5]
#  [ 0. ]
#  [ 0.5]
#  [ 1. ]]
x_data = np.linspace(-1,1,300)[:,np.newaxis]
# 加了一个noise,这样看起来会更像真实情况.类型与x_data一样
noise = np.random.normal(0,0.05,x_data.shape)
# y = x**2 - 0.5 + noise
y_data = np.square(x_data)-0.5+noise

# 利用占位符定义我们所需的神经网络的输入。
# tf.placeholder()就是代表占位符，这里的None代表无论输入有多少都可以，
# 因为输入只有一个特征，所以这里是1
xs=tf.placeholder(tf.float32,[None,1])
ys=tf.placeholder(tf.float32,[None,1])

# inputLayer hideLayer outputLayer
#    1         10         1
# hideLayer
l1 = add_layer(xs,1,10,activation_function=tf.nn.relu)
# outputLayer
predition = add_layer(l1,10,1,activation_function=None)

# 误差的平方和，再求平均
loss = tf.reduce_mean(tf.reduce_sum(tf.square(ys-predition),reduction_indices=[1]))
train_step=tf.train.GradientDescentOptimizer(0.1).minimize(loss)

init = tf.global_variables_initializer()
sess = tf.Session()
sess.run(init)

# 绘图
fig = plt.figure()
ax = fig.add_subplot(1,1,1)
ax.scatter(x_data,y_data)
plt.ion()
plt.show()

for i in range(1000):
    sess.run(train_step,feed_dict={xs:x_data,ys:y_data})
    if i % 50 == 0:
        #print sess.run(loss,feed_dict={xs:x_data,ys:y_data})
        predition_value= sess.run(predition,feed_dict={xs:x_data})
        lines =ax.plot(x_data,predition_value,'r-',lw=5)
        plt.pause(0.5)
        ax.lines.remove(lines[0])

# input()
```
学习的结果：

![image](https://xuleilx.github.io/images/test.gif)
![Alt Text](https://media.giphy.com/media/vFKqnCdLPNOKc/giphy.gif)
