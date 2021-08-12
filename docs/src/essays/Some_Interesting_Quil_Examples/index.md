---
keywords: Clojure,GIF
CJKmainfont: KaiTi
---

# About Quil

[Quil][]是Clojure下用来画图的一个库，对[Processing][]做了封装。Processing想必大家都知道，用来画图非常有意思，我第一次接触Processing是在图书馆里看到了[代码本色：用编程模拟自然系统 \[The Nature of Code：Simulating Natural Systems with Processing\]](https://book.douban.com/subject/26264736/)。不过只是大致翻了翻，有个基本的印象，最近碰巧想到用clojure来画图，于是找到了quil这个库。Processing这个库本身是用java写的（现在已经有很多语言的扩展了），因此用clojure写起来相当方便，而且得益于clojure中许多函数式编程的思想，写代码的感觉非常顺畅！以后深入了解下二者后写个详细的对比分析。本文主要是记录下平时写的一些比较有意思的动图。

[Quil]:http://quil.info/
[Processing]:https://processing.org/

# Lissajous 曲线的动画演示

第一次看到Lissajous曲线是从[Matrix67](http://www.matrix67.com/blog/archives/6947)的文章里看到的，这类曲线还是蛮有意思的，包括Quil官网上也有几个类似的例子，这里我也用Quil画了一个图~

![Lissajous.gif](Lissajous.gif)

代码如下：

```clojure
(ns hello-quil.core
  (:require [quil.core :as q]
            [quil.middleware :as m]))

(defn setup []
  (q/frame-rate 30)
  (q/background 255)
  (q/color-mode :hsb 10 1 1))

(defn f  [t]
  [(* 200 (q/sin  (* t 13))) (* 200 (q/sin  (* t 18))) ])

(defn draw-plot [f from to step]
  (doseq [two-points (->> (range from to step)
                          (map f)
                          (partition 2 1))]
    (apply q/line two-points)))

(defn draw []
  (q/with-translation  [(/  (q/width) 2)  (/  (q/height) 2)]
    (let [t (/  (q/frame-count) 80)]
      (q/stroke  1 1 1)
      (q/line (f t)
              (f (+ t (/ 1 80))))
      (q/save-frame "./data/Lissajous-####.png"))))

(q/defsketch trigonometry
  :size  [500 500]
  :draw draw
  :setup setup)

```
