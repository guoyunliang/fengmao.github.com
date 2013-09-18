---
title:  试用systemtap小记
layout: post
category: scripts
---

我是从褚霸的blog上知道systemtap的，随即被这个工具吸引住了。仔细把玩了一阵子，爱不释手~~ 


切入正题。
systemtap 安装就忽略了，网上资料很多，折腾折腾，总会搞定的。systemtap提供了一种监测正在运行程序的方法，可以监测kernel 或者 用户程序。
这就为了解程序运行状态，提供了非常给力的工具。本文主要介绍下用systemtap userspace probe 解掉一个bug的过程。

### BUG描述
在给tair proxy开发有序回包功能的时候，遇到一个bug。所有请求都放在队列中，从队头开始依次回包。可是，在客户端总是能收到一个没有按照既
定顺序的回包。也就是有一种协议请求包并没有按FIFO顺序回包，而其他协议又是按序回包。看了几遍代码，没有发现问题所在。

### 试用systemtap
在使用systemtap之前，我试图通过添加日志等方式，试图找出问题端倪。添加日志后，总是要重新编译，部署，查看日志，过程繁琐，耗时。
于是，给tair proxy布置几个probe就再好不过了。我在tair proxy 的request handler，request进入请求队列处，request收到response处
request 出队列处，给客户端发送response处添加了probe。

接下来，就是写systemtap脚本了。根据每一个probe处的情况，将相关变量打处理（暴力了，可以选择需要的变量打印出来）。在不杀
tair proxy进程的情况下，就可以获取各个probe处的相关变量值。

接下来，我在发送response处的probe 打印出变量发现: request对象的ipacket 和 opacket都为null. 找到我们代码中显示将这值赋值为null
的地方也加一个probe, 并且在这个probe的handler里将调用堆栈打印出来，这样我就能知道谁将其赋值为null了。

再次运行脚本，发现没有堆栈打出。那肯定不是我们代码将ipacket赋值为null, 那只能是libeasy干的了。libeasy只有在发出response后会这么做。

根据这个线索，终于找到了bug:  原来，正常情况，tair proxy的request handler将请求放入一个队列，并且向ds异步发出请求，截止检查request->opacket值，
根据请情况返回easy_ok或者easy_again。这个过程是handler线程执行的，接着在另外一个线程中执行上述异步请求的callback。在callback中将从ds拿到的值，
创建response挂在request->opacket上。接着是一个回包过程，检查队首request是否可回包，回包，直到对首request不可回包为止。
而有种协议，没有是同步完成的，也就是说在handler的线程中request->opacket就不为null了。 然后handler直接向libeasy返回easy_ok，
就变成了同步回包了。而此时request还在队列里，等待回包~~ 

###小结
上述bug使用debug或者日志，可能也能找到，但是只是比较繁琐了。使用systemtap就比较方便，你可以对正在运行的系统任何一处设置监测点。
可以方便获取全局的，局部的变量，设置修改变量值。重要的是，你可以根据请情况，随时修改你的脚本，干你想干的。
