---
layout: post
title: java注解
date: 2017-03-31 21:07:33
categories: 编程
tags: java
---
> 在写java代码的过程中，经常会遇到注解，但是没有去理解注解背后的原理，也没有实现过注解。网上关于java注解的文章已经有很多了，参考了一些资料，整理一下注解这方面的知识~

## 什么是注解
注解其实很常见。比如@override、Deprecated等。在使用Junit或Spring boot等一些框架的时候，注解更是无处不在了。那么，到底什么是注解呢？

```
Annotations, a form of metadata, provide data about a program that is not part of the program itself. Annotations have no direct effect on the operation of the code they annotate.   >>[https://docs.oracle.com/javase/tutorial/java/annotations/]
```
注解是元数据的一种，提供了关于程序的一些描述信息，但这些信息并不属于这个程序本身的一部分。注解并不会直接影响到代码的执行。

翻译起来有点拗口。实际上，注解是那些插入到源代码中用于某种工具进行处理的标签。注解不会改变对编写的程序的编译方式，对于包含和不包含注解的代码，java编译器都会生成相同的虚拟机指令。

一句话来说，注解只是描述代码的标签。注解本身不会做什么事情，为了使注解起到作用来实现一些黑科技，我们还需要用于处理注解的工具(编写代码处理这些注解)。

我们使用注解可以：

- 生成文档

- 在编译时进行检查。比如@override

- 替代配置文件，实现自动配置。比如 Springboot

注解Annotation是在jdk1.5之后引进的，jdk1.8之后又增加了一些新的特性。接下来的讨论基于jdk1.7。

## 注解的使用

在java中，注解是当做一个修饰符(比如public或static之类的关键词)来使用的。注解可以存在于：

包 | 类(包括enum) | 接口(包括注解接口) | 方法 | 构造器 | 成员变量 | 本地变量 | 方法参数

注意：

1.对于包的注解，需要在[package-info.java](http://strong-life-126-com.iteye.com/blog/806246)中声明。

2.对于本地变量的注解，只能在源码级别上进行处理。所有的本地变量注解在类编译完之后会被遗弃掉。

假如有这样一个注解：(注解的定义见下文)

```
@interface Result {
	String name() default "";
	int value() default -1;
    String res() default "";
}
```

我们可以这样使用它：

`@Result(name="res1",value=1)`

括号中元素的顺序无关紧要

`@Result(value=1,name="res1")等价于@Result(name="res1",value=1)`

如果元素值没有指定，则使用默认值：(没有声明默认值时必须指定元素值)

`@Result等价于@Result(name="",value=-1,"")`

如果元素的名字为特殊值value，那么可以忽略这个元素名和等号：

`@Result(1)等价于@Result(name="",value=1,"")`

如果元素是数组，那么他的值要用括号括起来：

`@Result(res={"a","b"})`

如果数组是单值，可以忽略这些括号：

`@Result(res="a")`

## 注解分类

根据注解的用途和使用方式，注解可以分为以下几类：

元注解：注解注解的注解。也就是用来描述注解定义的注解

预定义注解：jdk内置的一些注解

自定义注解：我们自己定义的注解

- 元注解

元注解包含下面几个：

**@Target: 指定这个注解可以应用于哪些项**

```
public enum ElementType {
    /** Class, interface (including annotation type), or enum declaration */
    TYPE,

    /** Field declaration (includes enum constants) */
    FIELD,

    /** Method declaration */
    METHOD,

    /** Parameter declaration */
    PARAMETER,

    /** Constructor declaration */
    CONSTRUCTOR,

    /** Local variable declaration */
    LOCAL_VARIABLE,

    /** Annotation type declaration */
    ANNOTATION_TYPE,

    /** Package declaration */
    PACKAGE
}
```
比如，我们定义了一个注解Bug，该注解只能应用于方法或成员变量：

```
@Target({ElementType.METHOD,ElementType.FIELD})
@interface Bug{
	int value() default -1;
}
```
注解Bug则只能用于类方法或成员变量，如果注解了其他项比如类或者包，编译则不会通过。

对于一个没有声明@Target的注解，可以应用到任何项上。

**@Retention: 指定这个注解可以保留多久**

```
public enum RetentionPolicy {
    /**
     * Annotations are to be discarded by the compiler.
     */
    SOURCE,

    /**
     * Annotations are to be recorded in the class file by the compiler
     * but need not be retained by the VM at run time.  This is the default
     * behavior.
     */
    CLASS,

    /**
     * Annotations are to be recorded in the class file by the compiler and
     * retained by the VM at run time, so they may be read reflectively.
     *
     * @see java.lang.reflect.AnnotatedElement
     */
    RUNTIME
}
```
SOURCE：只存在于源代码，编译成.class之后就没了

CLASS: 保留到类文件中，但是虚拟机不会载入

RUNTIME：保留到类文件中，并且虚拟机会载入。这意味着通过反射可以获取到这些注解和注解元素值

默认情况下(没有声明@Retention)，注解保留级别为CLASS

**@Document：指定这个注解应该包含在文档中**

文档化的注解意味着像javadoc这样的工具生成的文档中会包含这些注解。比如：

```
@Documented
@Retention(RetentionPolicy.RUNTIME)
@Target(value={CONSTRUCTOR, FIELD, LOCAL_VARIABLE, METHOD, PACKAGE, PARAMETER, TYPE})
public @interface Deprecated {
}
```
@Deprecated是文档化的注解，URLDecoder.decode(String s)方法应用了这个注解：

{% asset_img decode.jpg decode %}

{% asset_img doc.jpg doc %}

可以在文档中看到Deprecated的出现。

**@Inherited: 指定一个注解，当他应用于一个类的时候，能够自动被其子类继承**

@Inherited只能应用于对类的注解。如果一个类具有继承注解，那么他的所有子类都自动具有同样的注解。

比如，定义了一个继承注解@Secret表示一个类是隐私的不可被序列化传输的，那么该类的子类会被自动注解为不可序列化传输的。

```
@Inherited
@interface Secret{
}

@Secret class A{}

class B extends A{} //同样是@Secret的
```
当注解工具去获取声明了@Secret的对象时，他能够获取到A的对象和B的对象。

- 预定义注解

常用的有三个：@override、@Deprecated、@SuppressWarnings，具体的作用可以查文档或者源码，不再赘述。

## 注解的定义

上面的讨论中已经涉及到了注解的定义。一个注解是由一个注解接口来定义的：

```
@interface Result {
	String name();
	int value() default -1;
}
```
每个元素的声明有两种形式，有默认值和没有默认值的，就像上面那样。注解的元素可以是下面之一：

基本类型|String|Class类型|enum|注解类型|由前面所述类型构成的数组

```
@interface BugReport{
	enum Status{FIXED,OPEN,NEW,CLOSE};
	boolean isIgnore() default false;
	String id();
	Class<?> testCase() default Void.class;
	Status status() default Status.NEW;
	Author author() default @Author;
	String[] reportMsg() default "";
}
```
注意，虽然注解元素可以是另一个注解，但是不能在注解中引入循环依赖，比如@BugReport依赖@Author，而@Author又依赖@BugReport。同时，注解元素也不可以为null，元素的值必须是编译期常量。

我们可以通过在注解的定义前声明之前提到的元注解来定制我们的注解，比如：

```
@Target({ ElementType.METHOD, ElementType.FIELD })
@Inherited
@Documented
@Retention(RetentionPolicy.RUNTIME)
@interface Result {
	String name() default "";
	int value() default -1;
	String[] reportMsg() default "";
}
```
所有的注解接口隐式的继承自java.lang.annotation.Annotation接口。这是一个正常的接口，而不是注解接口。
```
public interface Annotation {
    boolean equals(Object obj);
    int hashCode();
    String toString();
    Class<? extends Annotation> annotationType();
}
```
也就是说，注解接口也是普通接口的一种。注解接口中的元素实际上也是方法的声明，这些方法类似于bean的get、set，我们使用@Result(name="A")的形式实际上是调用了set方法给某个变量赋值。

既然是接口，那么就应该有实现(不然怎么用呢？)。我们不需要主动提供实现了注解接口的类，虚拟机会在需要的时候产生一些代理类和对象。下文会提到。

既然可以为注解元素赋值，那么必定有方法去获得这些值。也就是注解的解析。

-----
## 注解的解析

我们定义了注解并且应用了注解，但是仅仅这样的话注解并不会起到什么作用。需要我们提供一种工具去解析声明的注解，然后实现一些自动配置或者生成报告的功能。这就是注解的解析。

- 源代码中的注解

注解的用处之一就是自动生成一些包含程序额外信息的文件。比如，根据注解生成代码进度报告，或者bug修复报告等。生成的文件可以是属性文件、xml文件、html文档或者shell脚本。也可以生成java源文件。



- 字节码中的注解

- 运行时的注解

