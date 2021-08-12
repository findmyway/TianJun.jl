---
keywords: Julia,ParallelComputing
CJKmainfont: KaiTi
---

# 一文读懂Julia中的并行计算

最近阅读了Julia中的[Distributed](https://github.com/JuliaLang/julia/tree/master/stdlib/Distributed)标准库，对Julia中的并行计算又多了一些思考。尽管官方文档中有一章详细介绍并行计算([中文](https://docs.juliacn.com/latest/manual/parallel-computing/), [英文](https://docs.julialang.org/en/v1/manual/parallel-computing/))，我刚接触Julia的时候也写了一篇[自底向上理解Julia中的并行计算](https://tianjun.me/essays/An_Introduction_to_Parallel_Computing_in_Julia_From_Bottom_Up)，不过总感觉讲得不够透彻。本文的目的是用一些实际的例子帮助大家深入理解Julia中的并行计算。

本文将包括以下内容：

- Task
- Channel
- RemoteChannel
- ClusterManager

本文**不包括**以下内容：

- XX问题应该选择哪种并行计算方式？

## Task

通常我们并没有感知到究竟什么是Task，其实每次我们从命令行里输入`julia`，打开REPL界面之后，就进入了一个task中，通过[`current_task`](https://docs.julialang.org/en/v1/base/parallel/#Base.current_task)函数就可以获取到当前运行中的task对象：

```julia
julia> t = current_task()
Task (runnable) @0x00007f34ded89600
```

可以看到，`t`的打印输出中，括号里提供了一个**runnable**信息，表明当前task `t` 是可执行的，除了`runnable`之外，task还有其它几个[状态](https://docs.julialang.org/en/v1.2-dev/manual/control-flow/#Task-states-1):

| Symbol      | Meaning                            |
|:----------- |:-----------------------------------|
| `:runnable` | Currently running, or able to run  |
| `:done`     | Successfully finished executing    |
| `:failed`   | Finished with an uncaught exception|

后面会介绍各个状态的具体含义，这里先留下个印象即可。这些状态存在`t.state`字段中：

```julia
julia> t.state
:runnable
```

那什么是Task呢？一个task就是一段执行逻辑，可以直接通过`Task`来构造：

```julia
julia> t_hi = Task(() -> println("Hi"))
Task (runnable) @0x00007f34dec870d0

julia> t_hi.state
:runnable
```

这里`Task`可以接收一个lambda函数作为参数，构造一个新的task。此外还有一个`@task`宏，用来方便地将一段执行逻辑构造成一个task：

```julia
julia> t_hello_world = @task begin
              println("I'm in a task!")
              "Hello World!"
              end
Task (runnable) @0x00007f34dc84b0d0
```

那么如何执行一个task呢？调用`schedule`即可：

```julia
julia> schedule(t_hello_world)
I'm in a task!
Task (runnable) @0x00007fb18f7eae10

julia> t_hello_world.state
:done

julia> t_hello_world.result
"Hello World!"
```

可以看到，上面的task顺利执行完之后，状态就变成了`:done`，对应的执行结果保存在`t_hello_world.result`字段中。此外还有几个函数用于检查状态：

- `istaskstarted`
- `istaskdone`
- `istaskfailed`

task中也可以报错，错误会保存在task 的`exception`字段中：

```julia
julia> schedule(t_error)
Task (failed) @0x0000000012aef0f0
Oh no...
error(::String) at .\error.jl:33
(::getfield(Main, Symbol("##7#8")))() at .\task.jl:87

julia> t_error.state
:failed

julia> t_error.result
ErrorException("Oh no...")

julia> t_error.exception
ErrorException("Oh no...")
```

那么，`schedule`究竟做了什么呢？这里就涉及`task`的底层实现了。简单来讲，Julia 会给每个 thread 都生成一个队列，`schedule`所做的就是将该task按照一定规则（后面会再详细解释）加入到某个队列中。由于我们启动 Julia 的时候，并没有指定`JULIA_NUM_THREADS`环境变量，所以默认只有一个队列：

```julia
julia> Base.Workqueues
1-element Array{Base.InvasiveLinkedListSynchronized{Task},1}:
 Base.InvasiveLinkedListSynchronized{Task}(Base.InvasiveLinkedList{Task}(nothing, nothing), Base.Threads.SpinLock(Base.Threads.Atomic{Int64}(0)))
```

将task加入队列中之后，调度器会在空闲时，负责从队列中顺序取task并执行。

<div class="alert alert-warning">
需要指出的是，前面的例子中，似乎执行完`schedule(t_error)`之后，`t_error`就立即执行得到了结果。其实，这是因为我们是在REPL中分步执行的，执行完`schedule(t_error)`之后，REPL就进入了等待的过程，此时调度器空闲了，就会按照既定的规则从队列中取task并执行。可以用下面的例子来验证下。
</div>

```julia
julia> t = @task @info "I'm in task"
Task (runnable) @0x0000000012a802f0

julia> begin
       schedule(t)
       @info "Hello"
       end
[ Info: Hello
[ Info: I'm in task
```

可以看到，`Hello`先打印了出来，然后 task `t` 接着就执行并打印 `I'm in task`。

目前为止，我们了解了什么是task (WHAT), 如何使用task (HOW)，那为什么要使用task呢？ (WHY)

这就涉及到我们还没提到的一个task的特性，在一段task的执行逻辑之中，我们可以（显式地/隐式地）指定某些地方能被中断和恢复。直接执行`yield()`就相当于显式地告诉调度器，“把我放到队列里取，让队列里其它task有机会被执行”，当然，如果全局的task队列中没有`runnable`的task，那么就会立即继续执行接下来的其它代码。下面举个例子：

```julia
julia> t1 = @task begin
       @info "begin task1"
       yield()
       @info "end task1"
       end
Task (runnable) @0x00007f7542e7e850

julia> t2 = @task begin
       @info "begin task2"
       yield()
       @info "end task2"
       end
Task (runnable) @0x00007f7542e7eb30

julia> begin
       schedule(t1)
       schedule(t2)
       yield()
       @info "Current task running"
       end
[ Info: begin task1
[ Info: begin task2
[ Info: Current task running
[ Info: end task1
[ Info: end task2
```

这里先定义了两个task，每个task都是先打印begin信息，然后是执行`yield()`允许自己被中断，一旦被恢复后，再打印end信息。注意最后一个代码块，首先调度`t1`,然后调度`t2`,此时`t1`和`t2`都被加到了一个队列中，最后执行`yield()`把自己也加入到队列中，让调度器开始调度。从输出的顺序可以看出，`t1`先被执行，执行到`yield()`语句后，让出控制权，调度器从队列中选出`t2`执行，同样执行到`yield()`之后让出控制权，然后当前task被选中执行，此后`t1`再次被选中，执行结束，然后再执行`t2`，直至结束。

此外，`yield`还可以接收一个task作为参数，执行后会将该task放在队列的最前面被调度，比如，上面的例子中，试着将`t2`中的`yield()`改成`yield(t1)`，然后`schedule(t2)`试试？

那允许一段代码被中断的好处是什么呢？

**并发**

一个经典的例子是，在做网络请求的时候，会等待响应，若没有中断的机制，那么会一直阻塞，这样导致宝贵的计算资源在此期间白白浪费掉了。有了中断机制之后，在等待响应的过程中，可以主动切出去，让调度器有机会运行其它task，等获取到响应之后，再将自己放回到task队列中，等待被调度并执行。

TODO: Need a picture here

为了实现上述逻辑，Julia中提供了一个`Condition`对象，用来表示一类抽象的**条件**。task可以执行`wait(c::Condition)`，将自己挂载在该Condition下的链表末尾，并`yield()`出去，若Condition满足，则可以调用`notify(c::Condition)`，将挂载在该Condition的task链表上的task逆序添加到调度器的执行队列中，从而让其它task有机会被执行。

```julia
julia> c = Condition()
Condition(#undef, 0, 0)

julia> t1 = @task begin
       @info "task1 working..."
       wait(c)
       @info "condition satisfied"
       end
Task (runnable) @0x00007f75412e45d0

julia> schedule(t1)
[ Info: task1 working...
Task (runnable) @0x00007f75412e45d0

julia> t1.state
:runnable

julia> notify(c)
[ Info: condition satisfied
```

Julia中[stream](https://github.com/JuliaLang/julia/blob/v1.1.0/base/stream.jl#L44)和[Timer](https://github.com/JuliaLang/julia/blob/v1.1.0/base/event.jl#L341)相关的操作都采用类似机制实现的。

理解上面的这些概念之后，就可以做很多有意义的事情了。