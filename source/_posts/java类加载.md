---
layout: post
title: java类加载
date: 2017-04-06 19:56:22
categories: 编程
tags: java
---
> 本篇笔记的目标是理解类加载器的架构，学会实现类加载器并理解热替换的底层原理。

## 什么是类加载

>类从被加载到虚拟机内存中开始，到卸载出内存为止，包括了以下几个生命周期：

![](http://img.blog.csdn.net/20150905224439218)

>什么时候会触发类加载的第一个阶段(加载)？虚拟机规范没有强制规定，这一点依据不同的虚拟机实现来定。但对于初始化阶段，虚拟机规范规定了有且只有5种>情况必须立即对类进行初始化(加载阶段自然要在此之前开始)：

>1.使用new关键字实例化对象、读取或设置一个类的静态字段(被final修饰的常量字段除外)、调用一个类的静态方法。

>2.使用反射方法对类进行调用

>3.初始化一个类的时候，发现其父类未初始化，则触发父类的初始化

>4.虚拟机启动时，用户需指定一个要执行的主类(包含main的那个类)，虚拟机先初始化该类

>5.当使用jdk1.7的动态语言支持时，如果一个java.lang.invoke。MethodHandle实例最后的解析结果REF_getStatic、REF_putStatic、REF_invokeStatic的方法句柄所对应的类没有进行过初始化，则先触发其初始化(不懂...)

--《深入理解jvm虚拟机》

这篇笔记所要学习的内容，仅仅是类加载的第一个阶段：加载。在加载阶段，虚拟机会完成下面三件事：

1.通过一个类的全限定名获取定义此类的二进制字节流

2.将这个字节流所代表的静态存储结构转化为方法区的运行时数据结构

3.在内存中生成一个代表这个类的java.lang.Class对象，作为方法区中这个类的各种数据的访问入口

在上面的三个阶段中，`通过一个类的全限定名获取定义此类的二进制字节流` 是开发人员可以控制的部分，也是我们这篇笔记所要探讨的内容。

虚拟机设计团队将`通过一个类的全限定名获取定义此类的二进制字节流`这个动作放到java虚拟机外部去实现，以便让应用程序自己决定去如何获取所需要的类。实现这个动作的代码模块被称为"类加载器"。`定义此类的二进制字节流`可以来自class文件、网络、zip包、或者运行时生成等。

类加载器实现类的加载动作，比较两个类是否相等，只有在这两个类是由同一个类加载器加载的前提下才有意义，否则，即使两个类源自于同一份class文件，被同一个虚拟机加载，只要加载他们的类加载器不同，那么这两个类必定不相等。

```java
public class ClassLocaderTest {
	public static void main(String[] args) {
        Object testClassLoader1 = getMyClassLoader1();
        System.out.println(testClassLoader1.getClass());
		System.out.println(testClassLoader1 instanceof space.kyu.TestClass);
    }
    static Object getMyClassLoader1() {
		Object obj = null;
		try {
			MyClassLoader1 loader = new MyClassLoader1();
			obj = loader.loadClass("space.kyu.TestClass").newInstance();
		} catch (Exception e) {
			System.out.println(e);
		}
		return obj;
	}
}
class MyClassLoader1 extends ClassLoader{
	@Override
	public Class<?> loadClass(String name) throws ClassNotFoundException {
		try {
			String fileName = name.substring(name.lastIndexOf(".") + 1) + ".class";
			InputStream stream = getClass().getResourceAsStream(fileName);
			if (stream == null) {
//				System.out.println("ClassLoader load class" + name);
				return super.loadClass(name);
			}
			byte[] bs = new byte[stream.available()];
			stream.read(bs);
//			System.out.println("MyClassLoader1 load class: " + name);
			return defineClass(name, bs, 0, bs.length);
		} catch (IOException e) {
			throw new ClassNotFoundException(name);
		}
	}
	
}
```

输出：

```
class space.kyu.TestClass
false
```

在上面的例子中，虚拟机中存在两个space.kyu.TestClass类，一个是由系统应用程序类加载器加载的，一个是由我们自己实现的类加载器加载的。虽然来自同一个class文件，但依然是两个独立的类，故不相等。


类加载器应用于类层次划分、OSGI、热部署、代码加密等方面。

## 类加载器层次结构

从java虚拟机的角度来看，类加载器分为两类：

1.启动类加载器
  
  使用c++实现，是虚拟机自身的一部分

2.其他类加载器
  
  由java语言实现，独立于虚拟机外部，全都继承自抽象类java.lang.ClassLoader

从类加载器的实现来看，类加载器又可分为系统提供的类加载器与我们自己实现的类加载器。系统提供的类加载器主要有三个：

- 引导类加载器，用来加载java核心类库。主要是放在JAVA_HOME\lib目录中或被-Xbootclasspath所指定的目录。

- 扩展类加载器，由sun.misc.Launcher$ExtClassLoader实现。负责加载JAVA_HOME\lib\ext目录中，或java.ext.dirs所指定的路径中的类库。

- 应用程序类加载器，由sun.misc.Launcher$AppClassLoader实现。这个类也是ClassLoader中getSystemClassLoader()方法的返回值。负责加载classpath上指定的类库。

除了系统提供的类加载器以外，我们可以通过继承 java.lang.ClassLoader类的方式实现自己的类加载器，以满足一些特殊的需求。

除了引导类加载器之外，所有的类加载器都有一个父类加载器。这种父子关系构成了类加载器的层次结构。

对于系统提供的类加载器来说，应用程序类加载器的父类加载器是扩展类加载器，而扩展类加载器的父类加载器是引导类加载器。

因为类加载器 Java 类如同其它的 Java 类一样，也是要由类加载器来加载的。对于开发人员编写的类加载器来说，其父类加载器是加载此类加载器 Java 类的类加载器。

这种类加载器之间的层次关系，称为类加载器的双亲委派模型：

![](http://jbcdn2.b0.upaiyun.com/2016/08/b80dd39d9cb22cb83b697737e3df4953.png)

注意，上图中的树状结构并不意味着继承关系，而是使用委托实现的。

双亲委派模型的工作过程是：如果一个类加载器收到了类加载的请求，他会首先把这个请求委托给自己的父类加载器去完成，每一层次的加载器都是如此，最后所有的类加载请求最终都会传递到顶层的引导类加载器中去，只有当父类加载器无法完成这个加载请求(所请求加载的类不在 他加载的范围内)时，子类加载器会尝试自己加载。

双亲委派机制保证了java核心类库的安全，如果尝试加载与rt.jar类库中已有的类重名的java类，该类永远无法被加载运行，因为请求被传递到引导类加载器之后，引导类加载器会返回加载到的rt.jar中的类。

我们观察一下双亲委派机制的实现：

首先看一下ClassLoader中的方法：

```
findLoadedClass：每个类加载器都维护有自己的一份已加载类名字空间，其中不能出现两个同名的类。凡是通过该类加载器加载的类，无论是直接的还是间接的，都保存在自己的名字空间中，该方法就是在该名字空间中寻找指定的类是否已存在，如果存在就返回给类的引用，否则就返回 null。这里的直接是指，存在于该类加载器的加载路径上并由该加载器完成加载，间接是指，由该类加载器把类的加载工作委托给其他类加载器完成类的实际加载。

getSystemClassLoader：Java2 中新增的方法。该方法返回系统使用的 ClassLoader。可以在自己定制的类加载器中通过该方法把一部分工作转交给系统类加载器去处理。

defineClass：该方法是 ClassLoader 中非常重要的一个方法，它接收以字节数组表示的类字节码，并把它转换成 Class 实例，该方法转换一个类的同时，会先要求装载该类的父类以及实现的接口类。

loadClass：加载类的入口方法，调用该方法完成类的显式加载。通过对该方法的重新实现，我们可以完全控制和管理类的加载过程。

findClass(String name):	查找名称为 name的类，返回的结果是 java.lang.Class类的实例。

resolveClass(Class<?> c): 链接指定的 Java 类。
```

实现双亲委派机制的代码集中在ClassLoader的loadClass方法中。

```java
 protected Class<?> loadClass(String name, boolean resolve)
        throws ClassNotFoundException
    {
        synchronized (getClassLoadingLock(name)) {
            // First, check if the class has already been loaded
            Class c = findLoadedClass(name);
            if (c == null) {
                long t0 = System.nanoTime();
                try {
                    if (parent != null) {
                        c = parent.loadClass(name, false);
                    } else {
                        c = findBootstrapClassOrNull(name);
                    }
                } catch (ClassNotFoundException e) {
                    // ClassNotFoundException thrown if class not found
                    // from the non-null parent class loader
                }

                if (c == null) {
                    // If still not found, then invoke findClass in order
                    // to find the class.
                    long t1 = System.nanoTime();
                    c = findClass(name);

                    // this is the defining class loader; record the stats
                    sun.misc.PerfCounter.getParentDelegationTime().addTime(t1 - t0);
                    sun.misc.PerfCounter.getFindClassTime().addElapsedTimeFrom(t1);
                    sun.misc.PerfCounter.getFindClasses().increment();
                }
            }
            if (resolve) {
                resolveClass(c);
            }
            return c;
        }
    }
```

先检查是否已经加载过，若没有则调用父类加载器的loadClass方法，若父类加载器为空则默认使用启动类加载器作为父加载器。如果父类加载器加载失败，抛出ClassNotFoundException异常后，则调用自己的findClass方法进行加载。

## 双亲委托机制的不足

双亲委派机制很好的解决了各个类加载器的基础类统一的问题，基础类总是作为被用户代码调用的API（比如rt.jar中的类）。但是如果基础类要调用用户的代码时会发生什么？

首先要搞明白一点：当我们使用 new 关键字或者 Class.forName 来加载类时，所要加载的类都是由调用 new 或者 Class.forName 的类的类加载器进行加载的。比如我们使用JDBC标准接口时，JDBC标准接口存在于rt.jar中，在这个接口中又需要调用各个数据库厂商提供的jdbc驱动程序来达到管理驱动的目的，这些驱动程序的jar包一般置于claspath路径下。问题出现了：JDBC标准接口是由引导类加载器加载的，故在这些接口中调用classpath路径下的jdbc驱动代码时，也会尝试使用引导类加载器进行加载。但是引导类加载器根本不可能认识这些代码(只负责rt.jar)。

为了解决这个问题，引入了线程上下文类加载器。

这个类加载器可以通过java.lang.Thread类的setContextClassLoader()方法进行设置，如果创建线程时没有设置，将会从父线程中继承一个，如果在应用程序的全局范围内都没有设置，那么这个类加载器默认就是应用程序类加载器。

使用java.lang.Thread.getContextClassLoader()可以获得线程上下文类加载器，故可以使用这个加载器加载classpath路径下的代码，也就是父类加载器请求子类加载器完成类加载动作，破坏了双亲委托模型。

## 实现自己的类加载器

上面提到的系统提供的类加载器在大多数情况下可以满足我们的需求，但是在某些情况下，我们需要开发自己的类加载器，比如，加载网络传输得到的类字节码、对字节码进行加密解码、加载运行时生成的字节码、实现类的热替换等。这些情况下类的字节码仅仅依靠上述的三种系统类加载器是无法加载的。

我自己实现了一些测试代码，现在将他们贴到这里，顺便对前面的总结做一个印证。下面的几个类都位于包space.kyu下面：

```java
class MyClassLoader1 extends ClassLoader{
	@Override
	public Class<?> loadClass(String name) throws ClassNotFoundException {
		try {
			String fileName = name.substring(name.lastIndexOf(".") + 1) + ".class";
			InputStream stream = getClass().getResourceAsStream(fileName);
			if (stream == null) {
//				System.out.println("ClassLoader load class" + name);
				return super.loadClass(name);
			}
			byte[] bs = new byte[stream.available()];
			stream.read(bs);
//			System.out.println("MyClassLoader1 load class: " + name);
			return defineClass(name, bs, 0, bs.length);
		} catch (IOException e) {
			throw new ClassNotFoundException(name);
		}
	}
}

public class MyClassLoader2 extends ClassLoader {
	public Class<?> loadDirectly(String name) throws ClassNotFoundException {
		try {
			String fileName = name.substring(name.lastIndexOf(".") + 1) + ".class";
			InputStream stream = getClass().getResourceAsStream(fileName);
			if (stream == null) {
//				System.out.println("ClassLoader load class" + name);
				return super.loadClass(name);
			}
			byte[] bs = new byte[stream.available()];
			stream.read(bs);
//			System.out.println("MyClassLoader2 load class: " + name);
			return defineClass(name, bs, 0, bs.length);
		} catch (IOException e) {
			throw new ClassNotFoundException(name);
		}
	}
}

public interface Operation {
	void doSomething();
}

public class Test {
	public String str;
	public Test(String str) {
		this.str = str;
	}
	
	public void test() {
		System.out.println(str);
	}
}

public class TestClass implements Operation{
	public Test test;
	@Override
	public void doSomething() {
		System.out.println("hello");
	}
	
	public Test test(){
		test = new Test("haha");
		System.out.println(test.str);
		return test;
	}
}

public class ClassLocaderTest {
	public static void main(String[] args) {
		Object testClassLoader1 = getMyClassLoader1();
		Object testClassLoader2 = getMyClassLoader2();
		System.out.println("*****************testClassLoader1*******************");
		printClassLoader(testClassLoader1);
		reflectInvoke(testClassLoader1);
		interfaceInvoke(testClassLoader1);
		System.out.println("*****************testClassLoader2*******************");
		printClassLoader(testClassLoader2);
		reflectInvoke(testClassLoader2);
		interfaceInvoke(testClassLoader2);
        
	}

	static void printClassLoader(Object object) {
		System.out.println("*********printClassLoader:");
		ClassLoader classLoader = object.getClass().getClassLoader();
		while (classLoader != null) {
			System.out.println(classLoader);
			classLoader = classLoader.getParent();
		}
	}

	static void reflectInvoke(Object obj) {
		System.out.println("*********reflectInvoke:");
		try {
			Method test = obj.getClass().getMethod("test", new Class[] {});
			test.invoke(obj, new Object[] {});
			Method doSomething = obj.getClass().getMethod("doSomething", new Class[] {});
			doSomething.invoke(obj, new Object[] {});
		} catch (InvocationTargetException e) {
			Throwable t = e.getTargetException();// 获取目标异常
			System.out.println(t);
		} catch (Exception e) {
			System.out.println(e);
		}
	}
	
	static void interfaceInvoke(Object obj) {
		System.out.println("*********interfaceInvoke:");
		try {
			Operation operation = (Operation) obj;
			operation.doSomething();
		} catch (Exception e) {
			System.out.println(e);
		}
	}

	static Object getMyClassLoader1() {
		Object obj = null;
		try {
			MyClassLoader1 loader = new MyClassLoader1();
			obj = loader.loadClass("space.kyu.TestClass").newInstance();
		} catch (Exception e) {
			System.out.println(e);
		}
		return obj;
	}

	static Object getMyClassLoader2() {
		Object obj = null;
		try {
			MyClassLoader2 loader = new MyClassLoader2();
			obj = loader.loadDirectly("space.kyu.TestClass").newInstance();
		} catch (Exception e) {
			System.out.println(e);
		}
		return obj;
	}
}

```
上述六个类位于space.kyu下不同的类文件当中。ClassLocaderTest运行结果：

```
*****************testClassLoader1*******************
*********printClassLoader:
space.kyu.MyClassLoader1@76e2d0ab
sun.misc.Launcher$AppClassLoader@52a53948
sun.misc.Launcher$ExtClassLoader@5d53d05b
*********reflectInvoke:
haha
hello
*********interfaceInvoke:
java.lang.ClassCastException: space.kyu.TestClass cannot be cast to space.kyu.Operation
*****************testClassLoader2*******************
*********printClassLoader:
space.kyu.MyClassLoader2@6c618821
sun.misc.Launcher$AppClassLoader@52a53948
sun.misc.Launcher$ExtClassLoader@5d53d05b
*********reflectInvoke:
haha
hello
*********interfaceInvoke:
hello
```
一般来说，我们自己开发的类加载器只要继承ClassLoader并覆盖findClass方法即可。这样的话就会自动使用双亲委派机制，我们可以在findClass方法中填写我们自己的加载逻辑：从网络上或者是硬盘上加载一个类的字节码。

上面的例子中并没有使用这个套路，MyClassLoader1直接复写loadClass方法，MyClassLoader1添加了方法loadDirectly，如果不这样做的话，我们在加载space.kyu.TestClass这个类的时候，因为这个类在classpath上，由于双亲委派机制，这个类会被应用程序类加载器先进行加载，达不到测试的效果。

- 观察上面printClassLoader部分，通过getParent方法打印了类加载器的层次结构。可见虽然我们并未显示指定这两个自定义加载器的父类加载器，但是他们的父类加载器已经被默认设置为sun.misc.Launcher$AppClassLoader，也就是加载这两个个自定义类加载器所使用的加载器。印证上面的结论：`对于开发人员编写的类加载器来说，其父类加载器是加载此类加载器 Java 类的类加载器。`

- reflectInvoke方法是使用反射机制调用了加载出来类的方法，如果去掉上面自定义类加载器中注掉的System.out方法，就会看到，在反射调用TestClass的test方法的时候，类加载器加载了space.kyu.Test这个类，并且加载他的类加载器正是我们自定义的类加载器，印证了我们上面的结论：`当我们使用 new 关键字或者 Class.forName 来加载类时，所要加载的类都是由调用 new 或者 Class.forName 的类的类加载器进行加载的`

- 思考上面的反射用法，为什么不直接将getMyClassLoader1()方法返回的Object对象强转为space.kyu.TestClass呢？比如这样：

  `space.kyu.TestClass testClass = (TestClass)getMyClassLoader1();`

  编译并没有问题，但是在运行时就会报错：java.lang.ClassCastException缓存

  为什么会出现这样的结果呢？其实从这篇文章的一开始就已经演示过了。`space.kyu.TestClass testClass`这个类是通过应用程序类加载器加载的，而`getMyClassLoader1()`方法得到的是我们自定义类加载器加载的类，这两个类是不相等的(虽然名字相同)，所以强转失败。

- 接下来看interfaceInvoke这部分。将自定义类加载器加载得到的对象强转为了接口类型。注意到，MyClassLoader1加载的类对象在强转时抛出异常，而MyClassLoader2可以正常强转并调用接口方法。

  MyClassLoader1加载的类为什么强转失败？原因在于，MyClassLoader1在加载TestClass类时，触发其父类接口Operation的加载，此时默认使用MyClassLoader1加载Operation类。在MyClassLoader1中我们覆盖了loadClass方法，故加载Operation时也会调用我们自己实现的loadClass方法进行加载。

  同样的，MyClassLoader2在加载TestClass类时，也触发其父类接口Operation的加载，此时默认使用MyClassLoader2加载Operation类。不同之处在于我们并未覆盖loadClass方法，加载Operation时调用了ClassLoader中的loadClass方法，在这个方法的实现中，由应用程序类加载器加载了Operation类。

  所以，出现上面结果的原因也就一目了然了。

## 类加载器与热替换

普通的java应用中不能实现类的热替换的原因在于同名类的不同版本的实例不能共存，因为使用了默认的类加载机制后，一个类只会被加载一次，再次请求加载时直接返回之前加载的缓存(findLoadedClass)。故我们重新编译生成
的class文件并不会被重新读取并加载。

为了绕过这个加载机制，我们可以通过不同的类加载器来加载该类的不同版本。

在space.kyu包下面新增一个类HotSwapTest：
```java
public class HotSwapTest {
	public static void main(String[] args) {
		Timer timer = new Timer(false);
		TimerTask task = new TimerTask() {
			public void run() {
				update();
			}
		};
		timer.schedule(task, 1000, 2000);
	}

	public static void update() {
		try {
			MyClassLoader2 loader = new MyClassLoader2();
			Object obj = loader.loadDirectly("space.kyu.TestClass").newInstance();
			Method doSomething = obj.getClass().getMethod("doSomething", new Class[] {});
			doSomething.invoke(obj, new Object[] {});
		} catch (Exception e) {
			e.printStackTrace();
		}
	}
}
```
在HotSwapTest类中，我们模拟了一个定时升级的任务：每隔两秒执行一次升级，实例化一个MyClassLoader2对象并使用该类加载器加载space.kyu.TestClass，反射调用其doSomething方法打印字符串。

编译并运行HotSwapTest，运行过程中，每隔两秒doSomething便打印字符串"hello"，此时修改space.kyu.TestClass源码，将打印字符串替换为"world"，CTRL+S，我们的程序并未停止，但是下一次打印出的字符串已然不同了：

```
hello
hello
hello
hello
hello
world
world
world

```

上面就是一个简单的热替换的例子。实际的应用中当然不是通过一个定时任务进行升级的。把新版本类的字节码通过网络传输到服务器上去，然后发送一个升级指令，使用上面类似的方法便可对类进行升级。

## 参考

[Java 类的热替换 —— 概念、设计与实现](https://www.ibm.com/developerworks/cn/java/j-lo-hotswapcls/)

[深入探讨 Java 类加载器](https://www.ibm.com/developerworks/cn/java/j-lo-classloader/)