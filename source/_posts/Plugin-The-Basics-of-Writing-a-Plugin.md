---
title: '[Plugin]The Basics of Writing a Plugin'
date: 2021-01-21 00:54:13
tags:
 - Gstreamer
 - Media
categories:
 - Gstreamer
---
# Foundations

## Elements and Plugins

Elements are at the core of GStreamer. In the context of plugin development, an element is an object derived from the GstElement class. 

## Pads

 A pad is similar to a plug or jack on a physical device.

## GstMiniObject, Buffers and Events

For data transport, there are two types of GstMiniObject defined: events (control) and buffers (content).

GstMiniObject 是[`GstBuffer`](https://gstreamer.freedesktop.org/documentation/gstreamer/gstbuffer.html#GstBuffer) 和[`GstEvent`](https://gstreamer.freedesktop.org/documentation/gstreamer/gstevent.html#GstEvent)的父类。

# Constructing the Boilerplate(gst-template)
## 模板代码生成和编译
```
$ git clone https://gitlab.freedesktop.org/gstreamer/gst-template.git
$ cd gst-template/gst-plugin/src
$ git brach -av
$ git checkout 1.18 #最新稳定版
$ ../tools/make_element MyFilter
$ gst-template# meson build
$ gst-template# ninjia -C build
```
### 修改 gst-plugin/meson.build

```text
# 修改前
plugin_sources = [
  'src/gstplugin.c'
  ]
gstpluginexample = library('gstplugin',

# 修改后
plugin_sources = [
  'src/gstmyfilter.c'
  ]
gstpluginexample = library('gstmyfilter',
```
### 修改源代码
可能是../tools/make_element的Bug，需要手动修改代码文件
```C
# gstmyfilter.h
# 修改前
G_DECLARE_FINAL_TYPE (GstMyFilter, gst_my_filter,
    GST, PLUGIN_TEMPLATE, GstElement)
# 修改后
G_DECLARE_FINAL_TYPE (GstMyFilter, gst_my_filter,
    GST, MYFILTER, GstElement)
```
### 代码解析
```c
// gstmyfilter.h
#define GST_TYPE_MY_FILTER (gst_my_filter_get_type())
// _get_type返回GType的类型
G_DECLARE_FINAL_TYPE (GstMyFilter, gst_my_filter,
    GST, MY_FILTER, GstElement)
// G_DECLARE_FINAL_TYPE 定义一个不能被继承的类
// #define G_DECLARE_FINAL_TYPE(ModuleObjName, module_obj_name, MODULE, OBJ_NAME, ParentName) \
//  GType module_obj_name##_get_type (void);                                                               \
//  G_GNUC_BEGIN_IGNORE_DEPRECATIONS                                                                       \
//  typedef struct _##ModuleObjName ModuleObjName;                                                         \
//  typedef struct { ParentName##Class parent_class; } ModuleObjName##Class;  
    
struct _GstMyFilter
{
  GstElement element;

  GstPad *sinkpad, *srcpad;

  gboolean silent;
};
// 在调用G_DEFINE_TYPE() 之前，必须定义_GstMyFilter类型，在G_DECLARE_FINAL_TYPE中被自动定义为GstMyFilter

// gstmyfilter.c
G_DEFINE_TYPE (GstMyFilter, gst_my_filter, GST_TYPE_ELEMENT);
// #define G_DEFINE_TYPE(TN, t_n, T_P) G_DEFINE_TYPE_EXTENDED (TN, t_n, T_P, 0, {})
// TN	The name of the new type, in Camel case.
// t_n	The name of the new type, in lowercase, with words separated by '_'.
// T_P	The GType of the parent type.
```
主要是三个初始化：类初始化，元素初始化，插件初始化
1. 类初始化：指定类具有的信号，参数和虚函数，并设置全局状态
2. 元素初始化：用于初始化此类型的特定实例。数据和事件处理函数设置
3. 插件初始化：插件加载后立即调用，并且应根据加载的插件是否正确初始化了设置返回值。另外，在此功能中，应注册插件中任何受支持的元素类型。

```c
// gstmyfilter.c
/* initialize the myfilter's class */
static void
gst_my_filter_class_init (GstMyFilterClass * klass)
{
  GObjectClass *gobject_class;
  GstElementClass *gstelement_class;

  gobject_class = (GObjectClass *) klass;
  gstelement_class = (GstElementClass *) klass;

    // gobject_class子类特有属性
  gobject_class->set_property = gst_my_filter_set_property;
  gobject_class->get_property = gst_my_filter_get_property;

  g_object_class_install_property (gobject_class, PROP_SILENT,
      g_param_spec_boolean ("silent", "Silent", "Produce verbose output ?",
          FALSE, G_PARAM_READWRITE));

    // gstelement_class父类属性
  gst_element_class_set_details_simple (gstelement_class,
      "MyFilter",
      "FIXME:Generic",
      "FIXME:Generic Template Element", "xuleilx <<user@hostname.org>>");

  gst_element_class_add_pad_template (gstelement_class,
      gst_static_pad_template_get (&src_factory));
  gst_element_class_add_pad_template (gstelement_class,
      gst_static_pad_template_get (&sink_factory));
}

/* initialize the new element
 * instantiate pads and add them to element
 * set pad calback functions
 * initialize instance structure
 */
static void
gst_my_filter_init (GstMyFilter * filter)
{
    // 设置数据、事件处理函数，并加入到element
  filter->sinkpad = gst_pad_new_from_static_template (&sink_factory, "sink");
  gst_pad_set_event_function (filter->sinkpad,
      GST_DEBUG_FUNCPTR (gst_my_filter_sink_event));
    // gst_my_filter_sink_event handles sink events
  gst_pad_set_chain_function (filter->sinkpad,
      GST_DEBUG_FUNCPTR (gst_my_filter_chain));
    // gst_my_filter_chain does the actual processing
    // _event 、_chain 、_query 
  GST_PAD_SET_PROXY_CAPS (filter->sinkpad);
  gst_element_add_pad (GST_ELEMENT (filter), filter->sinkpad);

  filter->srcpad = gst_pad_new_from_static_template (&src_factory, "src");
  GST_PAD_SET_PROXY_CAPS (filter->srcpad);
  gst_element_add_pad (GST_ELEMENT (filter), filter->srcpad);

  filter->silent = FALSE;
}

/* entry point to initialize the plug-in
 * initialize the plug-in itself
 * register the element factories and other features
 */
static gboolean
myfilter_init (GstPlugin * myfilter)
{
  /* debug category for filtering log messages
   *
   * exchange the string 'Template myfilter' with your description
   */
  GST_DEBUG_CATEGORY_INIT (gst_my_filter_debug, "myfilter",
      0, "Template myfilter");

  return gst_element_register (myfilter, "myfilter", GST_RANK_NONE,
      GST_TYPE_MY_FILTER);
  // gst_element_register (GstPlugin * plugin,
  //                  const gchar * name,
  //                  guint rank,
  //                  GType type)
  // Create a new elementfactory capable of instantiating objects of the type and add the factory to plugin.
  // plugin ( [allow-none] ) – GstPlugin to register the element with, or NULL for a static element.
  // name – name of elements of this type
  // rank – rank of element (higher rank means more importance when autoplugging)
  // type – GType of element to register
}

/* gstreamer looks for this structure to register myfilters
 *
 * exchange the string 'Template myfilter' with your myfilter description
 */
GST_PLUGIN_DEFINE (GST_VERSION_MAJOR,
    GST_VERSION_MINOR,
    myfilter,
    "Template myfilter",
    myfilter_init,
    PACKAGE_VERSION, GST_LICENSE, GST_PACKAGE_NAME, GST_PACKAGE_ORIGIN)
// Parameters:
// major – major version number of the gstreamer-core that plugin was compiled for
// minor – minor version number of the gstreamer-core that plugin was compiled for
// name – short, but unique name of the plugin
// description – information about the purpose of the plugin
// init – function pointer to the plugin_init method with the signature of static gboolean plugin_init (GstPlugin * plugin).
// version – full version string (e.g. VERSION from config.h)
// license – under which licence the package has been released, e.g. GPL, LGPL.
// package – the package-name (e.g. PACKAGE_NAME from config.h)
// origin – a description from where the package comes from (e.g. the homepage URL)
```

# What are states?

一般建议编写的插件继承自sources，sinks ，filter，transformation ，专门针对音频，视频还有其他的 base classes。

只需要实现基类的start() and stop() 就行了。如果是继承例如GstElement ，必须自己处理状态变更。Demuxer or muxer没有基类，需要自己处理。

upward先处理自己，然后往上处理父类
downward先处理父类，然后再处理自己

```c
static GstStateChangeReturn
gst_my_filter_change_state (GstElement *element, GstStateChange transition);

static void
gst_my_filter_class_init (GstMyFilterClass *klass)
{
  GstElementClass *element_class = GST_ELEMENT_CLASS (klass);

  element_class->change_state = gst_my_filter_change_state;
}

```
