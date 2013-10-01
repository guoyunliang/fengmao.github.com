---
title:  试用systemtap小记
layout: post
category: scripts
---
<script src="https://google-code-prettify.googlecode.com/svn/loader/run_prettify.js?lang=cc&skin=sunburst"></script>


我是从褚霸的blog上知道systemtap的，随即被这个工具吸引住了。仔细把玩了一阵子，爱不释手~~ 

###前言
关于systemtap是什么，如何安装的问题，我就不多说了。网上有很多资料。
这篇博文记录一个月来学习和使用systemtap过程中的弯路与心得。由于水平有限，我使用systemtap主要探测用户程序的一些问题。
其实，systemtap更像一把手术刀，是探测与剖析内核的利器。遗憾的是，截止目前，我还没有真正用systemtap解决线上问题。但
我相信，随着积累与认知的加深，systemtap会成为解决线上问题的瑞士军刀。过去的一个月里，我主要学习systemtap用户空间的
探测、用该工具用于mock test.

###systemtap用户空间探测
接下来，记录下systemtap在用户空间能干些什么。
####安插static probe
static probe是在应用程序开发的时候插在代码中合适位置的一条宏, 例如：STAP_PROBE1(X, XNAME, Parameter); 其中Parameter
是static probe上下文中的局部变量或者全局变量名（最好插入其地址）。当程序运行后，你想任何时候了解Parameter的值，你都
可以通过systemtap脚本查看，甚至修改该变量的值。举个例子：
<pre class="prettyprint lang-cc">
probe process("your path").mark("XNAME") {
  printf ("Parameter: %s\n", $Paramter$$);
}
</pre>

