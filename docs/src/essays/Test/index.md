---
keywords: test1,test2
---

# Markdown Basics

以下是引用：

> This is a MPE extended feature.

## 加粗，斜体，删除等

*This text will be italic*
_This will also be italic_

**This text will be bold**
__This will also be bold__

_You **can** combine them_

~~This text will be strikethrough~~

## 无序列表(嵌套)

* Item 1
* Item 2
  * Item 2a
  * Item 2b

## 有序列表（嵌套）

1. Item 1
1. Item 2
1. Item 3
   1. Item 3a
   1. Item 3b

## 图片

![GitHub Logo](github_logo.png)

![Remote IMG](https://assets-cdn.github.com/images/modules/logos_page/Octocat.png)

## 链接

http://github.com - automatic!
[GitHub](http://github.com)


## 横线

---

Hyphens

***

Asterisks

___

Underscores

## Inline code

For example: `lambda x: x^2`.

## Code

python and julia only

```python
import os
os.listdir('.')
```

### Tables
You can create tables by assembling a list of words and dividing them with hyphens `-` (for the first row), and then separating each column with a pipe `|`:  

First Header | Second Header
------------ | -------------
Content from cell 1 | Content from cell 2
Content in the first column | Content in the second column



### Emoji & Font-Awesome

> This only works for `markdown-it parser` but not `pandoc parser`.  
> Enabled by default. You can disable it from the package settings.  :thumbsup:

:smile:
:fa-car:

```
:smile:
:fa-car:
```


### Footnotes
Content [^1]

[^1]: Hi! This is a footnote

### Mark  

==marked==

```markdown
==marked==
```

<div class="alert alert-success">
Great!
</div>

## Equation

$$
\begin{equation}
a^2 + b^2 = c^2
\end{equation}
$$



## References
* [Mastering Markdown](https://guides.github.com/features/mastering-markdown/)
* [Daring Fireball: Markdown Basics](https://daringfireball.net/projects/markdown/basics)