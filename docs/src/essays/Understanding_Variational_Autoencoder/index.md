---
keywords: Algorithm
CJKmainfont: KaiTi
---

# Understanding Variational Autoencoder

本文主要记录自己在学习[Automatic Differentiation Variational Inference](https://arxiv.org/abs/1603.00788)过程中的一些参考资料和理解。

## 熵（Entropy）

以下借用《Statistical Rethinking》一书中的部分内容来理解Entropy及其相关的内容。

假设今天天气预报告诉我们，明天有可能下雨（记为事件A），该事件有一定的不确定性，等到第二天结束的时候，不论第二天是否下了雨，之前的不确定性都消失了。换句话说，在第二天看到事件A的结果时（下雨或没下雨），我们获取了一定的信息。

> **信息**：在观测到某一事件发生的结果之后，不确定性的降低程度。

直观上，衡量信息的指标需要满足一下三点：

1. 连续性。如果该指标不满足连续性，那么一点微小的概率变化会导致很大的不确定性的变化。
1. 递增性。随着可能发生的事件越多，不确定性越大。比如有两个城市需要预测天气，A城市的有一半的可能下雨，一半的可能是晴天，而B城市下雨、下冰雹和晴天的概率分别为1/3，那么我们希望B城市的不确定性更大一些，毕竟可能性空间更大。
1. 叠加性。将明天是否下雨记为事件A，明天是否刮风记为事件B，假设二者相互独立，那么将事件A的不确定性与事件B的不确定性之和，与（下雨/刮风、不下雨/刮风、下雨/不刮风、不下雨/不刮风）这四个事件发生的不确定性之和相等。

信息熵的表达形式刚好满足以上三点：

$$
\begin{equation}
\begin{split}
H(p) & = - \mathbb{E} \log \left(p_i\right) \\
     & = - \sum_{i=1}^{n} p_i \log\left(p_i \right) 
\end{split}
\end{equation}$$

简单来说，熵就是概率对数的加权平均。

## K-L散度（Kullback-Leibler Divergence ）

> **散度**:用某个分布去描述另外一个分布时引入的不确定性。

散度的定义如下：

$$
\begin{equation}
\begin{split}
D_{KL}(p,q) & = \sum_{i \in I} p_i  \left( \log (p_i) - \log (q_i) \right) \\
       & = \sum_{i \in I} p_i \log \left( \frac {p_i} {q_i} \right) 
\end{split}
\label{KL}
\end{equation}
$$

KL散度是大于等于0的，可以通过[Gibb's不等式][Gibb's inequality]证明：

首先，我们知道：

$$
\begin{equation}
\ln x \le x - 1
\end{equation}
$$

于是，根据$\eqref{KL}$中KL散度的定义，可以得到如下不等式：

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

可以看出，只有当两个分布一一对应相等的时候才取0。

如果将KL散度拆开，可以看作是交叉熵与信息熵之差：

$$
\begin{equation}
D_{KL} = H(p,q) - H(p)
\end{equation}
$$

关于KL散度，一个很重要的特性是，$KL(p,q)$一般不等于$KL(q,p)$，也就是说，KL散度是有方向性的。这里借用[Statistical Rethinking][SR]一书第6章中的例子来解释下。

假设在地球上随机选一地点，该点位于水面和陆地的概率分别为0.7和0.3，记为$q=(0.7,0.3)$，我们知道火星非常干燥，假设相应的概率为$p=(0.01,0.99)$，可以算出$KL(p,q)=1.14$，$KL(q,p)=2.62$。可以看出，用火星上的分布去估计地球上的分布时，得到的散度更大。直观可以这么理解：一个地球人第一次到火星上时，有很大概率落在陆地上，根据他在地球上的先验，落在陆地上的概率为0.3，因而不会特别惊讶；相反，一个火星人第一次落到地球上时，大概率会落到水面上，这对于火星人来说，是非常惊讶的事（火星上只有0.01的概率），因而其KL散度更大。因此，通常如果选择一个熵值较大的分布去估计某个真实分布时，得到的KL散度会更小一些。

## The Evidence Lower Bound

给定$\boldsymbol{x} = x_{1:n}$为观测变量，$\boldsymbol{z}=z_{1:m}$为隐变量，对应的联合概率为$p(\boldsymbol{z}, \boldsymbol{x})$，后验可以写成：

$$
\begin{equation}
p(\boldsymbol{z} | \boldsymbol{x}) = \frac{p(\boldsymbol{z}, \boldsymbol{x})}{p(\boldsymbol{x})}
\label{posterior}
\end{equation}
$$

其中$p(\boldsymbol{x})$称为证据：

$$
\begin{equation}
p(\boldsymbol{x}) = \int p(\boldsymbol{z}, \boldsymbol{x})d\boldsymbol{z}
\end{equation}
$$

变分推断背后的思想是，用一些简单的参数化分布（记为$Q_{\phi}(\boldsymbol{z} | \boldsymbol{x})$）去拟合后验分布$P(\boldsymbol{z}|\boldsymbol{x})$，通过调整参数$\phi$使得$Q_{\phi}$尽可能接近$P(\boldsymbol{z}|\boldsymbol{x})$，从而转换成优化问题。衡量二者相似度的方法之一就是用前面提到的KL散度，按理说，我们应该最小化$KL(P,Q)$，不过实际使用中通常是最小化$KL(Q,P)$，前面也介绍了，二者实际上是不同的，可以参考阅读[A Beginner's Guide to Variational Methods: Mean-Field Approximation][]一文中的*Forward KL vs. Reverse KL*和[KL Divergence: Forward vs Reverse?](http://wiseodd.github.io/techblog/2016/12/21/forward-reverse-kl/)部分来了解为什么优化$KL(Q,P)$。

$$
\begin{equation}
KL(q(\boldsymbol{z}) \| p(\boldsymbol{z}|\boldsymbol{x})) = \mathbb{E} [ \log q(\boldsymbol{z})] - \mathbb{E} [\log p(\boldsymbol{z}|\boldsymbol{x})]
\end{equation}
$$

这里的$\mathbb{E}$是相对$q(\boldsymbol{z})$的期望，将$\eqref{posterior}$代入可得：

$$
\begin{equation}
KL(q(\boldsymbol{z}) \| p(\boldsymbol{z}|\boldsymbol{x})) = \mathbb{E} [ \log q(\boldsymbol{z})] - \mathbb{E} [\log p(\boldsymbol{z},\boldsymbol{x})] + \log p(\boldsymbol{x})
\label{KLqp}
\end{equation}
$$

由于$p(\boldsymbol{x})$是固定的，于是最小化上式中的KL等价于最大化下面的证据下界：

$$
\begin{equation}
ELBO(q) = \mathbb{E}[\log p(\boldsymbol{z},\boldsymbol{x})] - \mathbb{E} [\log q(\boldsymbol{z})]
\label{ELBO}
\end{equation}
$$

上式中的联合概率又可以表示成先验乘以似然，于是有：

$$
\begin{equation}
\begin{split}
ELBO(q) & = \mathbb{E} [\log p(\boldsymbol{z})] + \mathbb{E} [\log p(\boldsymbol{x}| \boldsymbol{z})] - \mathbb{E} [\log q(\mathbb{z})] \\
& =\mathbb{E}[\log p(\boldsymbol{x}|\boldsymbol{z})] - KL(q(\boldsymbol{z})\| p(\boldsymbol{z}))
\end{split}
\end{equation}
$$

直观上看，第一项是似然的期望，最大化ELBO意味着我们希望隐变量能够很好地解释观测数据；第二项是隐变量的先验与估计之间的KL散度，越小越好。由$\eqref{KLqp}$和$\eqref{ELBO}$可以得到：

$$
\begin{equation}
\log p(\boldsymbol{x}) = KL(q(\boldsymbol{z}) \| p(\boldsymbol{z}|\boldsymbol{x})) + ELBO(q)
\end{equation}
$$

上面式左边是证据，由于KL散度大于等于0，因而右边的第二项ELBO也就称作证据下界。

## Variational Autoencoder

关于VAE的文章很多，这里就不详细介绍了。[VAE][]的原文不太好读懂，建议先读[Tutorial on Variational Autoencoders][]，然后可以看看一些代码实现，比如[Variational Autoencoder: Intuition and Implementation](http://wiseodd.github.io/techblog/2016/12/10/variational-autoencoder/)，和这里[Variational Autoencoders Explained](http://kvfrans.com/variational-autoencoders-explained/)。

## Read More

- [A Beginner's Guide to Variational Methods: Mean-Field Approximation][]
- [Variational Coin Toss](http://www.openias.org/variational-coin-toss)
- [Variational Inference: A Review for Statisticians](https://arxiv.org/abs/1601.00670)

[Gibb's inequality]:https://en.wikipedia.org/wiki/Gibbs%27_inequality
[SR]:https://book.douban.com/subject/26607925/
[A Beginner's Guide to Variational Methods: Mean-Field Approximation]:http://blog.evjang.com/2016/08/variational-bayes.html
[Tutorial on Variational Autoencoders]:https://arxiv.org/abs/1606.05908
[VAE]:https://arxiv.org/abs/1312.6114