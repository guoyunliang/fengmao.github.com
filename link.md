CPUs
====

You can insert a table of contents using the marker `[TOC]`:

[TOC]

### CPU related-concepts

#### Clock Rate [时钟频率]
正常工作的CPU是通过称之为时钟的信号来驱动，并且在一定的时钟频率下工作。每一CPU指令需要花费一个或者多个时钟周期，称之为 CPU-cycles。

时钟频率是一个CPU主要指标之一，频率越高，说明单位时间内执行的指令数越多。但是，提高时钟频率并不一定能够提升CPU性能。若CPU大部分时钟周期都是stall cycle (访问内存而引发的等待), 高的时钟频率并没有增加指令执行速度。

#### Instruction [指令]
执行一条指令通常会包含如下步骤：
> 1. Instruction fetch;
> 2. Instruction decode;
> 3. Execute;
> 4. Memory access (optional);
> 5. Register write-back(optional);

前三个步骤是必须的，后两个步骤是可选的。每一个步骤通常需要至少1个CPU cycle. 访问内存是最耗时的步骤，在访问内存期间，CPU消耗的时钟周期（必须消耗）称为stall cycles.

#### Instruction Pipeline [指令流水线]
指令流水线是指CPU能够并行执行CPU指令，通常是并行的执行的指令的不同步骤在CPU的不同执行单元上同时执行；

#### Instruction Width[指令宽度?]
指令宽度通常指一个CPU可以同时让指令on-fly的数量。

#### CPI (Cycles per instruction)
这是CPU的一个非常重要的指标，单位指令所需的时钟周期数。CPI越高，说明这个CPU消耗了越多的Stall cycles. 通常执行内存密集型任务时CPU的CPI会比较高。

#### Utilization [利用率]
CPU的利用率通过CPU执行指令时间占总时间的百分比。通常，CPU利用率高，并不是问题，只能说明CPU正在干活。

### CPU Architecture

#### Processor Components
CPU的硬件包含处理器(processor)以及子系统. 一个典型的2-cores处理器的架构图如下所示：

![generic 2-core processor components ][1]

其中Control Logic是CPU的核心组件，执行指令的若干步骤都是在该组件上完成的。

和CPU性能相关的组件(图中未标示)还包括：
* P-Cache: prefetch cache
* W-Cache: write cache
* Clock
* Timpstamp Counter : 高分辨率时间戳计数器
* Microcode ROM: 将指令转换为集成电路信号
* Temperature Sensors: 温度传感器？
* Network Interface

#### CPU Caches hierarchy
CPU的存储层级结构，数据在Cache以及Main Memory之间流动。
![Cache hierarchy][2]

Level1 Cache 通常分为Instruction Cache & Data Cache 保存的是虚拟地址; 在图中在MMU组件左边，使用的是虚拟地址，右边使用的物理地址。


#### MMU
MMU组件的功能是将物理地址转为为虚拟地址。一个典型的MMU组件结构图如下：

![MMU][3]

#### CPU Performance Counters
CPU性能计数器？ 是CPU的一组内部寄存器，记录CPU底层的一些事件发生的次数，这些计数器通常包括：

*  CPU cycles: 包含stall cycles 以及其类型；
*  CPU instructions: 已经执行完成的指令数;
*  Level 1,2,3 cache accesses:  hits & misses;
*  Floating-point unit: 浮点运算单元执行次数；
*  Memory I/O: read/write & stall cycles;

### Software

#### Scheduler (LINUX)
Scheduler Classes:
* RT
* O(1)
* CFS

Scheduler policies
* RR
* FIFO
* NORMAL
* BATCH

#### Idle Thread
Idle 线程是系统中一个特殊线程，具有最低的优先级的线程。当没有其他任何线程要执行的时候，该线程将On-CPU, 执行halt instruction, 或者是该CPU睡眠，并且在下一次硬件中断时候唤醒。

#### NUMA-Grouping


### 性能调优之CPU方法学 (Methodology)

这些调优方法通常包含：

* Tools Method;
* USE method.
* Workload characterization;
* Profiling;
* Cycle analysis;
* Performance monitoring;
* Static performance tuning;
* Priority tuning;
* Resource countols;
* CPU binding;
* Micro-benchmarking;
* Scaling;

#### Tools Method
这是最简单的方法，常被人使用。通过使用一些工具，收集一些数据，观测CPU性能状况。实际上，这种收集数据的过程本身也是需要消耗一些CPU性能的。

通常这些工具包括：

* uptime
* vmstat
* mpstat
* top/prstat
* pidstat/prstat
* perf/dtrace/stap/oprofile
* perf/cpustat

#### USE Method
USE是一种有效地分析系统性能的方法，通过构造一个check list，快速地辨别出任何系统瓶颈所在。更多内容请在[这里][l1]。该访问法可以用于检查CPU是否成为系统瓶颈，为此这个check list包含三个部分内容：

* Utilization: 检查资源的使用情况；
* Staturation: 检查等待CPU情况；
* Errors: CPU errors

关于USE方法，还有很多可深挖的东西。

[1]: http://i.imgur.com/8odJj2C.jpg
[2]: http://i.imgur.com/BxQanlA.jpg
[3]: http://i.imgur.com/sJ8YwIb.jpg
[l1]: http://www.brendangregg.com/usemethod.html
