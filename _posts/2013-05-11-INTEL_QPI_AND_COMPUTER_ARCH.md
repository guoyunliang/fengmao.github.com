---
title:   Intel QuickPath Interconnect(QPI)
layout: post
category: linux
---

###文献来源


[Northbridge (computing)](http://en.wikipedia.org/wiki/Northbridge_(computing)) 

[QuickPath Interconnect](http://www.intel.com/content/www/us/en/io/quickpath-technology/quickpath-technology-general.html) 

###QPI简介

<p>
2008年，Intel发布了QuickPath Interconnect技术，用于取代前端总线（FSB)。在本科的体系结构的课上，我们知道计算机的基本架构如下图所示。一个或多个CPU通过一套前端总线连接到北桥上，内存控制器也和北桥连接。各种设备，诸如网卡，硬盘，显卡，通过各种总线挂接在南桥上。南桥和北桥通过桥间总线连接。

<p align=center><img src=/images/2013-05-11/computer-arch.png width=220></p>
</p>

<p>
CPU(s)通过FSB与北桥连接，FSB的带宽与数据传输能力就会成为系统的瓶颈，特别是内存的带宽持续增大的情况下，这种瓶颈就越发明显。Intel发布QPI总线用于CPU与CPU，CPU与内存，CPU与shipset之间的连接总线。QPI是高速point-to-point总线，据Intel公开的资料，QPI总线可提供96G/s的带宽，完全超越了目前内存能够提供的带宽。传统架构中，CPU之间传递数据是需要占用FSB的带宽, 这显然不利于多核CPU并行工作。
</p>

<p>
根据Intel公布的资料，通常CPU内置内存控制器(MC)与QPI技术结合构建计算机系统。相比FSB总线，QPI总线有如下优势:
<ul>
<li>Scalable, high-performance communications.</li>
<li>Outstanding memory performance and fixibility to support leading technologies.</li>
<li>Tightly integrated interconnect reliability, availability, and serviceability (RAS).</li>
<li>Configurations allowing optimal balance of price, performance, and energy efficiency.</li>
</ul>
</p>

###QPI技术与计算机架构

<p>
自从QPI技术发布后，FSB被Intel干掉了。我们就来看看QPI取代FSB后的计算机体系架构吧，先看看单CPU的情况(这里以Intel Xeon E5200举例）。

<p align=center><img src=/images/2013-05-11/one-cpu-arch.gif width=235></p>

从图中我们可以看出，CPU集成了MC，并且CPU与Input/Output Hub(IOH)直接通过QPI连接，取代了FSB总线。
</p>

<p>
接下来，我们看看双CPU的情况。与FSB总线不同的是，多个CPU不是通过共享总线的方式与shipset连接的，而是各自使用独立的总线（QPI）与shipset连接，每个CPU拥有各自的内存。值得注意的是，2个CPU直接也是通过QPI总线连接的，满足CPU之间的数据交换需求。

<p align=center><img src=/images/2013-05-11/two-cpu-arch.gif width=235></p>

</p>
<p>
最后，看看4CPU的情况，与2CPU情况相同，CPU与内存，CPU与CPU直接，CPU与IOH直接均通过QPI总线连接，大大减少了争用总线的情况。

<p align=center><img src=/images/2013-05-11/multi-cpu-arch.gif width=235></p>

</p>
