---
layout: post
title: java序列化与反序列化
date: 2017-03-22 20:14:46
categories: 编程
tags: java
---

## 什么是序列化

所谓的序列化，即把java对象以二进制形式保存到内存、文件或者进行网络传输。从二进制的形式恢复成为java对象，即反序列化。

通过序列化可以将对象持久化，或者从一个地方传输到另一个地方。这方面的应用有RMI，远程方法调用。

java中实现序列化有两种方式，实现Serializable接口或者Externalizable接口。这篇总结只讨论Serializable的情况。

```
public class SerializeTest implements Serializable{
	    private static final long serialVersionUID = 1L;
		public String str;
		public SerializeTest(String str) {
			   this.str = str;
		}
		
		public static void main(String[] args) throws IOException, ClassNotFoundException {
			   SerializeTest test = new SerializeTest("hello");
			   ByteArrayOutputStream oStream = new ByteArrayOutputStream();
			   ObjectOutputStream objectOutputStream = new ObjectOutputStream(oStream);
			   objectOutputStream.writeObject(test);//序列化
			   
			   ObjectInputStream inputStream = new ObjectInputStream(new ByteArrayInputStream(oStream.toByteArray()));
			   SerializeTest obj = (SerializeTest) inputStream.readObject();//反序列化
			   System.out.println(obj.str);
		}
}
```
上面的代码演示了类SerializeTest实现序列化和反序列化的过程。

所有的序列化和反序列化过程都是java默认实现的，你只需要实现接口Serializable，就能得到一个实现了序列化的类。
通过ObjectOutputStream和ObjectInputStream分别将序列化对象输出或者写入到某个流当中。流的目的地可以是内存字节数组(上例)、文件、或者网络。

下面研究一下序列化过程中的几个问题：

## 静态变量如何序列化

```
public class SeriaUtil {
	    ByteArrayInputStream bInputStream;
	    ByteArrayOutputStream byOutputStream;
	    ObjectOutputStream outputStream ;
	    ObjectInputStream inputStream;
	    
        public void seria(Object test) throws IOException {
        	if (byOutputStream == null) {
        		byOutputStream = new ByteArrayOutputStream();
			}
        	if (outputStream == null) {
        		outputStream = new ObjectOutputStream(byOutputStream);
			}
		    outputStream.writeObject(test);
//		   System.out.println(byOutputStream.toByteArray().length); 
        }
        
        public Object  reSeria() throws IOException, ClassNotFoundException {
	        	if (bInputStream == null) {
					  bInputStream = new ByteArrayInputStream(byOutputStream.toByteArray());
				}
	        	if (inputStream == null) {
	        		inputStream = new ObjectInputStream(bInputStream);
				}
			    Object obj =  inputStream.readObject();
			    return obj;
        }
}

public class StaticTest implements Serializable{
	private static final long serialVersionUID = 1L;
	public static int A = 0;
	public static String B = "hello";
	
	public static void main(String[] args) throws IOException, ClassNotFoundException {
		    //先序列化类，此时 A=0 B = hello
		    SeriaUtil seriaUtil = new SeriaUtil();
		    StaticTest test = new StaticTest();
		    seriaUtil.seria(test);
		    //修改 静态变量的值
		    StaticTest.A = 1;
		    StaticTest.B = "world";
		    
		    StaticTest obj = (StaticTest) seriaUtil.reSeria();
		    //输出 A = 1 B = world
		    System.out.println(obj.A);
		    System.out.println(obj.B);
	}
}
```
上面的代码说明了，静态变量不会被序列化。

序列化StaticTest实例test时，静态变量 A=0 B="hello"，序列化之后，修改StaticTest类的静态变量值，A=1 B="world"，
此时反序列化得到之前序列化的实例对象赋给obj，发现obj的静态变量变为A=1 B="world"，说明静态变量并未序列化成功。

事实上，在序列化对象时，会忽略对象中的静态变量。很好理解，静态变量是属于类的，而不是某个对象的状态。我们序列化面向的是对象，是想要将对象的状态保存下来，所以
静态变量不会被序列化。反序列化得到的对象中的静态变量的值是当前jvm中静态变量的值。静态变量对于同一个jvm中同一个类加载器加载的类来说，是一样的。对于同一个静态变量，不会存在同一个类的不同实例拥有不同的值。

## 同一对象序列化两次，反序列化后得到的两个对象是否相等

这个问题提到的相等，是指是否为同一对象，即==关系

在某些情况下，确保这种关系是很重要的。比如王经理和李经理拥有同一个办公室，即存在引用关系：

```
public class Manager{
    Room room;
    public Manager(Room r){
        room = r;
    }
}

public class Room{}

public class APP{
    public void main(String args[]){
        Room room = new Room();
        Manager wang = new Manager(room);
        Manager li = new Manager(room);
    }
}
```
反序列化之后，wang，li，room的这种引用关系不应该发生变化。通过代码验证一下：

```
public class ReferenceTest implements Serializable{
		public String a;
		public ReferenceTest() {
			a = "hah";
		}
		public static void main(String[] args) throws Exception {
			  System.out.println("构造对象********************");
			  ReferenceTest test = new ReferenceTest();
			  System.out.println("序列化**********************");
			  SeriaUtil util = new SeriaUtil();
			  util.seria(test);
			  util.seria(test);//第二次序列化该对象
			  System.out.println("反序列化**********************");
			  ReferenceTest obj = (ReferenceTest) util.reSeria();
			  ReferenceTest obj1 = (ReferenceTest) util.reSeria();
			  System.out.println(obj == obj1);//true
			  System.out.println(obj == test);//false
		}
}
```
上面的例子证明（System.out.println(obj == obj1);//true），同一对象序列化多次之后，反序列化得到的多个对象相等，即内存地址一致。

使用同一个ObjectOutputStream对象序列化某个实例时，如果该实例还没有被序列化过，则序列化，若之前已经序列化过，则不再进行序列化，只是做一个标记而已。
所以在反序列化时，可以保持原有的引用关系。

System.out.println(obj == test);//false   也可以理解，反序列化之后重建了该对象，内存地址必然是新分配的，故obj != test

## 父类没有实现Serializable，父类中的变量如何序列化

```
public class SuperTest{
       public String superB;
       public SuperTest() {
    	   superB = "hehe";
    	   System.out.println("super 无参构造函数");
       }
       
       public SuperTest(String b){
    	   System.out.println("super 有参构造函数");
    	   superB = b;
       }
		public static void main(String[] args) throws IOException, ClassNotFoundException {
			  System.out.println("构造对象*******************");
			  SonTest sonTest = new SonTest("son", "super");
			  System.out.println("序列化*********************");
			  SeriaUtil  seriaUtil = new SeriaUtil();
			  seriaUtil.seria(sonTest);
			  System.out.println("反序列化******************");
			  SonTest obj = (SonTest) seriaUtil.reSeria();
			  System.out.println(obj.sonA);
			  System.out.println(obj.superB);
		}
}

class SonTest extends SuperTest  implements Serializable{
	 private static final long serialVersionUID = 1L;
	 public String sonA;
	 public SonTest() {
		 System.out.println("son 无参构造函数");
	 }
	 
	 public SonTest(String a, String b) {
		 super(b);
		 System.out.println("son 有参构造函数");
		 sonA = a;
	 }
}
```
输出：

构造对象*******************
super 有参构造函数
son 有参构造函数
序列化*********************
反序列化******************
super 无参构造函数
son
hehe

通过上面的代码可以看出，父类如果没有实现serializable，反序列化时会调用父类的无参构造函数初始化父类当中的变量。

所以，我们可以通过显示声明父类的无参构造函数，并在其中初始化变量值来控制反序列化后父类变量的值。

## transient使用

实现了serializable接口的类在序列化时默认会将所有的非静态变量进行序列化。我们可以控制某些字段不被默认的序列化机制序列化。

比如，有些字段是跟当前系统环境相关的或者涉及到隐私的，需要保密的。这些字段是不可以被序列化到文件中或者通过网络传输的。我们可以通过为这些字段声明
transient关键字，保证其不被序列化。

被关键字transient声明的变量不会被序列化，反序列化时该变量会被自动填充为null（int 为0）。我们也可以为这些字段实现自己的序列化机制。

```
public class TransientTest implements Serializable{
	   private static final long serialVersionUID = 1L;
		public transient String  str;
	    public TransientTest() {
	    	str = "hello";
	    }
	    
	    private void writeObject(ObjectOutputStream out) throws IOException {
	        out.defaultWriteObject();
	        String encryption = "key" + str;
	        out.writeObject(encryption);
	    }

	    private void readObject(ObjectInputStream in) throws IOException, ClassNotFoundException {
	        in.defaultReadObject();
	       String encryption =  (String) in.readObject();
	       str = encryption.substring("key".length(), encryption.length());
	    }
	    
		public static void main(String[] args) throws IOException, ClassNotFoundException {
			  TransientTest test = new TransientTest();
			  SeriaUtil util = new SeriaUtil();
			  util.seria(test);
			  TransientTest reSeria = (TransientTest) util.reSeria();
			  System.out.println(reSeria.str);//hello
		}
}
```
通过实现writeObject和readObject实现自己的序列化机制。上面的代码模拟了一个加密的序列化过程。

## 成员变量没有实现序列化

序列化某个实例时，如果这个实例含有对象类型的成员变量，那么同时会触发该变量的序列化机制。这时就要求这个成员变量也实现Serializable接口，如果没有实现该接口，抛出异常。

```
public class VariableTest implements Serializable{
	Variable variable ;
	public VariableTest() {
		variable = new Variable();
	}
	public static void main(String[] args) throws IOException, ClassNotFoundException {
		    System.out.println("构造对象*************");
		    VariableTest variableTest = new VariableTest();
		    System.out.println("序列化**************");
		    SeriaUtil util = new SeriaUtil();
		    //抛出异常：java.io.NotSerializableException
		    util.seria(variableTest);
		    System.out.println("反序列化****************");
		    VariableTest obj = (VariableTest) util.reSeria();
		    System.out.println(obj.variable.a);//抛出异常：Exception in thread "main" java.io.NotSerializableException: space.kyu.Variable
	}
}
class Variable {
	public String a;
	public Variable(){
		a = "hehe";
	}
}
```

## 单例模式下的序列化

```
public class SingleTest implements Serializable{
	public static SingleTest instance = new SingleTest();
	private SingleTest(){}
	public static void main(String[] args) throws IOException, ClassNotFoundException {
		SingleTest test = SingleTest.instance;
		SeriaUtil util = new SeriaUtil();
		util.seria(test);
		SingleTest reSeria = (SingleTest) util.reSeria();
		System.out.println(reSeria == SingleTest.instance);//false
	}
}
```

由上面的代码可以看出，有两个SingleTest实例同时存在，通过反序列化破坏了单例模式。反序列化时会开辟新的内存空间重新实例化对象，所以单例模式被破坏。

为了解决这种问题，可以实现readResolve()方法。

```
public class SingleTest implements Serializable{
	public static SingleTest instance = new SingleTest();
	private SingleTest(){}
	private Object readResolve() {
        return SingleTest.instance;
    }
	public static void main(String[] args) throws IOException, ClassNotFoundException {
		SingleTest test = SingleTest.instance;
		SeriaUtil util = new SeriaUtil();
		util.seria(test);
		SingleTest reSeria = (SingleTest) util.reSeria();
		System.out.println(reSeria == SingleTest.instance);//true
	}
}
```

## 序列化版本

