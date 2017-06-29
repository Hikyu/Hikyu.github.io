---
layout: post
title: 木耳炒山药
date: 2017-06-28 20:36:36
categories: 编程
tags: java
---
> 最近在看java nio方面的知识，打算写几篇博客总结一下，就从Buffer开始吧

## Buffer

java NIO库是在jdk1.4中引入的，NIO与IO之间的第一个区别在于，IO是面向流的，而NIO是面向块的。

所谓的面向流是指：系统一次一个字节的处理数据，一个输入流产生一个字节的数据，一个输出流消费一个字节的数据。

所谓的面向块是指：以块的形式处理数据。每一个操作都在一步中产生或者消费一个数据块。

按块的方式处理数据要比按流的方式处理数据快，因为按块的方式读取或写入数据所执行的系统调用要远少于一次一个字节的方式，类似于BufferedInputStream的方式。

上面所说的块，在NIO中就是Buffer对象。

一个 Buffer(缓冲区) 实质上是一个容器对象，它包含一些要写入或者刚读出的数据。在 NIO 库中，所有数据都是用缓冲区处理的。在读取数据时，它是直接读到缓冲区中的。在写入数据时，它是写入到缓冲区中的。缓冲区实质上是一个数组。通常它是一个字节数组，但是也可以使用其他种类的数组。但是一个缓冲区不 仅仅 是一个数组。缓冲区提供了对数据的结构化访问，而且还可以跟踪系统的读/写进程。

举例来说，ByteBuffer实质上是对byte数组进行了封装，其内部是一个byte数组，ByteBuffer对象提供了一些实用的API供我们去操作这个数组，完成一些读取或写入的功能。我们所要学习的，就是理解在调用这些API的时候，Buffer处理数组的方式。

除了boolean类型之外，java为每种基本类型都封装了对应的Buffer对象。

{% asset_img buffer.png Buffer %}

<!-- more -->

## 状态变量

Buffer使用四个值指定了缓冲区在某个时刻的状态：

**容量(Capacity)**：缓冲区能够容纳的数据元素的最大数量

实际上，这个值指定了底层数组的大小。这一值在缓冲区创建时被设定，并且永远不能被改变。

**位置(Position)**：下一个要被读或写的元素的索引

position 变量跟踪已经写了多少数据。更准确地说，它指定了下一个字节将放到数组的哪一个元素中。比如，从通道中读三个字节到缓冲区中，那么缓冲区的 position 将会设置为3，指向数组中第四个元素。

初始的position值为0。

**边界(Limit)**：缓冲区的第一个不能被读或写的元素。或者说，缓冲区中现存元素的计数。

在写模式下，Buffer的limit表示你最多能往Buffer里写多少数据。

当切换Buffer到读模式时， limit表示你最多能读到多少数据。因此，当切换Buffer到读模式时，limit会被设置成写模式下的position值。

**标记(Mark)**：一个备忘位置。

调用 mark()来设定 mark = postion。调用 reset()设定 position = mark。

初始的mark值为-1。

上面四个属性遵循以下的关系：

`0 <= mark <= position <= limit <= capacity`

## API

{% asset_img buffer_api.png Buffer %}

- **创建**

在了解这些api之前，首先需要知道如何创建一个Buffer对象：

在上一个小节中提到的7种缓冲区类没有一种是可以直接实例化的，他们都是抽象类，但都包含了静态工厂方法创建相应的实例。以ByteBuffer为例：(对于其他六中缓冲区类也适用)

`ByteBuffer buffer = ByteBuffer.allocate(1024);`

allocate方法分配了一个具有指定大小底层数组的缓冲区对象，这个大小也就是上面提到的Capacity。

我们也可以使用已经存在的数组来作为缓冲区对象的底层数组：

```java
byte array[] = new byte[1024];
ByteBuffer buffer = ByteBuffer.wrap(array);
```

此时，buffer对象的底层数组指向了array，这意味着直接修改array数组也会使buffer对象读取的数据产生变化。

```java
byte[] bs = new byte[10];
ByteBuffer buffer = ByteBuffer.wrap(bs);
System.out.println(buffer.toString());
```

打印如下：

```
java.nio.HeapByteBuffer[pos=0 lim=10 cap=10]
```

可见，新初始化的Buffer实例中，position = 0，limit=capacity=10

- **存取**

注意到Buffer类中并没有提供get或者put函数。实际上每一个Buffer对象都有这两个函数，但它们所采用的参数类型，以及它们返回的数据类型，对每个子类来说都是唯一的，所以它们不能在顶层Buffer类中被抽象地声明。这些存取方法被定义在Buffer类的子类当中，我们一ByteBuffer为例：

```java
public abstract byte get();
public abstract byte get (int index);
public abstract ByteBuffer put (byte b);
public abstract ByteBuffer put (int index, byte b);
```

ByteBuffer实际上还提供了 `get(byte[] dst, int offset, int length)`这样的接口，其内部实现也是循环调用了get()方法。

get和put可以是相对的或者是绝对的。

相对方案是不带有索引参数的函数。当相对函数被调用时，位置在返回时前进一。

绝对存取不会影响缓冲区的位置属性(Position、Limit、Capacity、Mark)。

```java
buffer.put((byte)'h').put((byte)'e').put((byte)'l').put((byte)'l').put((byte)'o');
print(buffer, bs);
buffer.put(0, (byte)'y').put((byte)'y');
print(buffer, bs);

//观察Buffer底层存储情况
public static void print(Buffer buffer, byte[] bs) {
		System.out.println(buffer.toString());
		for (int i = 0; i < bs.length; i++) {
			if (bs[i] != 0) {
				char c = (char)bs[i];
				System.out.print(c);
			} else {
				System.out.print("$");
			}
		}
		System.out.println("");
	}
```
打印如下：

```
java.nio.HeapByteBuffer[pos=5 lim=10 cap=10]
hello$$$$$
java.nio.HeapByteBuffer[pos=6 lim=10 cap=10]
yelloy$$$$
```
可以看到，存入5个字节之后，position增加为5，limit与capacity不变。
调用buffer.put(0, (byte)'y')，将bs[0]的数据改写为(byte)'y'，position并没有改变。

- **Buffer.flip()**

我们想要将刚刚写入的数据读出的话应该怎么做？应该将position设为0：buffer.position(0)，就可以从正确的位置开始获取数据。但是它是怎样知道何时到达我们所插入数据末端的呢？这就是边界属性被引入的目的。边界属性指明了缓冲区有效内容的末端。我们需要将limit设置为当前位置：buffer.limit(buffer.position())。

`buffer.limit(buffer.position()).position(0);`

Buffer已经提供了一个方法封装了这些操作：

```java
public final Buffer flip() {
        limit = position;
        position = 0;
        mark = -1;
        return this;
}
```
```java
buffer.flip();
print(buffer, bs);
```

打印如下：

```
java.nio.HeapByteBuffer[pos=0 lim=6 cap=10]
yelloy$$$$
```

调用buffer.flip()后，limit设置为当前position值，position重置为0.

- **Buffer.rewind()**

紧接着上面的程序：

```java
System.out.println((char)buffer.get());
System.out.println((char)buffer.get(3));
print(buffer, bs);
		
buffer.rewind();
print(buffer, bs);
```

打印如下：

```
y
l
java.nio.HeapByteBuffer[pos=1 lim=6 cap=10]
yelloy$$$$
java.nio.HeapByteBuffer[pos=0 lim=6 cap=10]
yelloy$$$$
```

可以看到，rewind()方法与filp()相似，但是不影响limit，他只是将position设为0，这样就可以从新读取已经读过的数据了。

```java
public final Buffer rewind() {
        position = 0;
        mark = -1;
        return this;
}
```

- **Buffer.mark()、Buffer.reset()**

```java
public final Buffer mark() {
        mark = position;
        return this;
}

public final Buffer reset() {
        int m = mark;
        if (m < 0)
            throw new InvalidMarkException();
        position = m;
        return this;
}
```
Buffer.mark(),使缓冲区能够记住一个位置并在之后将其返回。

缓冲区的标记在mark()函数被调用之前是未定义的，调用时标记被设为当前位置的值。reset()函数将位置设为当前的标记值。如果标记值未定义，调用reset()将导致InvalidMarkException异常。

```java
buffer.position(2);
buffer.mark();
print(buffer, bs);
buffer.position(4);
print(buffer, bs);
buffer.reset();
print(buffer, bs);
```

打印如下：

```
java.nio.HeapByteBuffer[pos=2 lim=6 cap=10]
yelloy$$$$
java.nio.HeapByteBuffer[pos=4 lim=6 cap=10]
yelloy$$$$
java.nio.HeapByteBuffer[pos=2 lim=6 cap=10]
yelloy$$$$
```

- **Buffer.remaining()、Buffer.hasRemaining()**

remaining()函数将返回从当前位置到上界还剩余的元素数目。

hasRemaining()会返回是否已经达到缓冲区的边界。

```java
public final int remaining() {
        return limit - position;
}

public final boolean hasRemaining() {
        return position < limit;
}
```
有两种方法读取缓冲区的所有剩余数据：

```java
// 第一种
for (int i = 0; buffer.hasRemaining(), i++) {
    myByteArray [i] = buffer.get();
}

// 第二种
int count = buffer.remaining();
for (int i = 0; i < count, i++) {
    myByteArray [i] = buffer.get();
}
```

- **Buffer.clear()**

clear()函数将缓冲区重置为空状态。它并不改变缓冲区中的任何数据元素，而是仅仅将上界设为容量的值，并把位置设回 0。

```java
public final Buffer clear() {
        position = 0;
        limit = capacity;
        mark = -1;
        return this;
}
```

- **ByteBuffer.compact()**

compact()方法并不是Buffer接口中定义的，而是属于ByteBuffer。

如果Buffer中仍有未读的数据，且后续还需要这些数据，但是此时想要先写些数据，那么使用compact()方法。

compact()方法将所有未读的数据拷贝到Buffer起始处。然后将position设到最后一个未读元素正后面。limit属性依然像clear()方法一样，设置成capacity。现在Buffer准备好写数据了，但是不会覆盖未读的数据。

```java
print(buffer, bs);
System.out.println(buffer.remaining());
buffer.compact();
print(buffer, bs);
```
打印如下：

```
java.nio.HeapByteBuffer[pos=2 lim=6 cap=10]
yelloy$$$$
4
java.nio.HeapByteBuffer[pos=4 lim=10 cap=10]
lloyoy$$$$
```

- **ByteBuffer.equals()、ByteBuffer.compareTo()**

可以使用equals()和compareTo()方法两个Buffer。

下面提到的剩余元素是从 position到limit之间的元素。

**equals()**

当满足下列条件时，表示两个Buffer相等：

有相同的类型（byte、char、int等）。

Buffer中剩余的byte、char等的个数相等。

Buffer中所有剩余的byte、char等都相同。

在每个缓冲区中应被get()函数返回的剩余数据元素序列必须一致。

equals只是比较Buffer的一部分，不是每一个在它里面的元素都比较。实际上，它只比较Buffer中的剩余元素。

**compareTo()**

compareTo()方法比较两个Buffer的剩余元素(byte、char等)， 如果满足下列条件，则认为一个Buffer“小于”另一个Buffer：

第一个不相等的元素小于另一个Buffer中对应的元素 。

所有元素都相等，但第一个Buffer比另一个先耗尽(第一个Buffer的元素个数比另一个少)。

## 只读缓冲区

可以使用asReadOnlyBuffer()函数来生成一个只读的缓冲区视图。

这个新的缓冲区不允许使用put()，并且其isReadOnly()函数将会返回true。对这一只读缓冲区的put()函数的调用尝试会导致抛出ReadOnlyBufferException异常。

两个缓冲区共享数据元素，拥有同样的容量，但每个缓冲区拥有各自的位置，上界和标记属性。对一个缓冲区内的数据元素所做的改变会反映在另外一个缓冲区上。

## 复制缓冲区

duplicate()函数创建了一个与原始缓冲区相似的新缓冲区。两个缓冲区共享数据元素，拥有同样的容量，但每个缓冲区拥有各自的位置，上界和标记属性。对一个缓冲区内的数据元素所做的改变会反映在另外一个缓冲区上。这一副本缓冲区具有与原始缓冲区同样的数据视图。如果原始的缓冲区为只读，或者为直接缓冲区，新的缓冲区将继承这些属性。

复制一个缓冲区会创建一个新的Buffer对象，但并不复制数据。原始缓冲区和副本都会操作同样的数据元素。

## 直接缓冲区

直接ByteBuffer是通过调用ByteBuffer.allocateDirect(int capacity)函数来创建的。

什么是直接缓冲区(DirectByteBuffer)呢？直接缓冲区意味着所分配的这段内存是堆外内存，而我们通过ByteBuffer.allocate(int capacity)或者ByteBuffer.wrap(byte[] array)分配的内存是堆内存，其返回的实例为HeapByteBuffer，HeapByteBuffer中持有一个byte数组，这个数组所占有的内存是堆内内存。

[Netty之Java堆外内存扫盲贴](http://calvin1978.blogcn.com/articles/directbytebuffer.html)了解java堆外内存。

sun.nio.ch.FileChannelImpl.read(ByteBuffer dst)

{% asset_img 1.png sun.nio.ch.FileChannelImpl.read %}

sun.nio.ch.IOUtil.read(FileDescriptor fd, ByteBuffer dst, long position,NativeDispatcher nd, Object lock)

{% asset_img 2.png sun.nio.ch.IOUtil.read %}

观察上面两段代码发现，我们通过一个文件通道去填充一个ByteBuffer时，先执行`sun.nio.ch.FileChannelImpl.read(ByteBuffer dst)`方法，其中调用了`sun.nio.ch.IOUtil.read(FileDescriptor fd, ByteBuffer dst, long position,NativeDispatcher nd, Object lock)`方法，观察这个方法，发现其中会做一个判断：如果是直接缓冲区(DirectBuffer)，直接调用`readIntoNativeBuffer(fd, dst, position, nd, lock)`并返回；如果是非直接缓冲区(HeapByteBuffer)，先获取一个直接缓冲区，然后使用该直接缓冲区作为参数调用`readIntoNativeBuffer(fd, dst, position, nd, lock)`，然后将填充完毕的DirectBuffer的内容复制到HeapByteBuffer当中，然后返回。

直接缓冲区的内存分配调用了sun.misc.Unsafe.allocateMemory(size),返回了内存基地址，实际上就是malloc。

看一下[java doc](https://docs.oracle.com/javase/7/docs/api/java/nio/ByteBuffer.html)对DirectBuffer的说明：

> A byte buffer is either direct or non-direct. Given a direct byte buffer, the Java virtual machine will make a best effort to perform native I/O operations directly upon it. That is, it will attempt to avoid copying the buffer's content to (or from) an intermediate buffer before (or after) each invocation of one of the underlying operating system's native I/O operations.

给定一个直接字节缓冲区，Java 虚拟机将尽最大努力直接对它执行本机 I/O 操作。也就是说，它会在每一次调用底层操作系统的本机 I/O 操作之前(或之后)，尝试避免将缓冲区的内容拷贝到一个中间缓冲区中(或者从一个中间缓冲区中拷贝数据)。

结合上面的代码，就可以理解这段话的含义。

那么，为什么需要直接缓冲区，也就是堆外内存来执行IO呢？

以读操作为例，数据从底层硬件读到内核缓冲区之后，操作系统会从内核空间复制数据到用户空间，此时的用户进程空间就是jvm，这意味着 I/O 操作的目标内存区域必须是连续的字节序列。在 Java 中，数组是对象，在 JVM 中，字节数组可能不会在内存中连续存储。因此，这个连续的字节序列就是直接缓冲区中分配的内存空间。需要直接缓冲区来当一个中间人，完成数据的写入或者读取。

其实，在传统BIO中，也是这么做的，同样需要一个堆外内存来充当这个中间人：比如FileInputStream.read(byte b[], int off, int len):

FileInputStream.read(byte b[], int off, int len)调用了readBytes(byte b[], int off, int len)方法，这个方法是一个本地方法：

```java
JNIEXPORT jint JNICALL  
Java_java_io_FileInputStream_readBytes(JNIEnv *env, jobject this,  
        jbyteArray bytes, jint off, jint len) {//除了前两个参数，后三个就是readBytes方法传递进来的，字节数组、起始位置、长度三个参数  
return readBytes(env, this, bytes, off, len, fis_fd);  
}  
```

```java
jint
readBytes(JNIEnv *env, jobject this, jbyteArray bytes,
          jint off, jint len, jfieldID fid)
{
    jint nread;
    char stackBuf[BUF_SIZE];
    char *buf = NULL;
    FD fd;
 
    if (IS_NULL(bytes)) {
        JNU_ThrowNullPointerException(env, NULL);
        return -1;
    }
 
    if (outOfBounds(env, off, len, bytes)) {
        JNU_ThrowByName(env, "java/lang/IndexOutOfBoundsException", NULL);
        return -1;
    }
 
    if (len == 0) {
        return 0;
    } else if (len > BUF_SIZE) {
        buf = malloc(len);// buf的分配
        if (buf == NULL) {
            JNU_ThrowOutOfMemoryError(env, NULL);
            return 0;
        }
    } else {
        buf = stackBuf;
    }
 
    fd = GET_FD(this, fid);
    if (fd == -1) {
        JNU_ThrowIOException(env, "Stream Closed");
        nread = -1;
    } else {
        nread = IO_Read(fd, buf, len);// buf是使用malloc分配的直接缓冲区，也就是堆外内存
        if (nread > 0) {
            (*env)->SetByteArrayRegion(env, bytes, off, nread, (jbyte *)buf);// 将直接缓冲区的内容copy到bytes数组中
        } else if (nread == JVM_IO_ERR) {
            JNU_ThrowIOExceptionWithLastError(env, "Read error");
        } else if (nread == JVM_IO_INTR) {
            JNU_ThrowByName(env, "java/io/InterruptedIOException", NULL);
        } else { /* EOF */
            nread = -1;
        }
    }
 
    if (buf != stackBuf) {
        free(buf);
    }
    return nread;
}
```
可以看到，这个方法其实最关键的就是IO_Read这个宏定义的处理，而IO_Read其实只是代表了一个方法名称叫handleRead，我们去看一下handleRead的源码。

```java
JNIEXPORT  
size_t  
handleRead(jlong fd, void *buf, jint len)  
{  
    DWORD read = 0;  
    BOOL result = 0;  
    HANDLE h = (HANDLE)fd;  
    if (h == INVALID_HANDLE_VALUE) {
        return -1;  
    }  
    result = ReadFile(h,          
                      buf,       
                      len,       
                      &read,      
                      NULL);     
    if (result == 0) {
        int error = GetLastError();  
        if (error == ERROR_BROKEN_PIPE) {  
            return 0; 
        }  
        return -1;  
    }  
    return read;  
}  
```

通过上面的代码可以发现，传统的BIO也是把操作系统返回的数据放到直接缓冲区当中，然后在copy回我们传入的byte数组当中。

所有的缓冲区都提供了一个叫做isDirect()的boolean函数，来测试特定缓冲区是否为直接缓冲区。

> A direct byte buffer may be created by invoking the allocateDirect factory method of this class. The buffers returned by this method typically have somewhat higher allocation and deallocation costs than non-direct buffers. The contents of direct buffers may reside outside of the normal garbage-collected heap, and so their impact upon the memory footprint of an application might not be obvious. It is therefore recommended that direct buffers be allocated primarily for large, long-lived buffers that are subject to the underlying system's native I/O operations. In general it is best to allocate direct buffers only when they yield a measureable gain in program performance.

直接缓冲区虽然避免了复制内存带来的消耗，但直接缓冲区使用的内存是通过调用本地操作系统方面的代码分配的，绕过了标准 JVM 堆栈。建立和销毁直接缓冲区会明显比具有堆栈的缓冲区更加破费，并且可能带来不易察觉的内存泄漏，或oom问题。所以，如果对于性能要求不是很严格，一般情况下，使用非直接缓冲区就足够了。

## 缓冲区分片

slice() 方法根据现有的缓冲区创建一种 子缓冲区 。也就是说，它创建一个新的缓冲区，新缓冲区与原来的缓冲区的一部分共享数据。

现在我们对这个缓冲区 分片 ，以创建一个包含槽 3 到槽 6 的子缓冲区。在某种意义上，子缓冲区就像原来的缓冲区中的一个 窗口。

窗口的起始和结束位置通过设置 position 和 limit 值来指定，然后调用 Buffer 的 slice() 方法：

```java
print(buffer, bs);
buffer.position( 3 ).limit( 7 );
ByteBuffer slice = buffer.slice();
print(slice, slice.array());
```

打印如下：

```
java.nio.HeapByteBuffer[pos=4 lim=10 cap=10]
lloyoy$$$$
java.nio.HeapByteBuffer[pos=0 lim=4 cap=4]
lloyoy$$$$
```

slice 是缓冲区的 子缓冲区 。不过， slice 和 buffer 共享同一个底层数据数组。

## 类型视图缓冲区

我们知道，Buffer可以作为通道执行IO的源头或者目标，但是通道只接受ByteBuffer类型的参数。比如read(ByteBuffer dst)。

我们在进行IO操作时，可能会使用各种ByteBuffer类去读取文件内容，接收来自网络连接的数据使用各种ByteBuffer类去读取文件内容，接收来自网络连接的数据等。一旦数据到达了您的 ByteBuffer，我们需要对他进行一些操作。ByteBuffer类允许创建视图来将byte型缓冲区字节数据映射为其它的原始数据类型。例如，asLongBuffer()函数创建一个将八个字节型数据当成一个 long 型数据来存取的视图缓冲区。

```java
public abstract class ByteBuffer extends Buffer implements Comparable{
    // 这里仅列出部分API
    public abstract CharBuffer asCharBuffer();
    public abstract ShortBuffer asShortBuffer();
    public abstract IntBuffer asIntBuffer();
    public abstract LongBuffer asLongBuffer();
    public abstract FloatBuffer asFloatBuffer();
    public abstract DoubleBuffer asDoubleBuffer();
}
```

```java
buffer.clear();
buffer.order(ByteOrder.BIG_ENDIAN);//指定字节序
buffer.put (0, (byte)0);
buffer.put (1, (byte)'H');
buffer.put (2, (byte)0);
buffer.put (3, (byte)'i');
buffer.put (4, (byte)0);
buffer.put (5, (byte)'!');
buffer.put (6, (byte)0);

CharBuffer charBuffer = buffer.asCharBuffer();
System.out.println("pos=" + charBuffer.position() + " limit=" + charBuffer.limit() + " cap=" + charBuffer.capacity());;
print(charBuffer, bs);
```

打印如下：

```
pos=0 limit=5 cap=5
Hi!   
$H$i$!$$$$
```

新的缓冲区的容量是字节缓冲区中存在的元素数量除以视图类型中组成一个数据类型的字节数。视图缓冲区的第一个元素从创建它的ByteBuffer对象的位置开始(positon()函数的返回值)。

{% asset_img 3.png 类型长度 %}

## 测试代码

前面提到的测试代码汇总：

```java
import java.nio.Buffer;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.CharBuffer;

public class Test {
	public static void main(String[] args) {
		byte[] bs = new byte[10];
		ByteBuffer buffer = ByteBuffer.wrap(bs);
		System.out.println(buffer.toString());
		// put
		buffer.put((byte)'h').put((byte)'e').put((byte)'l').put((byte)'l').put((byte)'o');
		print(buffer, bs);
		buffer.put(0, (byte)'y').put((byte)'y');
		print(buffer, bs);
		
		//flip
		buffer.flip();
		print(buffer, bs);
		
		// rewind
		System.out.println((char)buffer.get());
		System.out.println((char)buffer.get(3));
		print(buffer, bs);
		
		buffer.rewind();
		print(buffer, bs);
		
		// mark reset
		buffer.position(2);
		buffer.mark();
		print(buffer, bs);
		buffer.position(4);
		print(buffer, bs);
		buffer.reset();
		print(buffer, bs);
		
		// compact
		System.out.println(buffer.remaining());
		buffer.compact();
		print(buffer, bs);
		
		// slice
		buffer.position( 3 ).limit( 7 );
		ByteBuffer slice = buffer.slice();
		print(slice, slice.array());
		
		// asCharBuffer
		buffer.clear();
		buffer.order(ByteOrder.BIG_ENDIAN);
		buffer.put (0, (byte)0);
        buffer.put (1, (byte)'H');
        buffer.put (2, (byte)0);
        buffer.put (3, (byte)'i');
        buffer.put (4, (byte)0);
        buffer.put (5, (byte)'!');
        buffer.put (6, (byte)0);
		CharBuffer charBuffer = buffer.asCharBuffer();
		System.out.println("pos=" + charBuffer.position() + " limit=" + charBuffer.limit() + " cap=" + charBuffer.capacity());;
		print(charBuffer, bs);
	}
	
	public static void print(Buffer buffer, byte[] bs) {
		System.out.println(buffer.toString());
		for (int i = 0; i < bs.length; i++) {
			if (bs[i] != 0) {
				char c = (char)bs[i];
				System.out.print(c);
			} else {
				System.out.print("$");
			}
		}
		System.out.println("");
	}
}
```

## 参考

[Why is Traditional Java I/O Uninterruptable?](https://www.ksmpartners.com/2013/07/why-is-traditional-java-io-uninterruptable/)

[JNI探秘-----FileInputStream的read方法详解](http://blog.csdn.net/zuoxiaolong8810/article/details/9974525)

[NIO 入门](https://www.ibm.com/developerworks/cn/education/java/j-nio/j-nio.html)

[Java NIO Buffer](http://tutorials.jenkov.com/java-nio/buffers.html)