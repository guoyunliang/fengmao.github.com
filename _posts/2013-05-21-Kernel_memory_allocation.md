---
title:  Probe Kernel Memory Allocation
layout: post
category: scripts
---

###Problem

<script src="https://google-code-prettify.googlecode.com/svn/loader/run_prettify.js?lang=cc&skin=sunburst"></script>
<pre class="prettyprint">
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
</pre>

###Output
