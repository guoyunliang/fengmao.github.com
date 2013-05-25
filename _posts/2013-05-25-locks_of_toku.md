---
title:  读写锁[TOKU]
layout: post
category: code
---

###写在前面

在流量TOKU的代码的时候，发现TOKU没有使用pthread_rwlock api，而是自己实现了一个读写锁，并解释了为什么不用pthread的，而自己实现。

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
