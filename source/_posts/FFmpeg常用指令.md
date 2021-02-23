---
title: FFmpeg常用指令
date: 2021-02-22 23:51:02
tags:
 - ffmpeg
---
1、将文件当作源推送到RTMP服务器 

```
ffmpeg -re -i localFile.mp4 -c copy -f flv rtmp://server/live/streamName 
```

 参数解释
-r 以本地帧频读数据，主要用于模拟捕获设备。表示ffmpeg将按照帧率发送数据，不会按照最高的效率发送

2、将直播文件保存至本地 

```
ffmpeg -i rtmp://server/live/streamName -c copy dump.flv
```

 3、将其中一个直播流中的视频改用H.264压缩，音频不变，推送到另外一个直播服务器 

```
ffmpeg -i rtmp://server/live/originalStream -c:a copy -c:v libx264 -vpre slow -f flv rtmp://server/live/h264Stream  
```

4、将其中一个直播流中的视频改用H.264压缩，音频改用aac压缩，推送到另外一个直播服务器 

```
ffmpeg -i rtmp://server/live/originalStream -c:a libfaac -ar 44100 -ab 48k -c:v libx264 -vpre slow -vpre baseline -f flv rtmp://server/live/h264Stream 
```

5、将其中一个直播流中的视频不变，音频改用aac压缩，推送到另外一个直播服务器 

```
ffmpeg -i rtmp://server/live/originalStream -acodec libfaac -ar 44100 -ab 48k -vcodec copy -f flv rtmp://server/live/h264_AAC_Stream  
```

6、将一个高清流复制为几个不同清晰度的流重新发布，其中音频不变

```
ffmpeg -re -i rtmp://server/live/high_FMLE_stream -acodec copy -vcodec x264lib -s 640×360 -b 500k -vpre medium -vpre baseline rtmp://server/live/baseline_500k -acodec copy -vcodec x264lib -s 480×272 -b 300k -vpre medium -vpre baseline rtmp://server/live/baseline_300k -acodec copy -vcodec x264lib -s 320×200 -b 150k -vpre medium -vpre baseline rtmp://server/live/baseline_150k -acodec libfaac -vn -ab 48k rtmp://server/live/audio_only_AAC_48k  
```

7、将当前摄像头以及扬声器通过DSHOW采集，使用H.264/AAC压缩后推送到RTMP服务器 

```
ffmpeg -r 25 -f dshow -s 640×480 -i video=”video source name”:audio=”audio source name” -vcodec libx264 -b 600k -vpre slow -acodec libfaac -ab 128k -f flv rtmp://server/application/stream_name
```

8、将一个JPG图片经过H.264压缩后输出为MP4文件 

```
ffmpeg -i INPUT.jpg -an -vcodec libx264 -coder 1 -flags +loop -cmp +chroma -subq 10 -qcomp 0.6 -qmin 10 -qmax 51 -qdiff 4 -flags2 +dct8x8 -trellis 2 -partitions +parti8x8+parti4x4 -crf 24 -threads 0 -r 25 -g 25 -y OUTPUT.mp4  
```

9、将MP3转化为AAC 

```
ffmpeg -i 20120814164324_205.wav -acodec  libfaac -ab 64k -ar 44100  output.aac  
```

10、将AAC文件转化为flv文件，编码格式采用AAC 

```
ffmpeg -i output.aac -acodec libfaac -y -ab 32 -ar 44100 -qscale 10 -s 640*480 -r 15 outp
```
