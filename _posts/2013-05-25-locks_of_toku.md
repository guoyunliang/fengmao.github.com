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

主要是考虑到pthread_rwlock的性能问题，防止写者饥饿, 以及对这些关键代码作指令级的优化。这种方式还是值得借鉴的，特别是后端服务系统，对于一些调用非常平凡的代码，作一定的优化，是非常值得的。这些调用非常平凡的代码，作哪怕是很少量的优化，那总体上带来的性能提升也是很客观的(可能有不同意见）。

看看toku_rwlock的数据结构：
Overview：

+ a long mutex field as spin lock;
+ a reader counter;
+ a written boolean;
+ a singly linked list of semaphores for waiting requesters.

而实际代码中是如下定义：
struct rwlock {
  int reader;                  // the number of readers
  int want_read;                // the number of blocked readers
  toku_cond_t wait_read;
  int writer;                  // the number of writers
  int want_write;              // the number of blocked writers
  toku_cond_t wait_write;
  toku_cond_t* wait_users_go_to_zero;
};
这个定义完全满足Overview中关于这个锁定义的描述。

###How it works ?

**To lock a read rwlock**
Toku源代码文件中的Overview:
>1) Acquire the mutex.
>
>2) If the linked list is not empty or the writer boolean is true
>then
>a) initialize your semaphore (to 0),
>b) add your list element to the end of the list (with  rw="read")
>c) release the mutex
>d) wait on the semaphore
>e) when the semaphore release, return success.
>
>3) Otherwise increment the reader count, release the mutex, and return success.

在代码中，其逻辑如下：
1）若writter持有锁，或者有writter在等待锁，则增加want_read计数器, 并且将自己挂在wait_read条件上，等待条件满足；
2）若条件满足，则减少want_read计数器，增加read_count;否则，再次将自己挂在wait_read上（可能其他reader获得了锁）；
3）2）条件满足后，成功持有锁，返回。

可以看出TOKU实现的是写优先锁。

**To unlock a read rwlock**
Overview:
>1) Acquire mutex
>
>2) Decrement reader count
>
>3) If the count is still positive or the list is empty then return success
>
>4) Otherwise (count==zero and the list is nonempty)
>
>  a) If the first element of the list is a reader
>    i) while the first element is a reader
>      x) pop the list
>      y) increment the reader count
>      z) increment the semaphore (releasing it for some waiter)
>   ii) return success
>
>  b) Else if the first element is a writer
>    i) pop the list
>    ii) set writer to true
>    iii) increment the semaphore
>    iv) return success
在其代码中，其逻辑如下：
**To lock a write rwlock**
Overview:
>1) Acquire the mutex
>2) If the list is not empty or the reader count is nonzero
>   a) initialize semaphore
>   b) add to end of list (with rw="write")
>   c) release mutex
>   d) wait on the semaphore
>   e) return success when the semaphore releases
>3) Otherwise set writer=true, release mutex and return success.
