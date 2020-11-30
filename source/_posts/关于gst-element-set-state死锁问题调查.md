---
title: 关于gst_element_set_state死锁问题调查
date: 2020-11-26 23:53:16
tags: gdb
---

# 关于gst_element_set_state死锁问题调查
## ■现象
*gst_element_set_state* 变更GST_STATE_NULL状态时deadlock。

## ■再现步骤
1.Carlife语音识别时说"鲜花"
2.在VR语音提示音的时候播放过程中，按radio硬按键切源

**更普遍的再现方法：
(也就是说该问题是普遍性问题，与Carlife无直接关系)**
1.插入U盘播放音乐
2.音乐播放过程中，点击暂停
3.使用gst-launch-1.0 playbin uri=file:///media/disk/Track02.mp3 播放音乐
4.步骤3音乐播放过程中按radio硬按键切源
5.按Ctrl+C 结束步骤3的音乐播放，发现无法结束，终端输出以下内容后hangup。
**Setting pipeline to PAUSED ...**

## ■直接原因
调用 *gst_element_set_state()* 函数暂停播放时会调用到alsasink的 *gst_alsasink_reset()* 函数来重置PCM流，该函数会获取alsa_lock锁，以保证当前正在处理的Buffer中的数据处理结束后重置PCM流。
由于alsasink的 *gst_alsasink_write()* 函数获取alsa_lock锁之后，无法写入最后一包数据，导致该锁无法释放，最终导致 *gst_element_set_state()* 死锁。
也就是说**问题发生的时候，声卡的文件句柄无法正常写入**。
![声卡无法写入](https://xuleilx.github.io/images/声卡无法写入.png)
*err = snd_pcm_writei()* 的返回值是：-11。
*snd_strerror(err)* 打印出来的含义是："Resource temporarily unavailable"。
## ■根本原因
切源的时候DSP那边通路被切走，导致alsa的最后一包数据写不进去。
此时可以关声卡，但是不能写入数据。通路再切回来就能正常写入，声卡就可以关闭结束。
## ■调查详细
### 1）由于Carlife服务线程较多，为了准确定位是哪个线程，设置了线程名"SetNameForA7"
```shell
(gdb) info threads
  Id   Target Id         Frame 
  15   Thread 0xb6588450 (LWP 2718) "SetNameForA7" 0xb6f6e6ee in recv ()  ★
    at ../sysdeps/unix/syscall-template.S:81
  14   Thread 0xb5d88450 (LWP 2719) "CarlifeDaemon" __libc_do_syscall ()
    at ../ports/sysdeps/unix/sysv/linux/arm/libc-do-syscall.S:43
...略...
  2    Thread 0xae47a450 (LWP 2993) "TinyVpuDec:src" __libc_do_syscall ()
    at ../ports/sysdeps/unix/sysv/linux/arm/libc-do-syscall.S:43
* 1    Thread 0xb658a000 (LWP 2717) "CarlifeDaemon" __libc_do_syscall ()
    at ../ports/sysdeps/unix/sysv/linux/arm/libc-do-syscall.S:43
```
★处是我们要找的"SetNameForA7"线程

### 2）正常情况下线程2718的状态
```shell
(gdb) thread 18
[Switching to thread 18 (Thread 0xb6588450 (LWP 2718))]
#0  0xb6f6e6ee in recv () at ../sysdeps/unix/syscall-template.S:81
81	../sysdeps/unix/syscall-template.S: No such file or directory.
(gdb) bt
#0  0xb6f6e6ee in recv () at ../sysdeps/unix/syscall-template.S:81
#1  0xb6e64f64 in Socket::recv(unsigned char*, unsigned int) const ()
   from /usr/app/carlife/lib/libcarlifevehicle.so ★
#2  0xb6e639fa in CConnectManager::readCmdData(unsigned char*, unsigned int) ()
   from /usr/app/carlife/lib/libcarlifevehicle.so
...略...
#10 0xb6d54ee4 in ?? () from /usr/app/carlife/lib/libboost_thread.so.1.59.0
#11 0xb6f6845e in start_thread (arg=0xb6588910) at pthread_create.c:314
#12 0xb6905d9c in ?? ()
    at ../ports/sysdeps/unix/sysv/linux/arm/nptl/../clone.S:92
   from /lib/arm-linux-gnueabihf/libc.so.6
Backtrace stopped: previous frame identical to this frame (corrupt stack?)
```
该线程用于接收来自手机Carlife的命令通道的消息，recv是阻塞式函数，无消息时阻塞在recv处，属于正常情况。

### 3）出问题的时候，线程2718的状态
```shell
(gdb) thread 17
[Switching to thread 17 (Thread 0xb6588450 (LWP 2718))]
#0  __libc_do_syscall ()
    at ../ports/sysdeps/unix/sysv/linux/arm/libc-do-syscall.S:43
43	in ../ports/sysdeps/unix/sysv/linux/arm/libc-do-syscall.S
(gdb) bt
#0  __libc_do_syscall ()
    at ../ports/sysdeps/unix/sysv/linux/arm/libc-do-syscall.S:43
#1  0xb6f6dffc in __lll_lock_wait (futex=futex@entry=0x835fd8, private=0)
    at ../ports/sysdeps/unix/sysv/linux/arm/nptl/lowlevellock.c:46
#2  0xb6f6a3aa in __GI___pthread_mutex_lock (mutex=0x835fd8)
    at pthread_mutex_lock.c:134
#3  0xb6b88de2 in g_mutex_lock () from /usr/lib/libglib-2.0.so.0 ★
#4  0xae4e56a2 in ?? () from /usr/lib/gstreamer-1.0/libgstalsa.so
Backtrace stopped: previous frame identical to this frame (corrupt stack?)
```
可以看出是libgstalsa.so中获取互斥锁的地方deadlock了，此时由于gstreamer的调试信息未打开，所以无法看到完整的调用关系。

### 4）重新编译gstreamer1.0-plugins-base插件，加-g参数增加调试信息，重新打印堆栈回溯
```shell
(gdb) bt
#0  __libc_do_syscall ()
    at ../ports/sysdeps/unix/sysv/linux/arm/libc-do-syscall.S:43
#1  0xb6eb0ffc in __lll_lock_wait (futex=futex@entry=0x1fe0f30, private=0)
    at ../ports/sysdeps/unix/sysv/linux/arm/nptl/lowlevellock.c:46
#2  0xb6ead3aa in __GI___pthread_mutex_lock (mutex=0x1fe0f30)
    at pthread_mutex_lock.c:134
#3  0xb6acbde2 in g_mutex_lock () from /usr/lib/libglib-2.0.so.0 ★
#4  0xac4b86a2 in gst_alsasink_reset (asink=0x1fcede8)
    at /workspace/MR3/F516/poky/build/tmp/work/atlas7_arm-poky-linux-gnueabi/gstreamer1.0-plugins-base/1.6-r0/git/ext/alsa/gstalsasink.c:1122
#5  0xb03a3a1a in gst_audio_sink_ring_buffer_pause (buf=<optimized out>)
    at /workspace/MR3/F516/poky/build/tmp/work/atlas7_arm-poky-linux-gnueabi/gstreamer1.0-plugins-base/1.6-r0/git/gst-libs/gst/audio/gstaudiosink.c:545
#6  0xb0387082 in gst_audio_ring_buffer_pause_unlocked (
    buf=buf@entry=0x1fd4388)
    at /workspace/MR3/F516/poky/build/tmp/work/atlas7_arm-poky-linux-gnueabi/gstreamer1.0-plugins-base/1.6-r0/git/gst-libs/gst/audio/gstaudioringbuffer.c:1006
#7  0xb038966c in gst_audio_ring_buffer_pause (buf=0x1fd4388)
    at /workspace/MR3/F516/poky/build/tmp/work/atlas7_arm-poky-linux-gnueabi/gstreamer1.0-plugins-base/1.6-r0/git/gst-libs/gst/audio/gstaudioringbuffer.c:1049
#8  0xb03a0746 in gst_audio_base_sink_change_state (element=0x1fcede8, 
    transition=GST_STATE_CHANGE_PLAYING_TO_PAUSED)
    at /workspace/MR3/F516/poky/build/tmp/work/atlas7_arm-poky-linux-gnueabi/gst---Type <return> to continue, or q <return> to quit---
reamer1.0-plugins-base/1.6-r0/git/gst-libs/gst/audio/gstaudiobasesink.c:2471
#9  0xb6702ba2 in gst_element_change_state ()
   from /usr/lib/libgstreamer-1.0.so.0
#10 0xb6703004 in ?? () from /usr/lib/libgstreamer-1.0.so.0
Backtrace stopped: previous frame identical to this frame (corrupt stack?)
```
此时可以看出完整的Gstreamer设置管道状态的调用顺序。

### 5）通过阅读alsasink插件的代码,发现只有gst_alsasink_write()，gst_alsasink_reset()两个函数会获取alsa_lock锁。
通过代码分析，唯一可能的原因是 *gst_alsasink_write()* 中调用 *snd_pcm_writei()* 函数一直失败。

### 6）使用" export GST_DEBUG=3,alsa:7"打开alsa插件的日志，下面的日志证实了步骤5）的猜想。
![声卡无法写入](https://xuleilx.github.io/images/声卡无法写入.png)
## ■附录：
下面是 *gst_alsasink_write()* 和 *gst_alsasink_reset()* 函数的代码。
```c
static void
gst_alsasink_reset (GstAudioSink * asink)
{
  GstAlsaSink *alsa;
  gint err;

  alsa = GST_ALSA_SINK (asink);

  GST_ALSA_SINK_LOCK (asink);
  GST_DEBUG_OBJECT (alsa, "drop");
  CHECK (snd_pcm_drop (alsa->handle), drop_error);
  GST_DEBUG_OBJECT (alsa, "prepare");
  CHECK (snd_pcm_prepare (alsa->handle), prepare_error);
  GST_DEBUG_OBJECT (alsa, "reset done");
  GST_ALSA_SINK_UNLOCK (asink);

  return;

  /* ERRORS */
drop_error:
  {
    GST_ERROR_OBJECT (alsa, "alsa-reset: pcm drop error: %s",
        snd_strerror (err));
    GST_ALSA_SINK_UNLOCK (asink);
    return;
  }
prepare_error:
  {
    GST_ERROR_OBJECT (alsa, "alsa-reset: pcm prepare error: %s",
        snd_strerror (err));
    GST_ALSA_SINK_UNLOCK (asink);
    return;
  }
}
```
```c
static gint
gst_alsasink_write (GstAudioSink * asink, gpointer data, guint length)
{
  GstAlsaSink *alsa;
  gint err;
  gint cptr;
  guint8 *ptr = data;

  alsa = GST_ALSA_SINK (asink);

  if (alsa->iec958 && alsa->need_swap) {
    guint i;
    guint16 *ptr_tmp = (guint16 *) ptr;

    GST_DEBUG_OBJECT (asink, "swapping bytes");
    for (i = 0; i < length / 2; i++) {
      ptr_tmp[i] = GUINT16_SWAP_LE_BE (ptr_tmp[i]);
    }
  }

  GST_LOG_OBJECT (asink, "received audio samples buffer of %u bytes", length);

  cptr = length / alsa->bpf;

  GST_ALSA_SINK_LOCK (asink);
  while (cptr > 0) {
    /* start by doing a blocking wait for free space. Set the timeout
     * to 4 times the period time */
    err = snd_pcm_wait (alsa->handle, (4 * alsa->period_time / 1000));
    if (err < 0) {
      GST_DEBUG_OBJECT (asink, "wait error, %d", err);
    } else {
      GST_DELAY_SINK_LOCK (asink);
      err = snd_pcm_writei (alsa->handle, ptr, cptr);
      GST_DELAY_SINK_UNLOCK (asink);
    }

    GST_DEBUG_OBJECT (asink, "written %d frames out of %d", err, cptr);
    if (err < 0) {
      GST_DEBUG_OBJECT (asink, "Write error: %s", snd_strerror (err));
      if (err == -EAGAIN) {
        continue;
      } else if (err == -ENODEV) {
        goto device_disappeared;
      } else if (xrun_recovery (alsa, alsa->handle, err) < 0) {
        goto write_error;
      }
      continue;
    }

    ptr += snd_pcm_frames_to_bytes (alsa->handle, err);
    cptr -= err;
  }
  GST_ALSA_SINK_UNLOCK (asink);

  return length - (cptr * alsa->bpf);

write_error:
  {
    GST_ALSA_SINK_UNLOCK (asink);
    return length;              /* skip one period */
  }
device_disappeared:
  {
    GST_ELEMENT_ERROR (asink, RESOURCE, WRITE,
        (_("Error outputting to audio device. "
                "The device has been disconnected.")), (NULL));
    goto write_error;
  }
}
```
