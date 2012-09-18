---
title: linux 进程基础
layout: post
tags: linux process schedule
category: linux
---

#重要勘误#

*由于水平有限,难免"误中误",欢迎指出.*

进程(process)是有特定含义的:  
1) Run in user space.  
2) Runs with a process ID.  
3) Many interactions need to go through the kernel.  
4) All resources need to come from kernel.  
5) Needs to be scheduled by kernel.  

根据这些(如果对的话.[ref](http://superuser.com/questions/197168/is-kernel-a-process)),可以"理解"很多东西了.比如:  
~ kernel thread只不过是只运行于内核态的一种特别的process.  
~ user
thread,如使用pthread得到的,应该不是一般的轻量级进程,而只是用户自己管理的一些任务,它们需要kernel-supported[[ref](http://programmers.stackexchange.com/questions/107938/threads-kernel-threads-vs-kernel-supported-threads-vs-user-level-threads)].待确定.

本文是*ULK第三版*, *Linux內核设计与实现*的读书笔记。

POSIX 1003.1C标准规定一个多线程应用程序中的所有线程都必须有相同的PID。遵照此标准，Linux引入线程组的表示，一个线程组中的所有线程使用和该线程组领头线程（thread group leader）相同的PID，也就是该组中第一个轻量级进程的PID，它被存入进程描述符的tgid字段。getpid()系统调用返回当前进程的tgid值而不是pid的值。  
绝大多数进程都属于一个线程组，包含单一的成员，线程组的领头线程其tgid值与pid值相同。

x86这样的硬件体系结构寄存器比较少，为了方便定位task_struct，在2.6以前的内核中，各个进程的task_struct存放在它们内核栈的尾端，这样只要通过栈指针就能计算出它们的位置，从而避免使用额外的寄存器专门记录。  
由于现在使用slab分配器动态生成task_struct，所以只需要在栈底或栈顶（根据栈增长方向而定）创建一个新的结构struct thread_info，通过它定位task_struct。

/proc/sys/kernel/pid_max可以看出PID最大值默认为32768.

进程必然处于5种状态之一：  
TASK_RUNNING（运行）--进程是可执行的。  
TASK_INTERRUPTIBLE（可中断）--进程正在睡眠。  
TASK_UNINTERRUPTIBLE（不可中断）  
TASK_ZOMBIE（僵死）--进程已经结束，但其父进程还没有调用wait4()系统调用，进程描述符仍然保留，等待父进程查询使用。  
TASK_STOPPED（停止）--进程停止执行

进程创建  
许多其他操作系统都提供了spawn进程的机制，首先在新的地址空间里创建进程，读入可执行文件，最后开始执行。Unix采取了与众不同的进程创建方式，它把上述步骤分解到两个单独的函数中去执行：fork()和exec()。fork通过拷贝当前进程创建一个子进程，子进程与父进程的区别仅仅在于PID，PPID和某些资源和统计量。exec负责读取可执行文件将其载入地址空间开始运行。

#线程#

Linux实现线程的机制非常独特。从内核的角度来说，它并没有线程这个概念。Linux把所有的线程都当作进程来实现，线程仅仅被视为一个与其他进程共享某些资源的进程，每个线程拥有唯一隶属于自己的task_struct，在内核中，它看起来就像是一个普通的进程。  
创建线程与创建进程类似，只不过在调用clone()的时候需要传递一些参数标志来指明需要共享的资源：  
  clone(CLONE_VM | CLONE_FS | CLONE_FILES | CLONE_SIGHAND, 0);  

内核线程  
内核经常需要在后台执行一些操作，这种任务可以通过内核线程（kernel thread）完成--独立运行在内核空间的标准进程。内核线程和普通的进程间的区别在于内核线程没有独立的地址空间（实际上它的mm指针被设置为NULL），它们只在内核空间运行，从来不切换到用户空间去。

进程优先级  
Linux 内核提供了两组独立的优先级范围。  
1.nice值。范围-20～19，默认值0.nice值优先级越低。  
2.实时优先级。默认范围0~99

**时间片**是一个数值，表明进程在被抢占前所能持续运行的时间。进程并不是一定非要一次就用完它的所有时间片。  
当一个进程的时间片耗尽时，就认为进程到期了。没有时间片的进程不再投入运行，除非等到其他所有进程都耗尽了它们的时间片。到那个时候，所有进程的时间片会被重新计算。

#调度和抢占#

选定下一个进程并切换到它去执行是通过**schedule()**函数实现的。当内核代码想要休眠时，会直接调用该函数，另外，如果有哪个进程将被抢占，那么该函数也会被唤起执行。schedule()函数**独立于每个处理器运行**，因此每个CPU都要对下一次该运行哪个进程做出自己的判断。  

**休眠**的进程处于一个特殊的不可执行状态，通过**等待队列**进行处理。等待队列是由等待某些事件发生的进程组成的简单链表，内核通过 wake_queue_head_t 来代表等待队列。等待队列可以通过 DECLARE_WAITQUEUE()静态创建，或使用init_waitqueue_head()动态创建。进程吧自己放入等待队列中并设置成不可执行状态。

什么时候发生**上下文切换**?  
当一个新的进程被选出来准备投入运行的时候，schedule()就会调用context_switch()函数。这个函数完成两个基本工作：  
1.调用switch_mm()，把虚拟内存从上一个进程映射切换到新进程中。  
2.调用switch_to()，负责从上一个进程的处理器状态切换到新进程的处理器状态，包括保存、恢复栈信息和寄存器信息。  

也就是说，schedule()的时候发生上下文切换，何时调用schedule()?  
1.程序员显示调用schedule().  
2.内核提供need_reshed标志表明是否需要重新执行一次调度，每个进程都包含一个need_reshed标志（2.6中移入thread_info某个特殊变量的一位）。  
1）当某个进程耗尽时间片时，scheduler_tick()会设置这个标志。  
2）当一个优先级高的程序进入可执行状态的时候，try_to_wake_up()也会设置这个标志。
3）再返回用户空间以的时候，内核会检查need_reshed。
4）从中断返回的时候，内核会检查need_reshed。

内核抢占  
2.6版本内核开始内核引入抢占能力，只要重新调度是安全的，内核就可以在任何时间抢占正在执行的任务。  
何时重新调度是安全的？只要没有持有锁，正在执行的内核代码就是可以重新导入的，也就是可以抢占的。  
thread_info引入preempt_count计数器，初始值为0，每当使用锁的时候数值加1，释放锁的时候数值减1，数值为0的时候内核就可执行抢占。从中断返回内核空间的时候，内核会检查need_reshed和preempt_count的值，由此判读是否需要执行调度程序。  
如果内核中的进程被阻塞了，或者显式地调用schedule()，内核抢占也会显式地发生。这种形式的内核抢占从来都是受支持的。

实时调度策略  
Linux提供了两种实时调度策略：SCHED_FIFO和SCHED_RR。普通、非实时的调度策略是SCHED_NORMAL。  
SCHED_FIFO级的进程会比任何SCHED_NORMAL级的进程都先得到调度，一旦一个SCHED_FIFO级进程处于可执行状态，就会一直执行，直到它自己受阻塞或显式地释放处理器。它不基于时间片，可以一直执行下去，只有较高优先级的SCHED_FIFO或者SCHED_RR任务才能抢占SCHED_FIFO任务。  
SCHED_RR是带时间片的SCHED_FIFO，是一种实时轮流调度算法。  
这两种实时算法实现的都是静态优先级，内核不为之计算动态优先级。  
Linux的实时调度算法提供一种**软实时**的工作方式，内核调度进程，尽力使进程在它的限定时间到来前运行，但内核不保证总能满足这些进程的要求。

## 负载均衡 ##

Linux调度程序为**对称多处理系统**的每个处理器准备了单独的可执行队列和锁，也就是说每个处理器拥有一个自己的进程链表。处于效率的考虑，整个调度系统从每个处理器来看都是独立的，所以可能存在负载不均衡的情况，**负载均衡程序**负责处理此问题，它由kernel/sched.c中的函数load_balance()来实现。
