---
keywords: Design,Julia
CJKmainfont: KaiTi
---

# A Draft Design of Distributed Reinforcement Learning in Julia

I've been thinking for a while about how to design a distributed reinforcement learning package in Julia. Recently I read through the source code of some packages again, including:

- [Ray/rllib](https://github.com/ray-project/ray)
- [ReinforcementLearning.jl](https://github.com/JuliaReinforcementLearning/ReinforcementLearning.jl)
- [Dopamine](https://github.com/google/dopamine)
- [trfl](https://github.com/deepmind/trfl)
- [DeepRL](https://github.com/ShangtongZhang/DeepRL)

and some other resources included [here](https://github.com/JuliaReinforcementLearning/ReinforcementLearning.jl/wiki/Roadmap) by [Joel](https://github.com/JobJob). Although I still don't have a very clear design, I would like to write down my thoughts here in case they are useful for someone else.

The abstractions for reinforcement learning in rllib are quite straightforward. You may refer [RLlib: Abstractions for Distributed Reinforcement Learning](http://proceedings.mlr.press/v80/liang18b.html) for what I'm talking in the next.

1. BaseEnv
1. Policy Graph
1. Policy Evaluation
1. Policy Optimizer
1. Agent

It has been demonstrated that by using the concepts above most of the popular reinforcement learning algorithms can be implemented in rllib. However, it's not that easy to port those concepts directly into Julia. One of the most important reason is that we don't have an existing foundamental package like Ray. And the infrastructure of parallel programming in Julia is quite different. In the next section, I will try to adapt those concepts in Julia and describe how to implement some typical algorithms in the very high level.

## Actors Actors Actors

### Environment

Let's start from the environments part first. Environments in RL are relatively independent. By treating all environments asynchronously, rllib shows that it would be very convenient to introduce new environments. So here we also treat environments as actors running asynchronously.

First, we introduce the concept of `AbstractEnv`.

```julia
abstract type AbstractEnv end

function interact!(env, actions...) end
function observe(env, role) end
function reset!(env) end
```

Then we can wrap it into an actor

```julia
env_actor = @actor begin
    env = ExampleEnv(init_configs)
    while true
        sender, msg = receive()
        @match msg
            (:interact!, actions) => interact!(env, actions)
            (:observe, role) => tell(sender, observe(env, role))
            (:reset!,) => reset!(env)
            # do something else
            (:ping,) => tell(sender, :pong)
        end
    end
end

# The code above can be further simplified by introducing an `@wrap_actor` macro
env_actors = @wrap_actor ExampleEnv(init_configs)
```

### Policy

In the next, we can have a `PolicyGraph` object like the one in rllib:

```julia
abstract type AbstractPolicy end

function act(pg, obs) end
function learn(pg, batch) end
function set_weights(pg, weight) end
function get_weights(pg) end
```

### Evaluator

An evaluator will combine Policy and Environment together.

```julia
abstract type AbstractEvaluator end

struct ExampleEvaluator <: AbstractEvaluator
    env_actor
    policy
    #...
    ExampleEvaluator(env, policy, params..) = new(@wrap_actor env, policy, params...)
end

function sample(ev::Evaluator) end
```

Again, we can wrap it into an actor.

```julia
ev_actor = @wrap_actor ExampleEvaluator(env, policy, params)
```

When the `ev_actor` is invoked, a environment actor will also be invoked (in the same processor by default)

### Optimizer

An optimizer will interact with evaluators and do something like parameter updating and distributed sampling.

### Demo

Putting all components together. We have the following graph to show how each component is working in the Ape-X algorithm.

TODO: Add figure

And the pseudocode is:

```julia
# 1. create environments
env_actors = @wrap_actor CartPoleEnv(configs)

# 2. create policies
policy = DQNPolicy(configs)

# 3. define evaluators
mutable struct ApeXEvaluator
    env_actor
    policy
    batch_size
    n_samples
    replay_buffer
end

function sample(ev::ApeXEvaluator)
    while true
        if ev.n_samples >= ev.batch_size
            return sample(replay_buffer, evn.batch_size)
        else
            r, d, s = @await observe(ev.env_actor)  # it will be translated into send/receive
            a = ev.policy_actor(s)  # it will be translated into send/receive
            # update replay_buffer
            # calc loss
            # update grad
        end
    end
end

ev_actors = @smart_actors ApeXEvaluator env_actors policy_actors

# 4. optimizer
mutable struct ApeXOptimizer
    local_ev
    remote_evs
end

function step(optimizer::ApeXOptimizer)
    samples = @await get_high_priority_samples(optimizer.remote_evs)
    # evaluate local_env
    # broadcast local_weights
    # update priority of replay buffer
end
```