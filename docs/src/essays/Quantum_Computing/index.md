---
keywords: QuantumComputing,Julia
CJKmainfont: KaiTi
---

# 量子计算入门

本文用于记录我学习量子计算的过程。

(Suspended due to priority change.)

## Some Key Concepts

### Bloch Sphere

## Resources

### Web Pages

- [Quantum computing for the very curious](https://quantum.country)

    Michael Nielsen 写的简介，读下来很有收获，重新点燃了学习的兴趣！

- [The best resources for learning about quantum computing](https://medium.com/@johncoogan/the-best-resources-for-learning-about-quantum-computing-4fcc9f3cbe56)

    目前找到的最好的入门资料汇总。

- [Awesome quantum machine learning](https://github.com/krishnakumarsekar/awesome-quantum-machine-learning)

    量子计算与机器学习的结合。

### Books

#### [Introduction to the Theory of Computation](https://book.douban.com/subject/12986396/)

![Introduction_to_the_Theory_of_Computation.jpg](Resources/img/Introduction_to_the_Theory_of_Computation.jpg)

这本书用来补一下有关计算复杂度的知识。
很意外，这本书的Part 1 部分，填补了之前读[EOPL](https://book.douban.com/subject/3136252/)的一些关于Parser的空白。关于自动机，正则表达式，CFG的讲解一气呵成。Part2部分对图灵机有了更多的了解，halting啥的不再停留在表面的认识。读完Part3之后对复杂性有了新的的认识，之前看到有一个书评说，如果你在别人高谈阔论P，NP，NP-complete等问题时感到一脸懵逼，请立即抱起这本书，这里有你想要的答案。

#### [Quantum Computing Since Democritus][QCSD]

![Quantum_Computing_Since_Democritus.jpg](Resources/img/Quantum_Computing_Since_Democritus.jpg)

这本书没法评价。

因为压根没读懂，水平有限，摊手......

前几章跟Quantum Computing的关系不大，开篇的冷笑话，真的好冷......以至于我真的只记住了那句话(有兴趣的话，可以去看看作者的[博客](https://www.scottaaronson.com))：

> But if quantum mechanics isn't physics in the usual sense - if it's not about matter, or energy, or waves, or particles -then what *is* it about? From my perspective, it's about information and probabilities and observables, and how they relate to each other.

我能体会到作者独特的视角，无奈，自己相关的基础并不扎实，强行读到了第十章，后面的部分只是草草翻了下。后来偶然在网上看到了别人写的一篇[review](http://slatestarcodex.com/2014/09/01/book-review-and-highlights-quantum-computing-since-democritus/)，深有同感。总的来说，如果你看到chapter1~8的标题之后，确认你对相关内容不那么陌生（不是熟悉或精通），那么可以断定这是一本非常值得一读的书，否则真的很难跟上作者的脚步（当然，你也可以像我一样，不妨先读读试试～）。Anyway，即使只读了前十章，也依然收获颇丰，许多亮点与前面提到的那篇[review](http://slatestarcodex.com/2014/09/01/book-review-and-highlights-quantum-computing-since-democritus/)有许多共通之处。这里只说我感受最深的一点：

> There are two ways to teach quantum mechanics. The first way - which for most physicists today is still the only way - follows the historical order in which the ideas were discovered...
> The second way to teach quantum mechanics eschews a blow-by-blow account of its discovery, and instead *starts directly from the conceptual core* - namely, a certain generalization of the laws of probability to allow minus signs )and more generally, complex numbers).

作者首先提到了目前学习量子原理的两种方式（作者在书中采取的是后者），然后说道：

> *Quantum mechanics is what you would inevitably come up with if you started from probability theory, and then said, let's try to generalize it so that the numbers we used to call "probabilities" can be negative numbers. As such, the theory could have been invented by mathematicians in the nineteenth century without any input from experiment.* **It wasn't, but it could have been**.

是的，**实验先于理论**。另外两个类似的例子是**进化论**和**狭义相对论**。读到这里时，我联想到的是目前深度学习的现状，何其相似。作者认为：

> More often than not, the *only* reason we need experiments is that we're not smart enough.

#### [Q is for Quantum][QfQ]

![Q_IS_FOR_QUANTUM](Resources/img/Q_IS_FOR_QUANTUM.jpg)

吸取读上一本书的教训，还是先从简单点的入手。这本小册子很薄，总共150多页。作者构建了一个PETE BOX，用图形化的语言来阐述量子计算相关的一些概念。

PART 1 部分，对比经典计算机中的与或非门，清晰地描述了*量子门*(PETE BOX)的特性。

关键词：

1. superposition / misty state
1. interfere
1. collision

PART 2 部分，用一个很形象的例子（心灵感应?）讲清楚了一个很有意思的现象：

[**Entanglement**](https://en.wikipedia.org/wiki/Quantum_entanglement)

PART 3展开讨论了什么是**REALITY**，这部分相比前两部分理解得没那么透彻。照惯例，附上两篇书评：

- [Q is for Quantum & “reality”](https://tomate.wordpress.com/2017/10/03/q-is-for-quantum-reality/)
- [Review: Q is for Quantum by Terry Rudolph](http://janjanjan.uk/2017/08/29/review-q-quantum-terry-rudolph/)

#### [Picturing Quantum Processes][PQP]

![Picturing Quantum Processes](Resources/img/picturing_quantum_processes.jpg)

感觉这本书更适合在有一点点量子计算的基础之后再读，然后应该会有种耳目一新的感觉，居然还能采用这种方式来描述。目前读了大约1/5，基本能跟上作者的节奏，读这本书之前稍微回顾下线性计算会好点，有利于融会贯通。暂时需要先放下来，因为读这本书对我这种新手来说会比较累，需要同时理解两套理念（尽管二者并非独立的关系），留到后面有一定基础了再看下。

#### [Quantum_Computation_and_Quantum_Information][QCQI]

![Quantum_Computation_and_Quantum_Information](Resources/img/Quantum_Computation_and_Quantum_Information.jpg)

这本书同步进行中。

#### [Linear Algebra Done Right (3rd ed)][LADR]

![Linear_Algebra_Done_Right](Resources/img/Linear_Algebra_Done_Right.jpeg)

有些线性代数相关的部分需要回顾下。

这本书对应的[Solution](http://linearalgebras.com/)

此外，关于线性代数，[3Blue1Brown](https://www.youtube.com/playlist?list=PLZHQObOWTQDPD3MizzM2xVFitgF8hE_ab)这个视频合集也很不错。

[QCQI]: https://book.douban.com/subject/6937989/
[LADR]: https://book.douban.com/subject/26265880/
[PQP]: https://book.douban.com/subject/26995979/
[QfQ]: https://book.douban.com/subject/27167701/
[QCSD]: https://book.douban.com/subject/12030716/