layout: post
title: java I/O总结
date: 2017-03-19 17:09:19
categories: 编程
tags: java
---
> 在平时维护JDBC驱动的过程中，经常会接触到IO相关的代码。总结梳理一下java中的IO~

## IO

IO，即Input和Output。流可以理解为字节序列的流动，可以从其中读入字节序列的对象称为输入流，可以向其中写入字节序列的对象称为输出流。
这些字节序列的来源和目的地可以是文件，网络，或者内存等。

java中的IO基本可以分为两大类：

1.基于字节操作的 I/O 接口：InputStream 和 OutputStream

2.基于字符操作的 I/O 接口：Writer 和 Reader

不管是磁盘还是网络传输，最小的存储单元都是字节，而不是字符，所以 I/O 操作的都是字节而不是字符。但是我们的程序通常操作的数据都是以字符的形式存在，比如处理网页中的内容或者磁盘文件中的文本。
为了操作方便，提供了直接操作字符的接口。操作字符的接口底层还是基于字节的，只不过封装了一些例如编码和解码等操作。

下面是java.io包中的内容：[Package java.io](https://docs.oracle.com/javase/7/docs/api/java/io/package-summary.html)

{% asset_img io.png java.io %}

java.io 类图:

{% asset_img javaio.png java.io %}

## 字节接口

{% asset_img stream.png 字节流 %}

上图给出了InputStream和OutputStream的继承关系(不仅仅是java.io包)

理解InputStream家族，首先要理解[装饰者模式](http://www.cnblogs.com/god_bless_you/archive/2010/06/10/1755212.html)：

---
{% asset_img decorator.jpg 装饰者模式 %}

```
Component：

定义一个对象接口，可以给这些对象动态地添加职责。

public interface Component
{
	void operation();
}
 

Concrete Component：

定义一个对象，可以给这个对象添加一些职责。动作的具体实施者。

public class ConcreteComponent implements Component
{
	public void operation()
	{
		// Write your code here
	}
}
 

Decorator：

维持一个指向Component对象的引用，并定义一个与 Component接口一致的接口。

public class Decorator implements Component
{
	public Decorator(Component component)
	{
		this.component = component;
	}
	
	public void operation()
	{
		component.operation();
	}
	
	private Component component;
}
 

Concrete Decorator：

在Concrete Component的行为之前或之后，加上自己的行为，以“贴上”附加的职责。

public class ConcreteDecorator extends Decorator
{
	public void operation()
	{
		//addBehavior也可以在前面
		
		super.operation();
		
		addBehavior();
	}
	
	private void addBehavior()
	{
		//your code
	}
}
```
使用装饰模式来实现扩展比继承更加灵活，它以对客户透明的方式动态地给一个对象附加更多的责任。
装饰模式可以在不需要创造更多子类的情况下，将对象的功能加以扩展。

---

InputStream族与装饰者模式的对应关系：

Component: InputStream

ConcreteComponent: InputStream除FilterINputStream以外的直接子类，如FileInputStream，他们提供了最终的读取字节功能

Decorator: FilterInputStream

ConcreteDecorator: FilterINputStream的直接子类，如BufferedInputStream，他们为读取字节附加了一些功能

首先看一下InputStream为我们提供了哪些操作：

```
int	available()
返回不阻塞情况下可用的字节数
void close()
关闭这个输入流
void mark(int readlimit)
在流的当前位置打一个标记
boolean	markSupported()
如果这个流支持打标记，则返回true
abstract int read()
从数据中读取一个字节，并返回该字节
int	read(byte[] b)
读入一个字节数组，并返回读入的字节数
int	read(byte[] b, int off, int len)
读入一个字节数组，并返回读入的字节数。b:数据读入的数组  off:第一个读入的字节在b中的偏移量  len:读入字节的最大数量
void reset()
返回最后的标记，随后对read的调用将重新读入这些字节
long skip(long n)
在输入流中跳过n个字节，返回实际跳过数
```

其中：
abstract int read()
int	read(byte[] b)
int	read(byte[] b, int off, int len)

这三个方法提供了基本的读入功能。read方法在执行时将被阻塞，直到字节确实被读入。InputStream的子类实现或重写了这些方法的具体的操作，来完成对具体对象的读入功能。

通过一个简单的例子来理解InputStream的组合过滤器功能。

我们要从文件中读入数字，则首先必须有一个具体实现读取文件的FileInputStream实例： FileInputStream fin = new FileInputStream("test.dat");

流在默认情况下是不被缓冲区缓存的，也就是说，对于每一次的read的调用都会请求操作系统再分发一个字节。相比之下，一次请求一个数据块将其置于缓冲区显得更加高效。
因此，我们为流添加缓冲功能，形成缓冲流： BufferedInputStream bin = new BufferedInputStream(fin);

test.dat文件中存储的是十进制数字的二进制序列。此时我们的流仅仅提供了读取字节序列的功能，为了实现将二进制序列转为十进制数字的功能，我们做进一步转换：
DataInputStream din = new DataInputStream(bin);

此时我们可以调用 din.readInt()方法依次读取文件中以二进制形式存储的十进制数字了。

注意，我们将DataInputStream置于构造链的最后，这是因为我们最终希望使用DataInputStream的方法来读取十进制数字。

观察一下上面提到的几个类的实现，就会对这种装饰者模式的工作机制有更加深刻的理解。理解了装饰者模式之后，再结合上面的类图，使用IO流就会更加得心应手。

对于OutputStream，实现原理与InputStream是一样的，不再赘述。

## 字符接口

{% asset_img javaio2.bmp 字符流 %}



## 字符集

## 文件操作


