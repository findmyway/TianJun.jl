---
keywords: Java
CJKmainfont: KaiTi
---

# Java 8 中的Optional

最近在公司的一些内部服务中，主要都在用Java8开发，各种数据流的操作非常方便，虽然还赶不上clojure，但是也很不错了。在公司内部做服务的开发会有些头疼的问题，比如协作和代码审查。这里就聊聊协作中的一个细节：Optional。

因为类的主体是自己设计的，中间一些参数传递的都是Optional类型，协作的时候，对方很困惑，为什么需要Optional呢？好处是啥？我说，“预防空指针的问题呀~”。然后对方默默地写了一行代码：``long x = getFinishTime().orElse(null)``，然后欢快地用``if(x == null){...}else{...}``继续写代码去了。这个时候我就在思考另外一个问题：如果一个这样简单的概念都很难让大家广泛接受，那Haskell中那些复杂的特性又该如何可持续发展呢？

## 如何理解？

Optional的API介绍有很多，这里不重复介绍。我自己将其主要分为3类：

1. initial（``empty``,``of``, ``ofNullable``）
1. transform (``filter``, ``flatmap``, ``get``, ``isPresent``, ``map``, ``orElse``, ``orElseGet``, ``orElseThrow``)
1. action (``ifPresent``)

初看可能觉得，transform和action只是些语法上的简便处理，我实际使用中最大的体会有两点，一是真的大大减少了空指针的异常，毕竟传递一个Optional变量的时候，就好像变量自己会说话，“Hey，注意检查我哦~”，通过合理地使用Optional变量，可以很方便地定位一些本不应该出现空指针的问题，这在协作的时候很方便；此外，Optional变量能够很好地嵌入到stream中（虽然还有一点点不太方便的地方，Java9中有改进），使得整体的代码更简洁，可阅读性更高。

那有么有啥技巧呢？

## 减少``get``的使用！

显然，如果频繁使用``get``方法，那就意味着频繁使用``isPresent``，结果就是回到原来``if...else``的老路上了。可以参考[Java 8 Optional – Replace your get() calls](https://reversecoding.net/java-8-optional-replace-get-examples/)理解如何做代码替换。当然，有一点需要注意，不必强制将所有get都替换掉，Java8的一些函数式方法不是特别完善，有时候灵活处理下反而更方便。