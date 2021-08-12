---
keywords: OCaml,DataStructure,FunctionalProgramming
CJKmainfont: KaiTi
---

# Why

最初看到[CS3110][]这门课也挺巧合的，之前写这个网站的时候，用到了clojure下的一个库[clojure.zip][]，然后知道其中的实现是根据[Functional Perl The Zipper][]这篇paper实现的，尝试去读这篇论文的时候，看到里面用的sample使用OCaml写的，里面的第一句话就是：

> The main drawback to the purely applicative paradigm of programming is that
many efficient algorithms use destructive operations in data structures such as bit
vectors or character arrays or other mutable hierarchical classification structures,
which are not immediately modelled as purely applicative data structures. A well
known solution to this problem is called *functional arrays* (Paulson, 1991)

然而，我连function arrays在这里是指什么都不知道，于是google了下，碰巧就看到了[CS3110][]这门课，初略看了下，感觉挺有意思的一门课，所以打算完整学习下，提升下自己对Functional Programming的理解。

[CS3110]: http://www.cs.cornell.edu/courses/cs3110/2016fa/
[clojure.zip]: https://clojuredocs.org/clojure.zip
[Functional Perl The Zipper]: https://www.st.cs.uni-saarland.de/edu/seminare/2005/advanced-fp/docs/huet-zipper.pdf

# LEC 1

这部分主要是关于FP的一些介绍，大部分内容在之前学习clojure的时候已经有所了解了，主要是关于immutability 和FP更elegant。有意思的是，在slides里看到了那句经典语句的出处：

> “A language that doesn't affect the
way you think about programming
is not worth knowing.”  -- Alan J. Perlis 

# LEC 2

学习一门编程语言的5个方面：

1. Syntax
2. Semantics
3. Idioms  （个人感觉这一点需要在反复读别人代码的过程中加深体会）
4. Libraries
5. Tools

有一个观点我觉得挺好，``We don’t complain about syntax``，可能做研究的人更看重一门语言背后的思想，至于语法层面的东西反而不太care。不过咱大多数人都比价肤浅点，因而一门语言是否能被广泛推广的重要原因之一就是语法是否友好......

在OCaml中每一个expression包含了type-checking。这点是这节课终点介绍的内容，需要注意的是，function也是一种value，其对应的type则是由function的输入和输出的type共通构成的。

后面的pipeline（即``|>``)与clojure中的``->``宏应该是一个意思。

> Every OCaml function takes exactly one argument.

这句话的意思应该是说，OCaml里的函数默认都是Currying了的。难怪在utop里打印出来的函数类型看起来都有点奇怪，一开始还很困惑如果返回值是函数的话为什么没有区分参数和返回值的类型。（今天看了个知乎的问题[设计闭包（Closure）的初衷是为了解决什么问题？](https://www.zhihu.com/question/51402215)，又多了些理解。)

# LEC 3

这一课主要是list和模式匹配。

这里list采用``[]``的语法糖来代替``::``表示list的构建。需要注意的是，list成员的类型需要保持一致。在形式上与lisp中的list一致，不过在类型做出了限制。

同样，由于类型系统的引入，pattern match的ei类型也需要保持一致。有意思的是，在这里做模式匹配的pattern不仅仅是类型的匹配，还把destruction解构的思想也引入了，从而可以做诸如``a::b::c::[]``的匹配。

``List.hd``和``List.tl``分别对应``first``和``rest``（或者``car``,``cdr``），不过讲义里不建议用这个，更倾向模式匹配。

另外讲义里还提到了尾递归（Tail Recursion），OCaml里是支持尾递归优化的。有兴趣的话可以深入了解下不同语言对尾递归优化的支持情况。

# LEC 4

let expression 是可以嵌套的。（感觉这写法有点蠢......）
不过这章的进阶版match介绍可以跟clojure中的解构匹敌了。加入类型后更复杂了。

> (p : t): a pattern with an explicit type annotation.

关于option，**In Java, every object reference is implicitly an option.**一句类比就解释清楚了。记得Scala中也有option，按照讲义中的解释，由于类型系统的存在，option能在一定程度上避免C/Java中不经检查使用空指针的问题。特地查了下，为啥clojure中没有类似的用法，了解下有助于理解不同语言的理念[Why is the use of Maybe/Option not so pervasive in Clojure?](http://stackoverflow.com/questions/5839697/why-is-the-use-of-maybe-option-not-so-pervasive-in-clojure)。

# LEC 5

## LEC 5.1 type的基本理解

``type``的赋值应该可以理解为C中的``typedef``。这一章花了不少时间来消化（差不多5个上班前和下班后的时间），对type的认识稍微有些清晰了。

在Python等语言里，抽象层次一般是从Object开始，然后是抽象类A，接下来各种类的继承。而在这一章的内容则是从底层的数据类型开始采用bottom-up的思想介绍type的。

首先是最基础的int, float等类型，然后引入tuple后，有了``int * int``等类似的类型，不过这样的类型不太好描述，于是可以通过type对其重命名下``type point = float * float``，这类用法与以前对于type的理解一致。

type的第二种用法是枚举，然而，这枚举有点不一样。课件里给了这样一个例子``type day = Sun | Mon | Tue | Wed | Thu | Fri | Sat ``，课件里没提到的一点是，这里的枚举对象命名必须是大写开头的！而且这里的枚举对象并不是普通的``int, float``等基本类型，应该把它当做一个独立的实体来看待。我一开始很难接受这样的定义，因为在Python语言里，``Sun``等必须是个变量要声明好，或者就直接是个``string``类型的基础变量，又或者像clojure一样独立出一个``:key``这样的类型出来，否则很容易让人将这里的类型变量与普通的变量弄混。

PS: 刚刚查看了下文档，看到大小写的变量名是有特殊意义的。
> Case modifications are meaningful in OCaml: in effect capitalized words are reserved for constructors and module names in OCaml; in contrast regular variables (functions or identifiers) must start by a lowercase letter

type的第三种用法是对第二种用法的扩展。将之前的枚举对象改成了**构造器**，``type t = C1 [of t1] | ... | Cn [of tn]``讲义中的一个例子如下：

```ocaml
type point  = float * float
type shape =
  | Point  of point
  | Circle of point * float (* center and radius *)
  | Rect   of point * point 
```

然后，可以传递构造器中指定类型的数据来得到对应类型的值，例如：

```ocaml
let p = Point (1. , 3.)
let c = Circle ((1., 2.), 3.)
let r = Rect ((-1., -2.), (1., 2.))
```

同时，上面的``shape``对象可以在类型匹配的过程中解构得到其中的基本元素，然后做相应的运算：

```ocaml
let pi = 4.0 *. atan 1.0
let area = function
  | Point _ -> 0.0
  | Circle (_,r) -> pi *. (r ** 2.0)
  | Rect ((x1,y1),(x2,y2)) ->
      let w = x2 -. x1 in
      let h = y2 -. y1 in
        w *. h
        
let center = function
  | Point p -> p
  | Circle (p,_) -> p
  | Rect ((x1,y1),(x2,y2)) ->
      ((x2 +. x1) /. 2.0, 
       (y2 +. y1) /. 2.0)
       
let area_of_p = area p
let center_of_r = center r
```

## LEC 5.2 recursive type

最典型的就是树结构的定义：

```
type node = {value:int; next:mylist}
and mylist = Nil | Node of node
```

## LEC 5.3 parameterized variants

可以类比模板类，比如java中的``List<Integer>``，只不过这里的语法有点不一样，类型是反过来了的，比如一个泛型的list是``type 'a mylist =  Nil | Cons of 'a * 'a mylist``这样定义的，对于一个具体的数据，前面代码中的``'a``可以是任意实际的类型，比如int。``let x = Cons (3, Cons (1, Nil))``就是一个``int mylist``类型数据的实例。

LEC 5 中的Natural numbers部分很有意思，以前看SICP的时候，对这个概念理解得不清楚，现在看了代码后又有了更深的理解。

# LEC 6

这部分主要是关于高阶函数的一些应用，理解起来应该难度不大，课后习题部分需要花点时间。有个需要注意的地方是``fold_left``与``fold_right``的区别。``fold_left``是可以做到尾递归优化的，而``fold_right``则不是，如果确实需要的话，需要把列表翻转后再使用``fold_left``。

Pipeline的书写方式确实优雅一些，可能自己写代码的思维习惯还没有使用过来，感觉从右往左读代码也不是特别麻烦的一件事，只要有合适的缩进来表示。

# LEC 7

这部分主要是OCaml模块化的介绍，包的引入和抽象与其它语言是基本一致的，不同之处在于类型系统单独用一个接口文件来描述，有点像抽象类，但也不完全是。另外具体的实现文件并不是对应了以前Java中类的实现，反而是操作具体的数据。OCaml好像是有自己一套关于类的定义。

# READING LIST

- [Introduction to Objective Caml](http://courses.cms.caltech.edu/cs134/cs134b/book.pdf)
- [Real World OCaml](https://realworldocaml.org/v1/en/html/a-guided-tour.html)