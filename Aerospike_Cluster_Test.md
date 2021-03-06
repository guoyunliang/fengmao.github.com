## Aerospike 压测
@(CURRENT)[压测][转载请注明出处]
### 概述
我大约是在Aerospike开源后1个月后开始关注它。 查看了其官方介绍，被其描述的性能数据给震撼了。 进一步了解，发现起提供的数据结构完全可以和redis媲美。 抱着好奇的心态去看看，其优点可以借鉴。说实话，其代码可读性不敢恭维。经过断断续续的查看代码，发现它确实有很多有趣的地方，值得仔细分析。趁着元旦放假，来压它一把。


### 压测场景
由于持久化引擎代码还没有看完，今天就只压测Cache集群的场景。将Aerospike集群部署在2个测试机器上，数据保存1份，全在内存中(即Aerospike as Cache)。这是比较典型的Cache场景。

使用YCSB来压测集群。

### 测试机器配置
内存： 192G
SSD磁盘： 500G X 11
CPU: 24cores
网卡：千兆双网卡(负载均衡)

### 部署方式

采用源码编译的方式，将Aerospike部署在两个节点上。作为Cache集群，数据无需落在磁盘上，并且数据只存储1份。

将压测工具YCSB部署在4个相同配置的机器上。压测节点和部署服务节点都在同一个机房。

### 压测数据收集

压测数据主要有2方面，一方面来自YCSB的输出；另一方面，来自aerospike集群的monitor工具收集。将这些数据简单的整理成图表，希望能够直观的呈现压测结果。

安装KV长度，链接数， 读写比例3个维度多次测试，并收集数据。
将YCSB部署在4个测试机器上，每个机器上起一个YCSB instance, 并均分每个链接数。
收集包括，server端CPU利用率，负载(3分钟平均负载)，单机OPS，YCSB输出的平均RT，Server端分别统计到的RT超过1ms，8ms和64ms的请求数的百分比。
####读写比0:1压测

|KV长度(bytes)|链接数|CPU利用率|负载(3min)|单机OPS|读写比例|平均RT(us)| RT>1ms|RT>8ms|RT>64ms|
|:------------|:----:|--------:|---------:|---------:|-------:|-----:|---:|---:|----:|
|           64| 0.5K |<1600%   |<12       |     290K+|     0:1|<400  |<0.27% | 0 | 0 |
|           64|   1K |<1700%   |<15       |     320K+|     0:1|<750  |<2.65% | 0 | 0 |
|           64|   2K |<1800%   |<18       |     330K+|     0:1|<1000 |<7.68% | 0 | 0 |
|          512| 0.5K |<1500%   |<12       |     280K+|     0:1|<450  |<0.22% | 0 | 0 |
|          512|   1K |<1800%   |<15       |     300K+|     0:1|<800  |<2.43% | 0 | 0 |
|          512|   2K |<1900%   |<16       |     320K+|     0:1|<1400 |<14.3% | 0 | 0 |
|         1024| 0.5K |<1000%   |<7        |     190K+|     0:1|<650  |0      | 0 | 0 |
|         1024|   1K |<1100%   |<9        |     190K+|     0:1|<1000 |0      | 0 | 0 |

####读写比1:1压测
|KV长度(bytes)|链接数|CPU利用率|负载(3min)|单机OPS|读写比例|平均RT(us)|RT>1ms|RT>8ms|RT>64ms|
|:------------|:----:|--------:|---------:|---------:|-------:|-----:|---:|---:|----:|
|           64| 0.5K |<1600%   |<14       |     350K+|     1:1|<800  |<0.18% | 0 | 0 |
|           64|   1K |<1800%   |<14       |     360K+|     1:1|<1000 |<1.16% | 0 | 0 |
|           64|   2K |<1900%   |<14       |     400K+|     1:1|<1000 |<5.0%  | 0 | 0 |
|          512| 0.5K |<1600%   |<14       |     320K+|     1:1|<800  |<0.16% | 0 | 0 |
|          512|   1K |<1800%   |<13       |     360K+|     1:1|<1000 |<1.31% | 0 | 0 |
|         1024| 0.5K |<1400%   |<12       |     300K+|     1:1|<800  |<0.06% | 0 | 0 |

 
 
 
