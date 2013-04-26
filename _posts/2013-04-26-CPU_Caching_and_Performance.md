---
title:   CPU Caching and Performance
layout: post
category: linux
---



[Understanding CPU Caching and Performance](http://www.hesit.be/files/info/2/1101153620-Caching.pdf) 这篇文章写的挺好的，值得阅读。
文章把以下几个问题用图文并茂的方式说明的很清楚, 这里借鉴作者的图片。</p>

###CPU为什么需要Cache
这是个众所周知的问题，我还是将作者的图片贴上来，相当直观的。
![alt CPU Clock](/images/cpu_clock.png)

###存储器层级结构
我们知道，在计算机体系结构中，存储器是分级的。不同level的单位bit造价，访问速度以及容量都是不同的。这里简单总结下每个level的特征：
<ul>
<li> Registers,  Assess Time: 1~3 ns, Technlogy: Custom CMOS, Managed By: Compiler. </li>
<li> Level 1 Cache,  Assess Time: 2~8 ns, Technlogy: SRAM, Managed By: Hardware. </li>
<li> Level 2 Cache,  Assess Time: 5~12 ns, Technlogy: SRAM, Managed By: Hardware. </li>
<li> Main Memory,  Assess Time: 10~60 ns, Technlogy: DRAM, Managed By: Operating System. </li>
<li> HardDisk
     <ul>
     <li> HHD </li>
     <li> SSD </li>
     </ul>
</li>
</ul>

### Cache Associativity
将Main Memory 按Cache line划分为多个Block, 也就是说Main Memory中的block的大小和Cache line是相同的。每次从MM中读取数据都是，整个block的读到Cache中，填充为1个cache line。那么，这里就存在一个MM的Block与Cache line 映射的问题。

__1)__ Fully Associative
简而言之，内存中任何一个block可以映射到Cache中的任何一个block。优点是简单明了，缺点是需要很长的一个tag, 并且每次确定是否cache命中，需要和Cache中的每一个cache line作比较。
Memory Address: [Tag, Offset] 通过Tag来确定所访问的内存是否在Cache中。

![alt fully associative](/images/2013-04-26/fully_associative.png)

__2)__ Direct Mapped
由于Fully Associative需要作大量比较运算，并且硬件电路实现也有限制，于是变通一下。将MM中的一个block set映射到某一条固定的cache line, 其他的block set映射到其他的cache line。在这种情况下，CPU判断某个数据是否在cache中，无需比较每一个cache line, 从而简化电路的实现。
Memory Address: [Tag, Index, Offset], Index来确定block在哪一个cache line, 存在多个block映射到一个cache来，Tag用来确定block是否在cache line.

![alt direct mapped](/images/2013-04-26/direct_mapped.png)

__3)__ N-way Set Associative
Direct Mapped映射策略仍然有缺点，会产生所谓的conflict misses, 增加 cache misses，于是N-way Set Associative策略出现了，该策略是Fally Associative 和 Direct Mapped策略的一个折中，将Cache line分成多个set, block映射到这个set的时候，可以填充到set中的任何一个cache line, 而不局限于某一个cache line。明显，折中方式更为灵活。
Memory Address: [Tag, Index, Offset], Index 判断block映射在那个set, Tag 确定具体的block是否在set，以及在set的那个line。

![alt N-way Set Associative](/images/2013-04-26/n-way_set_associative.png)
 
总结下，实际上Flly Associative 策略是1-way set associative, 而Direct Mapped是m-way set associative策略。
