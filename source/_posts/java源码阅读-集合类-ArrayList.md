---
layout: post
title: "java源码阅读-Arraylist"
categories: 编程 
tags: 
- java
date:   2016-07-12 12:48:55
---

>上班半个月了，有点迷茫，不知道自己该学点什么。什么都想学，什么都不会。看到网上的[一篇文章](http://www.iteye.com/topic/1113732)，我觉得自己也该看点源码之类的了，不能总是抱着设计模式，JVM的书啃(还都没怎么看)。前两天尝试自己封装一下JDBC的测试代码，改了又改，总觉得不对劲，遂放弃。是时候看看大神的代码来吸取点经验了，希望有所收获。

我决定根据上面文章中作者提到的学习路径去看代码，首先就是JDK中的核心代码。第一篇就来研究一下JAVA中的集合类-Arraylist。

## 1.集合基础

java有一套[集合框架](http://docs.oracle.com/javase/tutorial/collections/index.html)，Arraylist等集合类都是这个框架的成员。首先看一下最顶层的几个接口：

<img src="http://docs.oracle.com/javase/tutorial/figures/collections/colls-coreInterfaces.gif" width="800" height="600"  /> 







