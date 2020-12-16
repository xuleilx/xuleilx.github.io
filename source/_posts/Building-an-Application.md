---
title: Building an Application
date: 2020-12-14 16:55:42
tags: Gstreamer, Media
---
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

