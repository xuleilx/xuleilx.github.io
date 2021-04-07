---
title: '[Plugin]Advanced Concepts'
date: 2021-01-21 00:59:29
tags:
 - Gstreamer
 - Media
categories:
 - Gstreamer
---
# Playbin连接流程

1. 根据URI找src插件

   playbin 根据 uri 中指定的协议来判断走哪个src element，比如：uri=file:///tmp/123.mp4 选择filesrcuri=https://www.freedesktop.org/software/gstreamer-sdk/data/media/sintel_trailer-480p.webm 选择 souphttpsrc

2. 通过typefind找demux插件

   通过typefind初步解析MIME媒体类型，找出支持该媒体类型的demux插件

3. Demux插件分流

   demux插件会解析数据流的头部，完成音频和视频的分流，创建Sometimes 的pads。流消失，pads就会消失。

4. Decode插件解码

   demux知道不同的MIME媒体类型的编码格式，找到对应解码插件

5. Sink插件

   播放或显示裸数据

# 特殊类型的pads
1. Sometimes pads：用于demux
2. Request pads：用于mux

# 数据流模式scheduling modes

Push- and Pull-mode。GStreamer在任何调度模式下都支持带有pads的element，其中并非所有pads都需要在同一模式下运行。

## Push mode

之前一篇文章里面有用到`_chain ()`，可以看到该函数是设置给了sinkpad，上游的`gst_pad_push`作用在srcpad上，触发下游元素`_chain ()`被调用。


## Pull mode

一般Demuxers, parsers 以及部分codec插件充当这样的角色，`gst_pad_pull_range`作用在sinkpad上，从src element中pull，push到downstream elements，控制着pipeline的数据流。需要提供随机访问。

可以看出，一般source pad会push数据给下游的element。当然source pad也可以pull，但是用的比较少。此模式的先决条件是使用`gst_pad_set_getrange_function`为source pad设置了`_get_range`。设置的函数会调用`gst_pad_pull_range`获取数据。

当sink element在PULL模式下激活时，它应该启动一个task ，该任务在其sinkpad上调用`gst_pad_pull_range`

This can come in useful for several different kinds of elements:

- Demuxers, parsers and certain kinds of decoders where data comes in unparsed (such as MPEG-audio or video streams), since those will prefer byte-exact (random) access from their input. If possible, however, such elements should be prepared to operate in push-mode mode, too.
- Certain kind of audio outputs, which require control over their input data flow, such as the Jack sound server.

```c
  gst_pad_set_activate_function (filter->sinkpad, gst_my_filter_activate);
  gst_pad_set_activatemode_function (filter->sinkpad,gst_my_filter_activate_mode);
  // gst_my_filter_activate_mode 启动一个task，调用gst_pad_push
```

### Providing random access

Several elements can implement random access:

- Data `sources`, such as a file source, that can provide data from any offset with reasonable low latency.
- `Filters` that would like to provide a pull-mode scheduling over the whole pipeline.
- `Parsers` who can easily provide this by skipping a small part of their input and are thus essentially "forwarding" getrange requests literally without any own processing involved. Examples include tag readers (e.g. ID3) or single output parsers, such as a WAVE parser.

# Caps negotiation

In GStreamer, negotiation of the media format always follows the following simple rules:

- A downstream element suggest a format on its sinkpad and places the suggestion in the result of the CAPS query performed on the sinkpad. See also [Implementing a CAPS query function](https://gstreamer.freedesktop.org/documentation/plugin-development/advanced/negotiation.html#implementing-a-caps-query-function).
- An upstream element decides on a format. It sends the selected media format downstream on its source pad with a CAPS event. Downstream elements reconfigure themselves to handle the media type in the CAPS event on the sinkpad.
- A downstream element can inform upstream that it would like to suggest a new format by sending a RECONFIGURE event upstream. The RECONFIGURE event simply instructs an upstream element to restart the negotiation phase. Because the element that sent out the RECONFIGURE event is now suggesting another format, the format in the pipeline might change.

## Dynamic negotiation

A typical flow goes like this:

- Caps are received on the sink pad of the element.
- If the element prefers to operate in passthrough mode, check if downstream accepts the caps with the ACCEPT_CAPS query. If it does, we can complete negotiation and we can operate in passthrough mode.
- Calculate the possible caps for the source pad.
- Query the downstream peer pad for the list of possible caps.
- Select from the downstream list the first caps that you can transform to and set this as the output caps. You might have to fixate the caps to some reasonable defaults to construct fixed caps.

Examples of this type of elements include:

- Converter elements such as videoconvert, audioconvert, audioresample, videoscale, ...

- Source elements such as audiotestsrc, videotestsrc, v4l2src, pulsesrc, ...

# Memory allocation

`GstBuffer` > `GstMemory`

`GstMemory(GstMapInfo)`：manages access to a piece of memory and then continue with one of it's main users
`GstBuffer`： is used to exchange data between plugins and with the application. A `GstBuffer` contains one or more `GstMemory` objects. These objects hold the buffer's data.
`GstMeta`：can be placed on buffers to provide extra info about it and its memory.
`GstBufferPool`：allows to more-efficiently manage buffers of the same size.

Elements can ask a `GstBufferPool` or `GstAllocator` from the downstream peer element. If downstream is able to provide these objects, upstream can use them to allocate buffers.

Many sink elements have accelerated methods for copying data to hardware, or have direct access to hardware. It is common for these elements to be able to create a `GstBufferPool` or `GstAllocator` for their upstream peers. 

**GstMemory的使用**

```c
  GstMemory *mem;
  GstMapInfo info;
  gint i;

  /* allocate 100 bytes */
  mem = gst_allocator_alloc (NULL, 100, NULL);

  /* get access to the memory in write mode */
  gst_memory_map (mem, &info, GST_MAP_WRITE);

  /* fill with pattern */
  for (i = 0; i < info.size; i++)
    info.data[i] = i;

  /* release memory */
  gst_memory_unmap (mem, &info);
```

**GstBuffer的使用**

```c
  GstBuffer *buffer;
  GstMemory *mem;
  GstMapInfo info;

  /* make empty buffer */
  buffer = gst_buffer_new ();

  /* make memory holding 100 bytes */
  mem = gst_allocator_alloc (NULL, 100, NULL);

  /* add the buffer */
  gst_buffer_append_memory (buffer, mem);

  /* get WRITE access to the memory and fill with 0xff */
  gst_buffer_map (buffer, &info, GST_MAP_WRITE);
  memset (info.data, 0xff, info.size);
  gst_buffer_unmap (buffer, &info);

  /* free the buffer */
  gst_buffer_unref (buffer);
```

**GstBufferPool的使用**

```c
  GstStructure *config;

  /* get config structure */
  config = gst_buffer_pool_get_config (pool);

  /* set caps, size, minimum and maximum buffers in the pool */
  gst_buffer_pool_config_set_params (config, caps, size, min, max);

  /* configure allocator and parameters */
  gst_buffer_pool_config_set_allocator (config, allocator, &params);

  /* store the updated configuration again */
  gst_buffer_pool_set_config (pool, config);
```

# Media Types and Properties

MIME类型：https://www.iana.org/assignments/media-types/media-types.xhtml

# Events

常见的Event：

- [Stream Start](https://gstreamer.freedesktop.org/documentation/plugin-development/advanced/events.html#stream-start)
- [Caps](https://gstreamer.freedesktop.org/documentation/plugin-development/advanced/events.html#caps)
- [Segment](https://gstreamer.freedesktop.org/documentation/plugin-development/advanced/events.html#segment)
- [Tag (metadata)](https://gstreamer.freedesktop.org/documentation/plugin-development/advanced/events.html#tag-metadata)
- [End of Stream (EOS)](https://gstreamer.freedesktop.org/documentation/plugin-development/advanced/events.html#end-of-stream-eos)
- [Table Of Contents](https://gstreamer.freedesktop.org/documentation/plugin-development/advanced/events.html#table-of-contents)
- [Gap](https://gstreamer.freedesktop.org/documentation/plugin-development/advanced/events.html#gap)
- [Flush Start](https://gstreamer.freedesktop.org/documentation/plugin-development/advanced/events.html#flush-start)
- [Flush Stop](https://gstreamer.freedesktop.org/documentation/plugin-development/advanced/events.html#flush-stop)
- [Quality Of Service (QOS)](https://gstreamer.freedesktop.org/documentation/plugin-development/advanced/events.html#quality-of-service-qos)
- [Seek Request](https://gstreamer.freedesktop.org/documentation/plugin-development/advanced/events.html#seek-request)
- [Navigation](https://gstreamer.freedesktop.org/documentation/plugin-development/advanced/events.html#navigation)

**Downstream event**：src -> sink

**Upstream event**: src <- sink

The most common upstream events are seek events, Quality-of-Service (QoS) and reconfigure events. `gst_pad_send_event`

**Segment event**: A segment event is sent downstream to announce the range of valid timestamps in the stream and how they should be transformed into running-time and stream-time. A segment event must always be sent before the first buffer of data and after a flush 

# Demuxer or Parser

**Parsers** are demuxers with only one source pad. 
