---
layout: post
title: 读懂Java_Thread_Dump
date: 2017-09-23 08:30:09
categories: 技术
tags: java
---

> 前段时间有现场发现死锁的问题，查看发回来的jstack dump文件，发现虽然大致看懂，但是不是很透彻。从网上看了一些介绍jstack的文章，大部分复制粘贴，讲解的也不够透彻，现在有时间来自己整理一下jstack的知识，记录一下~

## 获取Dump

java 提供了查看**当前用户启动的java进程**的工具 JPS：`jps`

```java
5008 org.eclipse.equinox.launcher_1.3.201.v20161025-1711.jar
10712 Main
888 App
15804 Jps
34300 SynchronizedTest
```
<!-- more -->

根据对应的java进程，查看其Thread Dump：`jstack 34300`

```java
2017-09-22 14:57:46
Full thread dump Java HotSpot(TM) 64-Bit Server VM (25.91-b15 mixed mode):

"DestroyJavaVM" #12 prio=5 os_prio=0 tid=0x0000000001c7e000 nid=0x7ca4 waiting on condition [0x0000000000000000]
   java.lang.Thread.State: RUNNABLE

"Synchronized_second" #11 prio=5 os_prio=0 tid=0x000000005887c000 nid=0x7430 waiting for monitor entry [0x00000000593af000]
   java.lang.Thread.State: BLOCKED (on object monitor)
        at jstack.SynchronizedTest$1.run(SynchronizedTest.java:8)
        - waiting to lock <0x00000000d5ad8fe8> (a java.lang.Class for jstack.SynchronizedTest)
        at java.lang.Thread.run(Thread.java:745)

"Synchronized_first" #10 prio=5 os_prio=0 tid=0x000000005887b000 nid=0x5bdc runnable [0x000000005969f000]
   java.lang.Thread.State: RUNNABLE
        at jstack.SynchronizedTest$1.run(SynchronizedTest.java:8)
        - locked <0x00000000d5ad8fe8> (a java.lang.Class for jstack.SynchronizedTest)
        at java.lang.Thread.run(Thread.java:745)

"Service Thread" #9 daemon prio=9 os_prio=0 tid=0x0000000058812800 nid=0x7a6c runnable [0x0000000000000000]
   java.lang.Thread.State: RUNNABLE

"C1 CompilerThread2" #8 daemon prio=9 os_prio=2 tid=0x000000005879a000 nid=0xc07c waiting on condition [0x0000000000000000]
   java.lang.Thread.State: RUNNABLE

"C2 CompilerThread1" #7 daemon prio=9 os_prio=2 tid=0x0000000058797000 nid=0x7e5c waiting on condition [0x0000000000000000]
   java.lang.Thread.State: RUNNABLE

"C2 CompilerThread0" #6 daemon prio=9 os_prio=2 tid=0x000000005877e000 nid=0x9474 waiting on condition [0x0000000000000000]
   java.lang.Thread.State: RUNNABLE

"Attach Listener" #5 daemon prio=5 os_prio=2 tid=0x000000005876b800 nid=0x861c waiting on condition [0x0000000000000000]
   java.lang.Thread.State: RUNNABLE

"Signal Dispatcher" #4 daemon prio=9 os_prio=2 tid=0x000000005751a000 nid=0x1ff4 runnable [0x0000000000000000]
   java.lang.Thread.State: RUNNABLE

"Finalizer" #3 daemon prio=8 os_prio=1 tid=0x00000000574fb000 nid=0x2e84 in Object.wait() [0x000000005875f000]
   java.lang.Thread.State: WAITING (on object monitor)
        at java.lang.Object.wait(Native Method)
        - waiting on <0x00000000d5988ee0> (a java.lang.ref.ReferenceQueue$Lock)
        at java.lang.ref.ReferenceQueue.remove(ReferenceQueue.java:143)
        - locked <0x00000000d5988ee0> (a java.lang.ref.ReferenceQueue$Lock)
        at java.lang.ref.ReferenceQueue.remove(ReferenceQueue.java:164)
        at java.lang.ref.Finalizer$FinalizerThread.run(Finalizer.java:209)

"Reference Handler" #2 daemon prio=10 os_prio=2 tid=0x00000000574b2000 nid=0x9dc8 in Object.wait() [0x000000005840f000]
   java.lang.Thread.State: WAITING (on object monitor)
        at java.lang.Object.wait(Native Method)
        - waiting on <0x00000000d5986b50> (a java.lang.ref.Reference$Lock)
        at java.lang.Object.wait(Object.java:502)
        at java.lang.ref.Reference.tryHandlePending(Reference.java:191)
        - locked <0x00000000d5986b50> (a java.lang.ref.Reference$Lock)
        at java.lang.ref.Reference$ReferenceHandler.run(Reference.java:153)

"VM Thread" os_prio=2 tid=0x00000000574aa800 nid=0x3b08 runnable

"GC task thread#0 (ParallelGC)" os_prio=0 tid=0x000000000233c800 nid=0xcba4 runnable

"GC task thread#1 (ParallelGC)" os_prio=0 tid=0x000000000233e000 nid=0x51f4 runnable

"GC task thread#2 (ParallelGC)" os_prio=0 tid=0x000000000233f800 nid=0x2474 runnable

"GC task thread#3 (ParallelGC)" os_prio=0 tid=0x0000000002341000 nid=0x6048 runnable

"VM Periodic Task Thread" os_prio=2 tid=0x000000005886d000 nid=0x902c waiting on condition

JNI global references: 16
```

注意，无论是使用jps命令或者jstack，要**确保执行该命令的用户和启动java进程的用户为同一用户**。

## 格式分析

观察上面的Dump文件，列出了进程12964所启动的所有线程的某一时刻的状态，我们要关注的是与业务逻辑相关的线程，比如：

```java
"Synchronized_second" #11 prio=5 os_prio=0 tid=0x000000005887c000 nid=0x7430 waiting for monitor entry [0x00000000593af000]
   java.lang.Thread.State: BLOCKED (on object monitor)
        at jstack.SynchronizedTest$1.run(SynchronizedTest.java:8)
        - waiting to lock <0x00000000d5ad8fe8> (a java.lang.Class for jstack.SynchronizedTest)
        at java.lang.Thread.run(Thread.java:745)
```

Synchronized_second：是线程的名字，可以在实例化Thread对象的时候指定。如果没有显示指定，java会按照"Thread-n"的方式命名线程，n为从0开始的序号。如果使用了jdk提供的线程池，线程的命名方式为"pool-m-thread-n"

prio=5：线程优先级

os_prio：系统线程优先级

tid：线程ID，在jvm中的唯一标识

nid：本地线程ID，线程在操作系统中的标识

waiting for monitor entry：线程当前的动作，代表线程当前的执行情况

java.lang.Thread.State：线程当前状态，由Thread.State定义:

```java
public enum State {
        /**
         * Thread state for a thread which has not yet started.
         */
        NEW,

        /**
         * Thread state for a runnable thread.  A thread in the runnable
         * state is executing in the Java virtual machine but it may
         * be waiting for other resources from the operating system
         * such as processor.
         */
        RUNNABLE,

        /**
         * Thread state for a thread blocked waiting for a monitor lock.
         * A thread in the blocked state is waiting for a monitor lock
         * to enter a synchronized block/method or
         * reenter a synchronized block/method after calling
         * {@link Object#wait() Object.wait}.
         */
        BLOCKED,

        /**
         * Thread state for a waiting thread.
         * A thread is in the waiting state due to calling one of the
         * following methods:
         * <ul>
         *   <li>{@link Object#wait() Object.wait} with no timeout</li>
         *   <li>{@link #join() Thread.join} with no timeout</li>
         *   <li>{@link LockSupport#park() LockSupport.park}</li>
         * </ul>
         *
         * <p>A thread in the waiting state is waiting for another thread to
         * perform a particular action.
         *
         * For example, a thread that has called <tt>Object.wait()</tt>
         * on an object is waiting for another thread to call
         * <tt>Object.notify()</tt> or <tt>Object.notifyAll()</tt> on
         * that object. A thread that has called <tt>Thread.join()</tt>
         * is waiting for a specified thread to terminate.
         */
        WAITING,

        /**
         * Thread state for a waiting thread with a specified waiting time.
         * A thread is in the timed waiting state due to calling one of
         * the following methods with a specified positive waiting time:
         * <ul>
         *   <li>{@link #sleep Thread.sleep}</li>
         *   <li>{@link Object#wait(long) Object.wait} with timeout</li>
         *   <li>{@link #join(long) Thread.join} with timeout</li>
         *   <li>{@link LockSupport#parkNanos LockSupport.parkNanos}</li>
         *   <li>{@link LockSupport#parkUntil LockSupport.parkUntil}</li>
         * </ul>
         */
        TIMED_WAITING,

        /**
         * Thread state for a terminated thread.
         * The thread has completed execution.
         */
        TERMINATED;
}
```

上面的这些状态反映了线程在虚拟机中的执行状态(而不是操作系统中的状态信息)，同一时刻，一个线程只能有一种状态：

| State         | 描述                                                                                                                                               |
|---------------|--------------------------------------------------------------------------------------------------------------------------------------------------|
| NEW           | 线程未启动，即创建了Thread实例，调用start方法之前，线程处于NEW状态                                                                                                         |
| RUNNABLE      | 表示线程具备运行的所有条件，正在运行或在执行队列中等待内核调用。如果线程一直处于这个状态(对比不同时刻的Dump文件)，表示该线程一直在执行或者一直处于等待队列中                                                                |
| BLOCKED       | 线程正在等待获取内置锁，进入Synchronized关键字修饰的代码块或方法                                                                                                           |
| WAITING       | 线程正在等待某个事件的发生，可能是由于调用了下列方法：Thread.join、Object.wait、LockSupport.park                                                                              |
| TIMED_WAITING | 线程正在等待某个事件的发生，如果达到限定的时间，线程也能恢复运行，可能是由于调用了下列方法：Thread.sleep(long)、Object.wait(long)、Thread.join(long)、LockSupport.parkNanos、LockSupport.parkUntil |
| TERMINATED    | 线程执行完毕，只剩Thread对象存在                                                                                                                              |

waiting to lock：线程调用修饰, 即线程执行的额外信息

## Entry Set & Wait Set

注意到上面的Thread Dump中出现了`waiting for monitor entry`，这代表什么意思呢？还需要了解java的Synchronized机制：

Synchronized使用了内置锁Monitor，每一个java对象都有且只有一个Monitor

```java
Object lock = new Object();
public void run() {
    synchronized (lock) {
       //do somthing
    }
}
```

使用Synchronized修饰代码称为临界区，jvm使用lock对象的Monitor实现多线程对这段代码的互斥访问：

{% asset_img Synchronized.png synchronized %}

Monitor对象有两个队列，WaitSet和EntrySet

- 线程通过synchronized要求获取对象的锁。首先进入EntrySet队列，如果此刻没有其他线程持有Monitor，直接得到Monitor，进入临界区，如果此时Monitor已经被其他线程持有，则在EntrySet队列中等待

- 持有Monitor的线程将Monitor释放(退出临界区或调用lock.wait)，EntrySet队列中的线程开始竞争Monitor，得到Monitor的线程可以进入临界区，其他线程继续等待

- 持有Monitor的线程调用lock.wait方法，该线程立即释放Monitor，并且被放入WaitSet

- 持有Monitor的线程lock.notify方法，jvm从WaitSet中选择一个线程放入EntrySet，如果调用了lock.notifyAll方法，则WaitSet中的所有线程都被放入EntrySet

## Dump 实例

下面实际看一下Thread.sleep、Synchronized、ReentrantLock、Thread.join等情况下的Dump文件内容：

- Thread.sleep

```java
public class SleepTest {
	public static void main(String[] args) {
		Runnable runnable = new Runnable() {
			
			public void run() {
				try {
					Thread.sleep(200000);
				} catch (InterruptedException e) {
					e.printStackTrace();
				}
			}
		};
		
		Thread thread = new Thread(runnable, "yukai");
		thread.setDaemon(false);
		thread.start();
	}
}
```

```
"yukai" #10 prio=5 os_prio=0 tid=0x0000000058e1c000 nid=0x27dc waiting on condition [0x000000005950e000]
		   java.lang.Thread.State: TIMED_WAITING (sleeping)
		        at java.lang.Thread.sleep(Native Method)
		        at jstack.SleepTest$1.run(SleepTest.java:9)
		        at java.lang.Thread.run(Thread.java:745)
```

- Thread.join

```java
public class JoinTest {
	public static void main(String[] args) {
		Thread thread = new Thread() {
            public void run() {
                try {
                    Thread.sleep(30000);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        };
        thread.start();
        try {
			thread.join();
		} catch (InterruptedException e) {
			e.printStackTrace();
		}
	}
}
```

```
"main" #1 prio=5 os_prio=0 tid=0x0000000001b9e000 nid=0xb2c8 in Object.wait() [0x00000000027de000]
		   java.lang.Thread.State: WAITING (on object monitor)
		        at java.lang.Object.wait(Native Method)
		        - waiting on <0x00000000d5adb268> (a jstack.JoinTest$1)
		        at java.lang.Thread.join(Thread.java:1245)
		        - locked <0x00000000d5adb268> (a jstack.JoinTest$1)
		        at java.lang.Thread.join(Thread.java:1319)
		        at jstack.JoinTest.main(JoinTest.java:16)
```

- Synchronized

```java
public class SynchronizedTest {
	public static void main(String[] args) {
		Runnable runnable = new Runnable() {
            public void run() {
                synchronized (SynchronizedTest.class) {
                    while (true) {
						
					}
                }
            }
        };
        
        new Thread(runnable, "Synchronized_first").start();
        try {
			Thread.sleep(1000);
		} catch (InterruptedException e) {
			e.printStackTrace();
		}
        
        new Thread(runnable, "Synchronized_second").start();
	}
}
```

```
"Synchronized_first" #10 prio=5 os_prio=0 tid=0x0000000058c09000 nid=0x3f0c runnable [0x00000000598ff000]
        		   java.lang.Thread.State: RUNNABLE
        		        at jstack.SynchronizedTest$1.run(SynchronizedTest.java:8)
        		        - locked <0x00000000d5ad8fe8> (a java.lang.Class for jstack.SynchronizedTest)
        		        at java.lang.Thread.run(Thread.java:745)

"Synchronized_second" #11 prio=5 os_prio=0 tid=0x0000000058c0a000 nid=0xab20 waiting for monitor entry [0x0000000059a4f000]
        		   java.lang.Thread.State: BLOCKED (on object monitor)
        		        at jstack.SynchronizedTest$1.run(SynchronizedTest.java:8)
        		        - waiting to lock <0x00000000d5ad8fe8> (a java.lang.Class for jstack.SynchronizedTest)
        		        at java.lang.Thread.run(Thread.java:745)                        
```

- Object.wait

```java
public class SynchronizedConditionTest {
	public static void main(String[] args) {
		
        new Thread(SynchronizedConditionTest.wait, "Synchronized_Condition").start();

        new Thread(SynchronizedConditionTest.timeWait, "Synchronized_Condition_time").start();
	}

	public static Runnable wait = new Runnable() {
		Object lock = new Object();
        public void run() {
            synchronized (lock) {
                try {
                	lock.wait();
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        }
    };

    public static Runnable timeWait = new Runnable() {
		Object lock = new Object();
        public void run() {
            synchronized (lock) {
                try {
                	lock.wait(20000);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        }
    };
}
```

```
"Synchronized_Condition" #10 prio=5 os_prio=0 tid=0x000000005893e800 nid=0x3468 in Object.wait() [0x000000005995f000]
			   java.lang.Thread.State: WAITING (on object monitor)
			        at java.lang.Object.wait(Native Method)
			        - waiting on <0x00000000d5adb980> (a java.lang.Object)
			        at java.lang.Object.wait(Object.java:502)
			        at jstack.SynchronizedConditionTest$1.run(SynchronizedConditionTest.java:16)
			        - locked <0x00000000d5adb980> (a java.lang.Object)
			        at java.lang.Thread.run(Thread.java:745)

"Synchronized_Condition_time" #11 prio=5 os_prio=0 tid=0x000000005893f000 nid=0x4f84 in Object.wait() [0x000000005905f000]
    		   java.lang.Thread.State: TIMED_WAITING (on object monitor)
    		        at java.lang.Object.wait(Native Method)
    		        - waiting on <0x00000000d5add2b8> (a java.lang.Object)
    		        at jstack.SynchronizedConditionTest$2.run(SynchronizedConditionTest.java:29)
    		        - locked <0x00000000d5add2b8> (a java.lang.Object)
    		        at java.lang.Thread.run(Thread.java:745)  
                    
```

- ReentrantLock

```java
public class ReentrantLockTest {
	private static Lock lock = new ReentrantLock();
	public static void main(String[] args) {
		Runnable runnable = new Runnable() {

			public void run() {
				try {
					lock.lock();
					while (true) {
						
					}
				} finally {
					lock.unlock();
				}
			}
		};
		
		new Thread(runnable, "ReentrantLock_first").start();
		try {
			Thread.sleep(1000);
		} catch (InterruptedException e) {
			e.printStackTrace();
		}
	
		new Thread(runnable, "ReentrantLock_second").start();
	}

}

```

```
"ReentrantLock_first" #10 prio=5 os_prio=0 tid=0x0000000058a53000 nid=0xb9a8 runnable [0x000000005988f000]
				   java.lang.Thread.State: RUNNABLE
				        at jstack.ReentrantLockTest$1.run(ReentrantLockTest.java:14)
				        at java.lang.Thread.run(Thread.java:745)

"ReentrantLock_second" #11 prio=5 os_prio=0 tid=0x0000000058a53800 nid=0x6440 waiting on condition [0x000000005998e000]
				   java.lang.Thread.State: WAITING (parking)
				        at sun.misc.Unsafe.park(Native Method)
				        - parking to wait for  <0x00000000d5adb7d8> (a java.util.concurrent.locks.ReentrantLock$NonfairSync)
				        at java.util.concurrent.locks.LockSupport.park(LockSupport.java:175)
				        at java.util.concurrent.locks.AbstractQueuedSynchronizer.parkAndCheckInterrupt(AbstractQueuedSynchronizer.java:836)
				        at java.util.concurrent.locks.AbstractQueuedSynchronizer.acquireQueued(AbstractQueuedSynchronizer.java:870)
				        at java.util.concurrent.locks.AbstractQueuedSynchronizer.acquire(AbstractQueuedSynchronizer.java:1199)
				        at java.util.concurrent.locks.ReentrantLock$NonfairSync.lock(ReentrantLock.java:209)
				        at java.util.concurrent.locks.ReentrantLock.lock(ReentrantLock.java:285)
				        at jstack.ReentrantLockTest$1.run(ReentrantLockTest.java:13)
				        at java.lang.Thread.run(Thread.java:745)
```

- Condition

```java
public class ReentrantLockConditionTest {

	public static void main(String[] args) {

		new Thread(ReentrantLockConditionTest.timeWait, "ReentrantLock_Condition_Time").start();

		new Thread(ReentrantLockConditionTest.wait, "ReentrantLock_Condition").start();
	}

	public static Runnable wait = new Runnable() {
		private Lock lock = new ReentrantLock();
		private Condition condition = lock.newCondition();

		public void run() {
			try {
				// 加锁, 进入临界区
				lock.lock();
				condition.await();
			} catch (InterruptedException e) {
				e.printStackTrace();
			} finally {
				// 解锁, 退出临界区
				lock.unlock();
			}
		}
	};
	
	public static Runnable timeWait = new Runnable() {
		private Lock lock = new ReentrantLock();
		private Condition condition = lock.newCondition();

		public void run() {
			try {
				// 加锁, 进入临界区
				lock.lock();
				condition.await(20000, TimeUnit.MILLISECONDS);
			} catch (InterruptedException e) {
				e.printStackTrace();
			} finally {
				// 解锁, 退出临界区
				lock.unlock();
			}
		}
	};

}
```

```
"ReentrantLock_Condition" #11 prio=5 os_prio=0 tid=0x000000005899a000 nid=0x47ac waiting on condition [0x000000005999f000]
			   java.lang.Thread.State: WAITING (parking)
			        at sun.misc.Unsafe.park(Native Method)
			        - parking to wait for  <0x00000000d5add5a0> (a java.util.concurrent.locks.AbstractQueuedSynchronizer$ConditionObject)
			        at java.util.concurrent.locks.LockSupport.park(LockSupport.java:175)
			        at java.util.concurrent.locks.AbstractQueuedSynchronizer$ConditionObject.await(AbstractQueuedSynchronizer.java:2039)
			        at jstack.ReentrantLockConditionTest$1.run(ReentrantLockConditionTest.java:25)
			        at java.lang.Thread.run(Thread.java:745)

"ReentrantLock_Condition_Time" #10 prio=5 os_prio=0 tid=0x0000000058999000 nid=0x2744 waiting on condition [0x000000005935f000]
			   java.lang.Thread.State: TIMED_WAITING (parking)
			        at sun.misc.Unsafe.park(Native Method)
			        - parking to wait for  <0x00000000d5adf550> (a java.util.concurrent.locks.AbstractQueuedSynchronizer$ConditionObject)
			        at java.util.concurrent.locks.LockSupport.parkNanos(LockSupport.java:215)
			        at java.util.concurrent.locks.AbstractQueuedSynchronizer$ConditionObject.await(AbstractQueuedSynchronizer.java:2163)
			        at jstack.ReentrantLockConditionTest$2.run(ReentrantLockConditionTest.java:43)
			        at java.lang.Thread.run(Thread.java:745)
```

- socket

```java
public class Server {
	public static final int PORT = 12345;//监听的端口号     
    private static int NUMBER = 0;
    public static void main(String[] args) {    
        System.out.println("服务器启动...\n");    
        Server server = new Server();    
        server.init();    
    }    
    
    public void init() {    
        try {    
            ServerSocket serverSocket = new ServerSocket(PORT);    
            while (true) {    
                // 一旦有堵塞, 则表示服务器与客户端获得了连接    
                Socket client = serverSocket.accept();    
                // 处理这次连接    
                new HandlerThread(client);    
            }    
        } catch (Exception e) {    
            System.out.println("服务器异常: " + e.getMessage());    
        }    
    }    
    
    private class HandlerThread implements Runnable {    
        private Socket socket;    
        public HandlerThread(Socket client) {    
            socket = client;    
            new Thread(this, "server" + NUMBER).start();    
        }    
    
        public void run() {    
            try {    
                // 读取客户端数据    
                DataInputStream input = new DataInputStream(socket.getInputStream());  
                String clientInputStr = input.readUTF();//这里要注意和客户端输出流的写方法对应,否则会抛 EOFException  
                // 处理客户端数据    
                System.out.println("客户端发过来的内容:" + clientInputStr);    
    
                // 向客户端回复信息    
                DataOutputStream out = new DataOutputStream(socket.getOutputStream());    
                System.out.print("请输入:\t");    
                // 发送键盘输入的一行    
                String s = new BufferedReader(new InputStreamReader(System.in)).readLine();    
                out.writeUTF(s);    
                  
                out.close();    
                input.close();    
            } catch (Exception e) {    
                System.out.println("服务器 run 异常: " + e.getMessage());    
            } finally {    
                if (socket != null) {    
                    try {    
                        socket.close();    
                    } catch (Exception e) {    
                        socket = null;    
                        System.out.println("服务端 finally 异常:" + e.getMessage());    
                    }    
                }    
            }   
        }    
    }    
}

public class Client {
	public static final String IP_ADDR = "localhost";// 服务器地址
	public static final int PORT = 12345;// 服务器端口号

	public static void main(String[] args) {
		System.out.println("客户端启动...");
		System.out.println("当接收到服务器端字符为 \"OK\" 的时候, 客户端将终止\n");
		while (true) {
			Socket socket = null;
			try {
				// 创建一个流套接字并将其连接到指定主机上的指定端口号
				socket = new Socket(IP_ADDR, PORT);

				// 读取服务器端数据
				DataInputStream input = new DataInputStream(socket.getInputStream());
				// 向服务器端发送数据
				DataOutputStream out = new DataOutputStream(socket.getOutputStream());
				System.out.print("请输入: \t");
				String str = new BufferedReader(new InputStreamReader(System.in)).readLine();
				out.writeUTF(str);

				String ret = input.readUTF();
				System.out.println("服务器端返回过来的是: " + ret);
				// 如接收到 "OK" 则断开连接
				if ("OK".equals(ret)) {
					System.out.println("客户端将关闭连接");
					Thread.sleep(500);
					break;
				}

				out.close();
				input.close();
			} catch (Exception e) {
				System.out.println("客户端异常:" + e.getMessage());
			} finally {
				if (socket != null) {
					try {
						socket.close();
					} catch (IOException e) {
						socket = null;
						System.out.println("客户端 finally 异常:" + e.getMessage());
					}
				}
			}
		}
	}
}
```

Server 端的dump内容

```
"main" #1 prio=5 os_prio=0 tid=0x000000000049e000 nid=0x6eec runnable [0x00000000027fe000]
		   java.lang.Thread.State: RUNNABLE
		        at java.net.DualStackPlainSocketImpl.accept0(Native Method)
		        at java.net.DualStackPlainSocketImpl.socketAccept(DualStackPlainSocketImpl.java:131)
		        at java.net.AbstractPlainSocketImpl.accept(AbstractPlainSocketImpl.java:409)
		        at java.net.PlainSocketImpl.accept(PlainSocketImpl.java:199)
		        - locked <0x00000000d5adc508> (a java.net.SocksSocketImpl)
		        at java.net.ServerSocket.implAccept(ServerSocket.java:545)
		        at java.net.ServerSocket.accept(ServerSocket.java:513)
		        at jstack.socket.Server.init(Server.java:24)
		        at jstack.socket.Server.main(Server.java:16)

"server0" #10 prio=5 os_prio=0 tid=0x0000000058a64000 nid=0x317c runnable [0x0000000059b3e000]
    		   java.lang.Thread.State: RUNNABLE
    		        at java.net.SocketInputStream.socketRead0(Native Method)
    		        at java.net.SocketInputStream.socketRead(SocketInputStream.java:116)
    		        at java.net.SocketInputStream.read(SocketInputStream.java:170)
    		        at java.net.SocketInputStream.read(SocketInputStream.java:141)
    		        at java.net.SocketInputStream.read(SocketInputStream.java:223)
    		        at java.io.DataInputStream.readUnsignedShort(DataInputStream.java:337)
    		        at java.io.DataInputStream.readUTF(DataInputStream.java:589)
    		        at java.io.DataInputStream.readUTF(DataInputStream.java:564)
    		        at jstack.socket.Server$HandlerThread.run(Server.java:44)
    		        at java.lang.Thread.run(Thread.java:745)
```

注意到，虽然线程阻塞在SocketInputStream.socketRead或者ServerSocket.accept方法上，但是dump文件中线程的状态依然为RUNNABLE。因为RUNNABLE表示的是线程在虚拟机中的状态信息，在操作系统中该线程有可能因为其他原因被阻塞。

有了上面各种情况下Dump文件的参照，再拿到真实环境下的Dump文件对照分析也应该容易一些了。

最后上一张Thread的状态转换图：

{% asset_img states.png java thread states %}
