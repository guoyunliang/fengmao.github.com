---
title:   Probe Kernel Memory Allocation
layout: post
category: scripts
---

偶然的机会看到stackoverflow上的一个问题，后面列了一个stap脚本，感觉有点意思。这段脚本来着于systemtap邮件组的一个邮件，作者Ross Mikosh。

###Problem

通过/proc/slabinfo 可以看到某些slab增长异常，即将耗尽系统内存。如何找出吃掉内存的真凶？
###Scripts
`
#This script displays the number of given slab allocations and the backtraces leading up to it. 

global slab = @1
global stats, stacks
probe kernel.function("kmem_cache_alloc") {
        if (kernel_string($cachep->name) == slab) {
                stats[execname()] <<< 1
                stacks[execname(),kernel_string($cachep->name),backtrace()] <<< 1
        }   
}
# Exit after 10 seconds
probe timer.ms(10000) { exit () }
probe end {
        printf("Number of %s slab allocations by process\n", slab)
        foreach ([exec] in stats) {
                printf("%s:\t%d\n",exec,@count(stats[exec]))
        }   
        printf("\nBacktrace of processes when allocating\n")
        foreach ([proc,cache,bt] in stacks) {
                printf("Exec: %s Name: %s  Count: %d\n",proc,cache,@count(stacks[proc,cache,bt]))
                print_stack(bt)
                printf("\n-------------------------------------------------------\n\n")
        }
}
`
###Output
