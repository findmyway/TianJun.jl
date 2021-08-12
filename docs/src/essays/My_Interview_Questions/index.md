---
keywords: Algorithm
CJKmainfont: KaiTi
---

# 我的面试题

## Update(20190918)

面了一天，头都有点蒙了，

<hr>

最近在知乎的时间轴上总是出现面试相关的问题，忽然想到一个比较有意思的事情，不妨把我平时遇到的一些问题提炼出来，写一个面试题汇总，下次再有人砸简历过来的时候先扔过去自测下，哈哈哈~

计划先写10个问题，暂时没打算给出标准答案，但是会写出问题的来源、我的思考过程以及一些hint，内容会涉及方方面面。

## 核心原则

~~来滴滴工作快一年了~~，关于公司文化，我印象最深刻的一点是：

> 招三年后能成为你上司的人

第一次看到这句话应该是在公司的洗手间。需要强调的是，这句话本身很值得玩味（刚去滴滴的时候恰好是四周年），成就他人，同时还要看到他人的增长潜力，对标自己现在的水平，以及目前自己上司的水平（技术/管理/沟通），呵呵，想出这句话来的人真有才。我个人对这个原则基本认同。

## 那么，问题来了

### Q0: 你所掌握的语言是如何影响你的思维过程的？

**问题来源**：《程序开发心理学》第12章的思考题。

**问题描述**：大多数应聘的人都会在简历上描述自己掌握或者了解的编程语言都有哪些，有些人可能对某种语言的细节和各种奇技淫巧非常熟悉，有些人可能对各种工具库的使用情况了如指掌，不过，大多数人可能没有想过这些语言是如何影响我们的思维过程的。

**Hint**: 每个人对这个问题的答案都不太一样，一方面是想从这个问题了解对方对于自己所掌握的语言的理解程度，从而对其编程能力有一个大致的预估；另一方面是了解对方的思维习惯和抽象能力，从而看出以后的工作中与此人共事是否愉快。对我自己而言，C中的指针（Reference）、Python中的Notebook（trial-and-error）、Clojure中的REPL和Macro（hot-fix，DRY等）是我一下子能想到的几点。

### Q1：概率
**问题描述**：
2M4. Suppose you have a deck with only three cards. Each card has two sides, and each side is either black or white. One card has two black sides.  e second card has one black and one white side.  e third card has two white sides. Now suppose all three cards are placed in a bag and shu ed. Someone reaches into the bag and pulls out a card and places it  at on a table. A black side is shown facing up, but you don’t know the color of the side facing down. Show that the probability that the other side is also black is 2/3. Use the counting method (Section 2 of the chapter) to approach this problem.  is means counting up the ways that each card could produce the observed data (a black side facing up on the table).

2M5. Now suppose there are four cards: B/B, B/W, W/W, and another B/B. Again suppose a card is drawn from the bag and a black side appears face up. Again calculate the probability that the other side is black.

**问题来源**：*Statistical Rethinking*一书第二章的习题

**Hint**：这个问题很基础，但很有意思，与之相似的一个问题是“三门问题”。这个问题还可以从很多个角度去扩展，比如计算信息熵、交叉熵等，总的来说就是希望对方能够对先验、似然、后验等概念很熟悉。进一步，还会考察下宏平均、微平均、辛普森悖论，以及均值、中位数、众数等基础概念的理解，以确保日常的数据分析中不会犯一些常识性错误。

**问题描述**
9. Simulation of a queuing problem: a clinic has three doctors. Patients come into the clinic at random, starting at 9 a.m., according to a Poisson process with time parameter 10 minutes: that is, the time after opening at which the first patient appears follows an exponential distribution with expectation 10 minutes and then, after each patient arrives, the waiting time until the next patient is independently exponentially distributed, also with expectation 10 minutes. When a patient arrives, he or she waits until a doctor is available. The amount of time spent by each doctor with each patient is a random variable, uniformly distributed between 5 and 20 minutes. The office stops admitting new patients at 4 p.m. and closes when the last patient is through with the doctor.
(a) Simulate this process once. How many patients came to the office? How many had to wait for a doctor? What was their average wait? When did the office close?
(b) Simulate the process 100 times and estimate the median and 50% interval for each of the summaries in (a).

**问题来源**：Bayesian Data Analysis 3 ed. 第一章习题部分第9题

**Hint**：这个问题之前似乎在某个面试题集锦中有看到过，能对结果做出解释就更好了。

**问题描述**：The question is to find the average number of rounds when playing the following game: P=6 players sitting in a circle each have B=3 coins and with probability 3⁻¹ they give one coin to their right or left side neighbour, or dump the coin to the centre. The game ends when all coins are in the centre.

**问题来源**：[https://xianblog.wordpress.com/2017/12/29/cyclic-riddle/](https://xianblog.wordpress.com/2017/12/29/cyclic-riddle/)

**Hint**:显然，如果只是简单地simulate一下，没有任何难度，难点在于，simulate之前，让面试者**凭直觉猜**，如何step-by-step地猜出结果，可以考验面试者的许多基础知识。（犹记得进微软面试的时候，shuneng问了我一个负泊松分布的问题，然而，当时还没读到《具体数学》里相关的部分，表现很糟糕:sweat:）

### Q2：Simulation

**问题描述：** 

**问题来源**：Mini Metro

**Hint**：TODO

### Q3: String

**问题描述：**

给定一些模板（million级别，短文本），模板中某些词需要根据字典展开（thousand级别），然后根据在线的用户输入返回所有匹配到的substring。如果模板需要根据动态更新呢？

**问题来源**：

目前的chatbot在许多场景仍然需要根据规则匹配来实现特殊的功能，所以如何设计一个高效的匹配算法，至关重要。对于算法基础较好的人来说，能够比较容易解决这个问题。那么，进阶一点的，如何做billion级别的匹配和相似性计算。再复杂点，你会怎么设计General Entity Extraction？

**Hint**：

考察多方面，Trie的应用，如何设计一个好的接口给别人调用，Aho-Corasick,理解faiss中的一些参数的含义，如何在实际业务中计算string的相似度。

### Q4: Y Combinator

**问题描述:**

给定2个函数，`dec`和`zero?`,如何不用递归实现`is-even?`和`is-odd?`？

**问题来源:**

EOPL Exercise 3.23, 3.24

**Hint**

目的主要是考察下思维切换的能力。如果能在给出Y Combinator的一般形式的情况下能写出来即可。当然，如果面试者对相关概念很熟，不妨再深入聊点进阶的话题。