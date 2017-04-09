layout: post
title: Java集合框架学习总结
date: 2016-08-16 22:50:16
categories: 编程 
tags: 
- java
- 源码
---

看Jdk的源码有大概一个月时间了，中间零零散散算是把[Java的集合](https://docs.oracle.com/javase/7/docs/technotes/guides/collections/index.html)看了个大概。源码还有很多地方不甚明白，但对java集合框架总体上有了个认识。总结一下，以后有时间再把源码理一遍。下一步的Jdk源码阅读计划是：[Java IO](https://docs.oracle.com/javase/7/docs/api/java/io/package-summary.html#package_description)

## 框架

{% asset_img collection.png 集合框架 %}

上图并没有把所有的接口和类都列出来，只是把我认为最常用和最核心的几个类和接口的继承关系表示出来。

通过上图可以看出，java集合框架主要分为两棵树，一棵继承自Collection，一棵继承自Map。接下来分四个部分总结一下。

<!-- more -->

## List

### Iterator

在总结List之前，先看一下Iterable这个接口,它只包含一个方法:

```java
Iterator<T> iterator();
```

这个方法返回一个[Iterator](https://docs.oracle.com/javase/8/docs/api/java/util/Iterator.html)，也就是一个迭代器，通过这个迭代器，我们可以在不了解集合内部实现的情况下遍历他,这也是设计模式中很重要的一个模式：迭代器模式(关于设计模式，待学习透彻后，会再写一篇博客总结).关于迭代器模式的好处就不再多说，顺便提一下，我们经常用到的foreach循环，内部也是通过迭代器实现的。

### [Collection](https://docs.oracle.com/javase/8/docs/api/java/util/Collection.html)

Collection 提供了集合的一些基本操作,Collection 接口提供的主要方法：

```
boolean add(Object o) 添加对象到集合；
boolean remove(Object o) 删除指定的对象；
int size() 返回当前集合中元素的数量；
boolean contains(Object o) 查找集合中是否有指定的对象；
boolean isEmpty() 判断集合是否为空；
Iterator iterator() 返回一个迭代器；
boolean containsAll(Collection c) 查找集合中是否有集合 C 中的元素；
boolean addAll(Collection c) 将集合 C 中所有的元素添加给该集合；
void clear() 删除集合中所有元素；
void removeAll(Collection c) 从集合中删除 C 集合中也有的元素；
void retainAll(Collection c) 从集合中删除集合 C 中不包含的元素。
```
没发现有什么好说的。

### [List](https://docs.oracle.com/javase/8/docs/api/java/util/List.html)

List



