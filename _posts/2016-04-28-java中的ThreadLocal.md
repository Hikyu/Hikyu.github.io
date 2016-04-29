---
layout: post
categories: java 多线程
---

> 今天测试那边在做压力测试的时候，发现新版本的Jdbc占用CPU很高，导致并发量降低，研究半天，发现出问题的地方在于每条语句执行过后都会调用ThreadLocal的get方法。研究一番ThreadLocal...

## **问题背景**：

每次sql语句执行结束之后，最后都会接受后台传回的ReadyForQueryPacket包，标记语句执行完毕。在新版本的协议当中，针对读写分离的功能，在这个包中增加了一些要接收的数据：标记数据库状态的lsn。这个lsn标志着主备机之间的数据是否存在差异。每次执行完sql语句之后，都要将数据库后台传回来的lsn与当前主机的lsn进行比较，从而决定下一步的读写过程。每次取本机的lsn操作长这样：

{% highlight ruby linenos %}
LsnVo lv = ((LsnVo)DispatchConnection.threadLocalLsn.get());
{% endhighlight %}

其中，threadLocalLsn是DispatchConnection中的一个ThreadLocal类的静态对象。由于每次执行sql语句之后都会执行它的get方法，导致不必要的cpu浪费。这就是cpu异常的原因。

遂改之：

{% highlight ruby linenos %}
LsnVo lv = ((DispatchConnection) conn).getLsnVo();
{% endhighlight %}

将threadLocalLsn的get方法的执行提前到DispatchConnection的构造函数中去，之后的每次读取都是直接读取在DispatchConnection保存的成员变量。避免了频繁的get方法调用。

曾经在这里还有个疑问，那就是我认为不可以将这个get方法提前到DispatchConnection初始化当中，理由是如果有多个线程操作同一个DispatchConnection对象的时候，他们其实读取的是同一个lsn,造成共享变量的问题，而实际上lsn是一个线程级变量，不应该被多个线程共享。

后来，宇哥跟我解释说一般不会有多个线程操作同一个connection 的场景，因为这样很容易造成不可预知的后果（事务提交等被打乱）。看来还是对数据库这块的知识太缺乏啊！

so,按照上面的改法问题解决了。

那为什么要使用ThreadLocal存储lsn呢？前面也说了lsn是一个线程级变量，每个线程可以有多个connection，但这多个connection应当操作同一个lsn对象。（个人认为这样做的原因：如果将lsn设为connection中的静态变量，意味着他是全局的，多线程共享的，这样做增加了复杂性，因为要解决多线程共享变量的问题。 如果将lsn设为connection私有的，每个connection都有他自己的lsn,这样的话如果一个线程中有大量的connection，就会造成频繁的不必要的从后台获取和提交lsn的动作。所以将lsn设定为线程级变量最为合适。ps:之后问了宇哥，使用ThreadLocal存储lsn的主要原因并不是这个，跟读写分离的机制有关。但就ThreadLocal的使用而言，这么解释也是可以的，增加对ThreadLocal使用场景的理解）

这就是ThreadLocal的一个典型应用场景。

## **应用场景**

之前看了网上很多资料说ThreadLocal的应用场景：

1.解决了多线程共享对象的问题，

2.实现线程间的数据隔离，每个线程都有他自己的变量副本。

对于1，这样的说法现在看起来也有些勉强，首先不能说解决了多线程共享对象的问题，因为如果一个对象需要多个线程共享（在某些场景下这是必须的），那么他在内存中应该只有一份，但是使用ThreadLocal之后会有多个内存对象存在，而不是多个引用指向同一片内存。这样的话只能通过线程同步或者其他方法解决这种问题。但是在上面的场景中，说ThreadLocal解决了多线程共享对象的问题，也说得通。但是要加一个前提，那就是这个所谓的共享对象其实是可以不共享的，并不是必须共享的。

对于2，当时理解的时候就有一个疑惑，既然实现了每个线程都有他自己的变量副本，那在线程类中直接添加成员变量不就行了吗？这样的话每个线程对象都有他自己的变量副本啊，为啥要搞的这么麻烦，用一个ThreadLocal来实现。现在才明白了，有时候这个线程类的创建并不是开发者自己，而是使用你的API的用户。例如上面的场景，你怎么可以要求使用JDBC的用户在创建线程类的时候为他设置一个指定的成员变量呢？这显然是不可能的！我们只能通过上面提到的方法，保证使用JDBC接口的用户创建了线程之后，他的每个线程内所有的connection都是在访问同一个lsn。

我们总结一下使用ThreadLocal的好处：

1.如同上面所说的，可以合并为一点：保证创建的每个线程访问他自己的变量。

2.避免了参数的传递增加程序复杂性。

3.使你的程序更加优雅。