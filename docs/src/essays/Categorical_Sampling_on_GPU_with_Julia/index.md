---
keywords: Julia,GPU,Sampling
CJKmainfont: KaiTi
---

# Categorical Sampling on GPU with Julia

A great blog post has discussed this topic in detail: [http://www.keithschwarz.com/darts-dice-coins/](http://www.keithschwarz.com/darts-dice-coins/). I strongly suggest you read through it first.

Sampling from a [categorical distribution](https://en.wikipedia.org/wiki/Categorical_distribution) is very straight forward in Julia. In [Distributions.jl](https://github.com/JuliaStats/Distributions.jl/blob/master/src/samplers/categorical.jl), there's a [naive sampling implementation](https://github.com/JuliaStats/Distributions.jl/blob/master/src/samplers/categorical.jl#L18-L28). As the name indicates, the implementation is very simple:

```julia
function rand(rng::AbstractRNG, s::CategoricalDirectSampler)
    p = s.prob
    n = length(p)
    i = 1
    c = p[1]
    u = rand(rng)
    while c < u && i < n
        c += p[i += 1]
    end
    return i
end
```

I usually use it as a warm-up interview question :smile:.

In [StatsBase.jl](https://github.com/JuliaStats/StatsBase.jl/blob/master/src/sampling.jl), there are many more efficient implementations for both with or without replacement. The [`sample!](https://github.com/JuliaStats/StatsBase.jl/blob/master/src/sampling.jl#L319) method in StatsBase.jl is smart enough to select an appropriate one according to the distribution.

Among those implementations, I'm more interested in the [`alias_sample!`](https://github.com/JuliaStats/StatsBase.jl/blob/master/src/sampling.jl#L526). As the documentation says, the alias sampling method takes $O(n \log n)$ for building the alias table (here $n$ is the length of distribution), and then $O(1)$ to draw each sample (consume 2 random numbers each time). This character makes it very suitable for some large scale simulations.

Next, we want to accelerate the alias sampling method further with GPU. Let's take a close look at the [implementation](https://github.com/JuliaStats/StatsBase.jl/blob/master/src/sampling.jl#L526-L542) in StatsBase.jl first:

```julia
function alias_sample!(rng::AbstractRNG, a::AbstractArray, wv::AbstractWeights, x::AbstractArray)
    n = length(a)
    length(wv) == n || throw(DimensionMismatch("Inconsistent lengths."))

    # create alias table
    ap = Vector{Float64}(undef, n)
    alias = Vector{Int}(undef, n)
    make_alias_table!(values(wv), sum(wv), ap, alias)

    # sampling
    s = RangeGenerator(1:n)
    for i = 1:length(x)
        j = rand(rng, s)
        x[i] = rand(rng) < ap[j] ? a[j] : a[alias[j]]
    end
    return x
end
```

Here the `AbstractWeights` is just a wrapper of a weighted vector with the sum pre-calculated. There're mainly two steps:

1. Create alias table
1. Sampling

To enable GPU acceleration, we can first generate the alias table on the CPU and then send it to the GPU. Then write a kernel on GPU to perform the sampling step.

The `make_alias_table!` function below is directly taken from [StatsBase.jl](https://github.com/JuliaStats/StatsBase.jl/blob/master/src/sampling.jl#L454-L511) with a small modification to make it compatible with `Float32`.

```julia
function make_alias_table!(w::AbstractVector{T}, wsum::S,
                           a::AbstractVector{T},
                           alias::AbstractVector{<:Integer}) where {S, T}
    n = length(w)
    length(a) == length(alias) == n ||
        throw(DimensionMismatch("Inconsistent array lengths."))

    ac = n / wsum
    for i = 1:n
        @inbounds a[i] = w[i] * ac
    end

    larges = Vector{Int}(undef, n)
    smalls = Vector{Int}(undef, n)
    kl = 0  # actual number of larges
    ks = 0  # actual number of smalls

    for i = 1:n
        @inbounds ai = a[i]
        if ai > 1.0
            larges[kl+=1] = i  # push to larges
        elseif ai < 1.0
            smalls[ks+=1] = i  # push to smalls
        end
    end

    while kl > 0 && ks > 0
        s = smalls[ks]; ks -= 1  # pop from smalls
        l = larges[kl]; kl -= 1  # pop from larges
        @inbounds alias[s] = l
        @inbounds al = a[l] = (a[l] - 1.0) + a[s]
        if al > 1.0
            larges[kl+=1] = l  # push to larges
        else
            smalls[ks+=1] = l  # push to smalls
        end
    end

    # this loop should be redundant, except for rounding
    for i = 1:ks
        @inbounds a[smalls[i]] = 1.0
    end
    nothing
end
```

The next step is to perform sampling on GPU:

```julia
function cu_alias_sample!(a::GPUArray{Ta}, wv::AbstractVector{Tw}, x::GPUArray{Ta}) where {Tw<:Number, Ta}
    length(a) == length(wv) || throw(DimensionMismatch("weight vector must have the same length with label vector"))
    n = length(wv)
    # create alias table
    ap = Vector{Tw}(undef, n)
    alias = Vector{Int64}(undef, n)
    make_alias_table!(wv, sum(wv), ap, alias)
    
    # to device
    alias = CuArray{Int64}(alias)
    ap = CuArray{Tw}(ap)
    
    function kernel(state, alias, ap, x, a, randstate)
        r1, r2 = GPUArrays.gpu_rand(Float32, state, randstate), GPUArrays.gpu_rand(Float32, state, randstate)
        r1 = r1 == 1.0 ? 0.0 : r1
        r2 = r2 == 1.0 ? 0.0 : r2
        i = linear_index(state)
        if i <= length(x)
            j = floor(Int, r1 * n) + 1
            @inbounds x[i] = r2 < ap[j] ? a[j] : a[alias[j]]
        end
        return
    end
    gpu_call(kernel, x, (alias, ap, x, a, GPUArrays.global_rng(x).state))
    x
end
```

<div class="alert alert-warning">
Especially take care of the 15~16 lines of the code above. By doing so it will avoid bound error in some extreme cases.
</div>

Now let's check the performance:

The result with GPU:

```julia

N, K = 10, 10^5

wv = rand(Float32, N)
a = CuArray{Int64}(1:N)
x = CuArray{Int64}(zeros(Int64, K));

@benchmark cu_alias_sample!($a,$wv, $x)

# BenchmarkTools.Trial: 
#   memory estimate:  5.22 KiB
#   allocs estimate:  124
#   --------------
#   minimum time:     77.197 μs (0.00% GC)
#   median time:      102.396 μs (0.00% GC)
#   mean time:        107.162 μs (1.07% GC)
#   maximum time:     18.155 ms (30.20% GC)
#   --------------
#   samples:          10000
#   evals/sample:     1
```

The result with CPU:

```julia
wv = weights(rand(Float64, N))
da = 1:N
dx = zeros(Int64, K)
@benchmark StatsBase.alias_sample!(Random.GLOBAL_RNG, $da,$wv, $dx)

# BenchmarkTools.Trial: 
#   memory estimate:  640 bytes
#   allocs estimate:  4
#   --------------
#   minimum time:     2.195 ms (0.00% GC)
#   median time:      2.233 ms (0.00% GC)
#   mean time:        2.240 ms (0.00% GC)
#   maximum time:     3.434 ms (0.00% GC)
#   --------------
#   samples:          2230
#   evals/sample:     1
```

About 20 times faster!

As you can see, in Julia we can easily leverage some existing code on CPU and port them to GPU without much effort!
