---
title:   Nehalem(microarchitecture)
layout: post
category: linux
---

###文献来源


[Nehalem, wiki](http://en.wikipedia.org/wiki/Nehalem_(microarchitecture) ) 

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

###Nehalem Instruction Decode & Macrocode

Nehalem架构的一个关键组件，称为前端流水线(Front-End Pipeline, FEP)。该流水线用于微指令解码为微操作, 采用in-order方式工作，一个cycle能够decode 4个微指令。FEP整个工作需要其他组件协同完成。这些组件包括指令预取单元(Instruction Fetch Unit, IFU), 分支预测单元(Branch-Prediction Unit, BPU), 预解码器（Instruction Length Decoder, ILD), Instruction Queue, 指令解码器(Instruction Decoding Unit)，以及一些基础存储组件TLB，L1 Cache等。接下来依次认识这些组件，了解其功能。


<p align=center><img src=/images/2013-05-13/front_end_pipeline.png width=706> </p>

**Instruction Fetch Unit(IFU)**

IFU从L1 Instruction Cache 或者 指令预取缓存(Instruction pre-fetch buffers)中读取指令，每个cycle读取16byte的指令。

**Branch-Prediction Unit(BPU)**
<p>
对于采用流水线方式执行的CPU来说，分支预测技术带来的好处是，如果分支预测正确(至少50%的正确率), pipeline无需等待，直接执行，即便预测错了，就取消pipeline上正在执行的任务。在预测错误的情况下，和没有分支预测功能是一样的，那添加一个分支预测单元显然是非常合理的事情了。

Nehalem的BPU可以为以下几种指令作分支预测：
</p>

+ direct alls/jumps;
+ indirect calls/jumps;
+ conditional branches;

BPU采用以下几种技术来提高预测准确率(这3条机制，我目前还不明白）：

+ 增加Branch Target Buffer的容量（这里为什么能够增加分支预测准确率，我不明白啊）
+ 使用Return Stack Buffer来预测RET指令；
+ 使用Front-End Queue。

**Instruction Length Decoder(ILD, or Pre-Decoder)**

我更愿意接受TLD的名称为Pre-Decoder, 因为它的作用就是对指令作预处理工作，其输出为Decoder的输入。主要作如下工作：

+ 确定指令size;
+ 解码指令的前缀;
+ 确定某些指令的一些熟悉，例如该指令是一条分支预测指令;

Pre-Coder每个cycle能够处理6条指令，并将预处理的指令放入Instruction Queue(IQ), 等待decoder来读取。 IQ是一个指令缓存，起承接作用，作为Precoder的输出目的地，作为decoder的输入源。

**Instruction Decoding Unit(IDU)**

IDU拥有4个decoder, 其中3个只能够解码simple instruction, 1个用户解码complex instruction。IDU的输入是macro-instructions, 输出是macro-operations, 输出目的缓存为Instruction Decoder Queue(IDQ)。IDU拥有循环检测功能。

###Out-of-order Execution Engine(EE)

Nehalem 配备了指令无序执行引擎。EE的首要目标是保证指令执行结果正确的情况下，最大化单位cycle内执行的macro-ops数量，以及最大化通过FU的指令流。Nehalem的EE有6个port, 最多支持128 条macro-ops上流水线，每个时钟周期有4条macro-ops会产生结果。macro-ops执行产生的结果采用write-back策略。Nehalem的EE由Register Rename and Allocation Unit(RRAU), Reorder Buffer(ROB), Unified Reservation Station(URS), Memory Order Buffer(MOB)和Execution Units and Operand Forwarding Network（EUOFN)构成。EE的逻辑框图如下所示。

<p align=center><img src=/images/2013-05-13/execution_engine.png width=800> </p>

**Register Rename and Allocation Unit(RRAU)**
RRAU为macro-ops准备资源，分配port, 以及其他准备工作:

+ 分配资源:
  <ul>
  <li>an entry of ROB</li>
  <li>an entry of RS</li>
  <li>a load/store buffer</li>
  </ul>
+ 将macro-op绑定到特点port;
+ 重命名寄存器，消除伪数据相关性, 将Architected Registers映射到Unarchitected Register上，释放Architected Registers。
+ 为macro-op提供立即数或者寄存器数据。

**Unified Reservation Station(URS)**

URS是一个拥有36entry的Queue，用于存储操作数还没有到位的macro-ops。由于操作数没有到位，不能上流水线执行。也就是说，在任何时候，不超过36macro-ops等待进入流水线执行。每一个时钟周期里，URS的调度器会最多选择6条macro-ops放入相应的port，进入流水线，并且最多有4条指令可以讲结果写入RS或者写入ROB。当macro-op的操作数准备好后，根据各个port的情况，选择合适的port，将macro-op投入到流水线。

**Reorder Buffer(ROB)**

ROB是EE的一个关键组件，其主要功能是保证out-of-order的方式执行指令产生的结果正确性。也就是说，ROB保证了乱序执行指令后产生的结果与非乱序方式产生的结果一样。Nehalem的ROB 有128entry, 因此可以最多支持128条maro-ops进入流水线。

**Memory Order Buffer(MOB)**

MOB确保macro-op执行完成后的结果以正确的顺序，正确的内容写入存储器。

**Execution Units and Operand Forwarding Network（EUOFN)**

Nehalem的EU是全pipeline方式工作的，每一个EU输出结果最多不超过1个cycle的延迟。EU从ROB或者寄存器获取数据。当某些macro-op等待数据的时候，可以让其他已经就绪的macro-op执行，提高整体效率。

###Nehalem的Cache 子系统

**Cache Hierarchy**

Nehalem Processor集成内存控制器，直接与DDR3内存连接。其内存与Core内部的寄存器直接有3级Cache，其中L1 Cache，L2 Cache是每个core私有的，L3Cache是多个core共享的。这里简单描述下每一级Cache吧：

+ L1 Cache, L1 Cache 由独立的instruction cache和data cache构成，均32KB, 单通道，block size 为64B. Instruction Cache是4-way set associative Cache， Data Cache是8-way set associate Cache。从L1 Cache读取数据需要4 clocks, 写入需要1 clock.
+ L2 Cache，256KB，8-way set associative, 可存储数据或者指令；block size 为64B. 读取数据需要10 clocks, 数据写入高一级存储器采用write-back策略。
+ L3 Cache, 16-way set associative, 8MB。不同于L1，L2 Cache，L3 Cache是包含式Cache(inclusive cache), 访问延迟35~40+ clocks。

这里需要注意的是，L3 Cache是Inclusive方式的，这样设计的好处是减少core之间不必要的数据探测（实现cache一致性协议相关）。如果某个block不在L3 Cache，那么该数据肯定不在core的L1，L2 Cache中。下图是一个Nehalem Processor的Cache层级示意图：

<p align=center><img src=/images/2013-05-13/cache_hierarchy.png width=200> </p>

**Memory Access Enhancements**

为增强Nehalem Core访问数据的性能，每个Core的L1 Cache与寄存器之间部署了load/store buffer 来减少数据到L1 Cache的延迟，作为一个临时数据存放点。为了保证数据的一致性，当出现中断或异常，I/O指令，LOCK指令，BINIT操作（？），SFENCE/MFENCE instruction的时候，store buffer的数据必须写入L1 Cache。

**Cache一致性**

Nehalem Cache 采用MESIF协议来维护socket内部各个core的local cache ，主存 和 其他socket的Cache之间的数据一致性。通过MSEIF协议，任何一个processor的任何一个core所看到的主存中的数据是一致的。

> MESI协议是经典的Cache 一致性协议，属于write-invalidate, snoopy类型的。write-invalidate是指当处于Share状态的block被修改时，其他的copy全部转变为Invalid状态。各个core通过监听MC总线来确定自己cache里的某个处于Share状态的block被修改。

MESIF协议属于write-invalidate, snoopy(但是具备directory-based协议的熟悉）类型一致性协议。其directory-based属性体现在，每个block有C位数（C与core的数量相等），每一位用于标记该block是否在对应的core的cache中。初始状态，Cache中不存在任何block, 那么cache中的block属于Invalid状态。当有core读取该block数据的时候，会出现read miss。接着数据从内存读取，填充到对应的多级Cache, 这个过程成为cache-line fill。首次被某个core读到cache的block，其状态为Exclusive。若该block被多个core读取到local cache, 该block的状态变为Share。若处于Share状态的block被某个core修改，该core会通过一个Request for Ownership动作，使该block在其他core local cache中全部失效。很明显，处于Exclusive状态的block是不会触发Requst-for-Ownership动作的。

Nehalem processor可以监听其他processor写主存事件。通过监听这一事件，processor调整local cache中block的状态，来确保processor的local cache 与主存，processor 与 processor之间的数据一致性。

Nehalem Core监听到其他processor试图去写一个block, 而该block处于该core的local cache中，并且处于Share状态，那么该core直接失效掉该block。下一次将会读取新的数据。若某个block处于Modify状态, 且没有write-back（显然在该block在其他core中处于Invalid状态），而其他core到内存中去读这个block(此时，内存中的block已是脏数据），拥有block Modify 状态的core发出一个信号给请求block的core, 并将modify的block发送给它。这个信号会被MC监听到，并且将数据写入到主存。此时，block处于Share状态。

> Nehalem Cache采用LRU算法淘汰block。LRU在软硬领域都可见呀。

MESI协议本身也可解决多sockets之间的数据一致性问题。Intel为了减少不必要的数据传输(减少内存带宽)，对处于Share状态的block作来区分。一个block在多个local cache中共享，该block在唯一一个cache中标记为Forward状态，其它的都标记为Shared状态。并规定只有Forward的block可以发送给block请求这者。

这里有还有2个问题需要补充：

<ul><li>包含式L3 Cache对cache一致性问题的影响？</li>
<li>每个block的核心确认位如何是如何被使用的？</li></ul>

**Global Queue**

Nehalem架构中，processor被划分为core和uncore两个区域。Global Queue是处于uncore区域的一个队列，该队列的目的是暂存数据的。Global Queue位于L2 Cache 与 L3 Cache之间的区域，见下图。

<p align=center><img src=/images/2013-05-13/nehalem_on_chip_memory_hierarchy.png width=636> </p>

实际上, GQ由3个子队列组成：

+ Write Queue, 16-entry, 缓存由local core发出的block；
+ Load Queue, 32-entry, 缓存从L3 Cache或者Memory 中读取的block;
+ QPI Queue，12-entry，缓存透过QPI输入或输出的block;

**TLB**
<p>
可执行程序拥有一个逻辑地址空间，操作系统根据逻辑地址来确定程序所需要的数据（代码或数据）。通常，数据是按照page的方式来组织起来的，page的大小有4KB,2MB,甚至1GB。物理内存也被按照page的尺寸划分为一块一块的，每一块称为一个frame。理论上，可执行程序中的任何一个page可以映射到物理内存中的任何一个frame中。这个映射过程，由操作系统负载完成。
</p>

<p>
可执行程序若要访问一个page中的内容（用逻辑地址标示），操作系统根据逻辑地址，以及其维护的映射关系，计算出该逻辑地址对应的数据所存储单元的物理地址，CPU根据物理地址访问对应的数据。通常，操作系统采用分级页表的办法来维护逻辑地址到物理地址的映射。逻辑地址到物理地址的转换，可能需要多次内存访问。
</p>

<p>
为了加快这个转换过程，CPU增加了TLB这样一个缓存设备。对于Nehalem 架构的CPU而言，扩展了TLB，采用2级TLB。通常，可执行程序的数据和指令是分开存储的。为了更好的使用数据（代码）局部性原理，TLB0 分为DTLB0和ITLB0，前者用于访问数据时候加快虚拟地址到物理地址的转换，后者用于访问代码时候加快虚拟地址到逻辑地址的转换过程。
</p>

<p>
TLB1没有对数据和指令作划分。
</p>
