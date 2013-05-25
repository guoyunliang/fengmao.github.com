---
title:  读写锁[TOKU]
layout: post
category: code
---

###写在前面

在翻看TOKU的代码的时候，发现TOKU没有使用pthread_rwlock api，而是自己实现了一个读写锁，并解释了为什么不用pthread的，而自己实现。

> TokuDB employs readers/writers locks for the ephemeral locks (e.g.,
>    on FT nodes) Why not just use the toku_pthread_rwlock API?
>  1) we need multiprocess rwlocks (not just multithreaded)
>
>  2) pthread rwlocks are very slow since they entail a system call(about 2000ns on a 2GHz T2500.)
>  Related: We expect the common case to be that the lock is granted
>
>  3) We are willing to employ machine-specific instructions(such as atomic exchange, and mfence, each of which runs in about 10ns.)
>
>  4) We want to guarantee nonstarvation (many rwlock implementations can starve the writers because another reader
>    comes * along before all the other readers have unlocked.)

主要是考虑到pthread_rwlock的性能问题，防止写者饥饿, 以及对这些关键代码作指令级的优化。这种方式还是值得借鉴的，特别是后端服务系统，对于一些调用非常平凡的代码，作一定的优化，是非常值得的。这些调用非常平凡的代码，作哪怕是很少量的优化，那总提上代理的性能提升也是很客观的(可能有不同意见）。
