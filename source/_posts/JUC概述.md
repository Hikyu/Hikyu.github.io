---
title: JUC概述
date: 2018-07-13 22:20:40
categories: 
- 技术
- 编程
tags: 
- java
- 多线程
---
# JUC概述

java.util.concurrent的缩写，该包参考自EDU.oswego.cs.dl.util.concurrent，是JSR 166标准规范的一个实现；

JSR 166，是一个关于Java并发编程的规范提案，在JDK中，该规范由java.util.concurrent包实现。

即，JUC是Java提供的并发包，其中包含了一些并发编程用到的基础组件。

<!-- more -->

## JUC

{% asset_img juc.png JUC %}

JUC这个包下的类基本上包含了我们在并发编程时用到的一些工具。大致可以分为以下几类：

- 原子更新

  Java从JDK1.5开始提供了java.util.concurrent.atomic包，方便程序员在多线程环  境下，无锁的进行原子操作。
  
  在Atomic包里一共有12个类，四种原子更新方式，分别是原子更新基本类型，原子更新  数组，原子更新引用和原子更新字段。

- 锁和条件变量

  java.util.concurrent.locks包下包含了同步器的框架  AbstractQueuedSynchronizer，基于AQS构建的Lock以及与Lock配合可以实现等待/通知模式的Condition。
  
  JUC 下的大多数工具类用到了Lock和Condition来实现并发。

- [线程池](http://yukai.space/2017/05/08/java%E7%BA%BF%E7%A8%8B%E6%B1%A0%E7%9A%84%E4%BD%BF%E7%94%A8/)

  涉及到的类比如：Executor、Executors、ThreadPoolExector、  AbstractExecutorService、Future、Callable、ScheduledThreadPoolExecutor等等。

- [阻塞队列](http://yukai.space/2017/12/10/Java%E9%98%BB%E5%A1%9E%E9%98%9F%E5%88%97/)

  涉及到的类比如：ArrayBlockingQueue、LinkedBlockingQueue、PriorityBlockingQueue、LinkedBlockingDeque等等。

- 并发容器

  涉及到的类比如：ConcurrentHashMap、CopyOnWriteArrayList、ConcurrentLinkedQueue、CopyOnWriteArraySet等等。

- [同步器](http://yukai.space/2017/12/20/Java%E5%90%8C%E6%AD%A5%E5%B7%A5%E5%85%B7%E7%B1%BB/)

  剩下的是一些在并发编程中时常会用到的[工具类](http://yukai.space/2017/12/20/Java%E5%90%8C%E6%AD%A5%E5%B7%A5%E5%85%B7%E7%B1%BB/)，主要用来协助线程同步。比如：CountDownLatch、CyclicBarrier、Exchanger、Semaphore、FutureTask等等。

## CAS

CAS理论是实现整个java并发包的基石，谈到AQS之前，我们还需要对CAS有所了解。

在JAVA中，sun.misc.Unsafe 类提供了硬件级别的原子操作来实现CAS。 java.util.concurrent 包下的大量类都使用了这个 Unsafe 类的CAS操作。

### 乐观锁和悲观锁

Java在JDK1.5之前都是靠synchronized关键字保证同步的，这种通过使用一致的锁定协议来协调对共享状态的访问，可以确保无论哪个线程持有共享变量的锁，都采用独占的方式来访问这些变量。独占锁其实就是一种悲观锁，所以可以说synchronized是悲观锁。

悲观锁机制存在以下问题：

- 在多线程竞争下，加锁、释放锁会导致比较多的上下文切换和调度延时，引起性能问题。

- 一个线程持有锁会导致其它所有需要此锁的线程挂起。

- 如果一个优先级高的线程等待一个优先级低的线程释放锁会导致优先级倒置，引起性能风险。

而另一个更加有效的锁就是乐观锁。所谓乐观锁就是，每次不加锁而是假设没有冲突而去完成某项操作，如果因为冲突失败就重试，直到成功为止。

### CAS实现乐观锁

CAS是项乐观锁技术，当多个线程尝试使用CAS同时更新同一个变量时，只有其中一个线程能更新变量的值，而其它线程都失败，失败的线程并不会被挂起，而是被告知这次竞争中失败，并可以再次尝试。

> CAS 操作包含三个操作数 —— 内存位置（V）、预期原值（A）和新值(B)。如果内存位置的值与预期原值相匹配，那么处理器会自动将该位置值更新为新值。否则，处理器不做任何操作。无论哪种情况，它都会在 CAS 指令之前返回该位置的值。（在 CAS 的一些特殊情况下将仅返回 CAS 是否成功，而不提取当前值。）

> CAS 有效地说明了“我认为位置 V 应该包含值 A；如果包含该值，则将 B 放到这个位置；否则，不要更改该位置，只告诉我这个位置现在的值即可。”

比如，Unsafe中的int类型的CAS操作方法：

```
public final native boolean compareAndSwapInt(Object o, long offset,
                                                int expected,
                                                int x);
```

参数o就是要进行cas操作的对象，offset参数是内存位置，expected参数就是期望的值，x参数是需要更新到的值。

比如，把1这个数字属性更新到2的话，需要这样调用：

```
compareAndSwapInt(this, valueOffset, 1, 2)
```

若此时内存位置的值为1，则更新为2，更新成功。否则更新失败,返回false。

## AQS

AQS(AbstractQueuedSynchronizer)是构建锁或者其他同步组件的基础框架，位于 java.util.concurrent.locks 下。

JUC(java.util.concurrent)里所有的锁机制都是基于AQS框架上构建的。

{% asset_img aqs.png AQS %}

首先通过上面我画的结构图（只是一个大致的框架，很多类并未列出），可以大致的了解到，JUC当中，锁、条件变量和一些并发工具类都围绕AQS进行构建。同时，线程池、阻塞队列等又依赖于锁和条件变量实现并发。所以说，AQS是JUC并发包中的核心基础组件。

AQS在内部定义了一个int state变量,用来表示同步状态，并通过一个双向的FIFO 同步队列来完成同步状态的管理，当有线程获取锁失败后,就被添加到队列末尾。

可以看到，ReentrantLock、Semaphore等类并没有直接继承AQS，而是通过一个内部类Sync继承AQS来使用这个同步器。原因在于，这些工具类面向的是用户,而同步器面向的则是线程控制，两者并不存在`is-a`的关系，故使用组合，而不是继承。

以ReentrantLock的lock方法为例，简单了解AQS的内部原理：

注意，lock有公平与非公平之分：

- 公平锁（Fair）：加锁前检查是否有排队等待的线程，优先排队等待的线程，先来先得 

- 非公平锁（Nonfair）：加锁时不考虑排队等待问题，直接尝试获取锁，获取不到自动到队尾等待

ReentrantLock 默认的lock()方法采用的是非公平锁。

```java
// ReentrantLock.NonfairSync，继承自AbstractQueuedSynchronizer:
final void lock() {
    if (compareAndSetState(0, 1))
        setExclusiveOwnerThread(Thread.currentThread());
    else
        acquire(1);
}
```
注意，下文提到的【锁】，并不是正真的锁对象，而是一种同步状态，指向AbstractQueuedSynchronizer中的state变量。加锁即state加上某个值，释放锁即state减去某个值。

可以看到，lock()方法先通过CAS尝试将同步状态state从0修改为1。若恰好锁的状态为0，则直接修改成功。然后将独占锁的owner设置为当前线程。

若加锁失败，则调用acquire(1)：

```java
// AbstractQueuedSynchronizer:
public final void acquire(int arg) {
    if (!tryAcquire(arg) &&
        acquireQueued(addWaiter(Node.EXCLUSIVE), arg))
        selfInterrupt();
}
```

tryAcquire(arg)方法由AQS的子类（ReentrantLock.NonfairSync）实现，再次尝试获取锁，如果获取到，则执行完毕，否则，执行`addWaiter(Node.EXCLUSIVE)`。

通过`addWaiter(Node.EXCLUSIVE)`方法生成一个新的节点node，并将该节点节点添加到同步队列末尾，并返回该节点。

在把node插入队列末尾后，它并不立即挂起该节点中线程,因为在插入它的过程中,前面的线程可能已经执行完成，所以它会先进行自旋操作`acquireQueued(node, arg)`，尝试让该线程重新获取锁。

```java
// AbstractQueuedSynchronizer:
final boolean acquireQueued(final Node node, int arg) {
    try {
        boolean interrupted = false;
        for (;;) {
            final Node p = node.predecessor();
            if (p == head && tryAcquire(arg)) {
                setHead(node);
                p.next = null; // help GC
                return interrupted;
            }
            if (shouldParkAfterFailedAcquire(p, node) &&
                parkAndCheckInterrupt())
                interrupted = true;
        }
    } catch (RuntimeException ex) {
        cancelAcquire(node);
        throw ex;
    }
}
```

上述方法中是一个for循环，首先判断前驱节点是否是head（head是持有锁的节点），若是则再次尝试获取锁。若成功则返回，否则，执行`shouldParkAfterFailedAcquire(p, node)`，判断此时是否应该挂起。若`shouldParkAfterFailedAcquire(p, node)`返回true，表示应挂起，执行`parkAndCheckInterrupt()`，将当前线程挂起。

该线程被唤醒后，继续执行for循环中的代码，尝试获取锁。

有关AQS的详细介绍，参考[深入学习java同步器AQS](https://zhuanlan.zhihu.com/p/27134110)、[AQS的原理浅析](http://ifeve.com/java-special-troops-aqs/)

## 条件变量（Condition）

条件变量用于实现`等待/通知模式`，比如LinkedBlockingQueue:

```java
//首先创建一个可重入锁，它本质是独占锁
private final ReentrantLock takeLock = new ReentrantLock();
//创建该锁上的条件队列
private final Condition notEmpty = takeLock.newCondition();
//使用过程
public E take() throws InterruptedException {
    //首先进行加锁
    takeLock.lockInterruptibly();
    try {
        //如果队列是空的，则进行等待
        notEmpty.await();
        //取元素的操作...
        
        //如果有剩余，则唤醒等待元素的线程
        notEmpty.signal();
    } finally {
        //释放锁
        takeLock.unlock();
    }
    //取完元素以后唤醒等待放入元素的线程
}
```

Condition接口由AQS内部类ConditionObject实现。ConditionObject在内部也维护了一个队列，与同步队列相对应的，称之为条件队列。该队列与同步队列类似，其节点为AQS内部类Node。

{% asset_img condition.png 条件队列 %}

当持有锁的线程调用了Condition.await()方法时，代表该线程的节点进入该Condition对象（ConditionObject）的条件队列，同时释放其持有的锁并挂起，等待被唤醒。

当在条件队列中的节点被其他线程调用Condition.signal()唤醒，该节点从条件队列中移除并被加入到同步队列中，同时尝试获取锁，若获取失败则继续挂起。

需要注意的是，条件队列只能用于独占锁。Condition对象由ReentrantLock.newCondition()方法返回，其内部是返回了AQS内部类ConditionObject对象。

对于同一个ReentrantLock对象，每调用一次newCondition()方法，便返回一个新的ConditionObject实例。这些ConditionObject实例之间是独立的，拥有各自的条件队列。但是这些ConditionObject实例都被绑定到了同一个同步队列上，即他们竞争的是同一把锁。

其原理是，ConditionObject是AQS的内部类，内部类中隐含了指向外部类AQS的引用。所有由同一个AQS对象实例化的ConditionObject，他们的外部类的引用指向了相同的AQS对象，故他们访问的外部类的同步队列也是同一个。

关于条件队列的详细解释，参考[深入浅出AQS之条件队列](https://segmentfault.com/a/1190000011429685)