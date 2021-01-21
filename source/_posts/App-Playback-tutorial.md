---
title: '[App]Playback tutorial'
date: 2020-12-27 22:47:11
tags:
	- Gstreamer
	- Media
---
# Playback tutorial 1: Playbin usage

## Property

We have set all these properties one by one, but we could have all of them with a single call to `g_object_set()`:

```c
g_object_set (data.playbin, "uri", "https://www.freedesktop.org/software/gstreamer-sdk/data/media/sintel_cropped_multilingual.webm", "flags", flags, "connection-speed", 56, NULL);
```

This is why `g_object_set()` requires a NULL as the last parameter.

## tag

`playbin` defines 3 action signals to retrieve metadata: `get-video-tags`, `get-audio-tags`and `get-text-tags`. 

get-audio-tags-> GstTagList -> Constants-> GST_TAG_IMAGE   可以参考ATC例子

How to retrieve a particular tag from the list with `gst_tag_list_get_string()`or `gst_tag_list_get_uint()`

# Playback tutorial 3: Short-cutting the pipeline

How to configure the `appsrc` using the `source-setup` signal

```c
/* This function is called when playbin has created the appsrc element, so we have
 * a chance to configure it. */
static void source_setup (GstElement *pipeline, GstElement *source, CustomData *data) {
  GstAudioInfo info;
  GstCaps *audio_caps;

  g_print ("Source has been created. Configuring.\n");
  data->app_source = source;

  /* Configure appsrc */
  gst_audio_info_set_format (&info, GST_AUDIO_FORMAT_S16, SAMPLE_RATE, 1, NULL);
  audio_caps = gst_audio_info_to_caps (&info);
  g_object_set (source, "caps", audio_caps, "format", GST_FORMAT_TIME, NULL);
  g_signal_connect (source, "need-data", G_CALLBACK (start_feed), data);
  g_signal_connect (source, "enough-data", G_CALLBACK (stop_feed), data);
  gst_caps_unref (audio_caps);
}

g_signal_connect (data.pipeline, "source-setup", G_CALLBACK (source_setup), &data);
```

# Playback tutorial 4: Progressive streaming
## deep-notify
```c
g_signal_connect (pipeline, "deep-notify::temp-location", G_CALLBACK (got_location), NULL);
```

`deep-notify` signals are emitted by `GstObject` elements (like `playbin`) when the properties of any of their children elements change. In this case we want to know when the `temp-location` property changes, indicating that the `queue2` has decided where to store the downloaded data.

"temp-location"其实是queue2的属性。

```c
static void got_location (GstObject *gstobject, GstObject *prop_object, GParamSpec *prop, gpointer data) {
  gchar *location;
  g_object_get (G_OBJECT (prop_object), "temp-location", &location, NULL);
  g_print ("Temporary file: %s\n", location);
  g_free (location);
  /* Uncomment this line to keep the temporary file after the program exits */
  /* g_object_set (G_OBJECT (prop_object), "temp-remove", FALSE, NULL); */
}
```

The `temp-location` property is read from the element that triggered the signal (the `queue2`) and printed on screen.

When the pipeline state changes from `PAUSED` to `READY`, this file is removed. As the comment reads, you can keep it by setting the `temp-remove` property of the `queue2` to `FALSE`.

## 定时器

In `main` we also install a timer which we use to refresh the UI every second.

```c
/* Register a function that GLib will call every second */
g_timeout_add_seconds (1, (GSourceFunc)refresh_ui, &data);
```
