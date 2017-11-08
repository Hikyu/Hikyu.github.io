---
layout: post
title: java任务取消
date: 2017-05-02 19:45:14
categories: 
- 技术
- 编程
tags:
- java
- 多线程
---
> 最近在用思维导图做读书笔记，虽然感觉没有网上所说的那么神奇，但是用来做笔记还是可以的。总结梳理了一下java取消任务执方面的一些内容，也是《java并发编程实战》的读书笔记。

{% asset_img java.png 任务取消 %}

<!-- more -->

## 取消原因

取消一个任务执行的理由有很多，通常有以下几个

- 用户请求取消

  通常用户点击“取消”按钮发出取消命令

- 有时间限制的操作

  计时任务，超时时就会取消任务执行并返回

- 应用程序逻辑

  比如有多个任务对一个问题进行分解和搜索解决方案，如果其中某个任务找到解决方案，其他并行的任务就可以取消了

- 发生错误

  比如爬虫程序下载网页到本地硬盘，如果盘满了之后爬取任务应该被取消

- 关闭

  程序或服务被关闭，则正在执行的任务也应该取消，而不是继续执行


## 取消线程执行

任务的取消执行，其实最后都会落到线程的终止上(任务都是由线程来执行)。在java中没有一种安全的抢占式方法来终止线程(Thread.stop 是不安全的终止线程执行的方法，已经废弃掉了)，所以需要一种很好的协作机制来平滑的关闭任务。

### 自然结束

中断线程的最好方法是让代码自然执行到结束，而不是从外部强制打断他。为此可以设置一个“任务取消标志”，任务代码会定期的查看这个标志，如果发现标志被设定了，则任务提前结束。

```java
public class SomeJob {
	private List<String> list = new ArrayList<>();
	private volatile boolean canceled = false;

	public void run() {
		while (!canceled) {
			String res = getResult();
			synchronized (this) {
				list.add(res);
			}
		}
	}

	private String getResult() {
		// do something...
		return "";
	}
	
	public void cancel() {
		this.canceled = true;
	}
}
```
上面的代码中，设置了一个volatile类型的变量canceled，所以其他线程对这个变量的修改对所有线程都是可见的(可见性)。每次循环执行某个操作之前都会检查这个变量是否被其他线程设置为true，如果为true则提前退出。

这是很常见的一种取消任务执行的手段，但是也有他的弊端，比如：

```java
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.LinkedBlockingQueue;

public class SomeJob {
	private BlockingQueue<String> list = new LinkedBlockingQueue<>(100);
	private volatile boolean canceled = false;

	public void run() {
		try {
			while (!canceled) {
				String res = getResult();
				synchronized (this) {
					list.put(res);
				}
			}
		} catch (InterruptedException e) {
			e.printStackTrace();
		}
	}

	private String getResult() {
		// do something...
		return "";
	}

	public void cancel() {
		this.canceled = true;
	}
}

```
上面将list替换为支持阻塞的BlockingQueue，他是一个有界队列，当调用list的put操作时，如果队列已经填满，那么将会一直阻塞直到队列有空余位置为止。如果恰好执行put操作是阻塞了，此时我们调用了cancel方法，那么什么时候检查canceled标志是不确定的，响应性很差，极端情况下，有可能永远也不会去再下一次轮询中检查canceled标志，试想我们执行了取消后，消费队列的线程已经停止，此时put操作又阻塞，那么将会一直阻塞下去，这个线程失去响应。

### 线程中断

通过线程自己的中断机制，可以解决上述问题。

每个线程都有一个boolean类型的变量，表示中断状态。当中断线程时，这个线程的中断状态将被设置为true。在Thread中有三个方法可以设置或访问这个变量：

- Thread.interrupt: 中断目标线程

- Thread.isInterrupted: 返回线程的中断状态

- Thread.interrupted: 清除线程的中断状态，并返回之前的值

调用interrupt并不意味着立即停止目标线程正在进行的任务，而只是将中断状态设置为true：他并不会正真中断一个正在运行的线程，而只是发出了一种中断请求，线程可以看到这个中断状态，然后在合适的时刻处理。

#### 中断请求

##### 响应中断阻塞

上面提到的中断请求，有些方法会处理这些请求，从而结束现在正在进行的任务。像上面代码中的BlockingQueue.put方法，当他在阻塞状态时，依然能够发现中断请求并提前返回，所以解决上面代码中的问题只需要对执行代码的线程thread调用thread.interrupt方法，BlockingQueue.put就可以从阻塞状态中恢复回来，从而完成取消。类似这样的支持中断的阻塞就叫做响应中断阻塞，主要有以下几个：

- Thread.sleep 

- Object.wait

- Thread.join

这些支持中断的阻塞在响应中断时执行的操作包括：

- 清除中断状态

- 抛出InterruptedException，表示阻塞操作由于中断而提前结束

jvm并不能保证这些阻塞方法检测到中断的速度，但在实际情况中响应速度还是很快的。

利用线程本身的中断状态作为取消机制，我们可以将上面的代码再改造一下：

```java
public class SomeJob {
	private BlockingQueue<String> list = new LinkedBlockingQueue<>();

	public void run() {
		try {
			while (!Thread.currentThread().isInterrupted()) {
				String res = getResult();
				synchronized (this) {
					list.put(res);
				}
			}
		} catch (InterruptedException e) {
			System.out.println("任务被取消...");
		}
	}

	private String getResult() {
		// do something...
		return "";
	}

	public void cancel(Thread thread) {
		thread.interrupt();
	}
}
```
任务代码在每次轮询操作前检查当前线程的状态，如果被中断了就退出。cancel方法是对当前执行任务的线程进行中断。

注意，调用cancel方法的是另一线程，传入的线程实例则是执行run方法的工作者线程，故在执行cancel方法后run方法可以检测到中断。

##### 不响应中断阻塞

并非所有的阻塞方法和阻塞机制都能够响应中断请求，比如正在read或write上阻塞的socket就不会响应中断，调用线程的interrupt方法只能设置线程的中断状态，除此以外没有任何作用，因为这些阻塞方法并不会去检查线程中断状态，也不会处理中断。这些阻塞就是不响应中断阻塞。主要有以下几个：

- java.io包中的同步socket io: 从socket中获取的InputStream和OutputStream中的read或write方法都不会响应中断，解决办法是关闭这个socket，使得正在执行read或write方法而被阻塞的线程抛出一个SocketException

- java.io包中的同步IO: 当中断一个正在InterruptibleChannel上等待的线程时，将抛出ClosedByInterruptException并关闭链路。

- Selector的异步IO: 如果一个线程在调用Selector.select方法时阻塞了，那么调用close或wakeup方法会使线程抛出ClosedSelectorException并返回

- 获得某个锁: 如果一个线程由于等待某个内置锁而阻塞，将无法响应中断。Lock类中提供了lockInterruptibly方法，该方法允许在等待一个锁的同时仍能响应中断。(BlockingQueue.put可以响应中断缘于此)

一个简单的例子，取消socket任务：

```java
public class CanceledThread extends Thread {
	private final Socket socket;
	private final InputStream stream;
	public CanceledThread(Socket socket) throws IOException {
		this.socket = socket;
		this.stream = socket.getInputStream();
	}
	@Override
	public void interrupt() {
		try {
			socket.close();
		} catch (Exception e) {
			// do nothing
		} finally {
			super.interrupt();
		}
	}
	
	@Override
	public void run() {
		try {
			byte[] bytes = new byte[1024];
			while (true) {
				int count = stream.read(bytes);
				if (count < 0) {
					break;
				} else if (count > 0) {
					// 处理读到 bytes
				}
 				
			}
		} catch (Exception e) {
			// 可能捕捉到InterruptedException 或 SocketException
			// 线程退出
		}
	}
}

```
在上面的代码中，即使socket的stream在read过程中阻塞了，也可以中断阻塞并返回。

#### 中断处理

上文提到，当调用可中断的阻塞库函数时，会抛出InterruptedException，这个异常会出现在我们的任务代码中(任务代码调用了这些阻塞方法)，有三种方法处理这个异常：

- 不处理，或者在捕捉到异常后打印日志以及做一些资源回收工作

  确定我们的任务代码可以这么做时才这么做。这意味这这个任务完全可以在这个线程中取消，不必再向上层报告或需要更上层的代码处理。

- 传递异常，从而使你的方法也成为可中断的阻塞方法

  简单的将异常抛出，让上层代码处理，这意味着需要上层代码再做一些资源回收等工作。

- 恢复中断状态，从而使调用栈中的上层代码能够对其进行处理

  如果不想或无法(Runnable中)传递InterruptedException时，可以通过再次调用interrupt来恢复中断状态。此时上层代码就可以捕捉到这个中断，从而作出处理。

ThreadPoolExcutor就是处理中断的一个例子：当其拥有的工作者线程检测到中断时，他会检查线程池是否正在关闭。如果是，他会在结束前执行一些线程清理工作，否则他可能创建一个新线程将线程池恢复到合理的规模。

## 取消任务

### 终止线程池

线程池的生命周期是由ExcutorService控制的。ExcutorService提供了两种关闭线程池的方法：

- shutdownNow

  强行关闭线程池，首先关闭当前正在执行的任务，然后返回所有尚未启动的任务清单(在任务队列当中的)

  关闭速度快，但是有风险，正在执行中的任务可能在执行一半的时候被结束

- shutdown

  正常关闭线程池，一直等到队列中的所有任务都执行完后才关闭，在此期间不接受新任务

  关闭速度慢，却更加安全

### 终止基于线程的服务

在写程序时往往会用到日志，在代码中插入println也是一种日志行为。为了避免由于日志为服务带来性能损耗和并发风险(多个线程同时打印日志有可能引发并发问题)，我们往往将打印日志任务放到某个队列中，由专门的线程从队列中取出任务进行打印。下面设计这样一个日志服务：

```java
public class LogService {
	private final BlockingQueue<String> queue;
	private final PrintWriter writer;
	private final LoggerThread thread;
	private boolean isShutDown = false;
	private int reservations = 0;

	public LogService(PrintWriter writer) {
		this.writer = writer;
		thread = new LoggerThread();
		queue = new LinkedBlockingQueue<>();
	}
	
	public void shutdown() {
		synchronized (this) {
			isShutDown = true;
		}
		thread.interrupt();
	}
	
	public void log(String msg) throws InterruptedException {
		synchronized (this) {
			if (isShutDown) {
				throw new IllegalStateException("日志服务已经关闭...");
			}
			reservations ++;
		}
		queue.put(msg);
	}

	class LoggerThread extends Thread {
		@Override
		public void run() {
			try {
				while (true) {
					try {
						synchronized (LogService.this) {
							if (isShutDown && reservations == 0) {
								break;
							}
							String msg = queue.take();
							synchronized (LogService.this) {
								reservations--;
							}
							writer.println(msg);
						}

					} catch (InterruptedException e) {
						// retry
					}
				}
			} finally {
				writer.close();
			}
		}
	}
}

```
当关闭日志服务时，日志服务不再会接收新的日志打印请求，并且会将队列中剩余的所有打印任务执行完毕，最后结束。如果此时日志打印线程恰好在queue.take方法中阻塞了，关闭日志服务时也能很好的从阻塞中恢复过来，结束服务。
