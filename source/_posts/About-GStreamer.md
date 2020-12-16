---
title: About GStreamer
date: 2020-12-14 16:55:26
tags: Gstreamer, Media
---
# What is GStreamer?

GStreamer plug-ins could be classified into

- protocols handling
- sources: for audio and video (involves protocol plugins)
- formats: parsers, formaters, muxers, demuxers, metadata, subtitles
- codecs: coders and decoders
- filters: converters, mixers, effects, ...
- sinks: for audio and video (involves protocol plugins)

![GStreamer overview](https://gstreamer.freedesktop.org/documentation/application-development/introduction/images/gstreamer-overview.png)

GStreamer is packaged into

- gstreamer: the core package
- gst-plugins-base: an essential exemplary set of elements
- gst-plugins-good: a set of good-quality plug-ins under LGPL
- gst-plugins-ugly: a set of good-quality plug-ins that might pose distribution problems
- gst-plugins-bad: a set of plug-ins that need more quality
- gst-libav: a set of plug-ins that wrap libav for decoding and encoding **软解插件**
- a few others packages



## Communicationend

GStreamer provides several mechanisms for communication and data exchange between the *application* and the *pipeline*.

- *buffers* are objects for passing streaming data between elements in the pipeline. Buffers always travel from sources to sinks (downstream).
- *events* are objects sent between elements or from the application to elements. Events can travel upstream and downstream. Downstream events can be synchronised to the data flow.
- *messages* are objects posted by elements on the pipeline's message bus, where they will be held for collection by the application. Messages can be intercepted synchronously from the streaming thread context of the element posting the message, but are usually handled asynchronously by the application from the application's main thread. Messages are used to transmit information such as errors, tags, state changes, buffering state, redirects etc. from elements to the application in a thread-safe way.
- *queries* allow applications to request information such as duration or current playback position from the pipeline. Queries are always answered synchronously. Elements can also use queries to request information from their peer elements (such as the file size or duration). They can be used both ways within a pipeline, but upstream queries are more common.

![GStreamer pipeline with different communication flows](https://gstreamer.freedesktop.org/documentation/application-development/introduction/images/communication.png)
- *signal*
  signal不是gstreamer特有的东西，它是来自于GObject体系，是用于app和GObject之间进行交互的一种机制。在gstreamer中，element本身也是gobject，所以，通过signal，就可以将app和element联系起来。
  当element发生了一些事情相让app知道时，就可以用signal的方式来通知app比如动态创建了一个Pad。当然也可以在element与element之间使用， 比如在Gstplaybin当中就会侦听uridecoderbin发出来的autoplug-factories，autoplug-select等信号。

  signal和Bus message不同，bus message是pipeline上的，一般是app和pipeline交互的一种方法。signal则具体到了每个element。

![整体框图](https://img-blog.csdnimg.cn/20190812141200931.jpg?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2hvdXhpYW9uaTAx,size_16,color_FFFFFF,t_70)
