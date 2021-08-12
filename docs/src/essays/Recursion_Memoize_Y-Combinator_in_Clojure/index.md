---
keywords: FunctionalProgramming,Clojure
CJKmainfont: KaiTi
---

# Recursion

在clojure中，主要靠递归来实现循环控制结构。记得在《c和指针》关于递归和迭代还有过详细介绍，有一些将二者互换的练习，如何形象地理解二者可以看[这里](https://www.zhihu.com/question/20278387)。从时间复杂度上来说，二者是等价的。通常将循环结构改写成递归结构的伪代码可以这么写：

```
for(init, end-condition, change-state)
    do-something-here
    
f(state, & args)
    condition-meet?
        yes-do-something-and-return
        no-please-recur(state-update, do-something-with-args-and-return-updated-args)
```

当然，递归调用可以发生在函数体内的任何地方，不过，有一类特殊的递归发生在函数返回的地方，称为尾递归（Tail Call）。正是因为发生在函数返回的地方，函数体内的运行时信息不再需要保存，因而可以做到尾递归优化(TCO)。不过，受限于JVM，clojure的实现里，并不能直接做到TCO，举例如下：

```clojure
(defn f [n] 
  (if (> n 0)
    (f (dec n))
    0))

(f 100)     ; 0
(f 100000)  ; StackOverflowError   clojure.lang.Numbers$LongOps.combine (Numbers.java:419)
```

不过在clojure中，提供了一种类似goto的语法，即[loop和recur](http://clojure.org/reference/special_forms#recur)来实现从函数尾部跳转。如果函数体内没有显式地提供loop语句，则会跳转到函数开始处。这里loop在语义上和let语句是等价的，只不过添加了一个标记方便编译器识别。使用``recur``需要注意的是只能写在函数的返回处，不能像普通的递归一样对递归调用的结果做二次处理。

```clojure
(defn factorial [x]
  (if (= 1 x)
   1
   (* x (factorial (dec x)))))
;; it's ok, but...
(factorial 10000N)  ;; CompilerException java.lang.StackOverflowError

(defn factorial-recur1 [x]
  (if (= 1 x)
    1
    (* x (recur (dec x)))))
;; this version will not pass compile
;; CompilerException java.lang.UnsupportedOperationException: Can only recur from tail position

(defn factorial-recur2 [x]
  (loop [n x
         acc 1]
    (if (= 1 n)
      acc
      (recur (dec n) (* n acc)))))
```

接下来考虑另一种情况，**mutual recursion**。假设定义了如下两个函数``my-even?``和``my-odd?``：

```clojure
(declare my-odd? my-even?)    ;; make forward declarations first
(defn my-odd? [n]
      (if (= n 0)
          false
         (my-even? (dec n))))
(defn my-even? [n]
      (if (= n 0)
          true
         (my-odd? (dec n))))
         
(my-even? 10000)  ;; CompilerException java.lang.StackOverflowError
```

这里，由于在函数的结尾处是相互递归调用，需要保存堆栈信息，因此会造成StackOverflow，前面我们借用了``loop``和``recur``实现了优化，那么这里能否用同样的套路呢?结果是不能！因为这样做相当于从一个函数内部goto到了另一个函数内部，``recur``显然是不会支持这样的操作的。为了解决这个问题，clojure中提供了一个有趣的函数``trampoline``。

```clojure
(defn trampoline
  ([f]
     (let [ret (f)]
       (if (fn? ret)
         (recur ret)
         ret)))
  ([f & args]
     (trampoline #(apply f args))))
```

其思想就是，每次执行完函数后，判断返回值是否仍然是函数，如果是，则recur然后继续执行，否则返回该值。然后，我们可以将``my-odd?``和``my-even?``最后的函数互调用封装在一个$\lambda$函数里，由``trampoline``去执行。由于返回值是一个$\lambda$函数，相当于立即返回了，因而不会再有StackOverflowError的问题。

```clojure
(declare my-even-helper? my-odd-helper?)  ;; make forward declarations first

(defn my-even-helper? [n]
  (if (zero? n)
    true
    #(my-odd-helper? (dec n))))

(defn my-odd-helper? [n]
  (if (zero? n)
    false
    #(my-even-helper? (dec n))))

(def my-even-new? (partial trampoline my-even-helper?))
(def my-odd-new? (partial trampoline my-odd-helper?))
```

除了用来解决mutual recursion的问题之外，``trampoline``还可以很优雅地用于解决有限状态机的问题，具体可以参考一些[这里](http://clojuredocs.org/clojure.core/trampoline)的例子.

# Memoize

前面只是对recursion做了个简单的回顾，接下来聊一个自己写代码过程中实际遇到的问题。

问题是这样子的，[Collatz Conjecture][]的简单描述如下：

> 给定任意一个正整数：1) 如果这个数是偶数，则对它除以2；2) 如果这个数是奇数，则对它乘以3以后加1。如此循环下去，最后都能够得到1。

找到1000000以内的某个数使得其收敛到1的步骤最长。

这里先不做过多的数学分析，先看一个最naive的版本：

```clojure
(defn collatz-cnt [x]
  (loop [x x c 1]
    (if (= 1 x)
      c
      (recur (if (even? x) 
               (/ x 2)
               (inc (* 3 x)))
             (inc c)))))
             
(time (reduce #(let [c (collatz-cnt %2)]
                 (if (> c (first %1))
                   [c %2]
                   %1))
              [0 0]
              (range 1 1000000 2)))
;"Elapsed time: 8867.352869 msecs"
;[525 837799]
```

这么做显然很耗时，通过简单分析可以看出，遍历求``collatz-cnt``的过程中，会有大量的重复计算。如果能把中间结果缓存起来，那么应该能减少很多计算量。clojure中提供了一个``memoize``函数专门用来缓存函数调用的中间结果，与Python3中``functools.lru_cache``有点类似（不过没有lru）。其[实现](https://github.com/clojure/clojure/blob/010864f8ed828f8d261807b7345f1a539c5b20df/src/clj/clojure/core.clj#L6097)如下：

```clojure
(defn memoize
  [f]
  (let [mem (atom {})]
    (fn [& args]
      (if-let [e (find @mem args)]
        (val e)
        (let [ret (apply f args)]
          (swap! mem assoc args ret)
          ret)))))
```

内部实际上就是通过``(atom {})``来实现缓存的，于是，我先简单地写了个缓存的版本：

```clojure
(def collatz-cnt-memo (memoize collatz-cnt))

(time (reduce #(let [c (collatz-cnt-memo %2)]
                 (if (> c (first %1))
                   [c %2]
                   %1))
              [0 0]
              (range 1 1000000 2)))
;"Elapsed time: 8916.976351 msecs"
;[525 837799]
```

不过跑完才发现，压根没有缓存，仍然是那么慢，仔细分析了下，是因为缓存的时候只对``collatz-cnt-memo``的参数做了缓存，并没有对``collatz-cnt``函数的参数做缓存。于是，写出了另一个版本：

```clojure
(def collatz-cnt-memo2 
  (memoize (fn [x]
             (if (= 1 x)
               1
               (if (even? x) 
                 (inc (collatz-cnt-memo2 (/ x 2)))
                 (inc (collatz-cnt-memo2 (inc (* 3 x)))))))))
```

看起来很完美，每次调用函数的时候，在尾部递归调用自己，而``collatz-cnt-memo2``函数又是缓存了的，效率应该提升很多。等等，似乎，这个并不是尾递归调用，会不会......``StackOverflowError``!!!试试``(collatz-cnt-memo2 837799)``果然如此。那，能否用recur来替换掉内部的递归呢？我自己试了下，几乎很难同时用``recur``和``memoize``来实现，比较接近一点的实现是不使用``memoize``函数，而是自己用宏实现一个类似的缓存机制（这样的做法显然不够优雅）。联想到前面的``trampoline``函数，可以尝试写出这样的版本：

```clojure
(def collatz-cnt-memo3 
  (memoize (fn [x c]
             (if (= 1 x)
               c
               (if (even? x) 
                 #(collatz-cnt-memo3 (/ x 2) (inc c))
                 #(collatz-cnt-memo3 (inc (* 3 x)) (inc c)))))))
(def collatz-cnt-memo3 (partial trampoline collatz-cnt-memo3))
```

似乎，解决了``StackOverflow``的问题，然而，这个函数并没有实现真正意义上的缓存，因为函数内部迭代的时候，传入了两个参数``x``和``c``，显然我们希望缓存的是``fn [x]``而不是``fn [x c]``，但是，如果只传一个参数``x``，又没法做到尾递归（最后需要一个inc操作递归的返回值，使得count + 1），似乎，陷入了一个怪圈......

关于如何一步步优化这个问题的clojure代码，可以看[这里](http://www.petrounias.org/articles/2014/08/03/collatz-sequence-generation-performance-profiling-in-clojure/)(确实要比C++和python的代码都要慢很多)。接下来转向另外一个话题。


# Y Combinator

看了一个周末，对自己的智商产生了怀疑......😂😂😂感觉，理解了是怎么回事，并没有体会到其中的精髓，建议看看[wikipedia](https://en.wikipedia.org/wiki/Fixed-point_combinator)。


# Reference



- [Trampolining through mutual recursion with Clojure](http://jakemccrary.com/blog/2010/12/06/trampolining-through-mutual-recursion/)
- [Clojure Doc - trampoline](http://clojuredocs.org/clojure.core/trampoline)
- [详解Clojure的递归(上）—— 直接递归及优化](http://www.blogjava.net/killme2008/archive/2010/07/14/326129.html)
- [详解Clojure的递归（下）——相互递归和trampoline](http://www.blogjava.net/killme2008/archive/2010/08/22/329576.html)
- [In Clojure, is it possible to combine memoization and tail call optimization?](http://stackoverflow.com/questions/9898069/in-clojure-is-it-possible-to-combine-memoization-and-tail-call-optimization)
- [How do I generate memoized recursive functions in Clojure?](http://stackoverflow.com/questions/3906831/how-do-i-generate-memoized-recursive-functions-in-clojure)
- [Recursions without names: Introduction to the Y combinator in clojure](http://blog.klipse.tech/lambda/2016/08/07/almost-y-combinator-clojure.html)
- [The Y combinator in clojure](http://blog.klipse.tech/lambda/2016/08/07/pure-y-combinator-clojure.html)
- [Y combinator real life application: recursive memoization in clojure](http://blog.klipse.tech/lambda/2016/08/10/y-combinator-app.html)
- [The Y Combinator (Slight Return)](http://mvanier.livejournal.com/2897.html)

[Collatz Conjecture]:https://en.wikipedia.org/wiki/Collatz_conjecture