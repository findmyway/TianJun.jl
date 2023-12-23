# 👋 关于

```@raw html
<div class="avatar"></div>
```

## 关于我的头像

原始照片拍摄于2012年的夏天，中南大学南校区图书馆前的小树林里，手里拿的是哪本书已经忘了，不过那支笔我还记得，是一支铅笔。
拍摄者是我老婆。

## 关于我

经历：

- **2023至今**，在[零一万物](https://01.ai/)从事大模型方向基础架构方面的工作。(持续招人中...🤗)
- **2022~2023**，在启元世界从事游戏领域的自然语言理解与强化学习。
- **2017~2022**，在微软从事自然语言处理相关的工作。
- **2016~2017**，在滴滴出行从事智能补贴和调度的工作。
- **2013~2016**，中科院自动化所自然语言处理处理方向硕士。
- **2009~2013**，中南大学自动化专业本科。

联系：

- [Twitter](https://twitter.com/TianJun1991),偶尔上去逛逛。
- [微信](/assets/wechat.jpg),不怎么发朋友圈，没啥可看的。
- [豆瓣](https://www.douban.com/people/find_my_way/)，偶尔上去记录下。
- [lichess](https://lichess.org/@/Jun_Tian)，有兴趣来一把？

开源：

- [ReinforcementLearning.jl](https://github.com/JuliaReinforcementLearning/ReinforcementLearning.jl)，最近一段时间的主要精力都花在了这上面。
- [趣学Julia](https://learnjuliathefunway.com/)，前段时间刚开了个坑，还没来得及写点东西。
- [Julia中文社区](https://discourse.juliacn.com/)，经常去上面回答问题。

编程：

- [Clojure](https://clojure.org/)，（曾经）最喜欢的编程语言。
- [Julia](https://julialang.org/)，目前觉得最好用的语言。

还有其它想知道的？欢迎来这里[🙋 提问](/AMA)。

## 关于本站

这个网站我折腾过好几次，目前体会最深的一点是，**请用你最熟悉的工具**。

我目前主要的业余时间都在写Julia，某种程度上讲，我对Julia的熟悉程度甚至超过了工作中所使用的其它编程语言。这也是为什么这一次将博客换成了基于Julia的一套构建流程。在Julia中，广泛使用的是一套是基于[Franklin.jl](https://franklinjl.org/)来构建博客，比如[Julia的官方博客](https://julialang.org/blog/)，不过综合考虑之后，我决定直接基于[Documenter.jl](https://github.com/JuliaDocs/Documenter.jl)来构建。一方面是我有选择恐惧症，面对各种各样的主题模板实在是不知道选哪个好，而自己从头写一个模板又没有那个时间精力了（虽然我之前确实写过一个[Distill](https://github.com/tlienart/DistillTemplate)的主题）；另一方面，我能力有限，实在是没有完全搞清楚`Franklin.jl`的代码是如何工作的，这让我在使用的过程中感觉很慌...... 相比之下，我对`Documenter.jl`比较熟悉，了解如何做一些个性化的定制。

整个博客的发布流程基本和一个普通的julia安装包的文档发布流程一样，只不过我单独写了一些[自定义的插件](https://github.com/findmyway/TianJun.jl/blob/master/docs/common.jl)，所以，如果有人有兴趣构建一个和我类似的博客的话，只需要把这些插件复制粘贴到`make.jl`文件里即可。

本站发表的内容默认遵循 [CC-BY-4.0](https://creativecommons.org/licenses/by/4.0/)。
