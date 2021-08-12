---
keywords: Python
CJKmainfont: KaiTi
---

# （6）一起用python之基础篇——数据结构

(撰写中。。。呃，写着写着，发觉其实原书写得很系统，一环扣一环，我这样子抽出来一点点地分析反而打乱了原有的结构。我这里写的，大致看下就好，不多说了，反正如果学习Python和数据结构的话，这本书非常非常推荐！）

## 写在前面

本来，这部分计划在几个月前就完成的，无奈这中间忙其它事去了，断断续续地写了一点点。现在刚好闲下来了，争取正式在实验室开始干活之前把这部分写完。加油~

依照以往学习编程语言的经验，在熟悉了语言的基本语法和标准库的应用后，需要进一步深入到底层基本数据结构。一方面深入理解python中常用的数据类型是怎么实现的，另一方面通过自己实现这些基本数据结构来掌握python中类的写法。

于是我大致找了一下python下数据结构方面的书，对比后发现[Data Structures and Algorithms in Python](http://book.douban.com/subject/10607365/ )这本书灰常好。其优点在于，非常适合本人的学习路线（粗略熟悉了python的使用，但是缺乏深入了解），而且本书的前面几章提供了很好的过渡。此外，对于各种类型的数据结构，作者都提供了完整的实现，可以说是学习的典范。当然，要说不足之处，就是最后图论部分内容稍微简略了一些。不过，考虑到本书已经七百多页，这部分从简是有道理的。个人觉得本书更侧重于数据结构部分，如果你只是想学习怎样用python实现基本的算法，可以参考这本书[Python Algorithms - Mastering Basic Algorithms in the Python Language](http://book.douban.com/subject/4915945/),胡家威同学写了个系列的，很值得一看[http://hujiaweibujidao.github.io/python/](http://hujiaweibujidao.github.io/python/)。

## 导读

以下内容可以看做是Data Structures and Algorithms in Python这本书的导读。我会指出各章节中的一些亮点和核心内容。

- [Ch1 Python 基础知识](#ch1)

> 这部分对Python的基本语法做了一个简单的描述，主要目的是让本书的读者在一个相同的起跑线上，方便后面的内容展开。

- [Ch2 面向对象编程](#ch2)

> 首先谈到了面向对象的设计模式，然后以一个例子讲解了Python中如何定义一个类，以及类与类之间的继承关系。最后介绍了Python中类内的变量管理。

- Ch3 算法分析基础

> 这部分几乎是算法书必备的内容。介绍如何分析算法的复杂度。

- [Ch4 递归](#ch4)

> 在开始讲数据结构之前，作者先介绍了一下递归的思想，个人感觉这个章节的安排稍微有些唐突，不过，也算是为后面做铺垫吧。作者对于递归的分类很有启发意义。

- [Ch5 基于Array的序列](#ch5)

> 忘掉Python下常用的list等等数据结构吧，作者先从最最基础的ctypes下的array结构开始构造类似于list的动态序列数据类型。这将为大家理解list类型奠定良好基础。C语言基础很好的话理解起来会很快。

- Ch6 栈、队列与双向队列

> 作者从ADT（Abstract Data Type）出发，在前面实现的基于Array的序列基础上，实现了栈、队列、双向队列这三种数据结构。

- Ch7 链表

> 该部分将前面已经实现的三种数据结构糅合在一起，在介绍了链表后，通过链表来实现上一章提到的集中数据结构。

- Ch8 树

> 从树，再到二叉树，然后深入其中，借用Array序列和链表来实现树这个类。最后介绍了遍历树的简单算法。

- Ch9 优先队列

> 同样，这部分先是介绍了优先队列后，分别用有序列表和无序列表实现了优先队列。然后由此引出了堆。再根据优先队列中的排序问题分别分析了选择排序、插入排序以及堆排序。

- Ch10 Map、哈希表以及跳表

> 这部分内容的重点是介绍了Hash的思想。此外作者跳出Python下常用的字典类型，对Map进行了不同的分类并实现。

- Ch11 搜索树

> 这部分内容主要围绕平衡树展开，介绍了AVL、红黑树等等。

- Ch12 排序与选择

> 尽管前面已经提到了集中排序算法，这里作者补充了并排、快排以及桶排序等等算法并做了比较。

- Ch13 文本处理

> 该部分主要是字符串查找的优化，重点分析了动态问题编程的思想。该部分还介绍了trie树（字典树）

- Ch14 图

> 该部分虽然简短，但覆盖面广，包含了图的结构、图的遍历、最短路径以及最小生成树等等。需要参考其他书作为补充。

- Ch15 内存管理与B树

> 介绍了Python中内存管理体系（内存分配，垃圾回收，缓存机制等等），并介绍了B树。

## Ch1 Python基础知识

这部分可以看做是个导读，都是一些比较基础的部分。在这里我指出几个需要格外注意的地方，算是备忘吧。

### "+="操作对不同数据类型的影响 【16页】

对于list类型，``+=``操作相当于list的extend方法，

```python
In [1]: a = [1,2]

In [2]: id(a)
Out[2]: 139898553654536

In [3]: a += [3,4]

In [4]: id(a)
Out[4]: 139898553654536

In [5]: a
Out[5]: [1, 2, 3, 4]

In [6]: a.extend([5,6])

In [7]: a
Out[7]: [1, 2, 3, 4, 5, 6]

In [8]: id(a)
Out[8]: 139898553654536

In [27]: a = a + [7,8]

In [28]: a
Out[28]: [1, 2, 3, 4, 5, 6, 7, 8]

In [29]: id(a)
Out[29]: 139898553711688
```

如上所示,注意前面的``+=``操作和``extend`` 对id(a)都没有影响,也就是说变量a的内存地址没有发生变化.但是``=``重新赋值时会重新开辟新的内存来存储新的数据.由此引出一个关于``+=``操作符的经典效率问题.

```python
In [48]: %%timeit -n 100
   ....: a = []
   ....: for i in range(10 **3):
   ....:     a = a + [i]
   ....: 
100 loops, best of 3: 1.45 ms per loop

In [49]: %%timeit -n 100
   ....: a = []
   ....: for i in range(10 **3):
   ....:     a += [i]
   ....: 
100 loops, best of 3: 114 µs per loop
```

对于str这类immutable类型的变量, ``+=``操作实际就是先对字符串拼接后再重新赋值.因而会涉及到重新分配存储空间的过程.

```python
In [13]: s = 'ab'

In [14]: id(s)
Out[14]: 139898582654064

In [15]: s += 'cd'

In [16]: s
Out[16]: 'abcd'

In [17]: id(s)
Out[17]: 139898553628352

#对比下字符串类型 += 操作 和 = 操作的效率可以发现,二者差不多

[56]: %%timeit
   ....: a = ''
   ....: for i in range(10 **3):
   ....:     a = a + str(i)
   ....: 
1000 loops, best of 3: 274 µs per loop

In [57]: %%timeit
   ....: a = ''
   ....: for i in range(10 **3):
   ....:     a += str(i)
   ....: 
1000 loops, best of 3: 273 µs per loop
```

### 迭代过程中改变原始数据 【39页】

这里只是简单的提到了一点,在for循环中改变``list``中的值时会对后面的循环过程有影响.举例来说:

```python
In [5]: a = [0,1,2]

In [6]: for i,x in enumerate(a):
    print('a before change: ', a)
    print('i = ',i,'x = ', x)
    a[(i+1)%len(a)] = -1
    print('a after change: ', a)
    print('--------------------------')
    ...:     

a before change:  [0, 1, 2]
i =  0 x =  0
a after change:  [0, -1, 2]
--------------------------
a before change:  [0, -1, 2]
i =  1 x =  -1
a after change:  [0, -1, -1]
--------------------------
a before change:  [0, -1, -1]
i =  2 x =  -1
a after change:  [-1, -1, -1]
--------------------------
```

不过,除了更改之外,还有添加删除操作(如pop, remove, del等),但是,在这一点上,``list ``和``dict``,``set``的表现很不一样.在遍历过程中,如果删除``list``的元素,并不会让遍历过程终止,删除某一元素后,后面的元素会向前移动并填补空缺(这在学习了ArrayBased Sequence后更容易理解),遍历的过程继续.如下所示:

```python
In [10]: a = list(range(10))

In [11]: for x in a:
   ....:     print(x, end=' ')
   ....:     if x == 5:
   ....:         a.remove(0)
   ....:         
0 1 2 3 4 5 7 8 9 
```

但是,如果在遍历dict和set时删除了某些元素则会引发Runtime Error

```python
In [15]: a = {1:1,2:2}

In [16]: for x in a:
   ....:     a.pop(x)
   ....:     
---------------------------------------------------------------------------
RuntimeError                              Traceback (most recent call last)
<ipython-input-16-c44bba0d19b6> in <module>()
----> 1 for x in a:
      2     a.pop(x)
      3 

RuntimeError: dictionary changed size during iteration
```

究其原因,可能是因为list结构采用的类似数组的实现方式,删除某一元素后,后面的元素可以对其填补.而set和dict采用的时链表一类的结构,删除某一元素后会导致结构不稳定(具体我还没找到).解决的办法一般时构造新的字典或者集合.

##Ch2

###  ``is``关键字【76页】

判断两个对象是否相同,一般有两种做法,``a is b`` 和 ``a == b``,这二者时有区别的. ``a is b``用来判断两个变量是否绑定的同一个对象,而``a == b``则是调用两个变量的``__eq__``方法,根据具体的实现有不同的意义.比如下面的例子:

    :::python
    In [17]: a = [1,2,3]

    In [18]: b = a

    In [19]: c = a[:]

    In [20]: a is b
    Out[20]: True

    In [21]: a == b
    Out[21]: True

    In [22]: a is c
    Out[22]: False

    In [23]: a == c
    Out[23]: True

此外还有

    :::python
    In [24]: 0 == False
    Out[24]: True

    In [25]: 0 is False
    Out[25]: False

也就是说, ``is`` 和 ``==``之间没有必然联系

最后还有个更奇葩的......

    :::python
    In [26]: a = 1

    In [27]: b = 1

    In [28]: a is b
    Out[28]: True

    In [29]: a = 111111111111111111111111111111111111111111111

    In [30]: b = 111111111111111111111111111111111111111111111

    In [31]: a is b
    Out[31]: False

    In [32]: a == b
    Out[32]: True

这一点在以前提到过,数字很小的1被缓存了,所以地址相同,从而当a和b都是1的时候,``a is b`` 的值是 True

## Ch4 递归

递归的核心就是3步.

1. 判断终止条件
1. 计算具有共性的那部分
1. 收缩计算范围,使其趋于终止条件

在最后的部分([169页]),作者总结前面的递归例子后,将递归分这么三类,区别在于上面的第二步出现条件判断,从而发生多次回调行为:

- 线性递归(Linear recursion):最多只有一次函数回调

- 二分递归(Binary recursion):函数体内部有两次回调

- 多路递归(Multiple recursion):函数体内部有超过两次的回调

线性递归的最简单例子是,求阶乘以及求和等.例如:

```python
def linear sum(S, n):
    ”””Return the sum of the first n numbers of sequence S.”””
    if n == 0:
        return 0
    else:
        return linear sum(S, n−1) + S[n−1]
```

一般来说,线性递归可以很容易转换成循环去求解.(建议转换成循环,避免出现runtime error,python对递归的深度有限制,这点在文中有提到)

二分递归最常见,就是用于二分搜索.

多路递归,(我表示木有理解到精髓...)

## Ch5 列表

列表这部分，作者使用ctypes下的py_object 作为基础。借用一个resize方法，实现了存储空间的动态增长。

关于列表最重要的一部分是理解下图，由于前面的系列文章里对列表的分析较多，不再赘述。

```python
#该部分源自书中的源码    
import ctypes                                      # provides low-level arrays

class DynamicArray:
  """A dynamic array class akin to a simplified Python list."""

  def __init__(self):
    """Create an empty array."""
    self._n = 0                                    # count actual elements
    self._capacity = 1                             # default array capacity
    self._A = self._make_array(self._capacity)     # low-level array
    
  def __len__(self):
    """Return number of elements stored in the array."""
    return self._n
    
  def __getitem__(self, k):
    """Return element at index k."""
    if not 0 <= k < self._n:
      raise IndexError('invalid index')
    return self._A[k]                              # retrieve from array
  
  def append(self, obj):
    """Add object to end of the array."""
    if self._n == self._capacity:                  # not enough room
      self._resize(2 * self._capacity)             # so double capacity
    self._A[self._n] = obj
    self._n += 1

  def _resize(self, c):                            # nonpublic utitity
    """Resize internal array to capacity c."""
    B = self._make_array(c)                        # new (bigger) array
    for k in range(self._n):                       # for each existing value
      B[k] = self._A[k]
    self._A = B                                    # use the bigger array
    self._capacity = c

  def _make_array(self, c):                        # nonpublic utitity
     """Return new array with capacity c."""   
     return (c * ctypes.py_object)()               # see ctypes documentation

  def insert(self, k, value):
    """Insert value at index k, shifting subsequent values rightward."""
    # (for simplicity, we assume 0 <= k <= n in this verion)
    if self._n == self._capacity:                  # not enough room
      self._resize(2 * self._capacity)             # so double capacity
    for j in range(self._n, k, -1):                # shift rightmost first
      self._A[j] = self._A[j-1]
    self._A[k] = value                             # store newest element
    self._n += 1

  def remove(self, value):
    """Remove first occurrence of value (or raise ValueError)."""
    # note: we do not consider shrinking the dynamic array in this version
    for k in range(self._n):
      if self._A[k] == value:              # found a match!
        for j in range(k, self._n - 1):    # shift others to fill gap
          self._A[j] = self._A[j+1]
        self._A[self._n - 1] = None        # help garbage collection
        self._n -= 1                       # we have one less item
        return                             # exit immediately
    raise ValueError('value not found')    # only reached if no match
```