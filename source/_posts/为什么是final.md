---
layout: post
date:   2016-07-31 17:30:55
title: "为什么是final"
categories: 编程
tags: 
- java
---

>之前一直知道这样一个事实：在java中，匿名内部类或局部内部类访问包含自己的函数的局部变量或形参时，该变量或形参必须声明为final类型的。今天逛博客时偶尔看到有人提问：为什么必须是final呢？？？对啊，为什么必须是final呢？翻了很多资料，网上关于这个问题的总结还挺多，但是都不懂他们在说什么（可能是自己理解不到位），所以自己总结一下。

注：以下提到的局部变量和形参，都是指产生这个匿名内部类的函数的局部变量和形参。

例子是这样的：

```java
public class Outer {
	private int outerVar=0;
	public void testInner(final String paramVal){
		final Integer localVal = 1;
		Inner inner = new Inner(){
			@Override
			public void doSomething() {
				System.out.println(localVal+paramVal);
			}
			
		};
		
		final int localVal1 = 2;
		class Inner2{
			public void testInner2(){
				System.out.println(localVal1);
			}
		}
	}
	interface Inner{
		public void doSomething();
	}
	public static void main(String args[]){
		Outer outer = new Outer();
		outer.testInner("hello");
	}
}
```

可以看到，paramVal，localVal，localVal1都是final的,去掉final关键字，编译就会报错。

后来在网上看到说，匿名内部类编译之后会形成一个新的.class文件，与他的外围类之间是相互独立的，java会帮助匿名内部类自动创建一个构造函数，构造函数参数即为匿名内部类用到的局部变量或形参。

我自己反编译了一下，并没有看到所谓的构造函数（难道是跟jdk有关？）

但是确实生成了这样几个.class文件：

Outer.class:class Outer

Outer$1.class:匿名内部类 new Inner(){...}

Outer$1Inner2.class:class Inner2

Outer$Inner.class:interface Inner

这说明，匿名内部类与他的外围类之间确实是相互独立的。

为了能看到这几个类是怎么构造的，还是看看他的字节码吧。使用 javap -c Outer$1.class命令，查看匿名内部类的字节码：

```java
class kyu.java.util.Outer$1 implements kyu.java.util.Outer$Inner {
  final java.lang.Integer val$localVar;

  final java.lang.String val$paramVal;

  final kyu.java.util.Outer this$0;

  kyu.java.util.Outer$1(kyu.java.util.Outer, java.lang.Integer, java.lang.String);
    Code:
       0: aload_0
       1: aload_1
       2: putfield      #1                  // Field this$0:Lkyu/java/util/Outer;
       5: aload_0
       6: aload_2
       7: putfield      #2                  // Field val$localVar:Ljava/lang/Integer;
      10: aload_0
      11: aload_3
      12: putfield      #3                  // Field val$paramVal:Ljava/lang/String;
      15: aload_0
      16: invokespecial #4                  // Method java/lang/Object."<init>":()V
      19: return

      .....
 }
```

上面只截取了构造函数那一部分字节码。可以看到匿名内部类生成了几个自己的成员变量，他们都是final类型的，其中 this$0 对应包含自己的外围类，其他两个成员变量对应匿名内部类中使用到的局部变量和形参
。在他的构造函数Outer$1中可以看到，这三个成员变量被赋值。即：之前提到的paramVal，localVal引用被各自复制了一份，存到了匿名内部类当中。

所以，现在有两个问题：

- **为什么需要在匿名内部类中通过构造函数将使用到的局部变量或形参的引用再复制一份，直接使用不是更方便吗？**

我们通常使用匿名内部类来执行一个异步的操作（在android中经常遇到的回调），这就存在一个生命周期不一致的问题。假如我们在匿名内部类中新开了一个线程，这个线程执行过程中需要使用局部变量或形参。但是极有可能当这个新开的线程执行到这一步的时候，产生这个匿名内部类的函数早已经执行完毕了，他的局部变量和形参也早已被回收了（局部变量和形参都存在于栈内存中），新开的线程所使用的局部变量或形参都是空的，不指向任何实例。这样就造成空指针问题。

- **局部变量或形参为什么必须是final类型？**

在1中我们知道匿名内部类将局部变量和形参的引用复制了一份，他们指向同一个实例。我们通过分析匿名内部类的字节码得到这个真相。但是从源代码的角度看，好像是匿名内部类直接使用了这个局部变量或形参，并不存在什么复制啊，他们明明就是同一个引用。

```java
final Integer localVal = 1;
Inner inner = new Inner(){
	@Override
	public void doSomething() {
		System.out.println(localVar+paramVal);
	}
};
```

这样就会给我们造成一个错觉：我们在这个局部变量存在的函数中继续修改这个局部变量引用时（将他指向另一个实例），修改的就是匿名内部类中使用的那个引用（反之在匿名内部类中修改局部变量指向的引用），因为他们看上去是同一个啊。实际上我们从1知道了，实际情况不是这样的。但是仅仅从代码的角度来看，是察觉不出这种变化的。所以如果要在语义上保证局部变量和副本的一致性，就应当使用final来保证该局部变量不变（干脆就不让你修改了）。

ps:后来在stackoverflow上看到[Why are only final variables accessible in anonymous class?](http://stackoverflow.com/questions/4732544/why-are-only-final-variables-accessible-in-anonymous-class)，可以参考一下。