---
title: systemtap 脚本访问c++对象的成员变量
layout: post
category: scripts
---
<script src="https://google-code-prettify.googlecode.com/svn/loader/run_prettify.js?lang=cc&skin=sunburst"></script>

### 开门见山
最近，用systemtap写了几个单元测试脚本，通过参数控制，基本上能够覆盖绝大部分路径（其实，可以覆盖所有路径的，只是需要时间
来写脚本）。这里不得不说，用systemtap真是一个非常棒的测试工具。我这应该是杀鸡用牛刀了。其实，systemtap 这个利器还有更有
趣的用途。只是，我还没有碰上这样应用场景而已。

在分析leveldb代码的过程中，我想通过systemtap来探测，leveldb在读写的过程中的一些状态以及其变化过程。于是，我写了systemtap
脚本，探测某些关键函数的参数以及返回值。由于leveldb是采用C++语言实现的，函数参数有很多c++对象，例如VersionEdit这类对象。
在systemtap脚本中通过@var("name")$$可以将参数转会字符串，通过printf函数打印出来，观察这些参数。但遗憾的是，VersionEdit
对象中有STL容器对象，我们无法查看STL容器内的东西。某些时候，我们非常希望了解这些容器里的内容。

也许你马上想到，Systemtap不是支持GURU模式嘛，可以嵌入C代码，通过C代码来解析这些容器内容。这个想法是靠谱的。但是，我们
需要明白，linux内核是c语言实现的，是不支持C++代码的，更别说访问C++对象了。那还有没有办法呢? 办法还是有的。这里举栗子，
假设我有如下程序代码：
<pre class="prettyprint lang-cc">
#include <iostream>
#include <vector>
using namespace std;
void test(vector<int>& bar) {
}
int main () {
  vector<int> bar;
  int size = 100;
  for (int i = 0; i < size; ++i) {
    bar.push_back(i + 200);
  }

  test(bar);
  return 0;
}
</pre>

我迫切想知道，test函数的参数bar中的内容是什么。那接下来一步一步告诉你怎么搞吧：

1）写成如下脚本
