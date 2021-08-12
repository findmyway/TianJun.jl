---
keywords: Game,ReinforcementLearning,Hanabi
CJKmainfont: KaiTi
---

# Let's Play Hanabi!

Papers are removed. (2021-08-12)

This blog provides some detailed information for my lighting talk on JuliaCon 2019 ([Let's Play Hanabi!](https://pretalx.com/juliacon2019/talk/8T3FVZ/)).

You may find the slide [here](./slide/LetsPlayHanabi.pdf) and the source code [here](https://github.com/findmyway/LetsPlayHanabi).

## The Rainbow Algorithm

Writing the Rainbow algorithm in Julia is relatively easy. It's just three dense layer together with a projection step. Although the structure is simple, it's not always that easy to make it work as we expect. Many parameters need to be tuned and some steps are not well documented in the original paper. (The evil lives in details!) You may read [Understanding Prioritized Experience Replay](https://danieltakeshi.github.io/2019/07/14/per/) to get a better understanding of what I mean here. To make things easier, I just keep all the parameters and loss calculation step the same with the original implementation in [deepmind/hanabi-learning-environment](https://github.com/deepmind/hanabi-learning-environment). And the result shows that these two implementation behaves similarly, except the speed.

With CPU only, the Flux based implementation is much slower compared to the TensorFlow based one. One of the most important reason is that TensorFlow will utilize available CPU as much as possible, even I manually change `tf.device("/cpu:*")` into `tf.device("/cpu:0")` or `tf.device("/cpu:1")`. So instead, I rerun the TensorFlow code in a docker environment with only 1 cpu allocated (by setting `--cpuset-cpus=0`) and the training speed decreased from 258 steps per second into 200. There's still an obvious advantage compared to my Julia implementation. I did some benchmark, it seems that the backpropagation step was the bottleneck. I tried to switch the `Tracker` into `Zygote`, hoping that it could be faster. However a strange error occurred and I was not sure how to fix it at that time.

With GPU enabled, the Flux based implementation is much faster. The speedup comes from two parts: the fused broadcast and `@view`. With fused broadcast, we can speed up the projection step. In theory, if we turn on the XLA in TensorFlow, we should witness similar improvement in the TensorFlow version. But I found that simply using the session config as described [here](https://www.tensorflow.org/xla/jit#session) in the original implementation seems not work. I guess that the reason is that some CPU computing steps are included in the training op. I haven't tried to manually optimize only the projection step yet.

The more interesting thing is that, the same Julia code runs faster on RTX 2080 TI compared to V100. The benchmark of a simple matrix multiplication shows that, for the size of 512 * 512 (the hidden layer size in my problem) it is about 1/3 faster on RTX 2080 TI. But for some large matrix multiplication, say 8192 * 8192, there isn't much difference on these two cards.

## Distributed Experience Replay Buffer

You may think it is relatively easy to adapt the Rainbow algorithm to the distributed version, after all Julia has a good support for parallel computing. But after some attempts, I must admit that there's no easy way. If we choose the multi-threading based implementation, obviously it can't be applied to multiple machines. If we choose the multi-processing, then the performance is not that good (I'll explain it soon). So it seems that a hybrid mode would be great, but that needs a delicate design.

Th Ape-X contains a learner and multiple actors. Each one can live in an independent processor. The difficult part is how to communicate between learner and actors. Here learner and actor both run very fast. The learner runs on a GPU and the actor only do forward inference. And the communication contains four parts:

### Parameter Sharing

Actors need to update their parameters periodically from the learner. Assuming that we have hundreds of actors, each time an actor invoke a remote call, it will slow down the speed of the learner. So the best way is that the learner periodically send it's parameters to a intermediate scheduler and let it communicate with other actors.

### Experience Updating

Actors will generate experiences as fast as possible with priorities pre-calculated. Then those experiences are cached locally for a while and sent to the global Prioritized Experience Replay Buffer. There shouldn't be any problem if the global buffer is an independent processor.

### Sample Generation

If the global Prioritized Experience Replay Buffer is in the same processor, then the experience updating step will slow down the learner. Otherwise, there's a overhead to copy experiences to the learner. I found it hard to balance these two.

### Experience Priority Updating

All the experiences consumed by the learner will be updated with new priorities.

As you can see, there are multiple steps updating the global experience replay buffer simultaneously. In the [pytorch](https://github.com/belepi93/Ape-X) implementation, there's a good picture demonstrating each component.

My feeling is that, it's really hard to keep the speed of learner and actor well balanced.

## Bayesian Action Decoder

This method is really elegant. The only problem is that it runs too slow. I'll update this part once I finished changing the original policy gradient based implementation into value based methods.
