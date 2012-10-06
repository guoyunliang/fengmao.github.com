---
title: 直接设备访问
layout: post
category: linux
tags: access device driver vfs
---

通过文件系统访问设备是常见的方式，是否可以不使用文件系统，而直接访问设备。  
答案是肯定的。就好像你实现一个文件系统，最终你是需要面对设备的，需要直接访问设备的。  
那么用户态可以直接访问设备吗？  
也是可以的，因为设备也是一个文件，直接访问设备文件即可，用的api是read、write等。  
`dd if=/dev/zero of=/dev/sdx bs=1M count=10`，dd命令就是直接访问设备，不过要千万慎用这条命令，它会搞垮sdx上原有的数据，使用`dd if=/dev/zero of=./data_10m bs=1M count=10`、`losetup /dev/loop0 ./data_10M`和`dd if=/dev/zero of=/dev/loop0 bs=1k count=10`代替。  
1. 看dd的源代码(在coreutils包里面)可知，写数据时用的是write接口。  
2. strace dd也可以看出来，使用read从/dev/zero里面读，使用write写入/dev/sdx。  

不过有一点值得思虑：这么做绕过VFS了吗？  
应该是没有的。因为write到内核就是fs/read_write.c里面的SYS_DEFINE3(write...)，执行的vfs_write。  
不过仍然是直接设备访问，拿dd loop的例子来说，首先走vfs_write，然后下到udev（mount看到/dev不是ext3的）的write方法，再下到drivers/block/loop.c的write方法(loop设备实际上没定义write方法，说明最后走的是loop对应的文件的write方法)。  
可以验证这个流程：修改内核，在loop.c对应位置加上dump_stack()；或者使用systemtap。  

*然而非常遗憾的是，二者都需要我重编内核。systemtap需要开启DEBUG等选项。编译内核时才发现我的x200已经不够用了。*

*这个国庆，中间的几天我跟老友打牌+美剧+睡觉度过了。在去玉泉之前，我就通宵重编了内核。然后直到今天10-05，验证systemtap能用了。*  
*这次重编内核，要开启CONFIG_DEBUG_INFO等重要的选项([更多细节](http://sourceware.org/systemtap/wiki/SystemTapWithSelfBuiltKernel))，然后使用的是debian的方式去编译([更多细节](http://www.debian.org/releases/stable/i386/ch08s06.html.zh_CN))，这样子操作起来十分简单。当然也可能依照常规方式，不过为何不“入乡随俗”了。*   

打算使用systemtap跟踪drivers/block/loop.c时发现，stap应该是通过/boot/System.map找到symbol的，但是loop.c属于loop模块，其symbols没有被编进System.map，所以不能这样：probe kernel.function("...")。fs/ext3也是以模块的方式编译的，也不能直接这么使用。——这是一个麻烦。  
要使用另外一种方式：probe module("...").xxx("...")。但操作时遇到这样的错误：“WARNING: cannot find module ext3 debuginfo: No DWARF information found”。——看起来CONFIG_DEBUG_INFO没能为模块生成额外的信息(什么信息?...)。  
看起来要打开-g编译选项，不知道是否有对应的BUILD OPTION，不过找到其他两个方法：make CFLAGS='-g'，直接修改顶层Makefile的CFLAGS_KERNEL和CFLAGS。  
重新编译安装之后(debian's way)，发现仍然是同样的warning，百思不得其解。最后使用readelf和objdump查看系统的loop.ko，发现真的没有DWARF info，但是编译过的源码目录下的loop.ko是又DWARF info的，不知道为什么。把源码目录下的loop.ko拷贝至/lib/modules，就可以用了。  

我用的stap脚本：  
{% highlight text %}
probe module("loop").function("*") {
    printf ("%s -> %s\n", thread_indent(1), probefunc())
    /* print_backtrace() */
}
{% endhighlight %}

因为使用了loop_thread，函数调用路径被打乱，print_backtrace()得不到上层更多的调用关系，输出的信息基本上是loop.c里面的函数调用轨迹，不能用来证明猜想，留待以后了。不过我相信这就是直接设备访问了。

systemtap的资料网上会有很多，给出两个：http://sourceware.org/systemtap/tutorial/tutorial.html，http://linux.die.net/man/5/stapprobes.

直接设备访问时，读取的块放在那里，写入的块如何组织，怎么考虑对齐...这些都是更深层的问题。不知道哪里有资料介绍这方面的内容呢？
