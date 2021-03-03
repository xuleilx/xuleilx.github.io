---
title: live555搭建rtsp服务器
date: 2021-03-02 19:25:13
tags:
 - rtsp
 - live555
---
# live555搭建rtsp直播或点播平台

http://www.live555.com/
# 编译
```shell
wget  http://www.live555.com/liveMedia/public/live555-latest.tar.gz
tar xzf live555-latest.tar.gz
cd live
./genMakefiles linux-64bit    #注意后面这个参数是根据当前文件夹下config.<后缀>获取得到的
make
sudo make install
```
# 启动
```shell
# 切换到存放视频文件的目录，运行服务
videos$ sudo live555MediaServer 
# 需要留意的是live555并不支持mp4格式，需要将mp4转为mkv
ffmpeg -i xxx.mp4 xxx.mkv
```
# 客户端播放
```shell
vlc rtsp://127.0.0.1/xxx.mkv
ffplay rtsp://127.0.0.1/xxx.mkv
```

