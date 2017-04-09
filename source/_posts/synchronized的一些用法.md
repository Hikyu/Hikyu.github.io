---
layout: post
date: 2016-08-16 15:31:44
categories: 编程
title: synchronized的用法
tags: 
- 多线程
- java
comments: true
---

>以前的工作过程中，偶尔会遇到synchronized的使用，比如[这篇总结](http://yukai.space/2015/12/21/notify%E9%97%AE%E9%A2%98/)。今天来总结一下自己对synchronized的关键字的一些认识。

## 同步锁

synchronized顾名思义，就是用来进行一些同步工作的，我们常常在多线程的环境中使用到它，实现互斥的效果。

每一个java对象都可以当做一个同步锁，线程进入同步代码块或方法的时候会自动获得该锁，在退出同步代码块或方法时会释放该锁。获得锁的唯一途径就是进入这个锁的保护的同步代码块或方法。这里的同步代码块和同步方法，就是使用synchronized关键字标记的代码块和方法。比如：

```java
synchronized (object) {
	//doSomething...		
}
```

上面的 '{' '}' 中间的内容，就是同步代码块，object可以认为是同步锁。同步锁实现了互斥的效果，这就是意味着最多只有一个线程能够获得该锁，当线程A尝试去获得线程B持有的锁时，线程A必须等待或者阻塞，知道线程B释放这个锁，如果B线程不释放这个锁，那么A线程将永远等待下去。

## synchronized修饰代码块

### synchronized同步锁为普通对象

```java
public void function(){
	synchronized (object) {
		//doSomething...		
	}
}
```
<!-- more -->
当某个线程要访问上面同步代码块中的内容时，若此时没有其他线程获得object对象的锁，则此线程获得object对象的锁，获得了这段代码的执行权，否则，此线程被阻塞，直到其他线程释放了object对象的锁。

下面的例子：

```java
public class SyncTest {
	public static void main(String args[]){
		Sync[] syncs = new Sync[5];
		for (int i = 0; i < syncs.length; i++) {
			syncs[i] = new Sync(new Object());
		}
		
		for(Sync sync : syncs){
			sync.start();
		}
	}
}
class Sync extends Thread{
	Object syncObj;
	public Sync(Object syncObj) {
		this.syncObj = syncObj;
	}
	public void run(){
		synchronized (syncObj) {
			System.out.println(Thread.currentThread().getName()+"运行中...");
			try {
				Thread.sleep(1000);
			} catch (InterruptedException e) {
				e.printStackTrace();
			}
			System.out.println(Thread.currentThread().getName()+"结束...");
		}
	}
}
```
运行结果：

```
Thread-0运行中...
Thread-1运行中...
Thread-2运行中...
Thread-3运行中...
Thread-4运行中...
Thread-1结束...
Thread-0结束...
Thread-3结束...
Thread-4结束...
Thread-2结束...
```

跟我们的预期不一样，这5个线程并没有按顺序执行，他们之间不是同步的。这是因为：5个线程中的syncObj并不是指向同一个对象，他们之间不存在同步锁的竞争，所以是非同步的。将程序改为：

```java
public class SyncTest {
	public static void main(String args[]){
		Sync[] syncs = new Sync[5];
		Object object = new Object();
		for (int i = 0; i < syncs.length; i++) {
			syncs[i] = new Sync(object);
		}
		
		for(Sync sync : syncs){
			sync.start();
		}
	}
}
class Sync extends Thread{
	Object syncObj;
	public Sync(Object syncObj) {
		this.syncObj = syncObj;
	}
	public void run(){
		synchronized (syncObj) {
			System.out.println(Thread.currentThread().getName()+"运行中...");
			try {
				Thread.sleep(1000);
			} catch (InterruptedException e) {
				e.printStackTrace();
			}
			System.out.println(Thread.currentThread().getName()+"结束...");
		}
	}
}
```

运行结果：

```java
Thread-0运行中...
Thread-0结束...
Thread-4运行中...
Thread-4结束...
Thread-2运行中...
Thread-2结束...
Thread-3运行中...
Thread-3结束...
Thread-1运行中...
Thread-1结束...
```

5个线程达到了同步的效果。但是5个线程的执行顺序并不是固定的，这是编译时重排序造成的。

重点要理解：**若想要多个线程同步，则这些线程必须竞争同一个同步锁。**

### synchronized同步锁为类

类也是一个对象，可以按照普通对象的方式去理解。他们的不同之处在于，普通对象作用于某个实例，而类对象作用于整个类。

将上面的例子修改一下：

```java
public class SyncTest {
	public static void main(String args[]){
		Sync[] syncs = new Sync[5];
		for (int i = 0; i < syncs.length; i++) {
			syncs[i] = new Sync();
		}
		
		for(Sync sync : syncs){
			sync.start();
		}
	}
}
class Sync extends Thread{
	public void run(){
		synchronized (SyncTest.class) {
			System.out.println(Thread.currentThread().getName()+"运行中...");
			try {
				Thread.sleep(1000);
			} catch (InterruptedException e) {
				e.printStackTrace();
			}
			System.out.println(Thread.currentThread().getName()+"结束...");
		}
	}
}
```

运行结果：

```
Thread-0运行中...
Thread-0结束...
Thread-3运行中...
Thread-3结束...
Thread-1运行中...
Thread-1结束...
Thread-4运行中...
Thread-4结束...
Thread-2运行中...
Thread-2结束...
```
这些线程同样实现了同步，因为他们的同步锁是同一个对象--SyncTest类对象。

需要注意的是，类对象锁和普通对象锁是两个不同的锁（即使这个对象是这个类的实例），他们之间互不干扰。

```java
public class SyncTest {
	public static void main(String args[]){
		Sync[] syncs = new Sync[5];
		for (int i = 0; i < syncs.length; i++) {
			syncs[i] = new Sync();
		}
		Sync1 sync1 = new Sync1(new SyncTest());
		
		for(Sync sync : syncs){
			sync.start();
		}
		
		sync1.start();
	}
}
class Sync extends Thread{
	public void run(){
		synchronized (SyncTest.class) {
			System.out.println(Thread.currentThread().getName()+"运行中...");
			try {
				Thread.sleep(1000);
			} catch (InterruptedException e) {
				e.printStackTrace();
			}
			System.out.println(Thread.currentThread().getName()+"结束...");
		}
	}
}

class Sync1 extends Thread{
	SyncTest syncTest;
	public Sync1(SyncTest syncTest){
		this.syncTest = syncTest;
	}
	public void run(){
		synchronized (syncTest) {
			System.out.println(Thread.currentThread().getName()+"运行中...");
			try {
				Thread.sleep(1000);
			} catch (InterruptedException e) {
				e.printStackTrace();
			}
			System.out.println(Thread.currentThread().getName()+"结束...");
		}
	}
}
```

运行结果：

```
Thread-0运行中...
Thread-5运行中...
Thread-0结束...
Thread-5结束...
Thread-4运行中...
Thread-4结束...
Thread-2运行中...
Thread-2结束...
Thread-3运行中...
Thread-3结束...
Thread-1运行中...
Thread-1结束...
```

可以看到，虽然Sync1中的对象锁是SyncTest的实例，但是Sync1与Sync的run方法中的synchronized代码块并没有实现同步，他们可以同时访问这段代码。

## synchronized修饰方法

synchronized修饰方法在本质上和修饰代码块是一样的，他们都是通过同步锁来实现同步的。

### synchronized修饰普通方法

```java
public synchronized void syncFunction(){
		//doSomething...
}
```
synchronized修饰普通方法中的同步锁就是这个对象本身，即"this"。

下面的代码：

```java
class Sync extends Thread{
	public synchronized void syncFunction(){
		doSomething();
	}
	
	public void syncFunction2(){
		synchronized (this) {
			doSomething();
		}
	}
	
	private void doSomething(){
		//doSomething...
	}
}
```

上面syncFunction()与syncFunction2()实现的同步效果是一样的。

当类中某个方法test()被synchronized关键字所修饰时，所有不同的线程访问这个类的同一个实例的test()方法都会实现同步的效果。不同的实例之间不存在同步锁的竞争，也就是说，不同的线程访问这个类不同实例的test()方法并不会实现同步。这很容易理解，因为不同的实例同步锁不同，每个实例都有自己的"this"。

### synchronized修饰静态方法

```java
public static synchronized void syncFunction(){
		//doSomething...
}
```
同样的，synchronized作用于静态方法时，跟使用类对象作为静态锁的效果是一样的，此时的类对象就是静态方法所属的类。

不同的线程访问某个类不同实例的syncFunction()方法(被synchronized修饰的静态方法，如上)时，他们之间实现了同步效果。结合上面的解释，这种情况也很好理解：此时不同线程竞争同一把同步锁，这就是这个类的类对象锁。

## 总结

理解synchronized的关键就在于：**若想要多个线程同步，则这些线程必须竞争同一个同步锁。**这个同步锁，可以理解为一个对象。