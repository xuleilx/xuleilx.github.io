---
title: Application Development Manual
date: 2020-12-22 22:38:35
tags: 
  - Gstreamer
  - Media
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

# Initializing GStreamer

## Simple initialization

```C
gst_init
```

## The GOption interface

[GOption](http://developer.gnome.org/glib/stable/glib-Commandline-option-parser.html) 

# Elements

```c
gst_element_factory_make ()
gst_object_unref ()
//gst_element_factory_make实际上是由gst_element_factory_find,gst_element_factory_create组合而成
gst_element_factory_make () 
	factory = gst_element_factory_find ()
	element = gst_element_factory_create () 
	gst_object_unref (GST_OBJECT (element));
	gst_object_unref (GST_OBJECT (factory));
```

## Using an element as a `GObject`

Every `GstElement` inherits at least one property from its parent `GstObject`: the "name" property.

You can get and set this property using the functions `gst_object_set_name` and `gst_object_get_name`

GObject：https://developer.gnome.org/gobject/stable/rn01.html
GLIB：https://developer.gnome.org/gobject/stable/pt01.html

## Linking elements

```c
// 组成PipeLine
gst_bin_add_many()
// Link的目的：匹配Element之间的pad，link只能发生在同一个pipeline中的Element之间
gst_element_link_many ()
```

## Element States

- `GST_STATE_NULL`: this is the default state. **No resources are allocated in this state,** so, transitioning to it will free all resources. The element must be in this state when its refcount reaches 0 and it is freed.

- `GST_STATE_READY`: in the ready state, **an element has allocated all of its global resources**, that is, resources that can be kept within streams. You can think about opening devices, allocating buffers and so on. However, the stream is not opened in this state, so the stream positions is automatically zero. If a stream was previously opened, it should be closed in this state, and position, properties and such should be reset.

- `GST_STATE_PAUSED`: in this state, an element has opened the stream, but is not actively processing it. An element is allowed to modify a stream's position, read and process data and such to prepare for playback as soon as state is changed to PLAYING, but it is *not* allowed to play the data which would make the clock run. In summary, PAUSED is the same as PLAYING but without a running clock.

  Elements going into the `PAUSED` state should prepare themselves for moving over to the `PLAYING` state as soon as possible. Video or audio outputs would, for example, wait for data to arrive and queue it so they can play it right after the state change. Also, video sinks can already play the first frame (since this does not affect the clock yet). Autopluggers could use this same state transition to already plug together a pipeline. Most other elements, such as codecs or filters, do not need to explicitly do anything in this state, however.

- `GST_STATE_PLAYING`: in the `PLAYING` state, an element does exactly the same as in the `PAUSED` state, except that the clock now runs.

[GST_STATE_READY](https://gstreamer.freedesktop.org/documentation/gstreamer/gstelement.html#GST_STATE_READY) or [GST_STATE_NULL](https://gstreamer.freedesktop.org/documentation/gstreamer/gstelement.html#GST_STATE_NULL) 这两个状态的变更是同步的。参照gst_element_set_state()接口说明。原因主要这两个状态涉及到资源的分配和释放。

 动态添加元素时，需要单独设置状态。when adding elements dynamically to an already-running pipeline, e.g. from within a "pad-added" signal callback, you need to set it to the desired target state yourself using `gst_element_set_state ()` or `gst_element_sync_state_with_parent ()`.

![gstreamer状态变更](https://xuleilx.github.io/images/gstreamer状态变更.png)

# Bins

Bins allow you to combine a group of linked elements into one logical element. You do not deal with the individual elements anymore but with just one element, the bin. 

## Creating a bin

```c
gst_bin_new();
gst_bin_add();
gst_bin_add_many();
gst_bin_remove();
// 可以选择是否放入pipeline中
gst_pipeline_new()
```

## Bins manage states of their children

Bins manage the state of all elements contained in them. If you set a bin (or a pipeline, which is a special top-level type of bin) to a certain target state using `gst_element_set_state ()`, it will make sure all elements contained within it will also be set to this state. This means it's usually only necessary to set the state of the top-level pipeline to start up the pipeline or shut it down.

# Bus

## How to use a bus

Run a GLib/Gtk+ main loop (or iterate the default GLib main context yourself regularly) and attach some kind of watch to the bus. This way the GLib main loop will check the bus for new messages and notify you whenever there are messages.

```c
// switch message
// 异步消息
gst_bus_add_watch()
gst_bus_add_signal_watch()
// 同步消息
gst_bus_set_sync_handler()

// 面向对象的做法，需要监视一个添加一个，不破坏原来代码
g_signal_connect (bus, "message::eos", G_CALLBACK (cb_message_eos), NULL);
```

 The return value of the handler should be `TRUE` to keep the handler attached to the bus, return `FALSE` to remove it.

## Message types

- Error, warning and information notifications
- End-of-stream notification
- Tags: metadata ID3信息
- State-changes
- Buffering: network-streams, 获取网络流媒体播放进度，“buffer-percent”
- Element messages
- Application-specific messages

# Pads and capabilities

- Pads
- Dynamic (or sometimes) pads
- Request pads

## Capabilities of a pad

### Properties and values

**Basic** types, this can be pretty much any `GType` registered with Glib. 

- An integer value (`G_TYPE_INT`): the property has this exact value.
- A boolean value (`G_TYPE_BOOLEAN`): the property is either `TRUE` or `FALSE`.
- A float value (`G_TYPE_FLOAT`): the property has this exact floating point value.
- A string value (`G_TYPE_STRING`): the property contains a UTF-8 string.
- A fraction value (`GST_TYPE_FRACTION`): contains a fraction expressed by an integer numerator and denominator.

**Range** types are `GType`s registered by GStreamer to indicate a range of possible values. 

- An integer range value (`GST_TYPE_INT_RANGE`): the property denotes a range of possible integers, with a lower and an upper boundary. The “vorbisdec” element, for example, has a rate property that can be between 8000 and 50000.
- A float range value (`GST_TYPE_FLOAT_RANGE`): the property denotes a range of possible floating point values, with a lower and an upper boundary.
- A fraction range value (`GST_TYPE_FRACTION_RANGE`): the property denotes a range of possible fraction values, with a lower and an upper boundary.

**List** value (`GST_TYPE_LIST`)
**Array** value (`GST_TYPE_ARRAY`)
`GST_TYPE_LIST`和`GST_TYPE_ARRAY`区别：`GST_TYPE_LIST`一组值中任意一个。`GST_TYPE_ARRAY`是一个整体，每个元素可能用的地方不一样，比如：这个数组有四个值，分别表示左右前后扬声器默认音量。

## What capabilities are used for

- Autoplugging: automatically finding elements to link to a pad based on its capabilities. All autopluggers use this method.

- Compatibility detection: when two pads are linked, GStreamer can verify if the two pads are talking about the same media type. The process of linking two pads and checking if they are compatible is called “caps negotiation”.

- Metadata: by reading the capabilities from a pad, applications can provide information about the type of media that is being streamed over the pad, which is information about the stream that is currently being played back. 比如：视频宽高.

  ```c
  gst_structure_get_int (str, "width", &width);
  ```

- Filtering: an application can use capabilities to limit the possible media types that can stream between two pads to a specific subset of their supported stream types. An application can, for example, use “filtered caps” to set a specific (fixed or non-fixed) video size that should stream between two pads. You will see an example of filtered caps later in this manual, in Manually adding or removing data from/to a pipeline. You can do caps filtering by inserting a capsfilter element into your pipeline and setting its “caps” property. **Caps filters are often placed after converter elements like audioconvert, audioresample, videoconvert or videoscale to force those converters to convert data to a specific output format at a certain point in a stream**.

### Creating capabilities for filtering

```c
// gst_caps_new_full ()  
caps = gst_caps_new_simple ("video/x-raw",
          "format", G_TYPE_STRING, "I420",
          "width", G_TYPE_INT, 384,
          "height", G_TYPE_INT, 288,
          "framerate", GST_TYPE_FRACTION, 25, 1,
          NULL);
link_ok = gst_element_link_filtered (element1, element2, caps);
```

# Buffers and Events

Events are control particles that are sent both up- and downstream in a pipeline along with buffers. `Downstream` events notify fellow elements of stream states. Possible events include **seeking, flushes, end-of-stream notifications** and so on. `Upstream` events are used both in application-element interaction as well as element-element interaction to request changes in stream state, such as **seeks**. 

```c
  GstEvent *event;

  event = gst_event_new_seek (1.0, GST_FORMAT_TIME,
                  GST_SEEK_FLAG_NONE,
                  GST_SEEK_METHOD_SET, time_ns,
                  GST_SEEK_TYPE_NONE, G_GUINT64_CONSTANT (0));
  gst_element_send_event (element, event);
```

# Position tracking and seeking

## Querying: getting the position or length of a stream

Internally, queries will be sent to the sinks, and “dispatched” `backwards` until one element can handle it; that result will be sent back to the function caller. Usually, that is the `demuxer`,  although with live sources (from a webcam), it is the source itself.

```C
gst_element_query ()
	gst_element_query_position ()
	gst_element_query_duration ()
// 定时查询进度
g_timeout_add (200, (GSourceFunc) cb_print_position, pipeline);
```

## Events: seeking (and more)

It is important to realise that seeks will not happen instantly in the sense that they are finished when the function `gst_element_seek ()` returns.



Seeks with the GST_SEEK_FLAG_FLUSH should be done when the pipeline is in PAUSED or PLAYING state.

Seeks without the GST_SEEK_FLAG_FLUSH should only be done when the pipeline is in the PLAYING state. 

Executing a non-flushing seek in the PAUSED state might deadlock because the pipeline streaming threads might be blocked in the sinks.



You can wait (blocking) for the seek to complete with `gst_element_get_state()` or by waiting for the ASYNC_DONE message to appear on the bus.

It is possible to do multiple seeks in short time-intervals, such as a direct response to slider movement. 

```c
gst_element_seek 
	gst_element_seek_simple
```

# Metadata

## Metadata reading

1. 歌曲名
2. 专辑名
3. 艺术家
4. 专辑图片

## 显示图片

gst-launch-1.0 -v filesrc location=3d_data.png ! decodebin ! autovideoconvert ! imagefreeze ! autovideosink

# Threads

## When would you want to force a thread?

We have seen that threads are created by elements but it is also possible to insert elements in the pipeline for the sole purpose of forcing a new thread in the pipeline.

There are several reasons to force the use of threads. However, for performance reasons, you never want to use one thread for every element out there, since that will create some overhead. Let's now list some situations where threads can be particularly useful:

- Data buffering, for example when dealing with network streams or when recording data from a live stream such as a video or audio card. Short hickups elsewhere in the pipeline will not cause data loss. See also [Stream buffering](https://gstreamer.freedesktop.org/documentation/application-development/advanced/buffering.html#stream-buffering) about network buffering with queue2.

![Data buffering, from a networked source](https://gstreamer.freedesktop.org/documentation/application-development/advanced/images/thread-buffering.png)

- Synchronizing output devices, e.g. when playing a stream containing both video and audio data. By using threads for both outputs, they will run independently and their synchronization will be better.

![Synchronizing audio and video sinks](https://gstreamer.freedesktop.org/documentation/application-development/advanced/images/thread-synchronizing.png)



We've mentioned the “queue” element several times now. A queue is the thread boundary element through which you can force the use of threads. 

To use a queue (and therefore force the use of two distinct threads in the pipeline), one can simply create a “queue” element and put this in as part of the pipeline. GStreamer will take care of all threading details internally.

# Playback Components

## Playbin

## Decodebin

Decodebin is the actual autoplugger backend of playbin, which was discussed in the previous section. Decodebin will, in short, accept input from a source that is linked to its sinkpad and will try to detect the media type contained in the stream, and set up decoder routines for each of those. It will automatically select decoders. For each decoded stream, it will emit the “pad-added” signal, to let the client know about the newly found decoded stream. For unknown streams (which might be the whole stream), it will emit the “unknown-type” signal. The application is then responsible for reporting the error to the user.

## URIDecodebin

## Playsink

# Things to check when writing an application

This chapter contains a fairly random selection of things that can be useful to keep in mind when writing GStreamer-based applications. It's up to you how much you're going to use the information provided here. We will shortly discuss how to debug pipeline problems using GStreamer applications. Also, we will touch upon how to acquire knowledge about plugins and elements and how to test simple pipelines before building applications around them.

## Good programming habits

- Always add a `GstBus` handler to your pipeline. Always report errors in your application, and try to do something with warnings and information messages, too.
- Always check return values of GStreamer functions. Especially, check return values of `gst_element_link ()`and `gst_element_set_state ()`.
- Dereference return values of all functions returning a non-base type, such as `gst_element_get_pad ()`. Also, always free non-const string returns, such as `gst_object_get_name ()`.
- Always use your pipeline object to keep track of the current state of your pipeline. Don't keep private variables in your application. Also, don't update your user interface if a user presses the “play” button. Instead, listen for the “state-changed” message on the `GstBus` and only update the user interface whenever this message is received.
- Report all bugs that you find to Gitlab at [https://gitlab.freedesktop.org/gstreamer/](https://gitlab.freedesktop.org/gstreamer).

## Debugging

Applications can make use of the extensive GStreamer debugging system to debug pipeline problems. Elements will write output to this system to log what they're doing. It's not used for error reporting, but it is very useful for tracking what an element is doing exactly, which can come in handy when debugging application issues (such as failing seeks, out-of-sync media, etc.).

Most GStreamer-based applications accept the commandline option `--gst-debug=LIST` and related family members. The list consists of astart of Rose highlighter annotation. comma-separated end of Rose highlighter annotation.list of category/level pairs, which can set the debugging level for a specific debugging category. For example, `--gst-debug=oggdemux:5` would turn on debugging for the Ogg demuxer element. You can use wildcards as well. A debugging level of 0 will turn off all debugging, and a level of 9 will turn on all debugging. Intermediate values only turn on some debugging (based on message severity; 2, for example, will only display errors and warnings). Here's a list of all available options:

- `start of Rose highlighter annotation.--gst-debug-helpend of Rose highlighter annotation.` will print available debug categories and exit.
- `--gst-debug-level=LEVEL` will set the default debug level (which can range from 0 (no output) to 9 (everything)).
- `--gst-debug=LIST` takes a comma-separated list of category_name:level pairs to set specific levels for the individual categories. Example: `GST_AUTOPLUG:5,avidemux:3`. Alternatively, you can also set the `GST_DEBUG`environment variable, which has the same effect.
- `--gst-debug-no-color` will disable color debugging. You can also set the GST_DEBUG_NO_COLOR environment variable to 1 if you want to disable colored debug output permanently. Note that if you are disabling color purely to avoid messing up your pager output, try using `less -R`.
- `--gst-debug-color-mode=MODE` will change debug log coloring mode. MODE can be one of the following: `on`, `off`, `auto`, `disable`, `unix`. You can also set the GST_DEBUG_COLOR_MODE environment variable if you want to change colored debug output permanently. Note that if you are disabling color purely to avoid messing up your pager output, try using `less -R`.
- `--gst-debug-disable` disables debugging altogether.
- `--gst-plugin-spew` enables printout of errors while loading GStreamer plugins.

## Conversion plugins

GStreamer contains a bunch of conversion plugins that most applications will find useful. Specifically, those are videoscalers (videoscale), colorspace convertors (videoconvert), audio format convertors and channel resamplers (audioconvert) and audio samplerate convertors (audioresample). Those convertors don't do anything when not required, they will act in passthrough mode. They will activate when the hardware doesn't support a specific request, though. All applications are recommended to use those elements.

## Utility applications provided with GStreamer

GStreamer comes with a default set of command-line utilities that can help in application development. We will discuss only `gst-launch` and `gst-inspect` here.

### `gst-launch`

`gst-launch` is a simple script-like commandline application that can be used to test pipelines. For example, the command `gst-launch audiotestsrc ! audioconvert ! audio/x-raw,channels=2 ! alsasink` will run a pipeline which generates a sine-wave audio stream and plays it to your ALSA audio card. `gst-launch` also allows the use of threads (will be used automatically as required or as queue elements are inserted in the pipeline) and bins (using brackets, so “(” and “)”). You can use dots to imply padnames on elements, or even omit the padname to automatically select a pad. Using all this, the pipeline `gst-launch filesrc location=file.ogg ! oggdemux name=d d. ! queue ! theoradec ! videoconvert ! xvimagesink d. ! queue ! vorbisdec ! audioconvert ! audioresample ! alsasink` will play an Ogg file containing a Theora video-stream and a Vorbis audio-stream. You can also use autopluggers such as decodebin on the commandline. See the manual page of `gst-launch` for more information.

### `gst-inspect`

`gst-inspect` can be used to inspect all properties, signals, dynamic parameters and the object hierarchy of an element. This can be very useful to see which `GObject` properties or which signals (and using what arguments) an element supports. Run `gst-inspect fakesrc` to get an idea of what it does. See the manual page of `gst-inspect`for more information.
