---
keywords: Python,Lisp,Hylang
CJKmainfont: KaiTi
---

# Write Python in Lisp

上周在Clojure微信群里，[Steve Chan](https://github.com/chanshunli)分享了个关于[Hylang](https://github.com/hylang/hy)的链接，让人眼前一亮，原来Python居然还可以这么写！经过这几天的摸索，意外地感觉不错，在这里推荐给大家试试，有兴趣的话可以看完官网的doc后再回来看下文。

## Hylang是什么？

Hy是基于python的lisp方言，与python的互操作非常顺畅，有点类似clojure于java的关系。从安装上可以看出，Hy实际上就是一个普通的python库，在python代码中可以直接`import hy`之后，把`.hy`文件当做普通的python文件，import其中的变量。核心代码部分，该有的也都有（最重要的当然是macro），可以从clojure无障碍迁移过来。

由于是直接把lisp代码转换成AST，开启`--spy`模式之后，可以看到每一行lisp代码转换之后的python代码，各种库的操作也完全没有障碍。试用了一些常用的库，基本没有什么大问题。目前感觉不是够顺畅的地方，反而是一些外围，比如没有很好的编辑环境。社区的vim插件提供的功能很弱，为此我特地入坑spacemacs！emacs对应的插件稍微好点，提供了发送代码到repl的功能，不过最重要的仍然是，没有代码补全，网上有人提供了一些静态的补全方案，通过提取hy库中的关键词和当前buffer中的变量名来补全（没有配置成功......），不过实际使用中会大量调用python库，因此急需像python里的anaconda-mode一类工具提供辅助补全。再比如静态语法检查，调试。

## Hylang不是......

### Hylang不是Clojure

这个是首先需要意识到的一点。尽管在语法和许多函数上和clojure很像，但是因为底层实现和语言的定位不一样，这其中的许多函数不再是clojure中对应函数的完整复制。以下列举一些很容易碰到的问题：

1. muttable & immutable. Hylang本身的定位是鼓励与python的互操作，因此大量的操作都是基于python本身的数据结构，需要非常小心数据随时都可能改变。在写Hylang代码的时候需要时刻提醒自己，“我写的是python代码！代码都会最终转换成python代码去执行！”，社区里最近也在讨论引入immutable的数据结构，不知道这块以后会怎么发展。
2. lazy. Hylang中大多数代码的lazy实现都是基于generators实现的了iterable，这下就蛋疼了。在python里，生成器访问一次之后，如果你不保存的话，数据就没有了......所以你会发现`(take n coll)`中，如果xs是一个iterable的数据，上面的代码执行多次是可能得到不同结果的。甚至如果不保存的话，没法访问已经被访问过的内容。不过好在0.12.0之后提供了lazy sequences，一定程度上缓解了这个问题。
3. in-place operations.在python中，许多函数都是默认in-place的，比如`sort`,`random.shuffle`等，有些可能提供了对应的非in-place的函数（如`sorted`），有些则没有。这点需要格外注意，否则，定义变量的时候很可能返回值就是个`None`。不过在`numpy`,`tensorflow`,`pandas`等库中，这点考虑得比较全面
4. scope. 看github上过去关于`let`绑定的issue，可以深入了解这块内容。在不确定变量名的scope时，可以看看对应的python代码。

## 体验过程中的一些坑

1. 文件名。写过了clojure的话会习惯`-`作为连接符，`hy`的文件名需要转换成`_`连接符，否则在python代码中不能import。
2. 某些函数的的实现有bug。我自己在尝试的过程中就发现了`partition`函数的实现有点问题，在github上提了个issue。社区里的反应还是挺快的，第二天就解决并合并到master上了。
3. 参数传递过程中，运用apply传递positional和named arguments时，需要分别用list和dict对二者封装，不能偷懒直接用一个list搞定。

## Hylang适合写点什么？

写Hylang也就这几天，对macro的感受还不是很强烈，主要是写了点日常的数据分析代码和tensorflow中的tutorial，以下是一些个人感受：

- 如果只是写一些调用API的代码，其实不太适合。比如我在翻译tensorflow的tutorial过程中，需要反复去查对应的API，很繁琐，而且已有的框架会在不知不觉中对写lisp风格的代码有一些限制，从而使得python代码更适合命令式地处理逻辑。
- 适合更抽象层的数据预处理逻辑。这块写起来会很舒服，对读代码和写代码的人来说，都是一种享受。可以将二者结合，这部分代码用hy处理后以接口的形式暴露给模型构建部分，最后再用hy糅合train,valid,test的过程。当然，现在某些库（tensorlayer）实际上把直接跟tensorflow打交道的部分做了很浅的一层封装，整体易用性更高了。

最后，一点学习经验：

> When I’m learning something new, I sometimes find myself practicing EDD (exception-driven development). I try to evaluate some code, get an exception or error message, and then Google the error message to figure out what the heck happened. -- *Mastering Clojure Macros*

另外，这个语言还是太小众了，玩玩就可以了，别太当真......