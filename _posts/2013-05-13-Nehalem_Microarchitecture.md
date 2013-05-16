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

