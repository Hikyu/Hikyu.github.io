---
layout: post
title: java泛型学习
date: 2016-10-10 20:05:03
categories: 编程 
tags:
- java
---

有一段时间没有更新博客了，过了国庆之后，好像变得更懒了~~前两天开发了一个用于记账的公众号，功能很简单，就是普通的增删查改...由于是个人开发者，无法进行公众号的认证，所以没什么高级的接口权限，只能搞的简陋一点了...下一步计划再丰富丰富，目前想到了这几个功能：配合有道或者金山词霸的Api进行中英互译（API怎么用，可不可以用目前还不清楚），配合微博的Api接口整点微博热门什么的，配合豆瓣的Api接口做一个电影或者书籍查询的功能等等....公众号的服务器代码目前还部署在自己的电脑上，用nat123做了一下公网ip的映射，接下来考虑是不是要换成云服务器更为妥当....

公众号在这里：

{% asset_img easybill.jpg EasyBill %}

目前，公众号已经开源：[WechatSubscriptionNumber](https://github.com/Hikyu/WechatSubscriptionNumber)

好了，言归正传。今天学习了java的泛型知识，不总结一下老是觉得跟没学一样...

## 泛型的好处

使用泛型的好处我觉得有两点：1：类型安全  2：减少类型强转

下面通过一个例子说明:

假设有一个Test类，通用的实现是:

```java
class Test {
	private Object o;

	public Test(Object o) {
		this.o = o;
	}

	public Object getObject() {
		return o;
	}

	public void setObject(Object o) {
		this.o = o;
	}
}
```
我们可以这样使用它：

```java
public static void main(String[] args) {
	Test test = new Test(new Integer(1));
	//编译时不报错
	//运行时报  java.lang.ClassCastException: java.lang.Integer cannot be cast to java.lang.String
	String o = (String) test.getObject();
}
```

看一个使用泛型的例子：

```java
class Test<T> {
	private T o;

	public Test(T o) {
		this.o = o;
	}

	public T getObject() {
		return o;
	}

	public void setObject(T o) {
		this.o = o;
	}
}

public static void main(String[] args) {
	Test1<Integer> test = new Test1<Integer>(new Integer(1));
	//编译时报错，无法通过编译
	//String o = test.getObject();

	//正常运行
	Integer o = test.getObject();
}
```
从上面的对比中能够看出两点：

1.使用泛型之后在编译时报错而非运行时，减少了出错的几率；

2.使用泛型之后编译器不再要求强转

## 定义泛型

泛型的机制能够在定义类、接口、方法时把类型参数化，也就是类似于方法的形参一样，把类型当做参数使用。

泛型参数部分使用`<>`包裹起来，比如`<T>`，T声明了一种类型，习惯上，这个类型参数使用单个大写字母来表示，指示所定义的参数类型。有如下惯例：

E：表示元素

T：表示类型

K：表示键

V：表示值

N：表示数字

### 定义泛型类

上面的例子就是一个很好的演示

```java
class Test<T> {
	private T o;

	public Test(T o) {
		this.o = o;
	}

	public T getObject() {
		return o;
	}

	public void setObject(T o) {
		this.o = o;
	}
}
```

使用泛型定义类之后，泛型参数 T 可以运用到该类中：可以声明成员变量类型、可以声明成员函数返回值类型、可以声明成员函数参数类型。

要注意：泛型参数T不能用于声明静态变量，同时也不能用于new一个对象比如：T o = new T();

下面的类型擦除会说到原因。

### 定义泛型接口

```java
interface Test<T> {
	public T test(T t);
}
```
使用泛型定义接口之后，泛型参数 T 可以运用到该接口中：可以声明接口函数返回值类型、可以声明接口函数参数类型。


### 定义泛型方法

可以单独给方法使用泛型，而不是泛化整个类：

```java
public static <T> T getT(T t){
	return t;
}
```
使用泛型定义方法后，泛型参数 T 可以声明该方法的返回值类型、可以声明该方法的参数类型。

要注意，定义方法所用的泛型参数需要在修饰符之后添加。

### 定义多个泛型参数

以接口为例：

```java
interface Test<T, S> {
	public T testT(T t);
	public S testS(S s);
}

public static void main(String[] args) {
    //编译时报错
	//getT("s");
}
```
多个泛型参数在尖括号中使用逗号隔开。类的泛化与方法的泛化类似。

### 泛型参数的界限

定义泛型参数界限有这样两种意义：

1.有时候我们希望限定这个泛型参数的类型为某个类的子类或者超类；

2.上面的例子中可以看到，我们定义了泛型参数，向方法中传入某种类型，这种类型是未知的，因此我们无法使用这种类型定义的变量，不能够调用它的方法。

```java
public static <T extends Number> Integer getT(T t) {
	return  new Integer(t.intValue());
}
```
上面例子中，`<T extends A>`表示T是A或A的子类，他限定了传入泛型方法参数的类型必须为A或A的子类，同时，在方法体中我们也可以使用t这个实参就像使用A的实例一样，调用Number具有的public方法。

除了`<T extends A>`限定T是A或A的子类外，还可以使用`<T super A> `这种方式来限定T是A或A的超类。

A可以是某个类或者接口。

除此以外，还可以为泛型参数限定多个限制范围，如`<T extends A & B & C>`，限定范围中最多只能有一个类(某个类只能有一个父类~~)，并且他必须是限定列表中的第一个。

```java
Class A { // }
interface B { // }
interface C { // }

//正确
class D <T extends A & B & C> { // }
//编译时报错
class D <T extends A & B & C> { // }
```

### 泛型的继承

看一下jdk中List的泛型继承例子：

```java
public interface List<E> extends Collection<E>{//...}
```
`List<String>` 就是 `Collection<String>` 的子类。

假如定义自己的接口：

```java
interface MyList<E,P> extends List<E> {
  void setPay(E e,P p);
  //...
}
```

`MyList<String,String>`、`MyList<String,Integer>`、`MyList<String,Exception>`都是`List<String>`的子类。

## 使用泛型

上面的例子中已经列举了一些使用泛化类或者泛化函数的例子，但是还有一些问题需要指出：

1.泛型参数只接受引用类型，不适用于基本类型

比如：

```java
class Test<T> {}

public static void main(String[] args) {
    //无法通过编译，不接受int类型的泛化参数
	//Test<int> test = new Test();
}
```

而我们使用泛化函数时：

```java
public static void main(String[] args) {
	getT(1);
}
public static <T> void getT(T t) {
}
```
是没有问题的，通过查看生成的字节码，发现getT(1)这个方法的字节码中1被自动装箱为Integer类型。

2.通配符的使用

考虑下面的情况：

```java
class Test<T> {}
public static void getT(Test<Number> t) {
}

public static void main(String[] args) {
	Test<Double> test = new Test();
	//编译时报错
	//getT(test);
}
```
报错的原因很好理解，虽然Double是Number的子类，但Test<Double>并不是Test<Number>的子类，故类型检查无法通过。这一点一定要明白。

那么如果我们确实想要传入一个Test<Double>类型的形参呢？可以使用通配符：

```java
class Test<T> {}
public static void main(String[] args) {
		Test<Double> test = new Test();
		//正常运行
		getT(test);
}
public static void getT(Test<? extends Number> t) {
}
```
`Test<? extends Number>`扩展了形参的类型，可以是`Test<Double>`、`Test<Integer>`等，尖括号中的类型必须是Number或继承于Number。同样的，通配符也适用于super，如`Test<? super A>`。

如果类型参数中既没有extends 关键字，也没有super关键字，只有一个?，代表无限定通配符。

`Test<?>`与`Test<Object>`并不相同，无论T是什么类型，`Test<T>` 是 `Test<?>`的子类，但是，`Test<T>` 不是 `Test<Object>` 的子类，想想上面的例子。

通常在两种情况下会使用无限定通配符：

1. 如果正在编写一个方法，可以使用Object类中提供的功能来实现

2. 代码实现的功能与类型参数无关，比如List.clear()与List.size()方法，还有经常使用的`Class<?>`方法，其实现的功能都与类型参数无关。

一般情况下，通配符`<? extends Number>`只是出现在使用泛型的时候，而不是定义泛型的时候，就像上面的例子那样。而`<T extends Number>`这种形式出现在定义泛型的时候，而不是使用泛型的时候，不要搞混了。

结合泛型的继承和通配符的使用，理解一下泛型的类型系统，也就是泛型类的继承关系：

以下内容来自：[Java深度历险（五）——Java泛型](http://www.infoq.com/cn/articles/cf-java-generics)

***
引入泛型之后的类型系统增加了两个维度：一个是类型参数自身的继承体系结构，另外一个是泛型类或接口自身的继承体系结构。第一个指的是对于 `List<String>`和`List<Object>`这样的情况，类型参数String是继承自Object的。而第二种指的是 List接口继承自Collection接口。对于这个类型系统，有如下的一些规则：

相同类型参数的泛型类的关系取决于泛型类自身的继承体系结构。即`List<String>`是`Collection<String>` 的子类型，`List<String>`可以替换`Collection<String>`。这种情况也适用于带有上下界的类型声明。
当泛型类的类型声明中使用了通配符的时候， 其子类型可以在两个维度上分别展开。如对`Collection<? extends Number>`来说，其子类型可以在Collection这个维度上展开，即`List<? extends Number>`和`Set<? extends Number>`等；也可以在Number这个层次上展开，即`Collection<Double>`和 `Collection<Integer>`等。如此循环下去，`ArrayList<Long>`和 `HashSet<Double>`等也都算是`Collection<? extends Number>`的子类型。
如果泛型类中包含多个类型参数，则对于每个类型参数分别应用上面的规则。
***

关于通配符的理解可以参考[Java 泛型 <? super T> 中 super 怎么 理解？与 extends 有何不同？](https://www.zhihu.com/question/20400700)


## 类型擦除

类型擦除发生在编译阶段，对于运行期的JVM来说，`List<int>`与`List<String>`就是同一个类，因为在编译结束之后，生成的字节码文件中，他们都是List类型。

1.java编译器会在编译前进行类型检查

java编译器承担了所有泛型的类型安全检查工作。

2.类型擦除后保留的原始类型

原始类型（raw type）就是擦除去了泛型信息，最后在字节码中的类型变量的真正类型。无论何时定义一个泛型类型，相应的原始类型都会被自动地提供。类型变量被擦除（crased），并使用其限定类型（无限定的变量用Object）替换。

3.自动类型转换

因为类型擦除的问题，所以所有的泛型类型变量最后都会被替换为原始类型。这样就引起了一个问题，既然都被替换为原始类型，那么为什么我们在获取的时候，不需要进行强制类型转换呢？

比如：

```java
public class Test {  
    public static void main(String[] args) {  
        ArrayList<Date> list=new ArrayList<Date>();  
        list.add(new Date());  
        Date myDate=list.get(0);  
    }
}  
```
`Date myDate=list.get(0);`这里我们并没有对其返回值进行强转就可以直接获取Date类型的返回值。原因在于在字节码当中，有checkcast这么一个操作帮助我们进行了强转，这是java自动进行的。

更多的关于类型擦除的知识，参考[ java泛型（二）、泛型的内部原理：类型擦除以及类型擦除带来的问题](http://blog.csdn.net/lonelyroamer/article/details/7868820)


## 实践

最近在重构公众号服务器的过程中，用到了泛型编程的知识。

```java
public interface BaseServiceContext<T extends ReqBaseMessage, R> {
	public void selectService(T reqMeg);

	public R executeRequest();
}
```
上面是一个选择service的上下文接口，接收到用户请求后通过这个接口选择对应的service并且执行service。这个接口相当于一个工厂和策略模式的结合体。下面是这个接口的一种实现：

```java
//请求为文本类型，返回string类型的处理结果
public class TextServiceContext implements BaseServiceContext<ReqTextMessage,String> {

	@Override
	public void selectService(ReqTextMessage reqMeg) {
		//.....
	}

	@Override
	public String executeRequest() {
		//.....
	}
}
```
可以看到，BaseServiceContext<ReqTextMessage,String>限定了selectService方法的参数类型和executeRequest方法的返回值类型，使其能够灵活的支持各种类型的参数和返回值。

看一下在没有学习泛型之前，这个接口是怎么实现的：

```java
public interface BaseServiceContext {
	public void selectService(ReqBaseMessage reqMeg);

	public Object executeRequest();
}

public class TextServiceContext implements BaseServiceContext {

	@Override
	public void selectService(ReqBaseMessage reqMeg) {
		//根据业务逻辑对reqMeg进行强转，需要程序员自己判断
		//很有可能强转失败
	}

	@Override
	public Object executeRequest() {
		//返回类型为object，在调用方法的外部强转为需要的类型
		//很有可能强转失败
	}
}
```
可以看到没有使用泛型接口的情况下，类型不安全且增大了强转失败的风险。同时也需要程序员根据业务逻辑去判断该强转成什么类型。使用泛型接口之后就没有了这些问题，只需要在使用接口时声明好他的泛型参数就o了。

上面只是我在开发过程中体会到泛型的一个好处，类似的例子还有很多。

## 注意事项



## 参考

[java 泛型编程（一）](http://peiquan.blog.51cto.com/7518552/1302898)

[泛型：工作原理及其重要性](http://www.oracle.com/technetwork/cn/articles/java/juneau-generics-2255374-zhs.html)

[Java深度历险（五）——Java泛型](http://www.infoq.com/cn/articles/cf-java-generics)

[java泛型详解](http://blog.csdn.net/u012152619/article/details/47253811)

[Java 泛型 <? super T> 中 super 怎么 理解？与 extends 有何不同？](https://www.zhihu.com/question/20400700)

