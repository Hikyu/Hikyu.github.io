---
layout: post
title: Java同步工具类
date: 2017-12-20 17:53:23
categories: 
- 技术
- 编程
tags:
- java
- 多线程
---

## CountDownLatch

CountDownLatch(闭锁)的用法：

CountDownLatch在实例化的时候需要传入一个int类型的计数器，表示需要等待事件的数量。CountDownLatch.countDown()方法递减这个计数器，表示一个事件已经发生了；而调用了CountDownLatch.await()方法的线程等待计数器值达到零，表示所有需要等待的事件已经发生了。若计数器值非零，那么await()方法会一直阻塞到计数器的值为零，或者等待超时。

CountDownLatch的应用场景：

- 确保某个计算在其所需要的所有资源都已经初始化后再继续执行。

- 确保某个服务在其依赖的所有其他服务都已经启动之后再启动。

- 等待某个操作的所有参与者都就绪后再执行。比如《荒野行动》，小队所有玩家点击“准备”之后房主才可以开始游戏。

<!-- more -->

比如，我们经常需要测试n个线程并发执行某个任务执行的时间：

```java
public long timeTasks(int nThreads, final Runnable task) throws InterruptedException {
	    final CountDownLatch startGate = new CountDownLatch(1);
	    final CountDownLatch endGate = new CountDownLatch(nThreads);
	    
	    for (int i = 0; i < nThreads; i++) {
			Thread t = new Thread() {
				public void run() {
					try {
						startGate.await();
						try {
							task.run();
						} finally {
							endGate.countDown();
						}
					} catch (InterruptedException e) {
					}
				};
			};
			t.start();
		}
	    
	    long start = System.nanoTime();
	    startGate.countDown();
	    endGate.await();
	    long end = System.nanoTime();
	    return end - start;
} 
```

startGate保证了主线程能够`同时释放`所有的工作线程；endGate是主线程能够等待最后一个线程执行完成，而不是顺序的等待每个线程执行完成。

## Semaphore

Semaphore(信号量)用来控制同时访问某个特定资源的操作数量，或者同时执行某个指定操作的数量。Semaphore还可以用来实现某种资源池，或对容器添加边界。

Semaphore的原理是：Semaphore中管理着一组虚拟的"许可"，许可的初始数量可以通过构造函数指定。在执行某个操作时可以先获得许可(acquire)，并在使用后释放许可(release)。如果当前没有许可，那么acquire将阻塞直到有许可；release方法将返回一个许可给Semaphore。注意，Semaphore并不受限于他在创建时初始化的许可数量，只要调用了release方法，Semaphore就会增加一个许可。

```java
Semaphore sem = new Semaphore(2);
System.out.println(sem.availablePermits());//2
sem.release();
System.out.println(sem.availablePermits());//3
sem.release(2);
System.out.println(sem.availablePermits());//5
sem.acquire();
System.out.println(sem.availablePermits());//4
```

Semaphore还提供了一些其他的方法用来获得许可：

```java
/*
 * 获得一个许可，如果当前没有许可，将阻塞直到有许可或线程被中断
 * 若线程被中断，抛出InterruptedException
 */
public void acquire() throws InterruptedException
/*
 * 获得指定数量的许可，如果当前没有这么多许可，将阻塞直到有许可或线程被中断
 * 若线程被中断，抛出InterruptedException
 */
public void acquire(int permits) throws InterruptedException
/*
 * 获得一个的许可，如果当前没有许可，将阻塞直到有许可；
 * 不响应线程中断，若检测到线程中断，重新设置中断状态，代码返回后由上层代码处理中断
 */
public void acquireUninterruptibly()
/*
 * 获得指定数量的许可，如果当前没有这么多许可，将阻塞直到有许可；
 * 不响应线程中断，若检测到线程中断，重新设置中断状态，代码返回后由上层代码处理中断
 */
public void acquireUninterruptibly(int permits)
/*
 * 获得一个的许可，如果当前没有许可，将返回false；
 */
public boolean tryAcquire()
/*
 * 获得指定数量的许可，如果当前没有这么多许可，将返回false；
 */
public boolean tryAcquire(int permits)
/*
 * 获得一个的许可，如果当前没有许可，将阻塞直到有许可或线程被中断或超过指定时间；
 */
public boolean tryAcquire(long timeout, TimeUnit unit) throws InterruptedException
/*
 * 获得指定数量的许可，如果当前没有这么多许可，将阻塞直到有许可或线程被中断或超过指定时间；
 */
public boolean tryAcquire(int permits, long timeout, TimeUnit unit) throws InterruptedException
```

此外，Semaphore构造函数还提供了一个bool参数，用于指定Semaphore是公平(true)还是非公平(false)的。

Semaphore维护了一个许可的阻塞等待队列；

公平策略是指：当一个线程A执行acquire方法时，如果阻塞队列有等待的线程，直接插入到阻塞队列尾节点并挂起，等待被唤醒。

非公平策略是指：当一个线程A执行acquire方法时，会直接尝试获取许可，而不管同一时刻阻塞队列中是否有线程也在等待许可。

例子：有界阻塞容器BoundedHashSet

```java
public class BoundedHashSet<T> {
	private final Set<T> set;
	private final Semaphore sem;
	
	public BoundedHashSet(int bound) {
		this.set = Collections.synchronizedSet(new HashSet<T>());
		this.sem = new Semaphore(bound);
	}
	
	public boolean add(T o) throws InterruptedException {
		sem.acquire();
		boolean wasAdd = false;
		try {
			wasAdd = set.add(o);
			return wasAdd;
		} finally {
			if (!wasAdd) {
				sem.release();
			}
		}
	}
	
	public boolean remove(Object o) {
		boolean wasRemoved = set.remove(o);
		if (wasRemoved) {
			sem.release();
		}
		return wasRemoved;
	}
}
```
## CyclicBarrier

CyclicBarrier(栅栏)从字面意思上来说，意为"循环栅栏"。所谓栅栏，就是屏障，CyclicBarrier所实现的功能就是让一组线程到达一个屏障点时阻塞(调用await方法)，直到所有的线程都到达屏障的位置(都调用了await方法)，此时所有的线程都被释放，CyclicBarrier也被重置便于下次使用。

CyclicBarrier提供了两组构造函数：

```java
public CyclicBarrier(int parties, Runnable barrierAction)
public CyclicBarrier(int parties)
```
parties 表示需要在屏障点阻塞的线程数。即，有 parties 个线程需要调用 CyclicBarrier 的 await 方法。

barrierAction 表示在所有线程到达屏障点之后需要执行的特殊动作。

若想理解 CyclicBarrier，看一下await的源码即可：

```java
public int await() throws InterruptedException, BrokenBarrierException {
    try {
        return dowait(false, 0L);
    } catch (TimeoutException toe) {
        throw new Error(toe); // cannot happen;
    }
}
private int dowait(boolean timed, long nanos)
    throws InterruptedException, BrokenBarrierException,
           TimeoutException {
    final ReentrantLock lock = this.lock;
    lock.lock();
    try {
		// 屏障
        final Generation g = generation;
        if (g.broken)
            throw new BrokenBarrierException();
        if (Thread.interrupted()) {
            breakBarrier();
            throw new InterruptedException();
        }
       int index = --count;
	   // index ==0 表示此时所有线程都已经调用await方法，到达了屏障点
       if (index == 0) {  // tripped
           boolean ranAction = false;
           try {
			   // 可以看到，由最后一个到达屏障点的线程执行了barrierAction
               final Runnable command = barrierCommand;
               if (command != null)
                   command.run();
               ranAction = true;
			   // 唤醒所有等待的线程，设置新的屏障，恢复Count
               nextGeneration();
               return 0;
           } finally {
               if (!ranAction)
                   breakBarrier();
           }
       }
        // loop until tripped, broken, interrupted, or timed out
		// 还有线程没有到达屏障(调用await)，本线程阻塞
        for (;;) {
            try {
                if (!timed)
                    trip.await();
                else if (nanos > 0L)
                    nanos = trip.awaitNanos(nanos);
            } catch (InterruptedException ie) {
                if (g == generation && ! g.broken) {
					// await的线程被中断了，打破了栅栏
					// 所有的线程都将被唤醒，抛出BrokenBarrierException
                    breakBarrier();
                    throw ie;
                } else {
                    // We're about to finish waiting even if we had not
                    // been interrupted, so this interrupt is deemed to
                    // "belong" to subsequent execution.
                    Thread.currentThread().interrupt();
                }
            }
            if (g.broken)
                throw new BrokenBarrierException();
			// 线程被唤醒，可能是所有线程执行到屏障点被唤醒；也可能是到达了超时时间被唤醒
			// 检查是否更新了屏障，如果更新了屏障，表示所有线程都执行到了屏障点，屏障被重置，返回当前索引
            if (g != generation)
                return index;
            if (timed && nanos <= 0L) {
                breakBarrier();
                throw new TimeoutException();
            }
        }
    } finally {
        lock.unlock();
    }
}

private void nextGeneration() {
    // signal completion of last generation
    trip.signalAll();
    // set up next generation
    count = parties;
    generation = new Generation();
}

private void breakBarrier() {
    generation.broken = true;
    count = parties;
    trip.signalAll();
}
```

例子：A,B,C 三个家庭开了三辆车自驾游，由于每辆车的速度不一致，约定每到达一个休息站，先到达的家庭需要等后面的家庭，等所有家庭都到齐了之后，买点东西，再同时出发。

```java
public class Traveling {
	private final CyclicBarrier barrier;
	private final Family[] families;
	/** 已经经过的休息站数量 */
	private volatile int restingCount = 0;
	
	public Traveling(String[] names) {
		this.families = new Family[names.length];
		for (int i = 0; i < families.length; ++i) {
			families[i] = new Family(names[i]);
		}
		int count = families.length;
		barrier = new CyclicBarrier(count, new Runnable() {
			
			@Override
			public void run() {
				restingCount ++;
				System.out.println("所有人到达休息站 " + restingCount + ", 休息一下，买点东西...");
			}
		});
	}
	
	public void start() {
		for (Family family : families) {
			new Thread(family).start();
		}
	}
	
	class Family implements Runnable {
		private String name;
		
		public Family(String name) {
			this.name = name;
		}
		
		@Override
		public void run() {
			while (restingCount < 5) {// 总共需要经过5个休息站才到达终点
				System.out.println(name + " 出发啦...");
				int runTime = new Random().nextInt(5);
				try {
					Thread.sleep(runTime * 1000);
				} catch (InterruptedException e) {
				}
				System.out.println(name + " 到达休息站...");
				try {
					barrier.await();
				} catch (InterruptedException e) {
				} catch (BrokenBarrierException e) {
				}
			}
		}
	}
	public static void main(String[] args) {
		Traveling traveling = new Traveling(new String[]{"A", "B", "C"});
		traveling.start();
	}
}
```

## Exchanger

Exchanger常用于`两个线程`之间安全的交换数据，在生产者-消费者线程模型中有可能会被用到。

{% asset_img exchanger.png exchanger %}

```java
public class ExchangerTest {
	public static void main(String[] args) {
		Exchanger<List<Integer>> exchanger = new Exchanger<>();
		new Consumer(exchanger).start();
		new Producer(exchanger).start();
	}
}

class Producer extends Thread {
	List<Integer> list = new ArrayList<>();
	Exchanger<List<Integer>> exchanger = null;

	public Producer(Exchanger<List<Integer>> exchanger) {
		super();
		this.exchanger = exchanger;
	}

	@Override
	public void run() {
		Random rand = new Random();
		for (int i = 0; i < 10; i++) {
			list.clear();
			// 生产数据
			list.add(rand.nextInt(10000));
			list.add(rand.nextInt(10000));
			list.add(rand.nextInt(10000));
			list.add(rand.nextInt(10000));
			list.add(rand.nextInt(10000));
			try {
				list = exchanger.exchange(list);
			} catch (InterruptedException e) {
				e.printStackTrace();
			}
		}
	}
}

class Consumer extends Thread {
	List<Integer> list = new ArrayList<>();
	Exchanger<List<Integer>> exchanger = null;

	public Consumer(Exchanger<List<Integer>> exchanger) {
		super();
		this.exchanger = exchanger;
	}

	@Override
	public void run() {
		for (int i = 0; i < 10; i++) {
			try {
				list = exchanger.exchange(list);
			} catch (InterruptedException e) {
				e.printStackTrace();
			}
			// 消费数据
			System.out.print(list.get(0) + ", ");
			System.out.print(list.get(1) + ", ");
			System.out.print(list.get(2) + ", ");
			System.out.print(list.get(3) + ", ");
			System.out.println(list.get(4) + ", ");
		}
	}
}
```

## FutureTask

在[并发场景下缓存的创建](http://yukai.space/2017/06/24/%E5%B9%B6%E5%8F%91%E5%9C%BA%E6%99%AF%E4%B8%8B%E7%BC%93%E5%AD%98%E7%9A%84%E5%88%9B%E5%BB%BA/)这篇文章中已经涉及到了FutureTask，FutureTask实现了Runnable和Future接口：

```java
public interface Future<V> {
    boolean cancel(boolean mayInterruptIfRunning);
    boolean isCancelled();
    boolean isDone();
    V get() throws InterruptedException, ExecutionException;
    V get(long timeout, TimeUnit unit) throws InterruptedException, ExecutionException, TimeoutException;
}
```

可以看出来，Future接口主要用来管理和查询一个任务的生命周期。FutureTask表示的任务是通过Callable来实现的，任务可能处于以下三种状态：

- 等待运行

- 正在运行

- 执行完毕，包括正常结束、由于取消而结束或由于异常而结束

Future.get方法的行为取决于任务的状态：如果任务已经完成，get方法会立即返回结果，否则get方法将一直阻塞直到任务进入完成状态，然后`返回结果`或`抛出异常`。FutureTask安全地将计算结果从计算结果的线程 传递到 获取这个结果的线程。

FutureTask可以表示一个异步的任务，用来执行一些时间较长的计算，这些计算可以在使用计算结果之前启动。

例子：实现一个Html页面渲染器。

最简单的方法是对HTML文档串行处理。遇到文本标签时，将其绘制到画布；遇到图片引用时，先通过网络获取他，然后绘制到画布。这种方法的缺点显而易见，那就是网络获取图片可能会比较耗时，用户需要等待较长的时间才能看到所有的文本。

在这里，我们找到了可以利用的并行性：将渲染过程分解为两个任务，一个是渲染所有的文本，另一个是下载所有的图片。绘制文本和下载图片可以同时进行。

```java
public class FutureRenderer {
    private final ExecutorService executor = Executors.newCachedThreadPool();
 
    void renderPage(CharSequence source) {
        final List<ImageInfo> imageInfos = scanForImageInfo(source);
        Callable<List<ImageData>> task =
                new Callable<List<ImageData>>() {
                    public List<ImageData> call() {
                        List<ImageData> result = new ArrayList<ImageData>();
                        for (ImageInfo imageInfo : imageInfos)
                            result.add(imageInfo.downloadImage());
                        return result;
                    }
                };
 
        Future<List<ImageData>> future = executor.submit(task);
        renderText(source);
 
        try {
            List<ImageData> imageData = future.get();
            for (ImageData data : imageData)
                renderImage(data);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            future.cancel(true);
        } catch (ExecutionException e) {
            throw launderThrowable(e.getCause());
        }
    }
}
```

可以看到，在渲染文本的任务开始之前，已经将下载图片的任务提交到线程池了。文本渲染完毕后，等待Future.get获取结果，然后渲染图片。这样，图片下载与文本渲染这两个任务就实现了并行执行。

## CompletionService

上个小结页面渲染的不足在于：用户需要等待所有的图片下载完毕，没有办法下载一张显示一张；如果渲染文本的速度远远大于下载图片的速度，那么程序并行后的性能与串行执行差别不大。

我们可以利用CompletionService将每张图片的下载创建成为并行的任务，减少下载所有图形需要的总时间；然后实现下载一张图片就立刻显示的功能。

CompletionService将Executor和BlockingQueue的功能结合在了一起，可以将Callable类型的任务提交给他执行，然后使用类似于队列的操作take或poll等方法获取已经完成的结果。

ExecutorCompletionService实现了CompletionService接口。ExecutorCompletionService的实现很简单，ExecutorCompletionService内部维护了一个BlockingQueue，用来保存计算结果。同时将任务包装为FutureTask的子类QueueingFuture：

```java
private class QueueingFuture extends FutureTask<Void> {
        QueueingFuture(RunnableFuture<V> task) {
            super(task, null);
            this.task = task;
        }
        protected void done() { completionQueue.add(task); }
        private final Future<V> task;
}
```

当任务执行完毕后，会调用done方法，将结果放入BlockingQueue当中，CompletionService的take和poll方法委托给BlockingQueue，这些方法会在得出结果之前阻塞。

{% asset_img ExecutorCompletionService.png ExecutorCompletionService %}

```java
public class Renderer {
    private final ExecutorService executor;

    Renderer(ExecutorService executor) {
        this.executor = executor;
    }

    void renderPage(CharSequence source) {
        final List<ImageInfo> info = scanForImageInfo(source);
        CompletionService<ImageData> completionService =
                new ExecutorCompletionService<ImageData>(executor);
        for (final ImageInfo imageInfo : info)
            completionService.submit(new Callable<ImageData>() {
                public ImageData call() {
                    return imageInfo.downloadImage();
                }
            });

        renderText(source);

        try {
            for (int t = 0, n = info.size(); t < n; t++) {
                Future<ImageData> f = completionService.take();
                ImageData imageData = f.get();
                renderImage(imageData);
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        } catch (ExecutionException e) {
            throw launderThrowable(e.getCause());
        }
    }
}
```

