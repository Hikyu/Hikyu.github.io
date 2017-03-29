---
layout: post
title: java代理机制
date: 2017-03-28 16:15:35
categories: 编程
tags: java
---
## 代理模式

代理模式，顾名思义，即一个客户不想或者不能直接访问一个对象，需要通过一个称为代理的第三方对象来实现间接引用。代理对象的作用就是客户端和目标对象
之间的一个中介，通过代理对象可以隐藏不让用户看到的内容或实现额外的服务。

代理机制应用的场景有很多：比如在代理对象中实现缓存，验证，权限控制等功能，真正的业务逻辑封装在真实对象中。RMI远程方法调用也用到了代理。当你调用一个远程方法的时候，相当于调用这个方法的代理对象，
在代理对象中封装了网络请求等部分，真实对象存在于另一个进程上。重构老旧代码的时候也常常会用到代理模式。

代理分两种：静态代理和动态代理

## 静态代理

静态代理即在代码中手动实现代理模式。代理模式涉及到三个角色：

真实对象RealSubject、抽象主题Subject、代理对象Proxy

{% asset_img Proxy.jpg Proxy %}

{% asset_img seq_Proxy.jpg.png seq_Proxy %}

```
public class ProxyTest {
	public static void main(String[] args) {
		new Proxy("hello").request();
	}
}
interface Subject {
	void request();
}
class Proxy implements Subject{
	String str;
	RealSubject subject;
	public Proxy(String string) {
		str = string;
		subject = new RealSubject(str);
	}
	@Override
	public void request() {
		System.out.println("代理对象验证机制....");
		subject.request();
	}
	
}

class RealSubject implements Subject{
	String str;
	public RealSubject(String string) {
		str = string;
	}
	@Override
	public void request() {
		System.out.println("真实对象打印str: " + str);
	}
	
}
```
输出：
```
代理对象验证机制....
真实对象打印str: hello
```
上面的代码模拟了一个代理对象实现验证机制的过程。可以看到，代码很简单，代理模式也很好理解。
（我们在真实生活中不也有代理么,,比如黄牛，帮你买到你买不到的火车票）

## JDK动态代理实现

动态代理时较为高级的一种代理模式。典型的应用有Spring AOP，RMI。

在上面的静态代理模式中，真实对象是事先存在的，并且作为代理对象的内部成员属性。一个真实的对象必须对应一个代理对象，如果真实对象很多的话会导致类膨胀。

另外，如何在事先不知道真实对象的情况下使用代理代理对象，这都是动态代理需要解决的问题。

比如有n个类需要在执行前打印几行日志，而这n个类是无法通过源代码修改的(从jar包中引入的)。通过静态代理实现的话将会有n个新的代理类产生，而使用动态代理的话，只需一个类即可。

动态代理的实现方式有很多，我们只讨论JDK中的动态代理实现。

```
import java.lang.reflect.InvocationHandler;
import java.lang.reflect.Method;
import java.lang.reflect.Proxy;

public class DynamicProxyTest {
	public static void main(String[] args) {
		Subject subject = (Subject) new DynamicProxy().bind(new RealSubject("hello"));
		subject.request();
	}
}

interface Subject {
	void request();
}

class RealSubject implements Subject{
	String str;
	public RealSubject(String string) {
		str = string;
	}
	@Override
	public void request() {
		System.out.println("真实对象打印str: " + str);
	}
}

class DynamicProxy implements InvocationHandler {
	Object object;
	public Object bind(Object object) {
		this.object = object;
		return Proxy.newProxyInstance(object.getClass().getClassLoader(), 
				object.getClass().getInterfaces(), this);
	}
	@Override
	public Object invoke(Object proxy, Method method, Object[] args)
			throws Throwable {
		System.out.println("代理对象验证...");
		return method.invoke(object, args);
	}
}
```
输出：
```
代理对象验证...
真实对象打印str: hello
```
可以看到，动态代理实现了与静态代理一样的功能，但他的优点在于代理的真实对象不是确定的，可以在运行时指定，增大了灵活性。如果我们有很多的真实对象需要代理访问，并且他们代理对象中的内容
都实现了相同的功能，那么我们只需要一个动态代理类即可。

## 动态代理原理

我们通过观察java.lang.reflect.Proxy的源码来了解动态代理的原理。下面的代码截取自openjdk1.7

{% asset_img 1.png Proxy %}

上面的方法截取自Proxy.newProxyInstance，可以看到，调用getProxyClass方法获取到一个代理类class对象，然后使用该class对象通过反射方法实例化一个对象返回。

接下来观察getProxyClass方法。

{% asset_img 2.png Proxy %}

这部分代码截取自getProxyClass，先从缓存中查询是否已经生成过对应的class，若有，则直接返回该对象，没有，则继续下一步生成class

{% asset_img 3.png Proxy %}

这部分代码是代理类class对象的生成过程。其中：

`byte[] proxyClassFile = ProxyGenerator.generateProxyClass(proxyName, interfaces);`这行代码调用ProxyGenerator.generateProxyClass返回了代理类class对象的字节码byte序列，
`proxyClass = defineClass0(loader, proxyName,proxyClassFile, 0, proxyClassFile.length);`这一行则进行了类加载的工作，最终生成了代理类class对象。

{asset_img 4.png Proxy}

generateProxyClass，其中的gen.generateClassFile()方法实现了字节码的生成。

{asset_img 5.png Proxy}

generateClassFile方法的实现。开头调用的三个addProxyMethod方法将object类中的hashcode、equals、toString方法重写，故对这三个方法的调用会传递到InvocationHandler.invoke方法当中。
注意，除了上述三个方法之外，调用代理类中Object定义的其他方法不会传递到invoke方法当中，也就是说，调用这些方法会执行Object中的默认实现。

如果想要查看ProxyGenerator.generateProxyClass这个方法在运行时产生的代理类中写了些什么，可以在main方法中加入：

```
System.getProperties().put("sun.misc.ProxyGenerator.saveGeneratedFiles", "true");
```
