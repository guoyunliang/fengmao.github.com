---
title: pthreads多线程库(一)
layout: post
category: linux
tags: linux process thread pthreads NPTL
---

###pthreads是一个标准

[pthreads](http://en.wikipedia.org/wiki/POSIX_Threads)是一个标准，POSIX standard for threads，POSIX.1c(95年左右)等定义了创建和操作线程的API，它的实现存在于很多Unix-like、POSIX-comformant的操作系统，如FreeBSD、OpenBSD、GNU/Linux，Mac OS X和Microsoft Windows。  

Linux下的实现是[NPTL](http://en.wikipedia.org/wiki/Native_POSIX_Thread_Library)(Native Posix Thread Library)。实现代码位于：glibc[[1](http://stackoverflow.com/questions/3224252/source-code-of-pthread-library),[2](http://stackoverflow.com/questions/1362238/implementation-of-pthread-create-on-linux)]。  
[man pthreads](http://linux.die.net/man/7/pthreads)得到：NPTL is available since glibc 2.3.2, and requires features that are present in the Linux 2.6 kernel。

**一点历史**  
在Linux 2.6内核以前，进程是调度单元，内核并不提供真正的线程支持，不过它提供系统调用clone，可用来创建调用进程的一个拷贝。[LinuxThreads](http://en.wikipedia.org/wiki/LinuxThreads)就是使用这个系统调用提供kernel-level的线程支持，而在LinuxThreads之前，很多pthread的实现都完全是userland的。然而，LinuxThreads的实现却有很多问题，如POSIX compliance以及进程间同步原语等<sup>[wiki]</sup>。  
NPTL应运而生，由RedHat开发，从2.6开始加入Linux内核代码。现在NPTL完全被包含于GNU C Library，也就是glibc，也就是说应该位于Linux libc<sup>[glibc&libc]</sup>。  
周边项目：[NPTL tracing tool](http://nptltracetool.sourceforge.net/)，[NPTL POSIX compliance test](http://posixtest.sourceforge.net/)

###问题

NPTL的使用在很多介绍pthreads编程的书籍里面都提到，好像都是介绍API等上层用法的。我想了解NPTL的实现细节，网络中并没找到好的参考资料，RedHat的[设计文档](http://www.akkadia.org/drepper/nptl-design.pdf)都提出警告：“我的文档过期了”。  

1、NPTL是否在用户态做schedule？  
NPTL没有在用户态做调度，这样是很没效果的，设想你的程序以1个进程的身份去参与内核进程调度，好不容易获得时间片之后，难道要在用户态再内部划分一次？这样的实现即时可以做到，其效率也定然不好吧。  

2、假如NPTL不是在用户态做schedule，而是通过对应的kernel thread来做，那么其中的细节是什么？  
*尚不知道。*  

3、NPTL用户态线程和内核线程的对应关系是什么？“1-1”还是“m-n”？是否可配？  
根据wiki，应该是1-1的，不知是否可以配置成m-n？  

4、是否可以通过shell命令查看出用户线程对应的内核线程？如ps这样的工具？  
ps可以看出。

    # ps -eLf
    UID        PID  PPID   LWP  C NLWP STIME TTY          TIME CMD
    root      5531 32483  5531  0   21 00:31 pts/3    00:00:00 ./xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    root      5531 32483  5532  0   21 00:31 pts/3    00:00:00 ./xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    root      5531 32483  5533  0   21 00:31 pts/3    00:00:00 ./xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    root      5531 32483  5534  0   21 00:31 pts/3    00:00:00 ./xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    ...

发现：PID、PPID都是相同的，NLWP表示number of threads，我在程序中启动了20个线程，加上main thread，总共21个，对每一个线程来说，NLWP显示是一样的。**LWP表示thread ID**，这是不同的。  
同时，从输出可以看出**“1-1”**的关系，一个用户线程是对应一个kernel scheduable entry，或者说kernel线程的。

5、虽然我已了解，使用pthreads应会带来程序性能的提升（主要是因为一个程序的线程多了，被调度到的几率也就大了），但此处还是问一个问题：使用pthreads真的会带来程序性能的提升吗？  
如果是1-1的搭配，在多核情况下，一般必然带来程序性能的提升。而即时在单核情况下，如果内核还支持多线程的话，看起来也能带来性能的提升，因为程序分为更多的进程（线程），参与进程调度时整体能得到更多的时间片。

[wiki]: http://en.wikipedia.org/wiki/Native_POSIX_Thread_Library "Native Posix Thread Library"
[glibc&libc]: http://xanpeng.github.com/2012/03/10/deep-into-malloc/ "glibc and linux libc"