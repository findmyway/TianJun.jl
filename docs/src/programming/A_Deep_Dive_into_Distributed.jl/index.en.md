# A Deep Dive into Distributed.jl

```@blog_meta
last_update="2021-12-06"
create="2021-08-20"
tags=["Distributed Computing", "Julia"]
```

[Distributed.jl](https://docs.julialang.org/en/v1/stdlib/Distributed/) is a standard library in Julia to do multi-processing and distributed computing. The [distributed-computing](https://docs.julialang.org/en/v1/manual/distributed-computing/) section in the official julia docs already provides a nice introduction on how to use it. I assume most of you have skimmed through it. So here I'll mainly focus on how this package is designed and implemented, hoping that you'll have a better understanding after this talk.

My talk will be organized in the Q&A style. So feel free to raise more questions in the end of this talk if anything is still unclear to you.

## 1. How to initialize `Distributed.jl`?

The easiest way is to start the `julia` with an extra parameter `-p auto`. Then based on the number of logical cores on your machine, the same number of julia processors will be created and connected on your machine. Or you can specify the number explicitly.

```

                         ┌─────────────┐
                    ┌────► myid() == 2 │
                    │    └─────────────┘
 ┌─────────────┐    │
 │ julia -p 3  │    │    ┌─────────────┐
 │             ├────┼────► myid() == 3 │
 │ myid() == 1 │    │    └─────────────┘
 └─────────────┘    │
                    │    ┌─────────────┐
                    └────► myid() == 4 │
                         └─────────────┘

```

To create multiple processors, we can provide a file like this:

```@example
println(run(`cat $(joinpath(@__DIR__, "local_machines"))`))
```

And set it to the `--machine-file` argument. In the above file, we use the localhost `127.0.0.1` for simplicity.

```


                                             ┌─────────────┐
                                          ┌──► myid() == 2 │
                              ┌────────┐  │  └─────────────┘
                           ┌──► Node 1 ├──┤
                           │  └────────┘  │  ┌─────────────┐
                           │              └──► myid() == 3 │
                           │                 └─────────────┘
 ┌──────────────────────┐  │
 │ julia --machine-file │  │
 │                      ├──┤
 │     myid() == 1      │  │                 ┌─────────────┐
 └──────────────────────┘  │              ┌──► myid() == 4 │
                           │  ┌────────┐  │  └─────────────┘
                           └──► Node 2 ├──┤
                              └────────┘  │  ┌─────────────┐
                                          └──► myid() == 5 │
                                             └─────────────┘
```

Of course, you can also set them dynamically with [`addprocs`](https://docs.julialang.org/en/v1/stdlib/Distributed/#Distributed.addprocs).

### 1.1 Why is there an extra processor created?

It's mentioned in the [distributed-computing](https://docs.julialang.org/en/v1/manual/distributed-computing/) section from the official doc that:

> Communication in Julia is generally "one-sided", meaning that the programmer needs to explicitly manage only one process in a two-process operation.

This means that, by design the processor we created to launch workers will serve as the header. Its main goal is to dispatch jobs to workers instead of doing computing on its own. So in most cases, we just execute code on the header and tell workers what they need to do. That is what "one-sided" means above.

So the header processor is just the extra one we created.

## 2. How are the workers created?

This can be narrowed down to several more specific questions. But before answering them, let's see what's happening when we load the package with `using Distributed` first.

```@embed https://github.com/JuliaLang/julia/blob/00734c5fd045316a00d287ca2c0ec1a2eef6e4d1/stdlib/Distributed/src/Distributed.jl#L111-L113
```

```@embed https://github.com/JuliaLang/julia/blob/00734c5fd045316a00d287ca2c0ec1a2eef6e4d1/stdlib/Distributed/src/cluster.jl#L1303-L1312
```

Let's ignore the first line for now. We'll discuss `start_gc_msgs_task` later.
Two important global variables are initialized here, the first one is `LPROC` (Local Processor for short), which serves like an identifier of the current processor. The second one is `PGRP`, (Processor Group for short). It records the workers we'll create later. It will be initialized with the only one element `LPROC` here. And that's why you'll see only one worker with id `1` is returned from `workers()`.

```@repl
using Distributed
workers()
```

The function to create workers is provided by [`addprocs`](https://docs.julialang.org/en/v1/stdlib/Distributed/#Distributed.addprocs). By default, it will be dispatched to `addprocs_locked(manager::ClusterManager; kw...)` (Here `ClusterManager` is an abstract type, we'll introduce two typical implementations in `Distributed.jl` soon). Since two main public APIs are involved in its implementation, let's examine the code in detail here:

```@embed https://github.com/JuliaLang/julia/blob/00734c5fd045316a00d287ca2c0ec1a2eef6e4d1/stdlib/Distributed/src/cluster.jl#L485-L502
```

First, it tries to call the [`launch`](https://docs.julialang.org/en/v1/stdlib/Distributed/#Distributed.launch) method implemented by specific `ClusterManager` asynchronously. Then the main task will periodically check whether the `launch` task has been finshed or not every second. If not, it'll try to setup the the connection with workers which has already been added into `launched` by the `ClusterManager`. Note that the outer `@sync` will guarantee all the `setup_launched_worker` calls are finished (all connections between header and worker are initialized).

So what should `launch` do? As the doc says:

>    launch(manager::ClusterManager, params::Dict, launched::Array, launch_ntfy::Condition)
>
> Implemented by cluster managers. For every Julia worker launched by this function, it should
> append a `WorkerConfig` entry to `launched` and notify `launch_ntfy`. The function MUST exit
> once all workers, requested by `manager` have been launched. `params` is a dictionary of all
> keyword arguments `addprocs` was called with.

But what is `WorkerConfig`? Its definition in `Distributed.jl` is specifically tight with two `ClusterManager` and we'll discuss soon. Basically it describes where and how the header should send messages to (Like a IO stream, or a http connection). Once the `ClusterManager` has finished initializing the worker processor, we need to register this worker in the header:

1. Figure out where to read messages from (`r_s`) and write messages to (`w_s`) worker.
2. Bind the `finalizer` of the worker to tell its cluster manager when it's finalized.
3. Create an async task to handle messages from the worker.
4. Send the header's information to worker so that the worker knows where the header is and how to send messages.
5. Wait until the worker confirms and joins the cluster. Otherwise, remove it if time is out.

### 2.1 How are workers created on my local machine?

```@embed https://github.com/JuliaLang/julia/blob/00734c5fd045316a00d287ca2c0ec1a2eef6e4d1/stdlib/Distributed/src/managers.jl#L460-L479
```

Pretty straightforward, right? A new julia processor is created and then a worker config is properly set. But how does this new processor handle new messages sent from sender or other workers? Note that there's an extra option `--worker` in the `cmd`.

```@embed https://github.com/JuliaLang/julia/blob/00734c5fd045316a00d287ca2c0ec1a2eef6e4d1/base/client.jl#L254-L262
```

With this option, the newly created julia processor will do some extra work for us to have everything properly set. Basically, it will create a new socked connection and handle messages coming in. You can use `netstat -tunlp | grep julia` to see which ports the workers are using.

### 2.2 How are workers created across different machines?

To create workers across machines, `Distributed.jl` provides a SSH based cluster manager. Although the code in the `SSHManager` looks very complex, the core idea behind is similar to the `LocalManager`. We run the command to create a julia worker processor through SSH and record the process id. Then we can use this id to kill the worker if required.

### 2.3 A practical example

In [ClusterManagers.jl](https://github.com/JuliaParallel/ClusterManagers.jl), several common cluster managers are provided. You should definitely check it first if the default `LocalManager` and `SSHManager` don't apply in your environment. Now let's take a close look at an interesting one: `ElasticManager`.

```
                                 ┌────────┐
                               ┌─┤ worker │
                               │ └────────┘
      ┌─────────────┐ connect  │   ......
      │ socket      │          │ ┌────────┐
      │             │◄─────────┼─┤ worker │
      │   - address │          │ └────────┘
      │   - port    │          │ ......
      └────▲───┬────┘          │ ┌────────┐
           │   │               └─┤ worker │
           │   │                 └────────┘
           │   │
           │   │ received new connection
    watch  │   │
  new conn │   │ check cookie
           │   │
           │   │ push into
           │   │
        ┌──┴───▼──┐
        │ pending │
        └────┬────┘
             │
             │
             │
        ┌────▼─────┐
        │ addprocs │
        └──────────┘
```

After initialization, the `ElasticManageer` created two background tasks: the first one is to watch on new connections, and the second one is to add new processors by reusing the `addprocs` function in `Distributed.jl`. In the `launch` step, it simply take take the pending socket and add it into `launched`. And in the `manage` step, it simply maintains a dict of active workers.

## 3. How do workers communicate?

In the above section, we've mentioned that a worker processor will run `start_worker` first after initialization, and then wait for messages. But how are messages encoded and interpreted?

```

                  ┌─────────────────────┐
                  │     .........       │
                  │ ┌─────────────────┐ │
                  │ │     BOUNDARY    │ │
                  │ └─────────────────┘ │
                  │                     │
                  │ ┌─────────────────┐ │
                  │ │ header          │ │
                  │ │                 │ │
               ┌──┼─►  * response_oid │ │
               │  │ │  * notify_oid   │ │
               │  │ └─────────────────┘ │
               │  │                     │
               │  │ ┌─────────────────┐ │
 ┌──────────┐  │  │ │                 │ │    ┌────────────┐
 │ send_msg ├──┼──┼─► builtin message ├─┼────► handle_msg │
 └──────────┘  │  │ │                 │ │    └────────────┘
               │  │ └─────────────────┘ │
               │  │                     │
               │  │ ┌─────────────────┐ │
               └──┼─►     BOUNDARY    │ │
                  │ └─────────────────┘ │
                  │     .........       │
                  └─────────────────────┘

```

Messages are serialized into a reader steam seperated by a collection of constant bytes (`MSG_BOUNDARY`). Each message has two parts, a header and a message body. In `Distributed.jl`, several predefined types of messages are provided. Each message then be deserialized and dispatched to a specific `handle_msg` implementation. Each header has exactly two fields, the `response_oid` and `notify_oid`. Now we are going to study two key concepts in `Distributed.jl`: **remote call** and **remote reference**.

### 3.1 Remote reference

In `Distributed.jl`, each worker has a unique id (`myid()`). To locate objects created by `Distributed.jl`, each of them will also have a unique id in that processor.

```@embed https://github.com/JuliaLang/julia/blob/00734c5fd045316a00d287ca2c0ec1a2eef6e4d1/stdlib/Distributed/src/Distributed.jl#L87-L96
```

As you can see, by default the `id` is auto-increment. And the `whence` is set to the current worker. Remember that each `AbstractRemoteRef` instance must at least contain these two basic id to locate it.

`Future`

```@embed https://github.com/JuliaLang/julia/blob/ed4c44fbaf/stdlib/Distributed/src/remotecall.jl#L25-L35
```

A `Future` is an abstract container of a remote object (it can also reside in the current processor). Beyond the `whence` and `id`, it has two extra fields. The `where` indicates where the underlying value `v` is stored. Understanding the difference between `where` and `whence` is crucial. Let's say we're on worker `1` and would like to do a simple calculation of `1+1` on worker `2`. Without the `where` field, we have to first send the remote calculation message to worker `2`. Then the worker create a unique `RRID` and return it to worker `1`. And when we want to fetch the calculation result `v`, we have to send the fetch command to worker `2` again and wait until the calculation is done and passed the result back to worker `1`.

```

                                timeline

                                    │
 ┌───────────────────────────────┐  │  ┌────────────────────────────────┐
 │ worker 1                      │  │  │                        worker 2│
 │                               │  │  │                                │
 │          remotecall F: 1 + 1 ─┼──┼──┤►                               │
 │                               │  │  │  create a unique remote ref: R │
 │                waiting......  │  │  │                                │
 │                              ◄├──┼──┼─ pass back R                   │
 │        remote_ref R received  │  │  │                                │
 │                               │  │  │  do the calculation of F       │
 │    do some other calculation  │  │  │                                │
 │                               │  │  │  ......                        │
 │                       ......  │  │  │                                │
 │                               │  │  │                                │
 │ fetch result from remote_ref ─┼──┼──┤► wait F finish                 │
 │                               │  │  │                                │
 │                               │  │  │  ......                        │
 │                waiting......  │  │  │                                │
 │                              ◄├──┼──┼─ send back result              │
 │          remote value cached  │  │  │                                │
 │                               │  │  │                                │
 └───────────────────────────────┘  │  └────────────────────────────────┘
                                    ▼
```

But if we have a `where` field to record where the calculation happens, then the first round could be reduced.

```
                              timeline

                                  │
 ┌─────────────────────────────┐  │  ┌───────────────────┐
 │  worker 1                   │  │  │          worker 2 │
 │                             │  │  │                   │
 │       create remote call F ─┼──┼──┤► received F & R   │
 │           and remote ref R  │  │  │                   │
 │                             │  │  │  do calculation   │
 │  do some other calculation  │  │  │                   │
 │                             │  │  │  ......           │
 │                     ......  │  │  │                   │
 │                             │  │  │                   │
 │  fetch reult from where(R) ─┼──┼──┤► wait F finish    │
 │                             │  │  │                   │
 │                             │  │  │  ......           │
 │              waiting......  │  │  │                   │
 │                            ◄├──┼──┼─ send back result │
 │        remote value cached  │  │  │                   │
 └─────────────────────────────┘  │  └───────────────────┘
                                  ▼
```

`RemoteChannel` is similar, except that the underlying value can not be copied back and forth. We can only check whether it is ready and `take!` elements from it.

### 3.2 Remote call

Now let's examine what's happening in the following simple code:

```julia
using Distributed

addprocs(2)

x = @spawnat 2 begin
    sleep(3)
    rand(3)
end

print(x[])
```

First, we create a worker with `addprocs(2)`. Then we try to create a remote call which simply returns a random vector. The `@spawnat` macro will wrap the following expression into a parameterless function (usually known as a `thunk`) and turn it into a `remotecall`. In `remotecall`, a `Future` is first created to store the result in the future. Then the `whence` and `id` info of the future is extracted to form the message header (a `RRID`). The `thunk` is wrapped in a specific `CallMsg` and forms the message body. The whole message is serialized and written to the worker's `r_stream`. Note that the `remotecall` is async, so you can work on some other stuff and fetch the result later. On the worker side, once received a new message, it is deserialized and dispatched to the corresponding `handle_msg` call. For `CallMsg`, it will create a temp `Channel(1)` to store the result and associate it with the `RRID` in its global `client_refs`. Now when we try to fetch the result with `x[]`, it will send another message of `remotecall_fetch` with a dedicated function `fetch_ref` and wait for the response. Once it receives the result. It will be cached in its `:v` field, so that future fetch calls will not do the remote call again.

The following up question is, what about the original data on worker `2`? Since now we have fetched and cached the value, we won't need it anymore.

Actually we can't remove it from worker `2` directly. Let's say we send the future `x` to another worker `3` before it fetches the result. If the result is removed from worker `2` immediately in respond to the fetch operation on worker `1`. Then the worker `3` will never get the chance to fetch the result. But we still need to remove it sometime, right? Otherwise the memory usage will keep growing. In fact, the worker where the data of the `Future` resides will keep track of the connected workers of this `Future`. Everytime the GC hapens with a `Future`, we'll try to delete itself from the connected clients. And when no connected clients left, we're safe to remove it from `client_refs`.

Note that some expresions can't be executed through `@spawnat` (for example `using SomePackage`). That's why we have several different message types and `handle_msg` implementations. But the whole pipeline is almost the same.

### 3.3 `WorkerPool` and `pmap`

With the knowledge above, now we know how the `Distributed.jl` works. But still it is not very easy to use since we have to deal with the worker id directly. That's why `WorkerPool` and `pmap` are provided. `pmap` tries to divide the workload first and the worker pool can help to leverage computing resource more efficiently. This part is relatively easy to read and understand.

## Is `Distributed.jl` perfect?

Well, the standard answer is, there's no perfect design, only traceoffs. In my opinion, `Distributed.jl` is designed for HPC environments, where all the workers are quite stable. All the functionalities it provides are very fundamental and do not feature usability that much. On top of it, there's a [Dagger.jl](https://github.com/JuliaParallel/Dagger.jl) which is more usable for dynamic graph computing. And I'm also considering implementing a more flexible one. Stay tuned!
