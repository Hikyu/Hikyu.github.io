---
layout: post
title:  "java中的ThreadLocal"
categories: 编程
tags: 
- java
- 多线程
date:   2016-06-21 12:48:55
---

> 今天测试那边在做压力测试的时候，发现新版本的Jdbc占用CPU很高，导致并发量降低，研究半天，发现出问题的地方在于每条语句执行过后都会调用ThreadLocal的get方法。研究一番ThreadLocal...

## **问题背景**：

每次sql语句执行结束之后，最后都会接受后台传回的ReadyForQueryPacket包，标记语句执行完毕。在新版本的协议当中，针对读写分离的功能，在这个包中增加了一些要接收的数据：标记数据库主机状态的lsn。这个lsn标志着主备机之间的数据是否存在差异。每次执行完sql语句之后，都要将数据库后台传回来的lsn与当前主机的lsn进行比较，从而决定下一步的读写过程。每次取本机的lsn操作长这样：

```java
LsnVo lv = ((LsnVo)DispatchConnection.threadLocalLsn.get());
```

其中，threadLocalLsn是DispatchConnection中的一个ThreadLocal类的静态对象。由于每次执行sql语句之后都会执行它的get方法，导致不必要的cpu浪费。这就是cpu异常的原因。

遂改之：

```java
LsnVo lv = ((DispatchConnection) conn).getLsnVo();
```

将threadLocalLsn的get方法的执行提前到DispatchConnection的构造函数中去，之后的每次读取都是直接读取在DispatchConnection保存的成员变量。避免了频繁的get方法调用。

曾经在这里还有个疑问，那就是我认为不可以将这个get方法提前到DispatchConnection初始化当中，理由是如果有多个线程操作同一个DispatchConnection对象的时候，他们其实读取的是同一个lsn,造成共享变量的问题，而实际上lsn是一个线程级变量，不应该被多个线程共享。

后来，宇哥跟我解释说一般不会有多个线程操作同一个connection 的场景，因为这样很容易造成不可预知的后果（事务提交等被打乱）。看来还是对数据库这块的知识太缺乏啊！

PS:后来还是出问题了，使用线程池的时候，确实有可能发生上面多线程并发的情况。改回原来版本，性能下降问题依然存在，现未找到合适的解决办法。2016/7/29

so,按照上面的改法问题解决了。

那为什么要使用ThreadLocal存储lsn呢？前面也说了lsn是一个线程级变量，每个线程可以有多个connection，但这多个connection应当操作同一个lsn对象。

这就是ThreadLocal的一个典型应用场景。

## **ThreadLocal原理**：

使用ThreadLocal存储变量，实现了线程级别的变量，即同一个线程内这个变量只有一个。

ThreadLocal的set和get方法：

```java
public void set(T value) {
        Thread t = Thread.currentThread();
        ThreadLocalMap map = getMap(t);
        if (map != null)
            map.set(this, value);
        else
            createMap(t, value);
}

public T get() {
        Thread t = Thread.currentThread();
        ThreadLocalMap map = getMap(t);
        if (map != null)
            return (T)map.get(this);

        // Maps are constructed lazily.  if the map for this thread
        // doesn't exist, create it, with this ThreadLocal and its
        // initial value as its only entry.
        T value = initialValue();
        createMap(t, value);
        return value;
}
```

可以看到，我们存入ThreadLocal的变量最终存到一个ThreadLocalMap中，这个ThreadLocalMap实际上是Thread的成员变量。这个ThreadLocalMap以ThreadLocal为键，是因为，在一个线程中很可能不只有一个ThreadLocal对象，每个ThreadLocal所要存储的Value值也不同。每次调用ThreadLocal的get方法时，都会去当前线程的ThreadLocalMap中找到对应的值。起到线程隔离的效果。

很容易明白他的工作原理。

## **应用场景**

之前看了网上很多资料说ThreadLocal的应用场景：

1.解决了多线程共享对象的问题，

2.实现线程间的数据隔离，每个线程都有他自己的变量副本。

对于1，这样的说法现在看起来也有些勉强，首先不能说解决了多线程共享对象的问题，因为如果一个对象需要多个线程共享（在某些场景下这是必须的），那么他在内存中应该只有一份，但是使用ThreadLocal之后会有多个内存对象存在，而不是多个引用指向同一片内存。这样的话只能通过线程同步或者其他方法解决这种问题。但是在上面的场景中，说ThreadLocal解决了多线程共享对象的问题，也说得通。但是要加一个前提，那就是这个所谓的共享对象其实是可以不共享的，并不是必须共享的。比如上面的场景中，DispatchConnection 中 的masterLsn代表主机的状态，这个Lsn是可以不设为全局的（虽然主机只有一台，代表主机真实状态的Lsn也只有一个），每个线程可以有自己的masterLsn来表示当前主机的状态，因为在同一个线程中，每次的数据库读写操作是基于上一次操作进行的。

对于2，每个线程有自己的变量副本。在上面的场景中，每个线程都应该操作同一个masterLsn。比如，首先创建了一个DispatchConnection，使用这个connection对数据库进行了更新操作，更新DispatchConnection中的masterLsn，然后关闭这个connection。紧接着又创建一个新的DispatchConnection，使用这个connection对数据库进行一些新的操作，比如查询刚才的更新。这个时候，需要将刚刚获得的masterLsn发送到备机，使备机与主机进行同步工作，然后才可以查询到上一个DispatchConnection所做的更新。所以，虽然创建了新的DispatchConnection，但前后两个DispatchConnection中的masterLsn应该是一样的，即这个masterLsn在同一个线程中应该只有一个，无论创建多少DispatchConnection（masterLsn是DispatchConnection的成员变量），这些connection中的Lsn都指向同一个对象。 故，使用ThreadLocal保存该masterLsn到DispatchConnection中。

我们总结一下使用ThreadLocal存储某个变量的场景，或者说条件：

1.这个变量在同一个线程中只允许有一个，比如上面的masterLsn，尽管包含masterLsn的DispatchConnection被创建了多次，但是他们的成员变量masterLsn指向同一个对象。

2.要满足1中的条件，可以将该变量设为static的。此时多个线程共享这同一个变量，内存中独一份。但是这个时候会产生同步问题，代码的复杂度上升，也容易出问题。

所以，使用ThreadLocal的场景应该是这样：**这个变量不同的线程之间不需要共享，也就是这个变量不要求是全局的。同时，在同一个线程中，这个变量要求只有一个，即这个变量为线程级别的变量。**

PS:既然说这个变量是线程级别的变量，那为什么不在这个线程类中创建这样一个变量呢？注意，线程的创建有时是不可控的，在上面的场景中，创建线程的基本上是使用DispatchConnection的用户，我们不能要求用户去创建masterLsn，更何况，这个masterLsn是属于DispatchConnection这个类，而DispatchConnection有可能创建销毁多次。

另外，网上提到使用ThreadLocal的一个好处：避免了参数的传递增加程序复杂性。

我不太理解这个好处从哪里体现出来。如果说要避免参数传递，将这个参数设为类的成员变量也可以解决。应用ThreadLocal的情况是：把ThreadLocal设为了成员变量，把这个参数存入ThreadLocal中。这个虽然说是避免了参数的传递，但这与使用ThreadLocal的目的相去甚远。使用ThreadLocal最主要还是解决线程级别的变量的问题。
