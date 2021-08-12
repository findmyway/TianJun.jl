---
keywords: Survey,ReinforcementLearning,Python
CJKmainfont: KaiTi
---

# 深度强化学习相关库概览

> 知己知彼，方能百战不殆！

在写一个新的DRL库之前，不妨先学习下已有工具包的组织架构，以及不同的工具包都有哪些优缺点。

以下是本文重点考虑的几个库(也欢迎推荐其它优秀的库)：

- [DeepRL](https://github.com/ShangtongZhang/DeepRL)
  这个库基于PyTorch，作者之前写了*Reinforcement Learning: An Introduction*的Python实现。似乎是前不久刚public的，可以看出作者的Python编码能力在这一年里似乎进步了不少😋，总之，DeepRL的结构还是蛮清晰的。
- [Coach](https://github.com/NervanaSystems/coach)
  据说是架构最清晰的一个库，支持TensorFlow。
- [TensorForce](https://github.com/reinforceio/tensorforce)
  也是基于TensorFlow的一个库。
- [RLlib](https://github.com/ray-project/ray/tree/master/python/ray/rllib)
  这个框架需要花点时间仔细研读下源码，里面封装了一个Actor模型用来处理分布式并发执行的逻辑依赖问题，做法跟Coach的那类Parameter sharing很不一样，从论文上来看，效率也要高很多，感觉是未来的一个趋势。得花时间想想channel模型是否适用（毕竟Julia目前并没有内置的actor模型）。

## DeepRL

整个库是围绕着Agent对象展开的，通过config初始化Agent对象，然后在外围执行`run_iterations`或`run_episodes`控制进度。OO的思想有点重，以至于初始化的时候需要指定的部分非常多。

### Pros

- Agent的划分很清晰，基本都控制在100行代码以内
- 在Gym的基础之上又套了一层Task，这个值得借鉴
- 在对PyTorch封装的部分，抽象出了`network_body`和`network_head`，姑且理解为编码层和输出层，这个也值得学习借鉴
- 有logger模块，后面自己实现的时候，可以结合类似TensorBoard的工具打log

### Cons

- 没有文档
- Agent中与环境交互部分耦合得比较紧，把一些step和rollout单独划分出来会更简洁些
- 一些小的模块作者已经在注意抽象了，比如replay等，但是接口还需改进
- 并行化，跑多个副本

## Coach

目前粗略看了下，真的是相当清晰。要是有一些Guide知道如何新写一个Agent，怎么做Compare等等，应该会有更多的人Envolve进来。后面写的时候应该会反复参考这个库。

怎么并行化运行多个task，以及维护一个Parameter Server，暂时没有想好如何在Julia中实现，直觉告诉我这点应该是Julia的优势。

## TensorForce

目前文档还不是很全，但目前看到的几点值得学习的地方是：

- contrib中，对不同环境做了统一抽象，这个跟我正在做的不谋而合
- agent虽然也按类做了划分，但是感觉不如Coach做得好
- 跟TF绑定得有点太紧了