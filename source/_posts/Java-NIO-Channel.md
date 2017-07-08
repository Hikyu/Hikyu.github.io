---
layout: post
title: Java-NIO-Channel
date: 2017-07-08 20:31:23
categories: 编程
tags: java
---
> Java NIO 学习第三篇--Channel

## Channel

通道(Channel)的作用有类似于流(Stream)，用于传输文件或者网络上的数据。

{% asset_img channel.png channel %}

<!-- more -->

上图中，箭头就相当于通道。一个不是很准确的例子：把通道想象成铁轨，缓冲区则是列车，铁轨的起始与终点则可以是socket，文件系统和我们的程序。假如当我们在代码中要写入数据到一份文件的时候，我们先把列车(缓冲区)装满，然后把列车(缓冲区)放置到铁轨上(通道)，数据就被传递到通道的另一端，文件系统。读取文件则相反，文件的内容被装到列车上，传递到程序这一侧，然后我们在代码中就可以读取这个列车中的内容(读取缓冲区)。

通道与传统的流还是有一些区别的：

- 通道可以同时支持读写(不是一定支持)，而流只支持单方向的操作，比如输入流只能读，输出流只能写。

- 通道可以支持异步的读或写，而流是同步的。

- 通道的读取或写入是通过缓冲区来进行的，而流则写入或返回字节。

## FileChannel

通道大致上可以分为两类：文件通道和socket通道。看一下文件通道：

文件通道可以由以下几个方法获得：

```java
RandomAccessFile file = new RandomAccessFile(new File(fileName), "rw");
FileChannel channel = file.getChannel();

FileInputStream stream = new FileInputStream(new File(fileName));
FileChannel channel = stream.getChannel();

FileOutputStream stream = new FileOutputStream(new File(fileName));
FileChannel channel = stream.getChannel();

FileChannel channel = FileChannel.open(Paths.get(fileName));
```

FileChannel 类结构：

{% asset_img filechannel.png Filechannel %}

可见FileChannel实现了读写接口、聚集、发散接口，以及文件锁功能。下面会提到。

看一下FileChannel的基本方法：

```java
public abstract class FileChannel extends AbstractChannel implements ByteChannel, GatheringByteChannel, ScatteringByteChannel {
    // 这里仅列出部分API
    public abstract long position()
    public abstract void position (long newPosition)
    public abstract int read (ByteBuffer dst)
    public abstract int read (ByteBuffer dst, long position)
    public abstract int write (ByteBuffer src)
    public abstract int write (ByteBuffer src, long position)
    public abstract long size()
    public abstract void truncate (long size)
    public abstract void force (boolean metaData)
}
```

在通道出现之前，底层的文件操作都是通过RandomAccessFile类的方法来实现的。FileChannel模拟同样的 I/O 服务，因此它们的API自然也是很相似的。

{% asset_img api.png Filechannel %}

上图是FileChannel、RandomAccessFile 和 [POSIX I/O system calls](http://wiki.jikexueyuan.com/project/linux-process/posix.html) 三者在方法上的对应关系。

POSIX接口我们在上一篇文章中也略有提及，他是一个系统级别的接口。下面看一下这几个接口，主要也是和上一篇文章文件描述符的介绍做一个呼应。

- position()和position(long newPosition)

position()返回当前文件的position值，position(long newPosition)将当前position设置为指定值。当字节被read()或write()方法传输时，文件position会自动更新。

position的含义与Buffer类中的position含义相似，都是指向下一个字节读取的位置。

回想一下介绍文件描述符的文章当中提到，当进程打开一个文件时，内核就会创建一个新的file对象，这个file对象有一个字段loff_t f_pos描述了文件的当前位置，position相当于loff_t f_pos的映射。由此可知，如果是使用同一文件描述符读取文件，那么他们的position是相互影响的：

```java
RandomAccessFile file = new RandomAccessFile(new File(fileName), "rw");
FileChannel channel = file.getChannel();
System.out.println("position: " + channel.position());
file.seek(30);
System.out.println("position: " + channel.position());
```

打印如下：

```
position: 0
position: 30
```

这是因为，file与channel使用了同一个文件描述符。如果新建另一个相同文件的通道，那么他们之间的position不会相互影响，因为使用了不同的文件描述符，指向不同的file对象。

- truncate(long size)

当需要减少一个文件的size时，truncate()方法会砍掉指定的size值之外的所有数据。这个方法要求通道具有写权限。

如果当前size大于给定size，超出给定size的所有字节都会被删除。如果提供的新size值大于或等于当前的文件size值，该文件不会被修改。

```java
RandomAccessFile file = new RandomAccessFile(new File(fileName), "rw");
FileChannel channel = file.getChannel();
System.out.println("size: " + channel.size());
System.out.println("position: " + channel.position());
System.out.println("trucate: 90");
channel.truncate(90);
System.out.println("size: " + channel.size());
System.out.println("position: " + channel.position());
```

打印如下：

```
size: 100
position: 0
trucate: 90
size: 90
position: 0
```

-  force (boolean metaData)

force()方法告诉通道强制将全部待定的修改都应用到磁盘的文件上。

如果文件位于一个本地文件系统，那么一旦force()方法返回，即可保证从通道被创建(或上次调用force())时起的对文件所做的全部修改已经被写入到磁盘。但是，如果文件位于一个远程的文件系统，如NFS上，那么不能保证待定修改一定能同步到永久存储器。

force()方法的布尔型参数表示在方法返回值前文件的元数据(metadata)是否也要被同步更新到磁盘。元数据指文件所有者、访问权限、最后一次修改时间等信息。
> Java NIO 学习第三篇--Channel

## Channel

通道(Channel)的作用有类似于流(Stream)，用于传输文件或者网络上的数据。

{% asset_img channel.png channel %}

上图中，箭头就相当于通道。一个不是很准确的例子：把通道想象成铁轨，缓冲区则是列车，铁轨的起始与终点则可以是socket，文件系统和我们的程序。假如当我们在代码中要写入数据到一份文件的时候，我们先把列车(缓冲区)装满，然后把列车(缓冲区)放置到铁轨上(通道)，数据就被传递到通道的另一端，文件系统。读取文件则相反，文件的内容被装到列车上，传递到程序这一侧，然后我们在代码中就可以读取这个列车中的内容(读取缓冲区)。

通道与传统的流还是有一些区别的：

- 通道可以同时支持读写(不是一定支持)，而流只支持单方向的操作，比如输入流只能读，输出流只能写。

- 通道可以支持异步的读或写，而流是同步的。

- 通道的读取或写入是通过缓冲区来进行的，而流则写入或返回字节。

## [FileChannel](https://docs.oracle.com/javase/7/docs/api/java/nio/channels/FileChannel.html)

通道大致上可以分为两类：文件通道和socket通道。看一下文件通道：

文件通道可以由以下几个方法获得：

```java
RandomAccessFile file = new RandomAccessFile(new File(fileName), "rw");
FileChannel channel = file.getChannel();

FileInputStream stream = new FileInputStream(new File(fileName));
FileChannel channel = stream.getChannel();

FileOutputStream stream = new FileOutputStream(new File(fileName));
FileChannel channel = stream.getChannel();

FileChannel channel = FileChannel.open(Paths.get(fileName));
```

FileChannel 类结构：

{% asset_img filechannel.png Filechannel %}

可见FileChannel实现了读写接口、聚集、发散接口，以及文件锁功能。下面会提到。

看一下FileChannel的基本方法：

```java
public abstract class FileChannel extends AbstractChannel implements ByteChannel, GatheringByteChannel, ScatteringByteChannel {
    // 这里仅列出部分API
    public abstract long position()
    public abstract void position (long newPosition)
    public abstract int read (ByteBuffer dst)
    public abstract int read (ByteBuffer dst, long position)
    public abstract int write (ByteBuffer src)
    public abstract int write (ByteBuffer src, long position)
    public abstract long size()
    public abstract void truncate (long size)
    public abstract void force (boolean metaData)
}
```

在通道出现之前，底层的文件操作都是通过RandomAccessFile类的方法来实现的。FileChannel模拟同样的 I/O 服务，因此它们的API自然也是很相似的。

{% asset_img api.png Filechannel %}

上图是FileChannel、RandomAccessFile 和 [POSIX I/O system calls](http://wiki.jikexueyuan.com/project/linux-process/posix.html) 三者在方法上的对应关系。

POSIX接口我们在上一篇文章中也略有提及，他是一个系统级别的接口。下面看一下这几个接口，主要也是和上一篇文章文件描述符的介绍做一个呼应。

- position()和position(long newPosition)

position()返回当前文件的position值，position(long newPosition)将当前position设置为指定值。当字节被read()或write()方法传输时，文件position会自动更新。

position的含义与Buffer类中的position含义相似，都是指向下一个字节读取的位置。

回想一下介绍文件描述符的文章当中提到，当进程打开一个文件时，内核就会创建一个新的file对象，这个file对象有一个字段loff_t f_pos描述了文件的当前位置，position相当于loff_t f_pos的映射。由此可知，如果是使用同一文件描述符读取文件，那么他们的position是相互影响的：

```java
RandomAccessFile file = new RandomAccessFile(new File(fileName), "rw");
FileChannel channel = file.getChannel();
System.out.println("position: " + channel.position());
file.seek(30);
System.out.println("position: " + channel.position());
```

打印如下：

```
position: 0
position: 30
```

这是因为，file与channel使用了同一个文件描述符。如果新建另一个相同文件的通道，那么他们之间的position不会相互影响，因为使用了不同的文件描述符，指向不同的file对象。

- truncate(long size)

当需要减少一个文件的size时，truncate()方法会砍掉指定的size值之外的所有数据。这个方法要求通道具有写权限。

如果当前size大于给定size，超出给定size的所有字节都会被删除。如果提供的新size值大于或等于当前的文件size值，该文件不会被修改。

```java
RandomAccessFile file = new RandomAccessFile(new File(fileName), "rw");
FileChannel channel = file.getChannel();
System.out.println("size: " + channel.size());
System.out.println("position: " + channel.position());
System.out.println("trucate: 90");
channel.truncate(90);
System.out.println("size: " + channel.size());
System.out.println("position: " + channel.position());
```

打印如下：

```
size: 100
position: 0
trucate: 90
size: 90
position: 0
```

-  force (boolean metaData)

force()方法告诉通道强制将全部待定的修改都应用到磁盘的文件上。

如果文件位于一个本地文件系统，那么一旦force()方法返回，即可保证从通道被创建(或上次调用force())时起的对文件所做的全部修改已经被写入到磁盘。但是，如果文件位于一个远程的文件系统，如NFS上，那么不能保证待定修改一定能同步到永久存储器。

force()方法的布尔型参数表示在方法返回值前文件的元数据(metadata)是否也要被同步更新到磁盘。元数据指文件所有者、访问权限、最后一次修改时间等信息。

FileChannel对象是线程安全的。如果有一个线程已经在执行会影响通道位置或文件大小的操作，那么其他尝试进行此类操作之一的线程必须等待。

## ReadableByteChannel、WritableByteChannel

通道可以是单向或者双向的。

```java
public interface ReadableByteChannel extends Channel{
    public int read (ByteBuffer dst) throws IOException;
}

public interface WritableByteChannel extends Channel{
    public int write (ByteBuffer src) throws IOException;
}

public interface ByteChannel extends ReadableByteChannel, WritableByteChannel{
}
```

{% asset_img bytechannel.png channel %}

实现ReadableByteChannel或WritableByteChannel其中之一的channel是单向的，只可以读或者写。如果一个类同时实现了这两种接口，那么他就具备了双向传输的能力。

java为我们提供了一个接口ByteChannel，同时继承了上述两个接口。所以，实现了ByteChannel接口的类可以读，也可以写。

在**FlieChannel**这一节中我们知道，文件在不同的方式下以不同的权限打开。比如`FileInputStream.getChannel()`方法返回一个FileChannel实例，FileChannel是个抽象类，间接的实现了ByteChannel接口，也就意味着提供了read和write接口。但是`FileInputStream.getChannel()`方法返回的FileChannel实际上是只读的，很简单，因为FileInputStream本身就是个输入流啊~在这样一个通道上调用write方法将抛出NonWritableChannelException异常，因为FileInputStream对象总是以read-only的权限打开通道。看一下代码：

FileInputStream.getChannel()

```java
public FileChannel getChannel() {
        synchronized (this) {
            if (channel == null) {
                // 第三个参数指定通道是否可读，第四个参数指定通道是否可写
                channel = FileChannelImpl.open(fd, path, true, false, this);

                /*
                 * Increment fd's use count. Invoking the channel's close()
                 * method will result in decrementing the use count set for
                 * the channel.
                 */
                fd.incrementAndGetUseCount();
            }
            return channel;
        }
}
```
同样的，`FileOutputStream.getChannel()`返回的通道是不可读的。

## InterruptibleChannel

InterruptibleChannel是一个标记接口，当被通道使用时可以标示该通道是可以中断的。

如果一个线程在一个通道上处于阻塞状态时被中断(另外一个线程调用该线程的interrupt()方法设置中断状态)，那么该通道将被关闭，该被阻塞线程也会产生一个ClosedByInterruptException异常。也就是说，假如一个线程的interrupt status被设置并且该线程试图访问一个通道，那么这个通道将立即被关闭，同时将抛出相同的ClosedByInterruptException异常。

在[java任务取消](http://yukai.space/2017/05/02/java%E4%BB%BB%E5%8A%A1%E5%8F%96%E6%B6%88/)中提到了，传统的java io 在读写时阻塞，是不会响应中断的。解决办法就是使用InterruptibleChannel，在线程被中断时可以关闭通道并返回。

可中断的通道也是可以异步关闭。实现InterruptibleChannel接口的通道可以在任何时候被关闭，即使有另一个被阻塞的线程在等待该通道上的一个I/O操作完成。当一个通道被关闭时，休眠在该通道上的所有线程都将被唤醒并接收到一个AsynchronousCloseException异常。接着通道就被关闭并将不再可用。

## Scatter/Gather

发散(Scatter)读取是将数据读入多个缓冲区(缓冲区数组)的操作。通道将数据依次填满到每个缓冲区当中。

汇聚(Gather)写出是将多个缓冲区(缓冲区数组)数据依次写入到通道的操作。

在FileChannel中提到的两个接口，提供了发散汇聚的功能：

```java
public interface ScatteringByteChannel extends ReadableByteChannel{
    public long read (ByteBuffer[] dsts) throws IOException;
    public long read (ByteBuffer[] dsts, int offset, int length) throws IOException;
}
public interface GatheringByteChannel extends WritableByteChannel{
    public long write(ByteBuffer[] srcs) throws IOException;
    public long write(ByteBuffer[] srcs, int offset, int length) throws IOException;
}
```

发散汇聚在某些场景下是很有用的，比如有一个消息协议格式分为head和body(比如http协议)，我们在接收这样一个消息的时候，通常的做法是把数据一下子都读过来，然后解析他。使用通道的发散功能会使这个过程变得简单：

```java
// head数据128字节
ByteBuffer header = ByteBuffer.allocate(128);
// body数据1024字节
ByteBuffer body   = ByteBuffer.allocate(1024);

ByteBuffer[] bufferArray = { header, body };

channel.read(bufferArray);
```

通道会依次填满这个buffer数组的每个buffer，如果一个buffer满了，就移动到下一个buffer。很自然的把head和body的数据分开了，但是要注意head和body的数据长度必须是固定的，因为channel只有填满一个buffer之后才会移动到下一个buffer。

## FileLock

摘抄一段oracle官网上FileLock的介绍吧，感觉说的挺清楚了。(因为懒，就不翻译了，读起来不是很费劲)

>A token representing a lock on a region of a file.
>A file-lock object is created each time a lock is acquired on a file via one of the lock or tryLock methods of the FileChannel class, or the lock or tryLock methods of the AsynchronousFileChannel class.
>
>A file-lock object is initially valid. It remains valid until the lock is released by invoking the release method, by closing the channel that was used to acquire it, or by the termination of the Java virtual machine, whichever comes first. The validity of a lock may be tested by invoking its >isValid method.
>
>A file lock is either exclusive or shared. A shared lock prevents other concurrently-running programs from acquiring an overlapping exclusive lock, but does allow them to acquire overlapping shared locks. An exclusive lock prevents other programs from acquiring an overlapping lock of either type. >Once it is released, a lock has no further effect on the locks that may be acquired by other programs.
>
>Whether a lock is exclusive or shared may be determined by invoking its isShared method. Some platforms do not support shared locks, in which case a request for a shared lock is automatically converted into a request for an exclusive lock.
>
>The locks held on a particular file by a single Java virtual machine do not overlap. The overlaps method may be used to test whether a candidate lock range overlaps an existing lock.
>
>A file-lock object records the file channel upon whose file the lock is held, the type and validity of the lock, and the position and size of the locked region. Only the validity of a lock is subject to change over time; all other aspects of a lock's state are immutable.
>
>File locks are held on behalf of the entire Java virtual machine. They are not suitable for controlling access to a file by multiple threads within the same virtual machine.
>
>File-lock objects are safe for use by multiple concurrent threads.
>
>**Platform dependencies**
>
>This file-locking API is intended to map directly to the native locking facility of the underlying operating system. Thus the locks held on a file should be visible to all programs that have access to the file, regardless of the language in which those programs are written.
>
>Whether or not a lock actually prevents another program from accessing the content of the locked region is system-dependent and therefore unspecified. The native file-locking facilities of some systems are merely advisory, meaning that programs must cooperatively observe a known locking protocol in >order to guarantee data integrity. On other systems native file locks are mandatory, meaning that if one program locks a region of a file then other programs are actually prevented from accessing that region in a way that would violate the lock. On yet other systems, whether native file locks are >advisory or mandatory is configurable on a per-file basis. To ensure consistent and correct behavior across platforms, it is strongly recommended that the locks provided by this API be used as if they were advisory locks.
>
>On some systems, acquiring a mandatory lock on a region of a file prevents that region from being mapped into memory, and vice versa. Programs that combine locking and mapping should be prepared for this combination to fail.
>
>On some systems, closing a channel releases all locks held by the Java virtual machine on the underlying file regardless of whether the locks were acquired via that channel or via another channel open on the same file. It is strongly recommended that, within a program, a unique channel be used to >acquire all locks on any given file.
>
>Some network filesystems permit file locking to be used with memory-mapped files only when the locked regions are page-aligned and a whole multiple of the underlying hardware's page size. Some network filesystems do not implement file locks on regions that extend past a certain position, often 230 >or 231. In general, great care should be taken when locking files that reside on network filesystems.

FileLock可以由以下几个方法获得：

```java
public abstract class FileChannel extends AbstractChannel implements ByteChannel, GatheringByteChannel, ScatteringByteChannel {
// 这里仅列出部分API
    public final FileLock lock()
    public abstract FileLock lock (long position, long size, boolean shared)
    public final FileLock tryLock()
    public abstract FileLock tryLock (long position, long size, boolean shared)
}
```

其中，lock是阻塞的，tryLock是非阻塞的。position和size决定了锁定的区域，shared决定了文件锁是共享的还是独占的。

不带参数的lock方法等价于`fileChannel.lock(0L, Long.MAX_VALUE, false)`，tryLock亦然。

lock方法是响应中断的，当线程被中断时方法抛出FileLockInterruptionException异常。如果通道被另外一个线程关闭，该暂停线程将恢复并产生一个 AsynchronousCloseException异常。

上面还提到了，文件锁是针对于进程级别的。如果有多个进程同时对一个文件锁定，并且其中有独占锁的话，这些锁的申请会被串行化。

如果是同一个进程(Jvm实例)的多个线程同时请求同一个文件区域的lock的话，会抛出OverlappingFileLockException异常。

## Channel-to-Channel

FileChannel提供了接口，用于通道和通道之间的直接传输。

```java
public abstract class FileChannel extends AbstractChannel implements ByteChannel, GatheringByteChannel, ScatteringByteChannel {
    // 这里仅列出部分API
    public abstract long transferTo (long position, long count, WritableByteChannel target)
    public abstract long transferFrom (ReadableByteChannel src, long position, long count)
}
```

只有FileChannel类有这两个方法，因此Channel-to-Channel传输中通道之一必须是FileChannel。不能在socket通道之间直接传输数据，不过socket通道实现WritableByteChannel和ReadableByteChannel接口，因此文件的内容可以用transferTo()方法传输给一个socket通道，或者也可以用transferFrom()方法将数据从一个socket通道直接读取到一个文件中。

直接的通道传输不会更新与某个FileChannel关联的position值。请求的数据传输将从position参数指定的位置开始，传输的字节数不超过count参数的值。实际传输的字节数会由方法返回。

直接通道传输的另一端如果是socket通道并且处于非阻塞模式的话，数据的传输将具有不确定性。比如，transferFrom从socket通道读取数据，如果socket中的数据尚未准备好，那么方法将直接返回。

例子：

```java
RandomAccessFile fromFile = new RandomAccessFile("fromFile.txt", "rw");
FileChannel      fromChannel = fromFile.getChannel();

RandomAccessFile toFile = new RandomAccessFile("toFile.txt", "rw");
FileChannel      toChannel = toFile.getChannel();

long position = 0;
long count    = fromChannel.size();

toChannel.transferFrom(fromChannel, position, count);


RandomAccessFile fromFile = new RandomAccessFile("fromFile.txt", "rw");
FileChannel      fromChannel = fromFile.getChannel();

RandomAccessFile toFile = new RandomAccessFile("toFile.txt", "rw");
FileChannel      toChannel = toFile.getChannel();

long position = 0;
long count    = fromChannel.size();

fromChannel.transferTo(position, count, toChannel);
```

## 参考

[Java nio入门教程详解](http://www.365mini.com/page/java-nio-course-17.htm)

## ReadableByteChannel、WritableByteChannel

通道可以是单向或者双向的。

```java
public interface ReadableByteChannel extends Channel{
    public int read (ByteBuffer dst) throws IOException;
}

public interface WritableByteChannel extends Channel{
    public int write (ByteBuffer src) throws IOException;
}

public interface ByteChannel extends ReadableByteChannel, WritableByteChannel{
}
```

{% asset_img bytechannel.png channel %}

实现ReadableByteChannel或WritableByteChannel其中之一的channel是单向的，只可以读或者写。如果一个类同时实现了这两种接口，那么他就具备了双向传输的能力。

java为我们提供了一个接口ByteChannel，同时继承了上述两个接口。所以，实现了ByteChannel接口的类可以读，也可以写。

在**FlieChannel**这一节中我们知道，文件在不同的方式下以不同的权限打开。比如`FileInputStream.getChannel()`方法返回一个FileChannel实例，FileChannel是个抽象类，间接的实现了ByteChannel接口，也就意味着提供了read和write接口。但是`FileInputStream.getChannel()`方法返回的FileChannel实际上是只读的，很简单，因为FileInputStream本身就是个输入流啊~在这样一个通道上调用write方法将抛出NonWritableChannelException异常，因为FileInputStream对象总是以read-only的权限打开通道。看一下代码：

FileInputStream.getChannel()

```java
public FileChannel getChannel() {
        synchronized (this) {
            if (channel == null) {
                // 第三个参数指定通道是否可读，第四个参数指定通道是否可写
                channel = FileChannelImpl.open(fd, path, true, false, this);

                /*
                 * Increment fd's use count. Invoking the channel's close()
                 * method will result in decrementing the use count set for
                 * the channel.
                 */
                fd.incrementAndGetUseCount();
            }
            return channel;
        }
}
```
同样的，`FileOutputStream.getChannel()`返回的通道是不可读的。

## InterruptibleChannel

InterruptibleChannel是一个标记接口，当被通道使用时可以标示该通道是可以中断的。

如果一个线程在一个通道上处于阻塞状态时被中断(另外一个线程调用该线程的interrupt()方法设置中断状态)，那么该通道将被关闭，该被阻塞线程也会产生一个ClosedByInterruptException异常。也就是说，假如一个线程的interrupt status被设置并且该线程试图访问一个通道，那么这个通道将立即被关闭，同时将抛出相同的ClosedByInterruptException异常。

在[java任务取消](http://yukai.space/2017/05/02/java%E4%BB%BB%E5%8A%A1%E5%8F%96%E6%B6%88/)中提到了，传统的java io 在读写时阻塞，是不会响应中断的。解决办法就是使用InterruptibleChannel，在线程被中断时可以关闭通道并返回。

可中断的通道也是可以异步关闭。实现InterruptibleChannel接口的通道可以在任何时候被关闭，即使有另一个被阻塞的线程在等待该通道上的一个I/O操作完成。当一个通道被关闭时，休眠在该通道上的所有线程都将被唤醒并接收到一个AsynchronousCloseException异常。接着通道就被关闭并将不再可用。

## Scatter/Gather

发散(Scatter)读取是将数据读入多个缓冲区(缓冲区数组)的操作。通道将数据依次填满到每个缓冲区当中。

汇聚(Gather)写出是将多个缓冲区(缓冲区数组)数据依次写入到通道的操作。

在FileChannel中提到的两个接口，提供了发散汇聚的功能：

```java
public interface ScatteringByteChannel extends ReadableByteChannel{
    public long read (ByteBuffer[] dsts) throws IOException;
    public long read (ByteBuffer[] dsts, int offset, int length) throws IOException;
}
public interface GatheringByteChannel extends WritableByteChannel{
    public long write(ByteBuffer[] srcs) throws IOException;
    public long write(ByteBuffer[] srcs, int offset, int length) throws IOException;
}
```

发散汇聚在某些场景下是很有用的，比如有一个消息协议格式分为head和body(比如http协议)，我们在接收这样一个消息的时候，通常的做法是把数据一下子都读过来，然后解析他。使用通道的发散功能会使这个过程变得简单：

```java
// head数据128字节
ByteBuffer header = ByteBuffer.allocate(128);
// body数据1024字节
ByteBuffer body   = ByteBuffer.allocate(1024);

ByteBuffer[] bufferArray = { header, body };

channel.read(bufferArray);
```

通道会依次填满这个buffer数组的每个buffer，如果一个buffer满了，就移动到下一个buffer。很自然的把head和body的数据分开了，但是要注意head和body的数据长度必须是固定的，因为channel只有填满一个buffer之后才会移动到下一个buffer。

## FileLock



## Channel-to-Channel

FileChannel提供了接口，用于通道和通道之间的直接传输。

```java
public abstract class FileChannel extends AbstractChannel implements ByteChannel, GatheringByteChannel, ScatteringByteChannel {
    // 这里仅列出部分API
    public abstract long transferTo (long position, long count, WritableByteChannel target)
    public abstract long transferFrom (ReadableByteChannel src, long position, long count)
}
```

只有FileChannel类有这两个方法，因此Channel-to-Channel传输中通道之一必须是FileChannel。不能在socket通道之间直接传输数据，不过socket通道实现WritableByteChannel和ReadableByteChannel接口，因此文件的内容可以用transferTo()方法传输给一个socket通道，或者也可以用transferFrom()方法将数据从一个socket通道直接读取到一个文件中。

直接的通道传输不会更新与某个FileChannel关联的position值。请求的数据传输将从position参数指定的位置开始，传输的字节数不超过count参数的值。实际传输的字节数会由方法返回。

直接通道传输的另一端如果是socket通道并且处于非阻塞模式的话，数据的传输将具有不确定性。比如，transferFrom从socket通道读取数据，如果socket中的数据尚未准备好，那么方法将直接返回。

例子：

```java
RandomAccessFile fromFile = new RandomAccessFile("fromFile.txt", "rw");
FileChannel      fromChannel = fromFile.getChannel();

RandomAccessFile toFile = new RandomAccessFile("toFile.txt", "rw");
FileChannel      toChannel = toFile.getChannel();

long position = 0;
long count    = fromChannel.size();

toChannel.transferFrom(fromChannel, position, count);


RandomAccessFile fromFile = new RandomAccessFile("fromFile.txt", "rw");
FileChannel      fromChannel = fromFile.getChannel();

RandomAccessFile toFile = new RandomAccessFile("toFile.txt", "rw");
FileChannel      toChannel = toFile.getChannel();

long position = 0;
long count    = fromChannel.size();

fromChannel.transferTo(position, count, toChannel);
```

## 参考

[Java nio入门教程详解](http://www.365mini.com/page/java-nio-course-17.htm)
