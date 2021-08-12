---
keywords: ParallelComputing,Julia
CJKmainfont: KaiTi
---

# 自底向上理解Julia中的并行计算

最近看到一些有关Julia并行计算的提问，所以这里不妨开个头，介绍下Julia中并行计算的实现，希望能有更多人能参与进来一起讨论。在Julia文档中，有专门的一部分讲解[Parallel Computing](https://docs.julialang.org/en/stable/manual/parallel-computing/)(中文翻译见[并行计算](http://docs.juliacn.com/latest/manual/parallel-computing/))，采用的是一种Top-Down的方式分别介绍了协程、多线程及分布式处理。这里我打算采用一种Bottom-Up的方式来介绍下Julia中的并行计算，建议先读完官方文档后继续往下看。

## 几个基本概念

### `Task`

顾名思义，`Task`就是构造一段执行任务，`Task`的定义在[task.c](https://github.com/JuliaLang/julia/blob/master/src/task.c)文件中，不过作为使用者，我们更关心的是调用接口：

```julia
julia> methods(Task)
# 1 method for generic function "(::Type)":
[1] Task(f) in Core at boot.jl:377

julia> methodswith(Task)
[1] bind(c::Channel, task::Task) in Base at channels.jl:191
[2] serialize(s::Serialization.AbstractSerializer, t::Task) in Serialization at /buildworker/worker/package_linux64/build/usr/share/julia/stdlib/v1.0/Serialization/src/Serialization.jl:427
[3] fetch(t::Task) in Base at task.jl:202
[4] istaskdone(t::Task) in Base at task.jl:117
[5] istaskstarted(t::Task) in Base at task.jl:134
[6] schedule(t::Task) in Base at event.jl:95
[7] schedule(t::Task, arg) in Base at event.jl:129
[8] show(io::IO, ::MIME{Symbol("text/plain")}, t::Task) in Base at show.jl:150
[9] show(io::IO, t::Task) in Base at task.jl:58
[10] wait(t::Task) in Base at task.jl:182
[11] yield(t::Task) in Base at event.jl:166
[12] yield(t::Task, x) in Base at event.jl:166
[13] yieldto(t::Task) in Base at event.jl:181
[14] yieldto(t::Task, x) in Base at event.jl:181

julia> fieldnames(Task)
(:parent, :storage, :state, :donenotify, :result, :exception, :backtrace, :logstate, :code)
```

task的构造函数只有一个`Task(f)`，其唯一的一个参数`f`必须是不带参数的函数，如果传一个带参数的函数，会在真正执行时触发`MethodError`。

```julia
julia> t = Task((x) -> x + 1)
Task (runnable) @0x00007f600e180d30

julia> schedule(t)
Task (failed) @0x00007f600e180d30
MethodError: no method matching (::getfield(Main, Symbol("##11#12")))()
Closest candidates are:
  #11(::Any) at REPL[29]:1
```

当然，每次都要记得构造一个闭包很傻，有一个`@task`宏可以用于简化这个过程：

```julia
julia> t = @task println("Hi")
Task (runnable) @0x00007f600f25aa10

julia> schedule(t)
Hi
Task (queued) @0x00007f600f25aa10

julia> t
Task (done) @0x00007f600f25aa10
```

上面为了看到一个task的执行结果，我们使用了`schedule`函数，其作用是将这个runnable的task加入到一个全局的task队列中，然后将task的状态置成`:queued`，系统在**空闲**时会执行该task（TODO:调度的逻辑），执行结果存在`:result`字段下，并根据执行结果修改其`:state`状态（`:failed`,`:done`）。不过上面的例子似乎给人一种错觉，在执行完`schedule(t)`之后，task `t`立即就执行了，并没有感受到所谓的**等待系统空闲**。下面这个例子用一个计算密集型的任务来验证下：

```julia
t = @task begin 
    println("begin task")
    inv(rand(2000, 2000))
    println("end task") 
    end

begin 
    schedule(t)
    println(length(Base.Workqueue))
    println(t.state)
    println("begin computing")
    println(sum(inv(randn(1500, 1500))))
    println("end computing")
    println(length(Base.Workqueue))
    println(t.state)
end

# 1
# queued
# begin computing
# 97.12983082590253
# end computing
# 1
# queued
# begin task
# end task
```

可以看到，在`schedule(t)`之后，`t`并没有立即被执行，而是被添加到了`Base.Workqueue`中一直处于`queued`状态，主流程继续执行，先进行了求逆计算，结束之后，系统再进行task切换，执行`t`。以上，就是所谓的**并发(Concurrency)**。对于单一进程来说，并发执行计算密集型任务并没有太大收益，不过，对IO密集型任务来说，则非常有用，在等待的过程中，可以切换到其它任务，一旦条件满足，再切回来就执行，这样看起来，似乎是在同时执行多个任务（并发）。Julia对这里所谓的条件提供了一个统一的概念，称为`Condition()`:

```julia
julia> fieldnames(Condition)
(:waitq,)
```

`Condition()`只有一个类型为`Vector`的字段`:waitq`用于记录在等待该条件的所有task，在一个task内部，可以通过执行`wait(c::Condition)`，声明其正在等待某个条件，然后将自己添加到`Base.Workqueue`尾部，同时从中取出第一个task并做切换。当条件满足时，通过执行`notify(c::Condition)`再将这些task重新加入到`Base.Workqueue`中等待执行。

```julia
julia> c = Condition()
Condition(Any[])

julia> t = @task begin
           println("waiting condition")
           wait(c)
           println("condition meet")
           end
Task (runnable) @0x00007f2d954c07f0

julia> schedule(t)
waiting condition
Task (queued) @0x00007f2d954c07f0

julia> notify(c)
condition meet
1
```

除了通过执行`wait`进行task切换之外，还可以通过执行`yield()`主动进行`task`的切换（其实也是调用了`wait()`函数）。

```julia
yield() = (enq_work(current_task()); wait())
```

下面看一个`yield`的例子：

```julia
julia> t1 = @task begin
       println("task1 begin")
       yield()
       println("task1 resumed")
       end
Task (runnable) @0x00007f2d954c2f50

julia> t2 = @task begin
       println("task2 begin")
       yield()
       println("task2 resumed")
       end
Task (runnable) @0x00007f2d954c31f0

julia> begin
       schedule(t1)
       schedule(t2)
       yield()
       end
task1 begin
task2 begin
task1 resumed
task2 resumed
```

关于task，理解这些基本够用了。一个典型的应用是`Timer`，其中有个字段`:cond`就是一个`Condition()`，每当设定的时间周期到了的时候，就会`notify`挂在该`:cond`上的task。另外经常用到的`@async`宏其实就是先构造了一个task，然后执行了`schedule`（二合一了）

下面我们再深入理解一个更有意思的例子。

### `Channel`

`Channel`就是一个通道，不同的task可以从一端往其中写入数据，而另外一些task则可以从另外一端读取数据。`Channel`的结构很简单：

```julia
mutable struct Channel{T} <: AbstractChannel{T}
    cond_take::Condition                 # waiting for data to become available
    cond_put::Condition                  # waiting for a writeable slot
    state::Symbol
    excp::Union{Exception, Nothing}         # exception to be thrown when state != :open

    data::Vector{T}
    sz_max::Int                          # maximum size of channel

    # Used when sz_max == 0, i.e., an unbuffered channel.
    waiters::Int
    takers::Vector{Task}
    putters::Vector{Task}
end
```

其中`state`字段表示当前channel的状态（`:open`, `:closed`）,`sz_max`则表示channel的长度（该长度可以设为0，~~即无限大~~）。

对于长度有限的channel来说，执行`put!(c, v)`写入数据时，如果当前`data`的长度已经达到了`sz_max`，则会调用`wait()`将当前task阻塞，然后每个事件周期都会检查`data`的长度是否已经小于`sz_max`，一旦该条件满足，就会往`data`中写入`v`，同时通知所有挂在`cond_take`字段上的task。而执行`take!(c)`读取数据时，如果当前`data`中有数据，则取出来，同时通知挂在`cond_put`上的task，否则，将当前task挂起到`cond_take`中，等待新的数据。

对于~~无限长~~长度为0的channel而言，需要用到`takers`和`putters`字段。在写入数据时，如果`takers`为空，就将当前task写入到`putters`中(然后还会通知`cond_take`上的task，这类task是通过`wait(c)`挂在在~~无限长~~channel上的)，否则，从`takers`中取一个出来**重新**执行（这里用的是`yield(t, v)`操作）。取数据时，先将自己加入到`waiters`中，然后判断`putters`是否为空，若空，则调用`wait()`将自己挂起，否则从`putters`中取出一个执行。

此外，关于`Channel`有个挺好用的函数`Channel(func::Function; ctype=Any, csize=0, taskref=nothing)`。关于`Channel`的例子实在太多了，手册中的那个生产者消费者的例子就挺不错的，这里不列举了。

## 多线程

这里暂时先不深入介绍多线程，主要是这个Julia中老大难的问题了，目前的接口仍然是实验性的，此外也有一些PR正在做这方面的事情，建议subscribe一些[multithreading](https://github.com/JuliaLang/julia/labels/multithreading)的PR，了解下最新的进展（比如[这个](https://github.com/JuliaLang/julia/pull/22631)）

## 多进程

前面提到的都还是**并发**，要实现真正的**并行**，需要充分利用多核/多台机器。手册里有提到，Julia实现的并行机制有点类似MPI，不过是单向的（也就是说，有一个master进程负责给其它进程分配执行任务）。所有分布式相关的代码都在Julia源码的`stdlib/Distributed`package下，接下来我们一步步展开介绍（如果你想在REPL中测试下面的示例代码，记得先执行`using Distributed`）。

首先讨论单机多进程的情况。在Julia中，一个工作进程称作一个worker，管理这些worker的进程是`LocalProcess`（也就是打开REPL后进入的进程）。每个进程都有自己的pid，`LocalProcess`的pid是`1`（为了表述方便，以下称其为master）。接下来先回答几个问题：

### 1. 如何表示一个work中的对象？

对于master而言，worker中的对象有两种表示，一个是`Future`，另一个是`RemoteChannel`。

```julia
mutable struct Future <: AbstractRemoteRef
    where::Int
    whence::Int
    id::Int
    v::Union{Some{Any}, Nothing}
end
```

其中，`where`表示`v`所在的pid，`whence`和`id`一般通过`RRID`生成，分别表示生成该`Future`对象的进程的pid，而`id`则是从1开始自增的id。`RemoteChannel`也类似：

```julia
mutable struct RemoteChannel{T<:AbstractChannel} <: AbstractRemoteRef
    where::Int
    whence::Int
    id::Int
end
```

### 2. 怎么发起远程调用？

Julia中，提供了一个底层函数`remotecall`来实现远程调用，执行后会立即返回一个`Future`对象，然后可以通过`fetch`将value写入到`Future`的`v`字段中（此时会发生数据转移，也就是导致并行计算性能瓶颈的地方）。例如：

```julia
julia> using Distributed

julia> addprocs()
4-element Array{Int64,1}:
 2
 3
 4
 5

julia> m = remotecall(rand, 5, 2, 2)
Future(5, 1, 6, nothing)

julia> fetch(m)
2×2 Array{Float64,2}:
 0.109123  0.304667
 0.454125  0.197551
```

此外，`Distributed`中还提供了一些工具函数和有用的宏，这里不深入介绍，我们更关心的是：

### 3. 什么时候会发生GC？

`Distributed`中有一个`clear!`函数用于将worker中的变量置成nothing，不过，如果不引入全局变量的话，大多时候并不需要手动进行该操作。`fetch`会自动执行`send_del_client`函数，并通知gc.此外手册里也提到，由于对master来说，一个RemoteReference的内存占用很小，并不会马上被gc，因而可以调用`finalize`，从而会立即执行`send_del_client`向worker发送gc信号。

TODO: 一个分布式并行计算的实例