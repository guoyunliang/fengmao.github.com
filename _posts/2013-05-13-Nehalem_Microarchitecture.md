---
title:   Nehalem(microarchitecture)
layout: post
category: linux
---

###文献来源


[Nehalem, wiki](http://en.wikipedia.org/wiki/Nehalem_(microarchitecture)) 

[Inside Nehalem](http://www.realworldtech.com/nehalem/) 

[Inside Nehalem, overview](http://www.notur.no/notur2009/files/semin.pdf) 

###Nehalem
2007年，Intel公司发布的一种CPU微架构, 命名为Nehalem。该微内架构由如下特征(来自wiki, 见上述文献来源):

<ul>
<li> 采用超线程技术; </li>
<li> 4-12M的L3 Cache; </li>
<li> 两级分支预测器(branch predictor) 和 两级TLB;</li>
<li> Native quad- and octa-core processors; </li>
<li> 采用QPI总线替代FSB总线方案;</li>
<li> 每一个core拥有64K的L1 cache (32KB L1 D-chache, 32KB L1 I-cahce), 256K的L2 Cache; </li>
<li> 集成PCI Express 和 DMI; </li>
<li> 集成内存控制器(MC), 支持多通道内存访问; </li>
<li> 2nd Intel VT技术(？); </li>
</ul>

###Nehalem Processor指令执行流程

Nehalem执行的是Intel64 ISA 微指令(macro-instructions)。从宏观上讲，CPU执行macro-instruction大概需要如下过程:
<ul>
<li>Fetch, 从内存中读取若干指令（并非一条一条的读取)到CPU;</li>
<li>Decode, 将读入的macro-instructions 解码为微操作(macro-operation);</li>
<li>Buffer, 将macro-operations存储在适当的地方, 准备进入out-of-order pipeline；</li>
<li>Dispatching, 当macro-operation的操作数准备好后，就讲微操作分发到合适的port; </li>
<li>Retire, 等待macro-operation执行完成，并且将结果写入适当的存储器中。</li>
</ul>
Nehalem Processor采用pipeline的方式执行微操作。CPU 每次读取一批微指令，并转换为微操作，将微操作分发到不同的功能单元（FU), 最大限度的利用所有FU。像其他CPU一样，Nehalem也采用来分支预测技术来提高FU的利用率，使得每个机器指令能够执行更多指令。

###Nehalem Processor Chip Overview

采用Nehalem架构的CPU，在Chip上可以部署多个core, 并且整个Chip可以在逻辑上划分为2个区域——cores 和 un-cores; 其中cores区域中部署来1个到多个独立的core, uncores区域部署来集成内存控制器(IMC），QPI总线，L3 Cache, 电源管理单元，性能监控模块等其他一些功能模块或接口。Nehalem CPU支持DDR3 内存，每一个core直接与内存连接，而非通过FBS或者其他共享总线连接。在这样情况下，单个core可获得7.998G/s的带宽。Nehalem Processor Chip的部署图如下所示：

<p align=center><img src=/images/2013-05-13/nehalem_processor_chip.png width=500> </p>

我的重点是搞清楚每一个core的内部情况，先上一张core的逻辑框图，如下所示：

<p align=center><img src=/images/2013-05-13/nehalem_core_arch.png width=650> </p>

接下来依次分析，上述逻辑框图中的每一个区域，试图高清楚core的工作状况。

###Nehalem Core Pipelie








