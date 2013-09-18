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
定顺序的回包。
