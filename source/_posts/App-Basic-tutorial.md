---
title: '[App]Basic tutorial'
date: 2020-12-24 23:06:17
tags:
 - Gstreamer
 - Media
categories:
 - Gstreamer
---


# Basic tutorial	

element -> pad -> caps  包含关系

# Basic tutorial 7: Multithreading and Pad Availability

## Request pads

To request (or release) pads in the `PLAYING` or `PAUSED` states, you need to take additional cautions (Pad blocking) which are not described in this tutorial. It is safe to request (or release) pads in the `NULL` or `READY` states, though.

## 多管道播放

1. 单播放
gst-launch-1.0 filesrc location=/home/xuleilx/Music/123.mp3 ! decodebin ! autoaudiosink 
2. 单显示
gst-launch-1.0 filesrc location=/home/xuleilx/Music/123.mp3 ! decodebin ! wavescope ! videoconvert ! autovideosink
3. 播放+显示
gst-launch-1.0 filesrc location=/home/xuleilx/Music/123.mp3 ! decodebin ! tee name=t ! queue ! autoaudiosink t. ! queue ! wavescope ! videoconvert ! autovideosink
4. 修改显示范围，增加个capsfilter
gst-launch-1.0 filesrc location=/home/xuleilx/Music/123.mp3 ! decodebin ! tee name=t ! queue ! autoaudiosink t. ! queue ! wavescope ! capsfilter caps="video/x-raw, format=BGRx,width=1280, height=720, framerate=30/1" ! videoconvert ! autovideosink

注意：
playbin的flags的vis有类似功能

# Basic tutorial 8: Short-cutting the pipeline

主要通过`appsrc`，`appsink`实现，截取管道中的数据。

This tutorial expands [Basic tutorial 7: Multithreading and Pad Availability](https://gstreamer.freedesktop.org/documentation/tutorials/basic/multithreading-and-pad-availability.html) in two ways: firstly, the `audiotestsrc` is replaced by an `appsrc` that will generate the audio data. Secondly, a new branch is added to the `tee` so data going into the audio sink and the wave display is also replicated into an `appsink`. The `appsink` uploads the information back into the application, which then just notifies the user that data has been received, but it could obviously perform more complex tasks.

![img](https://gstreamer.freedesktop.org/documentation/tutorials/basic/images/tutorials/basic-tutorial-8.png)

# Basic tutorial 10: GStreamer tools

三大利器，可以参照其源码实现想要的功能

```shell
gst-launch-1.0
gst-inspect-1.0
gst-discoverer-1.0 # id3信息
```

# Basic tutorial 11: Debugging tools

## Printing debug information
### The debug log
The first category is the Debug Level, which is a number specifying the amount of desired output:

```
| # | Name    | Description                                                    |
|---|---------|----------------------------------------------------------------|
| 0 | none    | No debug information is output.                                |
| 1 | ERROR   | Logs all fatal errors. These are errors that do not allow the  |
|   |         | core or elements to perform the requested action. The          |
|   |         | application can still recover if programmed to handle the      |
|   |         | conditions that triggered the error.                           |
| 2 | WARNING | Logs all warnings. Typically these are non-fatal, but          |
|   |         | user-visible problems are expected to happen.                  |
| 3 | FIXME   | Logs all "fixme" messages. Those typically that a codepath that|
|   |         | is known to be incomplete has been triggered. It may work in   |
|   |         | most cases, but may cause problems in specific instances.      |
| 4 | INFO    | Logs all informational messages. These are typically used for  |
|   |         | events in the system that only happen once, or are important   |
|   |         | and rare enough to be logged at this level.                    |
| 5 | DEBUG   | Logs all debug messages. These are general debug messages for  |
|   |         | events that happen only a limited number of times during an    |
|   |         | object's lifetime; these include setup, teardown, change of    |
|   |         | parameters, etc.                                               |
| 6 | LOG     | Logs all log messages. These are messages for events that      |
|   |         | happen repeatedly during an object's lifetime; these include   |
|   |         | streaming and steady-state conditions. This is used for log    |
|   |         | messages that happen on every buffer in an element for example.|
| 7 | TRACE   | Logs all trace messages. Those are message that happen very    |
|   |         | very often. This is for example is each time the reference     |
|   |         | count of a GstMiniObject, such as a GstBuffer or GstEvent, is  |
|   |         | modified.                                                      |
| 9 | MEMDUMP | Logs all memory dump messages. This is the heaviest logging and|
|   |         | may include dumping the content of blocks of memory.           |
+------------------------------------------------------------------------------+
```
#### 设置插件的日志等级
`GST_DEBUG=2,audiotestsrc:6`
#### 支持正则表达式
`GST_DEBUG=2,audio*:6`
#### 显示所有插件的日志等级：
`gst-launch-1.0 --gst-debug-help`
#### Gstreamer日志输出文件，默认输出到终端
`export GST_DEBUG_FILE=/tmp/gst.log`

### Adding your own debug information
Use the `GST_ERROR()`, `GST_WARNING()`, `GST_INFO()`, `GST_LOG()` and GST_DEBUG() macros. They accept the same parameters as printf, and they use the default category (default will be shown as the Debug category in the output log).

## Getting pipeline graphs
### 环境变量
`export GST_DEBUG_DUMP_DOT_DIR=/tmp/`

### 代码中
`GST_DEBUG_BIN_TO_DOT_FILE(GST_BIN(mypipeline), GST_DEBUG_GRAPH_SHOW_ALL, "test");`
生成/tmp/test.dot文件，用vscode安装Graphviz Preview可查看

# Basic tutorial 12: Streaming
对于流媒体来说，buffer是通用解决方案。gstreamer提供了queue、queue2和multiqueue 
```c
gst_bus_add_signal_watch (bus);
g_signal_connect (bus, "message", G_CALLBACK (cb_message), &data);
```
Live streams cannot be paused, so they behave in `PAUSED` state as if they were in the `PLAYING` state. Setting live streams to `PAUSED` succeeds, but returns `GST_STATE_CHANGE_NO_PREROLL`, instead of `GST_STATE_CHANGE_SUCCESS` to indicate that this is a live stream. We are receiving the `NO_PREROLL` return code even though we are trying to set the pipeline to `PLAYING`, because state changes happen progressively (from NULL to READY, to `PAUSED` and then to `PLAYING`).

For the second network issue, the loss of clock, we simply set the pipeline to PAUSED and back to PLAYING, so a new clock is selected, waiting for new media chunks to be received if necessary.

# Basic tutorial 14: Handy elements
## Bins
`playbin`
`uridecodebin`
`decodebin`
## File input/output
`filesrc`
`filesink`
## Network
`souphttpsrc`
## Test media generation
`videotestsrc`
`audiotestsrc`
## Video adapters
`videoconvert`
`videorate`
`videoscale`
## Audio adapters
`audioconvert`
`audioresample`
`audiorate`
## Multithreading
`queue`
`queue2`
`multiqueue`
`tee`
## Capabilities
`capsfilter`
`typefind`
## Debugging
`fakesink`
`identity`
