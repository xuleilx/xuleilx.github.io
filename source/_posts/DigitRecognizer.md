---
title: DigitRecognizer
date: 2018-06-12 20:26:31
tags: 机器学习
categories:
 - 机器学习
---
0、概述
========
	本篇主要记录本人在Kaggle的Digit Recognizer比赛中学习和用到的知识。
1、介绍
=========
		首先介绍一下数字识别(Digit Recognizer)，数字识别堪称机器学习领域的"Hello 
	World"，几乎可以说是每个学习机器学习的入门指南。不过，这个入门还是有门槛的，不像
	学习编程语言的"Hello World"，如果一开始就一头扎进来，可能会摸不着头脑。
		一开始接触机器学习的是看到有朋友圈里有人发TensorFlow相关的东西，于是在0基础
	的情况下，配置TensorFlow环境，模仿TensorFlow的例子开始了Digit Recognizer的
	实践，发现做下来不知道自己在做什么，例子的每一步不知道是在干什么，一头雾水。
		后来看了一位朋友的博客，分享的是他本人学习机器学习的心路历程，以及一些推荐的公
	开课和书籍，撸完Coursera上吴恩达的视频后对机器学习有了初步认识，接着撸了李宏毅的
	台大课程，感觉思路豁然开朗，顿时理解了吴恩达讲解的很多内容，毕竟是国语嘛，学起来就
	是快。最近开始撸线代和概率论，但是总觉得缺点什么，想想大概是缺少实践吧。
		寻找实践的突破口，发现项目中出现的Bug分配到各个担当是个费时费力的工作，如果能
	够通过Bug描述自动分类那不就可以节省大量人力成本了嘛。于是说干就干，撸起膀子加油
	干。文章分类很快想到了吴恩达老师讲的垃圾邮件分类问题，果断朴素贝叶斯算法。中文与英
	文不一样，英文通过空格可以分词，中文就没有那么简单了，于是调研了一下，发现github
	上有个很好的中文分分词库jieba。试了用一个项目的数据训练后去测试另一个项目的数据，
	准确率也就在50%左右，这样的准确率是无法忍受的，至少在90%以上的准确率才能当做产品
	使用吧。这个时候体会到了吴恩达老师的那句话，其实到最后机器学习工作者不是去实现什么
	牛逼的算法，因为已经有一大批专门研究算法的人每天从事着这样的工作，用实现好的算法库
	比自己实现的效率高，性能好。机器学习工作者主要的工作是：选择数据，选择模型，优化数
	据，优化配置，提高准确率。
		于是参加了Kaggle比赛，学习各路大神是如何玩转机器学习的。说了这么多，回到我们
	的主题Digit Recognizer，分类的方法很多，我们将一一道来。

2、实现
=======
2.1、SVM 实现数字识别(scikit-learn)
-------------------
```python
import pandas as pd
import matplotlib.pyplot as plt
from sklearn.model_selection import train_test_split
from sklearn import svm,metrics

# 将图片数据可视化
def showImgByRow(row,num=1):
    '''
    show pixel
    :param row:pixel row np.array
    :return: null
    '''
    picture = row.reshape((num*28,28))
    plt.imshow(picture,cmap='gray')
    plt.axis('off')
    plt.show()

# 读取训练数据
trainFile = r'digit-recognizer/train.csv'
trainDF = pd.read_csv(trainFile)

# 为了save your life，我们只取前500组数据。其实这样做是可能有问题的，
# 如果数据不是随机分布的，前5000个数据都是某个数字，那就game over了
# 所以无论做何种预测，最好打印出所有的数据分布。
images = trainDF.iloc[0:5000,1:]
labels = trainDF.iloc[0:5000,:1]
train_images, test_images,train_labels, test_labels = train_test_split(images, labels, train_size=0.8, random_state=0)

# 处理输入数据
X = train_images
y = train_labels.values.ravel()

# regularization 正规化，归一化
# 对于数字识别来说，像素点的为0与非0是完全不同的意义，
# 如果取0~255，可能会让算法过渡关注数字的大小，导致识别率的下降
X[X>0] = 1 #X/=255

# 创建分类器
clf = svm.SVC(decision_function_shape='ovr',C = 7,gamma = 0.009)
# 喂数据
clf.fit(X, y)

# 处理测试数据
test_images[test_images>0] = 1 #test_images/=255

# 预测数据
predicted = clf.predict(test_images)
expected = test_labels

#准确率
print(clf.score(test_images,test_labels))
print("Classification report for classifier %s:\n%s\n"
      % (clf, metrics.classification_report(expected, predicted)))
print("Confusion matrix:\n%s" % metrics.confusion_matrix(y, y))
```
2.2、MLP（DNN）实现数字识别(scikit-learn)
--------------
```python
from sklearn.neural_network import MLPClassifier
clf = MLPClassifier(hidden_layer_sizes=(50,), max_iter=10, alpha=1e-4,
                    solver='sgd', verbose=10, tol=1e-4, random_state=1,
                    learning_rate_init=.1)
```
2.3、DNN实现数字识别(keras)
--------------
```python
import pandas as pd
import matplotlib.pyplot as plt
from sklearn.model_selection import train_test_split
from keras.models import Sequential
from keras.layers import Dense,Activation
from keras.utils import to_categorical

# 读取训练数据
trainFile = r'digit-recognizer/train.csv'
trainDF = pd.read_csv(trainFile)

# 为了save your life，我们只取前500组数据。其实这样做是可能有问题的，
# 如果数据不是随机分布的，前5000个数据都是某个数字，那就game over了
# 所以无论做何种预测，最好打印出所有的数据分布。
images = trainDF.iloc[0:,1:]
labels = trainDF.iloc[0:,:1]
train_images, test_images,train_labels, test_labels = train_test_split(images, labels, train_size=0.9, random_state=0)

# 处理输入数据
X = images
y = labels.values.ravel()

# regularization 正规化，归一化
# 对于数字识别来说，像素点的为0与非0是完全不同的意义，
# 如果取0~255，可能会让算法过渡关注数字的大小，导致识别率的下降
X/=255 #X[X>0] = 1

# 创建分类器
clf = Sequential()
clf.add(Dense(output_dim=64,input_dim=784))
clf.add(Activation("relu"))
clf.add(Dense(output_dim=10))
clf.add(Activation("softmax"))

clf.compile(optimizer='rmsprop',
              loss='categorical_crossentropy',
              metrics=['accuracy'])

# Convert labels to categorical one-hot encoding
one_hot_labels = to_categorical(y, num_classes=10)

# Train the model, iterating on the data in batches of 32 samples
# 喂数据
clf.fit(X, one_hot_labels, epochs=10, batch_size=32)

# 处理测试数据
test_images/=255 #test_images[test_images>0] = 1

# evaluate数据
expected = test_labels
one_hot_test_labels = to_categorical(expected, num_classes=10)
score = clf.evaluate(test_images, one_hot_test_labels)
print(score)
```
2.4、CNN实现数字识别(keras)
--------------
参考李宏毅老师的教学视频，自己实现的卷积神经网络
```python
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from sklearn.model_selection import train_test_split
from keras.models import Sequential
from keras.layers.core import Dense,Activation
from keras.layers import MaxPooling2D,Convolution2D,Flatten
from keras.utils.np_utils import to_categorical

# 读取训练数据
trainFile = r'digit-recognizer/train.csv'
trainDF = pd.read_csv(trainFile)

# 为了save your life，我们只取前500组数据。其实这样做是可能有问题的，
# 如果数据不是随机分布的，前5000个数据都是某个数字，那就game over了
# 所以无论做何种预测，最好打印出所有的数据分布。
images = trainDF.iloc[0:5000,1:]
labels = trainDF.iloc[0:5000,:1]
train_images, test_images,train_labels, test_labels = train_test_split(images, labels, train_size=0.8, random_state=5)

# 处理输入数据
X = train_images.values
y = train_labels.values.ravel()

# regularization 正规化，归一化
# 对于数字识别来说，像素点的为0与非0是完全不同的意义，
# 如果取0~255，可能X会让算法过渡关注数字的大小，导致识别率的下降
# 此处采用正规化处理，减去平局值，除以标准差
mean_px = X.mean().astype(np.float32)
std_px = X.std().astype(np.float32)

def standardize(x):
    return (x-mean_px)/std_px

X = standardize(X)

# 创建模型
model = Sequential()
# 25个filter，每个大小是3*3.这样会得到25张图片，去掉边角图片变成26*26
model.add(Convolution2D(25,3,3,input_shape=(28,28,1)))
# 用2*2的框去取最大值。13*13*25
model.add(MaxPooling2D((2,2)))
# 越接近Output Filter越多，图包含的信息越多。11*11*50
model.add(Convolution2D(50,3,3))
# 用2*2的框去取最大值。5*5*50. 比如：去掉一半的像素点，不会改变原图像。
model.add(MaxPooling2D((2,2)))
# 将图像拉直成1D
model.add(Flatten())
# 以上是卷积过程，下面是DNN。100个neuron全连接
model.add(Dense(output_dim=100))
model.add(Activation('relu'))
model.add(Dense(output_dim=10))
model.add(Activation('softmax'))

model.compile(optimizer='rmsprop',
              loss='categorical_crossentropy',
              metrics=['accuracy'])
# Convert labels to categorical one-hot encoding
one_hot_labels = to_categorical(y, num_classes=10)

# Train the model, iterating on the data in batches of 32 samples
# 喂数据
model.fit(X.reshape(X.shape[0],28,28,1), one_hot_labels, epochs=30, batch_size=64)

# 处理测试数据
test_images = test_images.values
test_images = standardize(test_images)

# valuation
expected = test_labels
one_hot_test_labels = to_categorical(expected, num_classes=10)
score = model.evaluate(test_images.reshape(test_images.shape[0],28,28,1), one_hot_test_labels)
print(score)
```
Kaggle上Digit_Recognizer 的Kernel中评分最高的实现，主要的改善有：
1. Dropout 随机丢掉若干神经元
2. ReduceLROnPlateau当算法在最低点徘徊时，降低LR
3. ImageDataGenerator手动创建更多的学习样本。★关键
4. 分别在训练和测试集上绘制loss和accuracy，观察算法的学习情况。★调整学习方法的依据
```python
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.image as mpimg
import seaborn as sns

np.random.seed(2)
from sklearn.model_selection import train_test_split
from sklearn.metrics import confusion_matrix
import itertools

from keras.utils.np_utils import to_categorical # convert to one-hot-encoding
from keras.models import Sequential
from keras.layers import Dense, Dropout, Flatten, Conv2D, MaxPool2D
from keras.optimizers import RMSprop
from keras.preprocessing.image import ImageDataGenerator
from keras.callbacks import ReduceLROnPlateau

sns.set(style='white', context='notebook', palette='deep')

# Load the data
train = pd.read_csv(r"digit-recognizer/train.csv")
test = pd.read_csv(r"digit-recognizer/test.csv")

Y_train = train["label"]

# Drop 'label' column
X_train = train.drop(labels = ["label"],axis = 1)

# free some space
del train

# g = sns.countplot(Y_train)

Y_train.value_counts()

# plt.show()
# Check the data
print(X_train.isnull().any().describe())
print(test.isnull().any().describe())

# Normalize the data
X_train = X_train / 255.0
test = test / 255.0

# Reshape image in 3 dimensions (height = 28px, width = 28px , canal = 1)
X_train = X_train.values.reshape(-1,28,28,1)
test = test.values.reshape(-1,28,28,1)

# Encode labels to one hot vectors (ex : 2 -> [0,0,1,0,0,0,0,0,0,0])
Y_train = to_categorical(Y_train, num_classes = 10)

# Set the random seed
random_seed = 2

# Split the train and the validation set for the fitting
X_train, X_val, Y_train, Y_val = train_test_split(X_train, Y_train, test_size = 0.1, random_state=random_seed)

# Some examples
# g = plt.imshow(X_train[0][:,:,0])
#
# plt.show()
# Set the CNN model
# my CNN architechture is In -> [[Conv2D->relu]*2 -> MaxPool2D -> Dropout]*2 -> Flatten -> Dense -> Dropout -> Out

model = Sequential()

model.add(Conv2D(filters = 32, kernel_size = (5,5),padding = 'Same',
                 activation ='relu', input_shape = (28,28,1)))
model.add(Conv2D(filters = 32, kernel_size = (5,5),padding = 'Same',
                 activation ='relu'))
model.add(MaxPool2D(pool_size=(2,2)))
model.add(Dropout(0.25))

model.add(Conv2D(filters = 64, kernel_size = (3,3),padding = 'Same',
                 activation ='relu'))
model.add(Conv2D(filters = 64, kernel_size = (3,3),padding = 'Same',
                 activation ='relu'))
model.add(MaxPool2D(pool_size=(2,2), strides=(2,2)))
model.add(Dropout(0.25))

model.add(Flatten())
model.add(Dense(256, activation = "relu"))
model.add(Dropout(0.5))
model.add(Dense(10, activation = "softmax"))

# Define the optimizer
optimizer = RMSprop(lr=0.001, rho=0.9, epsilon=1e-08, decay=0.0)

# Compile the model
model.compile(optimizer = optimizer , loss = "categorical_crossentropy", metrics=["accuracy"])

# Set a learning rate annealer
learning_rate_reduction = ReduceLROnPlateau(monitor='val_acc',
                                            patience=3,
                                            verbose=1,
                                            factor=0.5,
                                            min_lr=0.00001)

epochs = 1 # Turn epochs to 30 to get 0.9967 accuracy
batch_size = 64

# With data augmentation to prevent overfitting (accuracy 0.99286)
datagen = ImageDataGenerator(
        featurewise_center=False,  # set input mean to 0 over the dataset
        samplewise_center=False,  # set each sample mean to 0
        featurewise_std_normalization=False,  # divide inputs by std of the dataset
        samplewise_std_normalization=False,  # divide each input by its std
        zca_whitening=False,  # apply ZCA whitening
        rotation_range=10,  # randomly rotate images in the range (degrees, 0 to 180)
        zoom_range = 0.1, # Randomly zoom image
        width_shift_range=0.1,  # randomly shift images horizontally (fraction of total width)
        height_shift_range=0.1,  # randomly shift images vertically (fraction of total height)
        horizontal_flip=False,  # randomly flip images
        vertical_flip=False)  # randomly flip images


datagen.fit(X_train)

# Fit the model
history = model.fit_generator(datagen.flow(X_train,Y_train, batch_size=batch_size),
                              epochs = epochs, validation_data = (X_val,Y_val),
                              verbose = 2, steps_per_epoch=X_train.shape[0] // batch_size
                              , callbacks=[learning_rate_reduction])

# Plot the loss and accuracy curves for training and validation
fig, ax = plt.subplots(2,1)
ax[0].plot(history.history['loss'], color='b', label="Training loss")
ax[0].plot(history.history['val_loss'], color='r', label="validation loss",axes =ax[0])
legend = ax[0].legend(loc='best', shadow=True)

ax[1].plot(history.history['acc'], color='b', label="Training accuracy")
ax[1].plot(history.history['val_acc'], color='r',label="Validation accuracy")
legend = ax[1].legend(loc='best', shadow=True)

# Plot the confusion_matrix
# confusion_mtx = confusion_matrix(expected, predicted)
# df_cm = pd.DataFrame(confusion_mtx, index = [i for i in range(0,10)], columns = [i for i in range(0,10)])
# plt.figure(figsize = (6,5))
# conf_mat = sns.heatmap(df_cm, annot=True, cmap='Blues', fmt='g', cbar = False)
# conf_mat.set(xlabel='Predicts', ylabel='True')
# plt.show()
```
2.5、kNN实现数字识别
--------------
此处不再赘述，请参考前文：
https://xuleilx.github.io/2018/04/12/k-%E8%BF%91%E9%82%BB%E7%AE%97%E6%B3%95/
3、总结
======

	机器学习把复杂的数字识别问题的变成了简单的分类问题。通过本文可以发现同一个问题可以
	由不同的算法解决。本文主要用的是SVM、DNN、CNN、kNN四种算法，分别采用刚刚接触的
	Scikit-learn和Keras实现。这里尤其要说明一点的是，神经网络将传统机器学习的函数模
	型选择问题变成了搭建神经网络结构的问题。通过对loss和accuracy在样本集和测试集上的
	表现权衡bias和variance，成功图像识别问题变成了数据分析问题。这大概就是机器学习的
	魅力所在，将无形变成有形。
