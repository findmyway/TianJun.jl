---
keywords: Python,Book
CJKmainfont: KaiTi
---

# （4）一起用python之基础篇——入门书

## 写在前面

从快毕业的时候在图书馆里借来第一本有关python的书算起，接触python的时间也不过半年有余。时间真的很短，很难有什么经验之谈，自己至今也仍有许多需要学习的地方。不过对于怎么入门这一块，倒是颇有感触。在这里记录下来，也许能对后人有所帮助吧~

## 我是怎么开始了解python

快毕业的时候，在中南的图书馆里瞎逛，偶然之间看到这么一本书，《可爱的python》。第一眼看上去，只是觉得书名还挺新颖的，反正也是闲着，抽出来看看吧。“**人生苦短，我用python**”，这是我在封面上看到的第一句话，这感叹句实在太吸引眼球，以至于这么长时间后，我早忘了书中讲的什么内容。留在脑海中的就只有封面上的这句话和作者的前言。

当时看完前言部分，我就感慨良多。一本好的编程入门书，不应该是一上来就告诉你怎么写Hello World，给你介绍变量、函数、控制流 blablabla...，而是作者站在一个朋友的角度来和你谈心，告诉你他自己学习这门编程语言的经历，他自己所体会到的这门编程语言的魅力在哪里，有哪些优点和不足之处，怎样能够更快更好地熟悉这门语言。这感觉就和当初学C++时候读的第一本书《Thinkng in C++》一样。作者提到，由于python这门语言的特殊性，对它的学习并不必拘泥于传统的教科书式的学习方式，而是重点在“使用”中学习，其基本思想就是用最短的时间掌握python最基础最核心的语法，然后在使用中碰到具体的问题时候，再去主动学习相关知识。这个观念对我的影响很深，可以说，回顾自己的历程，基本就是按照这个原则来的，而且收获确实很多。

下面就结合我自己的学习经历，谈谈刚入门时候的基本原则。

### 你只需要掌握最基础的

刚开始学习python的时候，可能会查看许多书，这些书为了能够涵盖得尽量全面，往往会涉及语言方方面面的细节。但是，*并不是每一个知识点都是你所需要的*。一开始你只需要掌握最基础的那部分知识。你可能会问，“我哪知道哪些是最基础的东西呢？” 我觉得，一个很简单的判断方法就是，拿起书都第一遍的时候，如果你能硬著头皮看下去并且能够理解里面所讲的内容，那很好，这就是最基础的。如果看了第一遍后云里雾里，鬼才知道哪天会用得上这些东西。OK，专门找个小笔记本，记下这部分内容方便以后查阅，然后，`跳过`这部分。我在第一次看decorator装饰器这个部分的时候实在看不下去，也不知道可能会有啥用，果断跳过，最近上高性能计算的课，学习下cuda的python接口时，里面都是装饰器修饰的函数，才又好好学习来一下，结合来自己的实际问题，这样理解起来也就更深入。

### 脚踏实地，出来混，迟早是要还的

记住，前面你跳过的那些问题，迟早是会冒出来的。你自己得清醒地意识到，这种**刻舟求剑**式的做法，是存在一些弊端的，虽然大多数时候，这些弊端不过是自己动手来实现一些别人已经实现来的东西，多花点时间精力罢了，但还有的时候，你可能会付出沉重的代价。类似的教训实在太多，比如看书的时候觉得itertools这个包没有太大用就跳过了，后来有一天要实现个排列组合的算法时花了很长时间来实现，结果偶然一天看到这货居然内置在iterrools里了；还有迭代器和生成器那部分，一开始以为自己可能用不到，后来要对一堆很大的文本做分析时候才发现内存不够了......所以说，出来混，迟早是要还的，那些跳过了东西，迟早某一天要出来坑你一把。那肿么办咧，**跳还是不跳**，这是个问题，个人觉得，刚入门的时候，还是能跳就跳吧。等自己对这门语言产生兴趣了，再来深入了解其语言的细节，也不算太晚。

### 多读书，都好书

关于python的书虽不如C++，Java之类的那么多，但好书却不少了，这半年看了有十多本书了吧，整体感觉质量都挺不错。以下按照由浅入深的顺序来推荐给大家。

- 相信我，你看的第一份文档，应该是[The Python Tutorial](http://docs.python.org/3/tutorial/index.html)。什么？英语的看不懂！我去，你都还没开始看！！！

- 看完上面的教程后，你可能会有种意犹未尽的感觉，难道，只需要这么点知识我就算入门了吗？如果你看完毫无压力，我只能说真的，这样就算入门。不过除此之外还有另外一些讲解python基础书，也值得一看。你应该把大多数时间花在上面这份tutorial上，下面(1)中基础点的书应该是当作补充。看这几本书的时候，牢记上面的两条原则！(我是不会告诉你下面的这些书大多都有中文版的:~)

    1. 基础点的：[A Byte of Python](http://files.swaroopch.com/python/byte_of_python.pdf), [learn python the hard way](http://learnpythonthehardway.org/book/)
    1. 稍稍进阶点的：[dive into python 3](http://www.diveintopython3.net/)
    1. 需要当工具书一样看的：[The Python Standard Library byExample](http://it-ebooks.info/book/1506/)
    1. 骨灰级的：[Python Cookbook, 3rd Edition](http://it-ebooks.info/book/2334/)

### 好用才是王道

看完上面这些书，你应该对python的基本语法特性，内部的标准库有了很深的了解。但是，我最想说的是，并不一定要等的你把这些书都读完了才开始做些事，（事实上，读完那份tutorial你就可以动手做很多事了）。你应该很清楚的知道自己要用python来做什么！！！想当初大一学c语言时候，学了也不知道为什么而学，所以啊，最后学完了那些语法知识后全都丢到一边，我那时候哪还知道c可以用来干那么多事。就我自己而言，学习python的目的是为了在一定程度上代替matlab作为科学计算工具，利用其丰富的包来实现许多功能，另外，用python写的代码可读性很高，不管是自己写还是读别人的代码，都是一种享受。

我想，你也一定有自己使用python目的，比如想用python爬网络上的资源，比如要用python建个网站，又或者是要和服务器上的后台打交道...你总可以找到自己要学习的那个部分，记住，`把重点花在这里！`。然后，等你对python有一些感性认识了，某一天自然会想起来要了解下python的底层是怎么实现的，为什么这样做比那样做更好等等问题。

编程语言说到底也只是工具罢了，工具固然是越好用越好，但更重要的是你要知道拿这些工具去解决什么样问题，以及怎样去解决！