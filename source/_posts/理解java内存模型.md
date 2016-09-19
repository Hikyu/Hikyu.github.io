---
layout: post
title: 理解java内存模型
date: 2016-09-10 10:32:40
categories: 技术
tags: java
---

最近一直在看周志明所著的《深入理解Java虚拟机》，看到java内存模型这一章。自己从网上也查了一些资料，算是对java内存模型有了一个大概的认识，对理解和编写java并发有很大的帮助。有一段时间没再写博客了，正好利用周末的时间把自己学到的java内存模型的知识总结一下。Have a nice day~

## 并发为啥会出现问题

PS：2016/9/13更新：今天在地铁上看到这篇文章：[Java 并发原理无废话指南](http://toutiao.io/posts/493923/app_preview),感觉跟我这一小节要说明的问题比较相似，参考一下。

### 原子性

其实去了解java内存模型主要是为java并发打下基础。我刚学编程接触多线程的时候，关于多线程并发为什么会有并发问题有过一些思考，老师或者网上的例子都会给出一个类似这样的例子：

```java
public class BankAccount {
	private static int accountBalance = 10000;

	static class Save implements Runnable {
		private int money;

		public Save(int money) {
			this.money = money;
		}

		@Override
		public void run() {
			//存钱
			int tempAccount = accountBalance + money;
			//设置余额
			accountBalance = tempAccount;
			System.out.println("此次存入：" + money);
			System.out.println("当前余额：" + accountBalance);
		}

	}

	static class Obtain implements Runnable {

		private int money;

		public Obtain(int money) {
			this.money = money;
		}

		@Override
		public void run() {
			if (money > accountBalance) {
				System.out.println("余额不足");
				return;
			}
			//取钱
			int tempAccount = accountBalance - money;
			try {
				Thread.sleep(1000);//艾玛，卡了一秒
			} catch (InterruptedException e) {
				e.printStackTrace();
			}
			//设置余额
			accountBalance = tempAccount;
			System.out.println("此次取出：" + money);
			System.out.println("当前余额：" + accountBalance);
		}

	}

	public static void main(String args[]) {
		int saveMoney = 10000;
		int obtainMoney = 10000;
		//自己取钱
		Thread obtain = new Thread(new Obtain(obtainMoney));
		//老婆存钱
		Thread save = new Thread(new Save(saveMoney));
		obtain.start();
		save.start();
	}

}
```

输出结果：

```
此次存入：10000
当前余额：20000
此次取出：10000
当前余额：0
```

可以看到，老婆往账户上存钱，自己从账户上取钱，两个线程同时发生，（为了保证获得演示效果，我们让取钱过程卡了一秒），结果苦逼了，账户上余额为零了，跟老婆解释不清了。

分析一下出现问题的原因：

出现这个问题的原因就在于两个人操作同一个账户，在一个人修改账户余额的时候另一个人也在修改账户余额，造成结果混乱。账户余额就是共享变量，操作账户的人就是并发线程，我们把这两个线程叫做自己线程和老婆线程。

这就涉及到线程并发的第一个问题：原子性。

我们可以看出来，出现上面的问题的主要原因其实有两部分：取钱和设置余额。取钱和设置余额这两个动作并不是原子操作，他们是分开执行的。如果在取完钱之后自己线程被挂起（这个挂起跟线程调度有关，我们在程序中模拟了这个挂起操作），老婆线程开始存钱。老婆线程存完钱后，自己线程又把刚刚的tempAccount设回余额，使旧的tempAccount覆盖了新的accountBalance，造成结果错误。

```
//取钱
int tempAccount = accountBalance - money;

//设置余额
accountBalance = tempAccount;
```

为了实现这种错误的效果，我故意把

```
accountBalance -= accountBalance;
```

拆成了上面的两行。其实`accountBalance -= accountBalance;`本身就不是一个原子操作，拆成两行是为了放大这种效果。

通过上面的分析，我们得出，某些读写共享变量的操作如果不是原子操作，多线程并发的情况下会出现并发问题。如何判断是否需要进行原子操作，跟业务逻辑有关，需要我们自己去判断。注意，常见的x=y,x++等都不是原子操作。

原子性是出现并发问题的重要因素，大多数情况下多线程并发出现问题都跟没有实现原子操作有关。原子性实现了多个线程并发访问某段代码的时候，使这些线程能够有序访问。因为实现原子操作代码的一旦被执行，就不能被打断，其他线程想要访问的时候，只能阻塞等待。

java中实现原子性使用了synchronized关键字，在synchronized块之间的代码具备原子性。把上面代码中的两个run方法声明为synchronized的，这样的话，这段代码中涉及到的对共享变量的操作就不会随意被打断，要么存完钱再去取，要么取完钱再去存，不会有上述代码提到的问题。

那么，该段代码出现并发问题仅仅是因为没有对共享变量实现原子操作吗？下面看内存可见性。

### 可见性

组成原理中学过，为了更充分的利用CPU的性能，往往要在内存与处理器之间加一层：Cache（缓存），来作为内存与处理器之间的缓冲：将处理器需要的数据复制到缓存当中，当运算结束后再从缓存同步回内存当中。因为缓存的速度远远快于内存，这样处理器无需等待缓慢的内存读写，解决了处理器与内存的速度矛盾。

Java虚拟机也有类似的机制，每个线程有其自己的工作内存(类似前面的Cache)，线程对变量的读写必须在工作内存中进行，而不能直接读写主存中的变量。（这里的变量指被各个线程共享的变量，比如堆中的对象和方法区中的变量。）

画个图：

{% asset_img 内存模型.png 内存模型 %}

这样的机制会带来另一个问题：缓存一致性。多个线程共同处理同一个变量时，各自的缓存中的数据并不一致，同步回主内存的数据以谁的缓存数据为准呢？这就带来了并发问题。

我们回到上述的例子：

上面例子中的代码出现并发问题仅仅是因为没有对共享变量实现原子操作吗？现在我们知道自己线程和老婆线程有各自的工作内存，他们各自对accountBalance 的读写都是基于工作内存的。然后在恰当的时机同步回主内存。现在我们假设类似`accountBalance -= accountBalance;`这样的操作是原子性操作，设想以下的场景：

1.老婆线程向账户中存10000，此时操作老婆线程工作内存中的accountBalance~(我们使用~来表明这个变量是工作内存当中的)，此时`accountBalance~ = 20000;accountBalance = 10000;`

2.自己线程现在向账户中取10000，此时操作自己线程工作内存中的accountBalance~(注意此accountBalance~跟老婆线程中的accountBalance~不是同一个)，此时`accountBalance~ = 0;accountBalance = 10000;`

3.现在老婆线程把自己的accountBalance~刷回主内存，此时accountBalance = 20000；

4.现在自己线程把自己的accountBalance~刷回主内存，此时accountBalance = 0；

通过以上的分析，看到了即使我们使对共享变量的写操作实现了原子性，但由于内存可见性的问题，依然存在并发问题。这就是造成多线程并发的第二个原因：内存可见性。

我们在原子性分析最后还说了，通过使用synchronized关键字可以保证不存在并发问题，是因为synchronized不仅实现了代码原子性操作，还保证了内存可见性。每次执行加锁和释放锁的同时，都会把线程的工作内存和主内存进行同步。一方面，它使自己线程和老婆线程只能串行操作账户余额，另一方面，他保证了当老婆线程存完钱之后会把自己工作内存中的accountBalance~刷回主内存。设想synchronized没有实现内存可见性的话，上面的问题依旧存在，注意这和互斥没有什么关系，此时两个线程依旧是串行访问。解释这么啰嗦主要是让大家明白原子操作和内存可见是造成并发问题的两个不同因素，但是通过锁可以同时解决这两个因素带来的问题。

### 有序性

Cpu在执行指令的时候，为了优化提高Cpu运行程序的速度，会将多条指令不按程序规定的顺序分发给各个不同的电路单元处理，叫做指令重排序。注意乱序执行的指令之间没有数据依赖关系，因为乱序执行的结果必须保证结果的正确性。理解起来比较麻烦，通过一个例子来看一下。

以下例子来自《深入理解Java虚拟机》：

```java
Map configOptions;
char[] configText;

boolean initialized = false;

//假设以下代码在线程A中执行
//模拟读取配置信息，当读取完成后将initialized设置为true通知其他线程配置可用
configOptions = new HashMap();
configText = readConfigFile(flieName);
processConfigOptions(configText,configOptions);
initialized = true;

//假设以下代码在线程B中执行
//等待initialized为true,代表线程A已经把配置信息初始化完成
while(!initialized){
	sleep();
}
//使用线程A中初始化好的配置信息
doSomethingWithConfig();
```

在上面的例子中，由于指令重排序的优化，导致线程A中最后一句代码`initialized=true`被提前执行，这样线程B中使用配置信息的代码就可能出现错误。

所以，指令重排序也是造成并发问题的一个因素。在java中，synchronized关键字也可以解决指令重排序带来的并发问题，他可以保证线程之间操作的有序性。如果使用synchronized关键字将上面例子中访问initialized的相关代码包裹起来，就保证了这种多线程之间操作的有序性。因为使用synchronized关键字后，持有同一个锁的两个同步块只能串行的进入，比如：

```java
Map configOptions;
char[] configText;

boolean initialized = false;

//假设以下代码在线程A中执行
//模拟读取配置信息，当读取完成后将initialized设置为true通知其他线程配置可用
public synchronized void init(){
	configOptions = new HashMap();
	configText = readConfigFile(flieName);
	processConfigOptions(configText,configOptions);
	initialized = true;
}

//假设以下代码在线程B中执行
//等待initialized为true,代表线程A已经把配置信息初始化完成
public synchronized void doSomething(){
	while(!initialized){
		sleep();
	}
	//使用线程A中初始化好的配置信息
	doSomethingWithConfig();
}
```
注意上面两个方法在同一个类中实现。

至此，我们分析出了造成多线程并发问题的三个原因：原子性、可见性、原子性。并且知道了通过synchronized可以解决这三个因素带来的并发问题。java中大部分的并发控制都能通过synchronized来实现。再结合之前写的一篇[synchronized的用法](http://yukai.space/2016/08/16/synchronized%E7%9A%84%E4%B8%80%E4%BA%9B%E7%94%A8%E6%B3%95/)，对synchronized的使用更加得心应手啦！

## 先行发生原则

没有理解先行发生原则之前，看到网上很多博客提到这个，感觉很高深有木有~~~，理解了他之后，发现其实也挺简单。理解先行发生原则有助于我们判断线程是否安全，并发环境下两个操作之间是否存在数据冲突的问题。通过阅读《深入理解java虚拟机》和参阅网上的一些博客，我认为通过先行发生原则可以使我们知道自己写的多线程程序是否会因为可见性、原子性两个因素导致并发问题产生。至于原子性带来的问题，应该是程序员自己去分析具体的业务逻辑场景，并不能通过套用先行发生原则来判断自己的程序是否有并发问题。

比如我想到了之前宇哥跟我提到的一个bug:

在JDBC中获取日期之后通过一个静态的SimpleDateFormat对象把日期类型转换为字符串返回给用户。高并发情况下出现了这样一个问题：返回的日期是错误的，跟用户期待的日期不一致。

后来通过反复排查，最后发现是这个静态SimpleDateFormat对象造成的并发问题，他内部有一个Calendar对象，每次执行format方法的时候会调用`calendar.setTime(date);`,很明显当某个线程中在日期转换过程中被挂起的时候，恰好另一个线程也在执行转换日期的代码，他们调用同一个SimpleDateFormat对象中的同一个`calendar.setTime(date);`，结果肯定就变得混乱了。

上面的问题就是静态SimpleDateFormat对象被共享带来的结果，实际上也是原子性的问题，跟有序性和可见性并没有太大的关系。这就是所谓的业务逻辑相关，需要我们自己去分析。

解释了半天先行发生原则的作用和使用条件，下面该说说先行发生原则本身。

先行发生原则是指：如果说操作A先行发生于操作B，也就是发生在操作B之前，操作A产生的影响能被操作B观察到。

还是用《深入理解java虚拟机》中的例子来解释(真的是一本好书啊，一定要多看几遍)：

```
//以下操作在线程A中执行
i = 1;

//以下操作在线程B中执行
j = i;

//以下操作在线程C中执行
i = 2;
```

假设线程A中的操作`i=1`先行发生于线程B的操作`j=i`,那么可以确定在线程B的操作执行之后，j一定等于1。因为：根据先行发生原则，`i=1`的结果可以被B观察到。

现在保持A先行发生于B，线程C出现在A与B之间，但是线程C与B没有先行发生关系。那么j会等于多少呢？答案至不确定。因为线程C对变量i的影响可能会被B观察到，也可能不会。因为两者之间没有先行发生关系。

其实说白了，先行发生原则就是操作A在时间上或者逻辑上比B先发生，那么B一定能看到A操作带来的影响（修改了共享变量的值等等），那么此时A就是先行发生于B。

你可能会说难道B还有可能不会看到A带来的影响吗？A操作先执行的呀！想一想我们上面提到的内存可见性和有序性...

如果还没有理解所谓的先行发生原则的话，可以看一下[这篇文章](http://ifeve.com/easy-happens-before/)。

下面介绍几个java内存模型中存在的先行发生关系：

**程序次序规则**：一个线程内，按照程序代码的顺序，书写在前面的操作先行发生于(逻辑上)书写在后面的操作。

**管程锁定规则**：一个unlock操作先行发生于后面对同一个锁的lock操作。后面指时间上的先后顺序。

**volatile变量规则**：对一个volatile变量的写操作先行发生于后面对这个变量的读操作。这里的后面指时间上的先后顺序。

**传递性**：如果操作A先行发生于操作B，操作B先行发生于操作C，那么，操作A也就先行发生于操作C。

以上只是一部分先行发生关系，其他的不再一一介绍。

那么，先行发生原则如何使用呢？我们看一个例子：

```java
private int value = 0;

public void setValue(int value){
	this.value = value;
}

public int getValue(){
	return value;
}
```

假设存在线程A和B，A先调用了setValue(1),然后线程B调用了同一个对象的getValue(),那么线程B收到的返回值是多少？

套用上面存在的先行发生关系，我们发现，虽然线程A在操作时间上先行发生于线程B，但是无法确定B中的getValue()方法的返回结果。也就是说，这里的操作是不安全的。此时我们可以通过synchronized关键字来解决。可以看看[这个](http://wiki.jikexueyuan.com/project/java-memory-model/lock.html)

通过上面的分析，我们了解了先行发生原则的作用：判断内存可见性与重排序是否造成并发问题。

## Volatile关键字

通过上面的学习，再来看volatile就变得简单很多了。之前我对这个关键字也是看的云里雾里，现在仍然有个小疑问，后面会提到。

volatile关键字想必都不陌生，有时候在同步中会看到他。那么volatile究竟有什么作用呢?其实他实现了两个功能：**保证内存可见性和禁止重排序**。基于上面的内容应该对这个关键字心里有了个大概。那么，如何使用它呢？看一个例子就会用了。同样来自《深入理解java虚拟机》：

```java
public class VolatileTest {
	public static volatile int race = 0;
	
	public static void increase(){
		race++;
	}
	
	private static int THREAD_COUNT = 20;
	
	public static void main(String args[]) {
		Thread[] threads = new Thread[THREAD_COUNT];
		for (int i = 0; i < THREAD_COUNT; i++) {
			threads[i] = new Thread(new Runnable() {
				
				@Override
				public void run() {
					for(int i = 0; i< 10000; i++) {
						increase();
					}
				}
			});
			threads[i].start();
		}
		while (Thread.activeCount()>1) {
			Thread.yield();
		}
		System.out.println(race);
	}
}

```

```
运行结果：130310 //每次运行结果并不相同
```

可以看到，虽然使用了volatile关键字，但是并没有达到我们预期的效果：race=200000。Execute me?你特么在逗我？原因就在于`race++`,我们上面也提到过，这种自增运算并不是原子性的，恰好，volatile也没有保证原子性。所以出现了不理想的结果。

这个时候应该会有人说：volatile不是实现了内存可见性吗？自增运算虽然不是原子性的，但20个线程在访问race的时候不应该看到的是最新的值嘛？赋值的时候不是对主内存中的race操作吗？跟原子性有毛关系？以前的我就是这么想的。

现在我们来了解一下volatile的内存可见性是怎么实现的。前面也说了：**每个线程有其自己的工作内存，线程对变量的读写必须在工作内存中进行，而不能直接读写主存中的变量**。

当遇到读volatile变量的时候，会立即把主存中的变量值同步到工作内存当中。

当遇到写volatile变量的时候，会立即把工作内存中的变量值同步到主存中。

关于volatile怎么实现内存可见性，是通过一个叫[内存屏障](https://zh.wikipedia.org/wiki/%E5%86%85%E5%AD%98%E5%B1%8F%E9%9A%9C)的东西来实现的。具体的可以看下[这个](http://tech.meituan.com/java-memory-reordering.html)

所以说：所谓的实现内存可见性并不是直接操作主内存，还是通过工作内存来实现的。当某线程把race的值取到操作栈顶的时候，volatile关键字保证了race值在此时是正确的，与主内存同步的。但是在执行race++的后续指令的时候(race++不是原子性操作，通过多个指令完成)，其他线程可能已经更新了race的值了，操作栈顶的race值变成了过期的数据，race++执行完毕后可能把较小的race值同步回主内存。

关于volatile关键字的禁止重排序，具体的可以看下[这个](http://tech.meituan.com/java-memory-reordering.html)

我们从先行发生原则的角度看一下volatile的禁止重排序：

{% asset_img volatile.png volatile先行发生原则 %}

其中：i是普通变量，x是被volatile修饰的变量。A、B操作在一个线程当中，C、D操作在另一个线程当中。B先于C执行。

根据前面的volatile先行发生关系，我们可以得出，B先行发生于C，又因为A先行发生于B(程序次序规则)，所以A先行发生于C。那么A产生的影响一定会被C观察到，当B被执行的时候，会将当前工作内存中的变量都刷回到主内存当中，并通知其他线程同步主内存到自己的工作内存。这样便保证了A产生的影响一定会被C观察到。同时，A不能被重排序到B之后，因为这样的话，A产生是影响便不能被C观察到了，违背了先行发生原则。

即：**普通读写不能与其后的所有写volatile变量重排序**。同理，**普通读写不能与之前的所有读volatile变量重排序**。

下面看看volatile的使用场景：

1.运算结果并不依赖变量的当前值，或者能够确保只有单一的线程修改变量的值。

2.变量不需要与其他状态的变量共同参与不变约束。

第一点就很好理解了，volatile不保证原子性嘛~~

**第二点我也有点疑惑，待研究...**

关于volatile的使用场景，可以看看这篇文章：[Java 理论与实践: 正确使用 Volatile 变量](http://www.ibm.com/developerworks/cn/java/j-jtp06197.html)

## 最后

终于把自己想要总结的写完了~~断断续续写了四个小时...好累...

加油！





