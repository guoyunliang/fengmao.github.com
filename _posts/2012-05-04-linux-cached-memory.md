---
title: Linux cached memory
layout: post
tags: linux cache memory free top
category: linux
---

*本文在"[关于Linux的缓存内存 Cache Memory详解](http://www.opsers.org/base/cache-memory-on-linux-detailed-cache-memory.html)"上修改得到.*

Linux与Win的内存管理不同, 会尽量缓存内存以提高读写性能, 通常叫做Cache Memory. 有时候你会发现没有什么程序在运行, 但是使用top或free命令看到可用内存free项会很少, 此时查看系统的 /proc/meminfo 文件, 会发现有一项 Cached Memory:

    # cat /proc/meminfo
    MemTotal:        4140288 kB
    MemFree:         3803900 kB
    Buffers:            2036 kB
    Cached:            28304 kB    ----> here

`free` 可以看到更多内存相关的细节:

    # free
                 total       used       free     shared    buffers     cached
    Mem:       4140288     325908    3814380          0        692      24672
    -/+ buffers/cache:     300544    3839744
    Swap:      6297472          0    6297472

`free` 的输出中, 

    total=used+free
    used=buffers+cached (maybe add shared also)
    -buffers/cache=used-buffers-cached
    +buffers/cache=free+buffers+cached

`top` 也可以看到内存信息.

**什么是Cache Memory(缓存内存)**

*首先需要提起注意, cache/buffer 这类词汇在中文, e文技术书籍中都被用烂了, 作者理解可能不同, 各人翻译可能有别, 因而每次遇到, 都需要结合上下文去考虑.*

当你读写文件的时候, Linux内核为了提高读写性能与速度, 会将文件在内存中进行缓存, 这部分内存就是Cache Memory(缓存内存). 即使你的程序运行结束后, Cache Memory也不会自动释放. 这就会导致你在Linux系统中程序频繁读写文件后, 你会发现可用物理内存会很少.

**现在来让 Cached Momory 暴涨**: 找一编译过的 kernel source, 执行:

    # find . -type f -name "*" | xargs cat 1> /dev/null

在另一个 terminal 中通过 `top` 和 `free` 可以看到 cached memory 在急速增长, free(空闲内存)对应地在急速减少.

    top - 17:41:14 up  8:48,  2 users,  load average: 0.96, 0.51, 0.20
    Tasks: 131 total,   1 running, 130 sleeping,   0 stopped,   0 zombie
    Cpu(s):  0.1%us,  0.1%sy,  0.0%ni, 66.8%id, 32.9%wa,  0.0%hi,  0.1%si,  0.0%st
    Mem:   4140288k total,  4121260k used,    19028k free,    72308k buffers
    Swap:  6297472k total,        0k used,  6297472k free,  3746504k cached    ----> here
    
    # free
                 total       used       free     shared    buffers     cached  ----> here
    Mem:       4140288    4118476      21812          0      79232    3738336
    -/+ buffers/cache:     300908    3839380
    Swap:      6297472          0    6297472

缓存内存(Cache Memory)在你需要使用内存的时候会自动释放, 所以你不必担心没有内存可用. 如果你希望手动去释放Cache Memory也是有办法的.

    To free pagecache:
    echo 1 > /proc/sys/vm/drop_caches
    To free dentries and inodes:
    echo 2 > /proc/sys/vm/drop_caches
    To free pagecache, dentries and inodes:
    echo 3 > /proc/sys/vm/drop_caches

执行完毕后, cached memory 还原为小值. 如果你有强迫症, 这会让你很爽. 但实际上, 基本是没有必要手动去释放 cached memory 的.