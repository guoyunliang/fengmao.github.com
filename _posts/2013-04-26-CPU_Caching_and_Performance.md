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
我们知道，在计算机体系结构中，存储器是分级的。不同level的单位bit造价，访问速度以及容量都是不同的。这里简单总结如下：
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
