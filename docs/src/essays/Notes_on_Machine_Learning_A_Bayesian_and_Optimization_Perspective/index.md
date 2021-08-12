---
keywords: Book,MachineLearning
CJKmainfont: KaiTi
---

# Machine Learning A Bayesian and Optimization Perspective 读书笔记

个人感觉这本书的覆盖面有点广，更适合有一定基础之后在回过头来读。暂时先看完了2，3，4章，打个卡，后面有机会再继续读这本书。

## CH02

这一章先回顾了些基础知识，主要是概率和信息论里的基础，顺带复习了下《概率统计》那本书。2.4节的随机过程没太看懂，这块要补一补相关的基础，以后需要的时候再回头来看看。

下面是我写的部分习题的解答。

### P2.1

$$\begin{equation}
E(X) = \sum_{i=1}^n E(X_i) = np
\end{equation}$$

$$\begin{equation}
\begin{split}
Var(X) &= \sum_{i=1}^n Var(X_i) \\
       &= n\,Var(X_i) \\
       &= n \left( E(X_i^2) - (E(X_i))^2\right) \\
       &= n(p - p^2)
\end{split}
\end{equation}$$

### P2.2

$$\begin{equation}
E(X) = \int_a^b x \frac{1}{b-a} \, dx = \frac{a+b}{2}
\end{equation}$$

$$\begin{equation}
\begin{split}
Var(X) &= E(X^2) - (E(X))^2 \\
       &= \int_a^b x^2 \frac{1}{b-a} \, dx - \left( \frac{a+b}{2}\right) ^ 2\\
     &= \frac{a^2 + ab + b^2}{3}  - \frac{a^2 + 2ab + b^2}{4} \\
     &= \frac{a^2 -2ab + b^2}{12}
\end{split}
\end{equation}$$

### P2.3

See the Appendix A.1 in [http://cs229.stanford.edu/section/gaussians.pdf](http://cs229.stanford.edu/section/gaussians.pdf)

### P2.4

The definition of beta function is given by:

$$
\begin{equation}
B(\alpha, \beta) = \int_0^1 x^{\alpha-1} (1-x)^{\beta - 1}\, dx
\label{beta_eq}
\end{equation}
$$

And we have:

$$\begin{equation}
B(\alpha, \beta) = \frac{\Gamma(\alpha) \Gamma(\beta)}{\Gamma(\alpha + \beta)}
\label{beta_eq_gamma}
\end{equation}$$

The Beta distribution is:

$$\begin{equation}
f(x \mid \alpha, \beta) = \left\{\begin{matrix}
\frac{\Gamma(\alpha + \beta)}{\Gamma(\alpha) \Gamma(\beta)} x^{\alpha -1}(1-x)^{\beta - 1} & for \; 0\lt x \lt1 \\ 
0 & otherwise.
\end{matrix}\right.
\end{equation}
$$

So we get:

$$\begin{equation}
\begin{split}
E(X^k) &= \int_0^1 x^k f(x \mid \alpha, \beta) \, dx \\
       &= \frac{\Gamma(\alpha + \beta)}{\Gamma(\alpha) \Gamma(\beta)} \int_0^1 x^{\alpha + k -1}(1-x)^{\beta - 1} \, dx \\
       &= \frac{\Gamma(\alpha + \beta)}{\Gamma(\alpha)\Gamma(\beta)}  \cdot  \frac{\Gamma(\alpha + k) \Gamma(\beta)}{\Gamma(\alpha + k + \beta)}
\end{split}
\label{beta_moment}
\end{equation}$$ 

And the Gamma function has a property that:

$$\begin{equation}
\begin{matrix}
\Gamma(\alpha) = (\alpha - 1)\Gamma(\alpha-1) & if \alpha \gt 1
\end{matrix}
\label{gamma_property}
\end{equation}$$


Combine $\eqref{beta_moment}$ and $\eqref{gamma_property}$, we have that:

$$\begin{equation}
E(X) = \frac{\alpha}{\alpha + \beta}
\end{equation}$$

$$\begin{equation}
E(X^2) = \frac{\alpha (\alpha + 1)}{(\alpha + \beta)(\alpha + \beta + 1)}
\end{equation}$$

So we get:
$$\begin{equation}
Var(X) = E(X^2) -(E(X))^2 =\frac{\alpha \beta}{(\alpha + \beta)^2(\alpha + \beta + 1)}
\end{equation}$$

### P2.5

Bellow I will show that $\eqref{beta_eq_gamma}$ and $\eqref{beta_eq}$ are equal:
$$
\begin{split}
\Gamma(a)\Gamma(b) 
&= \int_0^\infty e^{-x} x^{a-1} \, dx \int_0^{\infty} e^{-y} y^{b-1} \, dy  \\
&= \int_0^\infty \int_0^\infty  e^{-(x+y)} x^{a-1} y^{b-1} \, dx \,dy  \\
\end{split}$$

change $t = x + y$, naturally $t \ge x$ we have:

$$\begin{split}
\int_0^\infty \int_0^\infty  e^{-(x+y)} x^{a-1} y^{b-1} \, dx \,dy  
&= \int_0^\infty e^{-t} \left(\int_0^\infty x^{a-1}(t-x)^{b-1} \, dx\right)\, dt \\
& \stackrel{x=\mu t}{=}\int_0^\infty e^{-t} \left( t^{a+b-1 } \int_0^{1} \mu^{a-1} (1-\mu)^{b-1} \, d\mu\right) dt \\
& = \int_0^{1} \mu^{a-1} (1-\mu)^{b-1} \, d\mu \int_0^{\infty}e^{-t} t^{a+b-1} \, dt \\
&= \int_0^{1} \mu^{a-1} (1-\mu)^{b-1} \, d\mu \cdot \Gamma(a+b)
\end{split}$$

### P2.6

$$\begin{equation}
\begin{split}
E(X^k) &= \int_0^{\infty} x^k \frac{b^a}{\Gamma(a)} x^{a-1} e^{-bx} \, dx \\
&\stackrel{z=bx}{=}\int_0^{\infty} \frac{b^a}{\Gamma(a)} \left(\frac{z}{b}\right)^{a-1+k}e^{z} \frac{1}{b}\, dz \\
&= b^{-k} \frac{\Gamma(a+k)}{\Gamma(a)} \\
\end{split}
\end{equation}$$

Then we have:
$$\begin{align}
E(X) &= \frac{a}{b} \\
E(X^2) &= \frac{(a+1)a}{b^2}  \\
Var(X) &=E(X^2)-(E(X))^2 = \frac{a}{b^2}
\end{align}$$

### P2.7

See [http://www.mas.ncl.ac.uk/~nmf16/teaching/mas3301/week6.pdf](http://www.mas.ncl.ac.uk/~nmf16/teaching/mas3301/week6.pdf) for details.

### P2.8

Suppose $Var(X_i) = \sigma^2$, so we have $Var(\bar{X})=\sigma^2/n$, when $n \to \infty$, $Var(\bar{X}) \to 0$.

### P2.11

Let $f(x) = \ln x -x + 1$, the first order is $f'(x) = 1/x - 1$, so we have $f(x) \ge f(1) = 0$.

### P2.12

$$\begin{equation}
\begin{split}
I(x,y) &= \sum_{x \in \mathcal{X}} \sum_{y \in \mathcal{Y}}P(x,y) \log {\frac{P(x,y)}{P(x)P(y)}} \\
&= - \sum_{x \in \mathcal{X}} \sum_{y \in \mathcal{Y}}P(x,y) \log {\frac{P(x)P(y)}{P(x,y)}} \\
& \ge - \sum_{x \in \mathcal{X}} \sum_{y \in \mathcal{Y}} P(x,y)\left(\frac{P(x)P(y)}{P(x,y)} -1\right) \\
\end{split}
\end{equation}$$

### P2.13

$$
\begin{equation}
\begin{split}
-\sum_{i \in I} p_i \log \left( \frac {q_i} {p_i} \right) & \ge - \sum_{i \in I} p_i \left( \frac {q_i - p_i} {p_i}\right) \\
 &= -\sum_{i \in I} (q_i - p_i) \\
 &= 1 - \sum_{i \in I} q_i \\
 &\ge 0
\end{split}
\end{equation}
$$

### P2.15 

See [https://stats.stackexchange.com/questions/66108/](https://stats.stackexchange.com/questions/66108/why-is-entropy-maximised-when-the-probability-distribution-is-uniform) for details.

## CH03

这一章先从参数估计入手，介绍了参数视角下的线性回归和分类问题，作者提到了本书重点关注有监督的问题，无监督的问题没有涉及。

下面是我写的部分习题的解答。

### P3.1

$$\begin{equation}
\begin{split}
\sigma_c^2 &= Var(\hat{\theta}) \\
&= Var(\frac{1}{m} \sum_{i=1}^{m} \hat{\theta}_i) \\
&= \frac{1}{m^2} \sum_{i=1}^{m} Var(\hat{\theta}_i) \\
&= \frac{1}{m} \sigma^2
\end{split}
\end{equation}$$

### P3.2 & P3.3

See [http://willett.ece.wisc.edu/wp-uploads/2016/01/15-MVUE.pdf](http://willett.ece.wisc.edu/wp-uploads/2016/01/15-MVUE.pdf) for details.

### P3.4

According to the quadratic formula, we can easily get the inequation.

### P3.5

By taking the derivative of $MSE(\hat{\theta}_b)$ with respect to $\alpha$, we let:

$$\begin{equation}
2(1+\alpha)MSE(\hat{\theta}_{MVU}) + 2\hat{\theta}_o^2 \alpha = 0
\end{equation}$$

and then we get:

$$\begin{equation}
\alpha_* = - \frac{MSE(\hat{\theta}_{MVU})}{MSE(\hat{\theta}_{MVU}) + \hat{\theta}_o^2} = - \frac{1}{1+\frac{\hat{\theta}_o^2}{MSE(\hat{\theta}_{MVU})}}
\end{equation}$$

### P3.6

Since the expectation in Eq 3.26 is taken with respect to $p(\mathcal{X};\theta)$, if the integration and differentiation can be interchanged, we can first take the integration of $p(\mathcal{X};\theta)$, resulting Eq 3.26