---
title: OpenNebula架构浅析
layout: post
category: coding
tags: opennebula cloud ruby java occi ssh
---

OpenNebula是当下流行的云计算平台之一。  
我一直在想，这种云计算平台的核心技术是什么？现在看来，其核心功能是提供统一的、单一的操作界面，现在的人越来越懒，利用这个界面，便可以管理物理集群，管理所有虚拟资源。  
因此，OpenNebula等**没有核心技术**，它们采用的虚拟化技术（如KVM、XEN、LXC）都是现成的。  
或者说，OpenNebula等的核心技术/竞争力在于其框架是否简单、可靠、易扩展。  

总概OpenNebula，它在管理节点上维护各种数据库表，并利用ssh执行远端命令。  

###物理结构

OpenNebula系统的物理结构：  
![](http://opennebula.org/_media/documentation:rel3.4:one_high.png)  

frontend上安装和运行着OpenNebula，Hosts和Datastores不需要特别安装什么，只需要满足（1）ssh可连；（2）Hosts上hypervisor正常；（3）Ruby>1.8.7(用以执行某些脚本吧，就像执行shell脚本一样)。  

###frontend

貌似OpenNebula简称为ONE。ONE有两种操作界面：web和cli。  
能提供cli是值得表扬的，虽然OpenStack等类似平台也很可能提供有cli。因为cli是很方便脚本化的，对测试等很有用。  

这里仅说web。  
ONE的web server是sunstone，启动之后，便可以通过http://localhost:9869之类的访问web页面。  

页面请求可分为两种：GET和POST。GET请求数据，如查看vm列表。POST发起命令，如创建新的vm。  
使用ONE 3.8.1的代码，以创建vm为例，简介ONE的架构。（需要运转大脑＋什么东西都“略懂”一些，才能顺利完成这个过程）。  

1、chrome页面，F12启动DeveloperTools。创建vm的连接对应名字“VM.create_dialog”。  
2、点击弹出JS悬浮框，`find . -type f -name "*.js" | xargs grep -n "VM.create_dialog"`，找到需要执行“Sunstone.runAction("VM.create",vm);”。  
3、找到src/sunstone/public/js/sunstone.js。  
4、找到src/sunstone/public/js/opennebula.js，在"create": function(...)部分发出HTTP POST请求，ajax形式的，数据传递使用json。  

上面还在前端，下面开始进入web服务器流程。  

5、sunstone是ruby脚本，它采用的web server是[Sinatra](http://www.sinatrarb.com/)，sunstone-server.rb指定了POST的响应函数，是“@SunstoneServer.perform_action(...)”。  
6、perform_action@SunstoneServer.rb。  
7、perform_action@VirtualMachineJSON.rb，找不到create，就看deploy吧。  
8、super.deploy，也就是VirtualMachine.deploy，位于src/oca/ruby/OpenNebula/VirtualMachine.rb。oca是OpenNebula Cloud API的缩写，据此可以感受到ONE的架构逻辑。  
9、发起xmlrpc调用：“@client.call(VM_METHODS[:deploy], @pe_id, host_id.to_i)”。注意，这是**本地xmlrpc调用**，endpoint是“http://localhost:2633/RPC2”。  

上面是web server部分：收到request，识别，继续调用底层功能。  
下面是底层功能，cli和web应该在这里开始“汇合”。  

10、xmlrpc server在哪里启动？这个找起来有点蛋疼，它在src/rm/RequestManager.cc里面，是CPP代码，IP设置为INADDR_ANY，端口在oned.conf里配置为2633。  
11、后面的流程基本上同下图：  
![](/images/one_request_sched.jpg)  

###架构  

上面已经说到了request处理的架构，其中流程图摘自博文“[opennebula action调度流程图](http://blog.chinaunix.net/uid-20940095-id-3426882.html)”。  
此网友还有一篇博文“[opennebula源码分析之框架分析](http://blog.chinaunix.net/uid-20940095-id-3304443.html)”，这两篇对我的帮助很大，使我一天左右就了解了ONE的大体架构，在此表达感谢！  

要支持上面的操作，需要启动一些后台进程(线程)，不做描述，仅列出示意图(仍摘自上面网友的博文)。  
![](/images/one_oned.png)  

![](/images/one_process_pipe.png)  

![](/images/one_create_vm.png)  

两个有意思的点：  
1、ONE是个大系统，它调用很多其他的功能，很多不是通过API调用的，而是通过脚本创建新进程。于是需要进程间通信，对此ONE使用pipe，参考上图。  
2、在OpenNebula页面上增加新功能，后台可以选择增强sunstone+oned，也可以另起一个Server（比如JettyServer）。  

###virsh save的流程

如果你用的是OpenNebula的不同版本，对你来说上面的流程图是不准确的，但仍然有用，比如用作理解的线索。  
我又走了一遍虚拟机save操作的流程，现在对OpenNebula的理解是：  
1、它使用了很多脚本，但是对脚本执行做了非常精细的控制。  
2、代码流程很绕，不知是否绝对必要...  

虚拟机save的流程大致是：  

1. 选中虚机，点击“save”按钮；
1. js找到执行的是VM.stop；
1. @client.call(VM_METHODS[:vm.action], "stop", ...);
1. (local xmlrpc call)
1. xmlrpc server，VirtualMachineAction::request_execute();
1. DispatchManager::stop();
1. LifeCycleManager::trigger(stop);
1. ActionManager::trigger(stop);
1. (ActionRequest放入am的队列actions中...)
1. ActionListener从队列里取，这里实际上执行子类LifeCycleMananger::do_action(stop);
1. vmm.trigger(VirtualMachineManager::SAVE); => 这里是一个stop->save的转换！
1. (ActionRequest放入am的队列actions中...)
1. ActionListener的子类vmm.do_action(save);
1. vmm.save_action();
1. vmd.save();
1. write_drv()写nebula_mad_pipe;
1. MadListener从pipe的另一端ne_mad_pipe[0]取，然后execlp(executable)，执行one_vmm_exec;
1. one_vmm_exec.rb;
1. do_action@OpenNebulaDriver.rb;
1. RemoteCommand.run();
1. 将/var/remotes/vmm/kvm/save脚本传到host上，并执行；
1. 执行结果大致原路返回；