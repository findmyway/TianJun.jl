---
keywords: Book
CJKmainfont: KaiTi
---

# 读书笔记【The Senior Software Engineer】

图书馆意外翻到的一本书，读了读发现还挺有意思，随手写点读书笔记。

关于 **Senior**，作者开篇就解释了，在大多数公司里，**Senior**区别于**Junior**，用来指代那些拥有更多决策权的员工。不过作者有意指出，题目中的**Senior**在我们这行一般是指工作了三年以上的人（从这个角度来说，我也勉强算是qualified的目标读者了......）。全书分十一章，阐述了作者18年来的一些工作心得，许多地方很有认同感，摘录下来，或许其他人读了也会有点收获？

## Focus on Delivering Results

这一章其实拆分成了3个部分：

- **Results**
- **Focus**
- **Delivering**

首先是观念上的转变，作为SDE，一般认为产出就是代码，不过作者认为，产出一定是要体现商业价值：

> A *result* then, is an artivact of direct business value. Working code, documentation, and definitive statements are all results. Anything else must be understood as fundamentally different.

然后是**Focus**，作者描述了工作中一个常见的场景：回邮件。阐述了为什么持续focus在当前的工作上要好于立即回复邮件（1. Distraction 2. We can forward to others 3. Keep promises to a minimum）。

最后是 deliver smaller results more often，也是软件开发里常提到的一个概念，至于优点嘛：

> First, it turns a boring progress report into working, usable software. You won't have to merely *tell* the rest of the company how far along you are, you can *show* them.
> Secondly, promises of smaller value over shorter time are easier to keep. You are much more likely to accurately estimate one week's worth of work than you are one month's.

## Fix Bugs Efficiently and Cleanly

作者总结了自己修bug的一些best practice，我自认在工作中没这么规范的做过，但从心底还是认同书中提到的这个流程：

1. Understand the problem.
1. Write tests that fail (because the problem has yet to be solved).
1. Solve the problem as quickly as you can, using your tests to know when you've solved it.
1. Modify your solution for readability, conciseness, and safety by suing your tests to make sure you haven't broken anything.
1. Commit your changes.

简单来说，就是test driven development 。核心思想就两点：

1. Thinking before coding
1. Separating "getting it to work" from "doing it right". It's hard to do both at the same time.

自我反思下，大多时候只做到了"getting it to work"，尬。越是到了项目后期，"doing it right"的代价也越来越大。当然，也不能走极端了（Don't over-engineer and know when to quit），然后引用了**《重构》**中的一句话：

> [Refactoring is] restructuring an existing body of code, altering its internal structure without changing its external behavior.

还有一点，记得及早commit，嗯，这一点感受还是很深的，不然，就等着哭去了......

## Add New Features with Ease

这部分内容中，自认为需要改进的应当是 *Plan your implementation* 这部分。列清楚 TODO list，找人交流讨论实现，然后预估每部分的大致时间。

> Whatever you produce here is for your internal use only and is designed to capture your thinking at a high level about how to solve the problem and what bases need covering. Once you dive into the code, you will focus on much smaller concerns. Your "plan" here is for those moments when you get done with something and stick your head up to see where you are.

## Deal With Technical Debt and Slop

第一次了解这个单词，**Sloppy**，不过，其描述的场景在工作中太常见了。复制，粘贴，再修修补补，Test全绿，Coverage蹭蹭涨，Well Done！不过，作为Senior的工程师，绝对不能ship这类代码。

关于Technical Debt，书中的一个做法直接在comment里明确写出来了，感觉这个得有工具track，不然这些Debt大概率没机会偿还了......

## Play Well With Others

这大概是Senior进阶路上最难的一步。

> Translating your work to non-technical people is a skill that can be more valuable than any specific technical knowledge you have. It's what makes a senior developer in the eyes of others.

作者的两个建议是：

- Empathize with your audience.
- Distill what you know in a way your audience can understand.

关于第二点，有一些更实际的建议：

- Adapt Terms
  - Avoid technical jargon of your own.
  - Listen carefully to the words people use and ask questions if you aren't 100% sure what they mean.
  - Don't "talk down". The other person is likely a highly intelligent person who is capable of understanding what you're explaining. Treating them like a child will only make things worse. (这点确实在太常见了)
  - Don't be afraid to use longer descriptive phrases in place of acronyms or other jargon.
- Abstract Cepts to Simplify Them
  - Avoid technical details
  - Explain things using analogies; don't worry about precision
  - Use diagrams, visual aids, or demonstrations where possible.
  - Always offer to provide more details (这点已经听许多人说过了，挺受益的)
  - If a question has taken you off course, spend a few seconds re-establishing the context of your discussion. (这个需要反复练习，一是得清醒地意识到off course了，二是根据问题重新澄清讨论主题)
  - Be prepared to "justify" your position if challenged.
  - **Remember, it's not the other person's job to understand you, it's your job to make sure they understand.
  - Don't be afraid to stop and re-group if things are going poorly. Find a colleague you trust or respect who can (or already does) understand the technical information in question and ask how they would handle it.

## Make Technical Decisions

越往后走，就有越多（重要）的事情需要做决定，作者的建议是，从两方面出发，分别考虑：

1. **Identify Facts**
  注意区分 **Facts** 和 **Opinions**
1. **Identify Priorities**
  综合考虑多方的**Priorities**，自己的，整个team的，boss的等等

此外，注意区分**fallicies** （有意思的是，这里还提到了Clojure）。即使是一些非常聪明的人也会犯类似的错。

> If someone remains unconvinced by your arguments, rather than assume the person is "not getting it", take a moment to consider if your argument really is lacking. Give everyone the benefit of the doubt. Is there a fact you got wrong? A priority ou haven't identified? **Your mission isn't to prove that you are right, it's to deliver the best results you can **.

还有一点非常值得学习：**Document the decision-making process**.

> A document like this is useful for two reasons. First, it can prevent someone else from going through the trouble that you've just gone through. Second, it keeps you from having to remember the details whe, sixmonths from now, a new team member asks why things are done a certain way.

## Bootstrap a Greenfield System

这部分涉及的内容反而在现有的项目里是做得比较好的一块（原因大概是，Dialog这块常做常新？）。

## Learn to Write

作者在这部分给出了许多关于写作的建议。

Three steps to better writing:

1. Get it down
  An outline, then each section.
1. Revise it
    1. Instead of using demonstratives "this" and "that" or pronouns like "it" or "they", use the specific names of things, enven if it seems slightly redundant.
    1. Name objects, concepts and procedures as specifically as you can.
    1. Avoid acronyms, shorthand, jargon unless you are **absolutely** sure the reader will understand it. (这个必须吐槽，OneNote上各种缩写满天飞)
    1. Organize thoughts into paragraphs. (一段表达一个意思，避免所有内容都杂糅在一段里)
    1. Write as if the readers are getting more and more rushed for time as they read. 尽量开门见山
1. Polish it

后面如何写Email和如何写技术文档可以单独找两本书来读了。

## Interview Potential Co-Workers

这部分可以跳过，帮助有限。

## Be Responsive and Productive

Visibility 除了体现在代码上之外，还体现在 *Responsiveness*。学会处理各种interruption。

## Lead the Team

这部分体会没那么深，可能，还没到这层境界？