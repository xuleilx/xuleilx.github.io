---
title: inotify - monitoring filesystem events
date: 2021-08-27 10:29:27
tags: 
---
# 概论

inotify是Linux中用于监控文件系统变化的一个框架，不同于前一个框架dnotify, inotify可以实现基于inode的文件监控。也就是说监控对象不再局限于目录，也包含了文件。不仅如此，在事件的通知方面，inotify摈弃了dnotify的信号方式，采用在文件系统的处理函数中放置hook函数的方式实现。

# 详细说明

## 函数
```C
#include <sys/inotify.h>
int inotify_init(void);int inotify_init1(int flags);
int inotify_add_watch(int fd, const char *pathname, uint32_t mask);
int inotify_rm_watch(int fd, int wd);
```
## 数据结构

在inotify中，对于一个文件或目录的监控被称为一个watch。 给某一个文件或目录添加一个watch就表示要对该文件添加某一类型的监控。监控的类型由一个掩码Mask表示，mask有：
```c
IN_ACCESS ： 文件的读操作
IN_ATTRIB ： 文件属性变化
IN_CLOSE_WRITE ： 文件被关闭之前被写
IN_CLOSE_NOWRITE ： 文件被关闭
IN_CREATE ： 新建文件
IN_DELETE ： 删除文件
IN_MODIFY ： 修改文件
IN_MOVE_SELF ： 被监控的文件或者目录被移动
IN_MOVED_FROM ： 文件从被监控的目录中移出
IN_MOVED_TO ： 文件从被监控的目录中移入
IN_OPEN ： 文件被打开
```
事件的类型有了，我们还需要一个结构体去表示一次事件， 在用户空间，inotify使用inotify_event表示一个事件，每一个事件都有一个特定的身份标示wd, wd是一个整型变量。每一个事件都有一组事件类型与其关联(IN_CREATE | IN_OPEN)。 事件中还应包含文件名。
```c
struct inotify_event {
    int wd; /* Watch deor */
    uint32_t mask; /* Mask of events */
    uint32_t cookie; /* Unique cookie associating related
    events (for rename(2)) */
    uint32_t len; /* Size of name field */
    char name[]; /* Optional null-terminated name */
};
```
## 实例
为了防止文件描述符fd的快速消耗，inotify提出了一个inotify instance(inotify实例)的概念。每一个inotify实例表示一个可读写的fd, 一个inotify实例链接有多个对于文件的watch。而函数inotify_init的工作就是生成一个inotify实例。

如何添加对于目标文件的watch呢？使用inotify_add_watch完成该任务，inotify_add_watch有三个参数，第一个参数是该watch所属的实例的fd, 第二个参数是被监控的文件名，第三个参数要监控的事件类型。

有添加就有删除, inotify_rm_watch(int fd, int wd)完成watch的删除工作，类似的, fd表示实例，wd表示即将删除的watch.

```c
/*
 * @Author: lei.xu@ts
 * @Date: 2021-08-27 09:51:05
 * @LastEditTime: 2021-08-27 10:07:10
 * @LastEditors: your name
 * @Description: 
 * @FilePath: /frameworks/tmp/123.c
 * Copyright ThunderSoft All rights reserved.
 */
#include <stdio.h>
#include <unistd.h>
#include <sys/select.h>
#include <errno.h>
#include <sys/inotify.h>

static void _inotify_event_handler(struct inotify_event *event) //从buf中取出一个事件。
{
    printf("event->mask: 0x%08x\n", event->mask);
    printf("event->name: %s\n", event->name);
}

int main(int argc, char **argv)
{
    if (argc != 2)
    {
        printf("Usage: %s <file/dir>\n", argv[0]);
        return -1;
    }

    unsigned char buf[1024] = {0};
    struct inotify_event *event = NULL;

    int fd = inotify_init();                                //初始化
    int wd = inotify_add_watch(fd, argv[1], IN_ALL_EVENTS); //监控指定文件的ALL_EVENTS。

    for (;;)
    {
        fd_set fds;
        FD_ZERO(&fds);
        FD_SET(fd, &fds);

        if (select(fd + 1, &fds, NULL, NULL, NULL) > 0) //监控fd的事件。当有事件发生时，返回值>0
        {
            int len, index = 0;
            while (((len = read(fd, &buf, sizeof(buf))) < 0) && (errno == EINTR))
                ; //没有读取到事件。
            while (index < len)
            {
                event = (struct inotify_event *)(buf + index);
                _inotify_event_handler(event);                      //获取事件。
                index += sizeof(struct inotify_event) + event->len; //移动index指向下一个事件。
            }
        }
    }

    inotify_rm_watch(fd, wd); //删除对指定文件的监控。

    return 0;
}
```
从以上代码可以看出，inotify的使用很简单，由于一个inotify实例被抽象为一个文件，所以我们可以通过read函数直接读取其中的事件。详情可以` man inotify`。