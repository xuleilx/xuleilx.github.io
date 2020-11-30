---
title: 启动Siri导致车机卡死问题分析
date: 2020-11-29 19:44:28
tags: Media
---

# 启动Siri导致车机卡死问题分析

## 问题现象
启动Siri后，车机卡顿，串口输入输出卡顿。CPU使用率达到接近100%。

## 再现步骤
启动Siri

## 根本原因
**直接原因**
录声音的时候用到snd_pcm_wait接口，来判断是否用数据
即使没有数据snd_pcm_wait也会直接返回，
_GetAvailDelayWithTimestamp函数中的snd_pcm_status
循环调用ioctl判断有无数据，导致CPU 100%其他进程无法得到运行。

**根本原因**
该项目音频架构变更，采用外置836的DSP。
怀疑alsa版本与新的音频架构不匹配导致。
也可以说是alsa的Bug，旧版本的alsa对外置的DSP适配不好。

**对比：**
其他同平台高通原生内置dsp，无此问题，snd_pcm_wait会正常等待。

## 代码调用流程
```C
snd_pcm_wait  // Wait for a PCM to become ready.
snd_pcm_avail // Return number of frames ready to be read (capture) / written (playback)
snd_pcm_status // Obtain status (runtime) information for PCM handle.
	ioctl
```

## 解决方案
**方案1：**
通过尝试替换alsa版本可以解决该问题，使用二分法找到修改该问题的版本。

alsa修改版本
https://www.alsa-project.org/wiki/Detailed_changes_v1.1.1_v1.1.2

最终方案，不是打单个patch，而是更新至最新稳定版alsa。

**方案2：**
alsa修改 snd_pcm_wait 函数，强制poll等待数据

**方案3：**
修改Carplay代码，主动释放cpu。该方案cpu依然很高，但是车机不会卡死。
可以作为规避方案。

## 分析详细
下面我们开始抽丝剥茧：

### gdb定位卡死点
![Siri_gdb_bt](https://xuleilx.github.io/images/Siri_gdb_bt.jpg)

在认知里，我们知道ioctl一般是直接返回的(消耗CPU资源)，一般释放时间片的操作如select，poll，nanosleep等。所以怀疑一直循环调用ioctl导致CPU使用率过高。

对比之前的音频架构首先我们可以明确两个调查方向：

1. 为什么 snd_pcm_wait 没有等待 ？（根本原因，理论上就应该在改接口处等待PCM数据流）
2. 为什么 snd_pcm_status 会死循环 ？（直接原因）

### 为什么snd_pcm_status 会死循环(方案1)

由gdb调试结果可知，栈的调用关系是从snd_pcm_rate_status开始的，然后调用到snd_pcm_plugin_status，那我们看下新旧alsa版本这两个函数的差异：

**snd_pcm_plugin_status：**

![snd_pcm_plugin_status](https://xuleilx.github.io/images/snd_pcm_plugin_status.png)

**snd_pcm_rate_status：**

![snd_pcm_rate_status](https://xuleilx.github.io/images/snd_pcm_rate_status.png)
再看看 ioctl 究竟在干什么：
![Siri_gdb_ioctl](https://xuleilx.github.io/images/Siri_gdb_ioctl.jpg)

我们可以很明显的看到 _agian 的死循环。通过gdb单步执行可以确认的确在死循环。

于是我们找到了这个alsa的patch：

![atomic_patch](https://xuleilx.github.io/images/atomic_patch.jpg)
打上patch确认有效。

### 为什么 snd_pcm_wait 没有等待(方案2)
通过增加日志打印，发现每次都是走的default。没有走 snd_pcm_wait_nocheck 函数，其实这个时候根本没有数据可以读。

![pcm_wait](https://xuleilx.github.io/images/pcm_wait.jpg)

通过修改代码，强制让程序走一次 snd_pcm_wait_nocheck 亦可解决该问题。

```C
// 修改前
default:
	return 1;
// 修改后
default:
	break;
```
## 插曲
不要以为故事已经结束了，其实才刚刚开始。开玩笑啦！
打完这个patch之后，其它的问题开始出现了，原则是修改任何问题必须最小改动，但是alsa版本跨度太大，patch之间也会有诸多依赖。
打完单个patch之后，发现高概率声卡打开会失败，报下面三个错误：

```text
ALSA lib pcm_dsnoop.c:584:(snd_pcm_dsnoop_open) unable to create IPC semaphore

ALSA lib pcm_dsnoop.c:600:(snd_pcm_dsnoop_open) unable to create IPC shm instance

ALSA lib pcm_dsnoop.c:666:(snd_pcm_dsnoop_open) unable to open slave
```
也就是说 snd_pcm_dsnoop_open 函数里面的这三处错误都遇到了。

![snd_pcm_dsnoop_open](https://xuleilx.github.io/images/snd_pcm_dsnoop_open.jpg)
当然，我们也找到了对应的patch：
https://git.alsa-project.org/?p=alsa-lib.git;a=commit;h=dec428c352217010e4b8bd750d302b8062339d32

```text
author	Qing Cai <bsiice@msn.com>	
Thu, 10 Mar 2016 20:40:51 +0800 (07:40 -0500)
committer	Takashi Iwai <tiwai@suse.de>	
Thu, 10 Mar 2016 22:34:36 +0800 (15:34 +0100)

pcm: fix 'unable to create IPC shm instance' caused by fork from a thread

As stated in manpage SHMCTL(2), shm_nattch is "No. of current attaches"
(i.e., number of processes attached to the shared memeory). If an
application uses alsa-lib and invokes fork() from a thread of the
application, there may be the following execution sequence:
 1. execute the following statement:
      pcm_direct.c:110: dmix->shmptr = shmat(dmix->shmid, 0, 0)
    (shm_nattch becomes 1)
 2. invoke fork() in some thread.
    (shm_nattch becomes 2)
 3. execute the following statement:
      pcm_direct.c:122: if (buf.shm_nattch == 1)
 4. execute the following statement:
      pcm_direct.c:131: if (dmix->shmptr->magic != SND_PCM_DIRECT_MAGIC)
    (As stated in manpage SHMGET(2), "When a new shared memory segment
     is created, its contents are initialized to zero values", so
     dmix->shmptr->magic is 0)
 5. execute the following statements:
      pcm_direct.c:132: snd_pcm_direct_shm_discard(dmix)
      pcm_direct.c:133: return -EINVAL
The above execution sequence will cause the following error:
  unable to create IPC shm instance
This error causes multimedia application has no sound. This error rarely
occurs, probability is about 1%.

More notes about this patch:
this patch tries to address the race above by changing the condition
to identify "the first user".  Until now, the first user was
identified by checking shm_nattch.  But this is racy, as stated in the
above.

In this version, we try to assign a shm at first without IPC_CREAT.
If this succeeds, we are not alone, so we must not be the first user.
Only when this fails, try to get a shmem with IPC_CREAT and IPC_EXCL.
If this succeeds, we are the first user.  And, one more notable point
is that the race of this function call itself is protected by
semaphore in the caller side.  The only point to avoid is the race
after shmget() and the first initialization, and this method should
work around that.

Signed-off-by: Qing Cai <bsiice@msn.com>
Signed-off-by: Qing Cai <caiqing@neusoft.com>
Signed-off-by: Takashi Iwai <tiwai@suse.de>
```

看到 neusoft 居然是东软，有点惊讶。敬佩这样一步步找根本原因，给开源代码提patch的共享者。向他们致敬。
