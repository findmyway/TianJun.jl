---
keywords: Julia,Concurrency
CJKmainfont: KaiTi
---

# 用Julia实现读写锁

本文受[Implementing reader-writer locks](https://eli.thegreenplace.net/2019/implementing-reader-writer-locks/)一文启发，采用Julia实现读写锁（原文用的是Golang）。

## 为何需要读写锁

在多线程编程过程中，对于一些关键资源，需要对其加锁，以保证同一时刻只有一个线程在操作数据。不过在某些场景下，加锁带来的代价会比较大。如果只有一个互斥锁，那么当读取操作的次数远大于写入操作的次数时，由于每次读取都会对数据加锁，必然带来额外的开销。显然，如果多次读取操作之间没有写入操作，那么这段时间内其实时不需要对数据加锁的，于是乎，便有了读写锁专门用于提升此类场景下锁的效率。

接下来，我们将一步步实现高效的读写锁。

## MutexAsRWLock

先假设只有一把锁，看看其效率如何：

```Julia
struct MutexAsRWLock
    m::Threads.Mutex
    MutexAsRWLock() = new(Threads.Mutex())
end

read_lock(l::MutexAsRWLock) = lock(l.m)
read_unlock(l::MutexAsRWLock) = unlock(l.m)
write_lock(l::MutexAsRWLock) = lock(l.m)
write_unlock(l::MutexAsRWLock) = unlock(l.m)
```

然后用原文中提到的测试方法，测试下这种情况下，`read_lock`和`write_lock`获取锁的时间：

```julia
julia> batch_test_rwlock(rwl, 1000, 10)
(2.0248251801001482e-8, 1.9721886599999977e-8)
```

## ReaderCountRWLock

接下来将其换成一种最简单的实现：读写锁共用一个互斥锁，不过，获取写锁时，如果当前已经有了读锁（count大于1），那么就将其释放掉，然后循环下去：

```julia
mutable struct ReaderCountRWLock
    m::Threads.Mutex
    reader_count::Int
    ReaderCountRWLock() = new(Threads.Mutex(), 0)
end

function read_lock(l::ReaderCountRWLock)
    lock(l.m) do
    l.reader_count += 1
    end
end

function read_unlock(l::ReaderCountRWLock)
    lock(l.m) do
        l.reader_count -= 1
        if l.reader_count < 0
            error("reader count negative")
        end
    end
end

function write_lock(l::ReaderCountRWLock)
    while true
        lock(l.m)
        if l.reader_count > 0
            unlock(l.m)
        else
            break
        end
    end
end

function write_unlock(l::ReaderCountRWLock)
    unlock(l.m)
end
```

```julia
julia> batch_test_rwlock(rwl, 1000, 10)
(1.2749199800001581e-10, 4.536146970000002e-8)
```

可以看到，读锁的时间大大降低了，但是写入锁的时间稍稍增加了一些。

