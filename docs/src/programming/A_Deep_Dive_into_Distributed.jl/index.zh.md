# 深入理解Julia中的Distributed.jl标准库

```@blog_meta
last_update="2021-08-20"
create="2021-08-20"
tags=["分布式", "Julia", "并行计算"]
```

[Distributed.jl](https://docs.julialang.org/en/v1/stdlib/Distributed/)是Julia中的一个标准库，基于多进程进行分布式
计算。在官方（[中文](https://docs.juliacn.com/latest/manual/distributed-computing/)）[文
档](https://docs.julialang.org/en/v1/manual/distributed-computing/)中，有专门的一章对此做了详细的讲解，如果你从未使用过
这个库的话，建议先读下官方文档。这里我将着重从这个库的设计和代码实现层面进行深入讲解，并在最后提供一个迷你版的实现。

## `Distributed.jl` 的启动流程

```
                              +----------+
                        +---->+ Worker_1 |
                        |     +----------+
+-----------------+     |     
| ClusterManager  +-----+        ......
+-----------------+     |
                        |     +----------+
                        +---->+ Worker_N |
                              +----------+

```

如上图所示，`Distributed.jl`的基本思路是，主节点上先构造一个
[ClusterManager](https://docs.julialang.org/en/v1/manual/distributed-computing/#ClusterManagers)
然后在各个子节点上构造worker进程，相互之间通过cookie（一段固定长度的随机字符串）确认身份。所有worker的信息都在
`ClusterManager`中有记录，包括IP、端口等。有了这些这些信息之后，剩下的就是约定如何通信了，`Distributed.jl`中使用了
[Serialization.jl](https://docs.julialang.org/en/v1/stdlib/Serialization/)标准库来实现序列化和反序列化。此外，还提供了一
些常用的宏（`@everywhere`, `@spawn`）和远程对象(`Future`, `RemoteChannel`)来屏蔽一些底层的操作。

整体流程看起来比较清晰


启动的过程中，首先会创建一个
[ClusterManager](https://docs.julialang.org/en/v1/manual/distributed-computing/#ClusterManagers)对象，该对象负责在本地或
者其它机器上创建多个子进程，维护子进程的连接信息。这个库原生提供了两个`ClusterManager`的实现，`LocalManager`和
`SSHManager`。接下来以`LocalManager`为例，来分析完整的`Distributed.jl`启动流程。

在本机启动多进程可以直接在运行`julia`时通过指定参数`-p auto`实现，或者在进入REPL之后，运行`using Distributed`，然后调用
`addprocs`函数实现。其中关键的函数调用栈如下：

- `addprocs`
  - `init_multi`
    - `init_bind_addr`，配置当前进程绑定的IP和端口信息
    - `cluster_cookie`，设置与其它进程通信用的cookie，确保后面不会连接到其它不认识的进程上了
  - `launch`


```@comment
```
