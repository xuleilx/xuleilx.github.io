---
title: ID3信息
date: 2020-11-26 23:06:23
tags: Media
---
# ID3信息
## Taglib
1. 网址：https://taglib.org/
2. 代码：https://github.com/xuleilx/taglib/
3. 实例：https://github.com/xuleilx/taglib/tree/master/examples  新增读取图片实例


## Gstreamer
```shell
# gst-discoverer-1.0 /media/disk/USB/music/123.mp3

Analyzing file:///media/disk/USB/music/123.mp3
Done discovering file:///media/disk/USB/music/123.mp3

Topology:
  unknown: ID3 tag
    audio: MPEG-1 Layer 3 (MP3)

Properties:
  Duration: 0:04:59.339660934
  Seekable: yes
  Tags:
      container format: ID3 tag
      ID3v2 frame: buffer of 23 bytes
      image: buffer of 5926 bytes, type: image/jpeg, width=(int)150, height=(int)150, sof-marker=(int)0
      album: 十一月的萧邦
      artist: 周杰伦
      title: 发如雪
      has crc: false
      channel mode: joint-stereo
      audio codec: MPEG-1 Layer 3 (MP3)
      nominal bitrate: 128000
      bitrate: 127706
```
