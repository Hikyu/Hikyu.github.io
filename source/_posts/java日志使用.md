---
layout: post
date:   2017-02-21 12:48:55
title:  "java日志框架的使用"
categories: 工具
tags: 
- java
---

> 之前在web项目中用到了日志，日志在web应用中很重要，特别是对于程序员追查bug而言。但是由于对混乱的日志框架体系不是十分清楚，导致各种jar包冲突和日志不正常输出。今天来总结一下日志框架的使用
> 主要介绍日志门面slf4j结合日志实现log4j。关于其他的日志框架介绍和使用，参考链接里列出了前辈总结的很好的资料，相信读完之后一定会有收获。

## 日志门面和实际日志框架

日志框架有：jdk自带的logging(jul)，log4j1、log4j2、logback
日志门面有：apache commons-logging、slf4j

日志框架很好理解，就是提供日志api，使我们可以很轻易的，有组织有规范的输出日志。日志门面的作用是在日志记录实现的基础上提供一个封装的 API 层次，
对日志记录 API 的使用者提供一个统一的接口，使得可以自由切换不同的日志记录实现。日志门面就好比java中的jdbc规范接口，各个数据库厂家实现的jdbc驱动程序就是实际的日志框架，
他们遵循了这个规范，使得我们在编写java程序时不用考虑底层驱动的不同，只需调用jdbc规范接口即可。这是典型的面向对象思想。

##  slf4j的使用

### 简介

![slf4j使用](https://www.slf4j.org/images/concrete-bindings.png)

上图来自slf4j官网

slf4j-api.jar包含了slf4j的抽象层API，我们在代码中调用这个jar包中的接口。API层

slf4j-log412.jar、slf4j-jdk14.jar等是slf4j通向具体日志实现框架的桥梁。中间层

log4j.jar等则是具体的日志实现框架。实现层


>SLF4J does not rely on any special class loader machinery. In fact, each SLF4J binding is hardwired at compile time to use one and only one specific logging framework. For example, the slf4j-log4j12-1.7.23.jar binding is bound at compile time to use log4j. In your code, in addition to slf4j-api-1.7.23.jar, you simply drop one and only one binding of your choice onto the appropriate class path location. Do not place more than one binding on your class path. Here is a graphical illustration of the general idea.

上面这段话的意思大概是，我们不应该在classpath中绑定多于一个的中间层，否则会导致jar包冲突或者输出混乱。

>To switch logging frameworks, just replace slf4j bindings on your class path. For example, to switch from java.util.logging to log4j, just replace slf4j-jdk14-1.7.23.jar with slf4j-log4j12-1.7.23.jar.

当我们需要将日志实现由jul切换到log4j时，仅仅把中间层替换，同时切换实现层即可，并不需要修改代码。这就是日志门面的好处。不过实际应用中，需要切换日志实现的场景貌似不是很多。

### slf4j结合log4j

#### 依赖

需要的jar包：slf4j-api.jar、slf4j-log4j12.jar、log4j.jar

对应的maven依赖：

```
<dependency>
    <groupId>org.slf4j</groupId>
    <artifactId>slf4j-api</artifactId>
    <version>1.7.23</version>
</dependency>
<dependency> 
  <groupId>org.slf4j</groupId>
  <artifactId>slf4j-log4j12</artifactId>
  <version>1.7.23</version>
</dependency>
<dependency>
    <groupId>log4j</groupId>
    <artifactId>log4j</artifactId>
    <version>1.2.17</version>
</dependency>
```
#### 使用

编写log4j.properties配置文件，放到类路径下

```
log4j.rootLogger=INFO,stdout

log4j.appender.stdout=org.apache.log4j.ConsoleAppender
log4j.appender.stdout.Target=System.out
log4j.appender.stdout.layout=org.apache.log4j.PatternLayout
log4j.appender.stdout.layout.ConversionPattern=[%-5p] %d{yyyy-MM-dd HH:mm:ss,SSS} method:%l%n%m%n

```
java代码

```
package space.kyu.LogTest.log4j;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class Test {
	public static Logger logger = LoggerFactory.getLogger(Test.class);
	
	public void test() {
		logger.info("info");
		logger.debug("debug");
		logger.warn("warn");
		logger.error("error");
	}
	public static void main(String[] args) {
		new Test().test();
	}
}
```
输出

```
[INFO ] 2017-02-21 14:52:28,083 method:space.kyu.LogTest.log4j.Test.test(Test.java:10)
info
[WARN ] 2017-02-21 14:52:28,085 method:space.kyu.LogTest.log4j.Test.test(Test.java:12)
warn
[ERROR] 2017-02-21 14:52:28,085 method:space.kyu.LogTest.log4j.Test.test(Test.java:13)
error
```

#### 原理

slf4j-api.jar: org.slf4j.LoggerFactory
```
 public static Logger getLogger(String name) {
    ILoggerFactory iLoggerFactory = getILoggerFactory();
     return iLoggerFactory.getLogger(name);
 }
```
可以看到，主要分为两部分，获取ILoggerFactory，使用ILoggerFactory获取logger.

slf4j-api.jar: org.slf4j.LoggerFactory
```
public static ILoggerFactory getILoggerFactory() {
        if (INITIALIZATION_STATE == UNINITIALIZED) {
            synchronized (LoggerFactory.class) {
                if (INITIALIZATION_STATE == UNINITIALIZED) {
                    INITIALIZATION_STATE = ONGOING_INITIALIZATION;
                    performInitialization();
                }
            }
        }
        switch (INITIALIZATION_STATE) {
        case SUCCESSFUL_INITIALIZATION:
            return StaticLoggerBinder.getSingleton().getLoggerFactory();
        case NOP_FALLBACK_INITIALIZATION:
            return NOP_FALLBACK_FACTORY;
        case FAILED_INITIALIZATION:
            throw new IllegalStateException(UNSUCCESSFUL_INIT_MSG);
        case ONGOING_INITIALIZATION:
            // support re-entrant behavior.
            // See also http://jira.qos.ch/browse/SLF4J-97
            return SUBST_FACTORY;
        }
        throw new IllegalStateException("Unreachable code");
}
```
注意`return StaticLoggerBinder.getSingleton().getLoggerFactory();`这行，StaticLoggerBinder是slf4j-log4j12.jar中的类

slf4j-log4j12.jar: org.slf4j.impl.StaticLoggerBinder
```
private StaticLoggerBinder() {
        loggerFactory = new Log4jLoggerFactory();
        try {
            @SuppressWarnings("unused")
            Level level = Level.TRACE;
        } catch (NoSuchFieldError nsfe) {
            Util.report("This version of SLF4J requires log4j version 1.2.12 or later. See also http://www.slf4j.org/codes.html#log4j_version");
        }
}

```
slf4j-log4j12.jar: org.slf4j.impl.Log4jLoggerFactory
```
public Log4jLoggerFactory() {
        loggerMap = new ConcurrentHashMap<String, Logger>();
        // force log4j to initialize
        org.apache.log4j.LogManager.getRootLogger();
}
```
注意`org.apache.log4j.LogManager.getRootLogger();`初始化了log4j为具体的日志实现

追踪源代码还可以发现，我们在代码中调用的`LoggerFactory.getLogger(Test.class);`最终返回的是org.apache.log4j.Logger实例，也就是说，日志实现最终托付给了log4j

## log4j的使用

### 日志组件

Loggers：Logger负责捕捉事件并将其发送给合适的Appender。

Appenders：也被称为Handlers，负责将日志事件记录到目标位置。在将日志事件输出之前，Appenders使用Layouts来对事件进行格式化处理。

Layouts：也被称为Formatters，它负责对日志事件中的数据进行转换和格式化。Layouts决定了数据在一条日志记录中的最终形式。

当Logger记录一个事件时，它将事件转发给适当的Appender。然后Appender使用Layout来对日志记录进行格式化，并将其发送给控制台、文件或者其它目标位置。

### 日志级别

每个Logger都被了一个日志级别（log level），用来控制日志信息的输出。日志级别从高到低分为：

org.apache.log4j.Level
```
  public final static int OFF_INT = Integer.MAX_VALUE;
  public final static int FATAL_INT = 50000;
  public final static int ERROR_INT = 40000;
  public final static int WARN_INT  = 30000;
  public final static int INFO_INT  = 20000;
  public final static int DEBUG_INT = 10000;
    //public final static int FINE_INT = DEBUG_INT;
  public final static int ALL_INT = Integer.MIN_VALUE;
```
A：off 最高等级，用于关闭所有日志记录。

B：fatal 指出每个严重的错误事件将会导致应用程序的退出。

C：error 指出虽然发生错误事件，但仍然不影响系统的继续运行。

D：warm 表明会出现潜在的错误情形。

E：info 一般和在粗粒度级别上，强调应用程序的运行全程。

F：debug 一般用于细粒度级别上，对调试应用程序非常有帮助。

G：all 最低等级，用于打开所有日志记录。

我们一般只是用error,warn,info和debug就够了。

### 配置文件编写

了解了组件和日志级别，我们可以编写自己的配置文件，log4j.properties放到类路径下，如果缺少了配置文件，log4j会报错。我们也可以使用`PropertyConfigurator.configure ( String configFilename)`来指定配置文件

#### 配置logger

配置根logger：`log4j.rootLogger = [ level ] , appenderName, appenderName, …`

比如：`log4j.rootLogger=INFO,stdout`

level为日志级别，表示这个logger只打印级别大于等于level的日志。

appenderName定义了如何处理日志，即把日志输出到哪个地方，如何输出。

可以看出，一个logger可以根据appender同时输出到多个地方，logger与appender是一对多的关系。

我们也可以定义自己的logger：`log4j.logger.yukai=DEBUG,stdout`

#### 配置appender

appender定义了日志输出的目的地：`log4j.appender.appenderName = fully.qualified.name.of.appender.class `

其中，Log4j提供的常用的appender：

org.apache.log4j.ConsoleAppender（控制台），

org.apache.log4j.FileAppender（文件），

org.apache.log4j.DailyRollingFileAppender（每天产生一个日志文件），

org.apache.log4j.RollingFileAppender（文件大小到达指定尺寸的时候产生一个新的文件），

org.apache.log4j.WriterAppender（将日志信息以流格式发送到任意指定的地方）

我们还可以设置appender的属性，比如针对ConsoleAppender

```
属性	                  描述
layout	    Appender 使用 Layout 对象和与之关联的模式来格式化日志信息。
target	    目的地可以是控制台、文件，或依赖于 appender 的对象。
level	    级别用来控制过滤日志信息。
threshold	Appender 可脱离于日志级别定义一个阀值级别，Appender 对象会忽略所有级别低于阀值级别的日志。
filter	    Filter 对象可在级别基础之上分析日志信息，来决定 Appender 对象是否处理或忽略一条日志记录。
```

#### 配置layout

一个appender可以关联某一个layout，用来格式化日志的输出。可用的layout有以下几种：

org.apache.log4j.HTMLLayout（以HTML表格形式布局）， 

org.apache.log4j.PatternLayout（可以灵活地指定布局模式）， 

org.apache.log4j.SimpleLayout（包含日志信息的级别和信息字符串）， 

org.apache.log4j.TTCCLayout（包含日志产生的时间、线程、类别等等信息）

可用的格式：

%m 输出代码中指定的消息 

%p 输出优先级，即DEBUG，INFO，WARN，ERROR，FATAL 

%r 输出自应用启动到输出该log信息耗费的毫秒数 

%c 输出所属的类目，通常就是所在类的全名 

%t 输出产生该日志事件的线程名 

%n 输出一个回车换行符，Windows平台为"rn"，Unix平台为"n" 

%d 输出日志时间点的日期或时间，默认格式为ISO8601，也可以在其后指定格式，比如：%d{yyy MMM dd HH:mm:ss,SSS}，输出类似：2002年10月18日 22：10：28，921 

%l 输出日志事件的发生位置，包括类目名、发生的线程，以及在代码中的行数。举例：Testlog4.main(Test Log4.java:10)

比如：

```
log4j.appender.stdout.layout=org.apache.log4j.PatternLayout
log4j.appender.stdout.layout.ConversionPattern=[%-5p] %d{yyyy-MM-dd HH:mm:ss,SSS} method:%l%n%m%n
```

打印的信息：

```
[ERROR] 2017-02-21 16:41:25,563 method:space.kyu.LogTest.log4j.Test.test(Test.java:13)
info
```

#### logger的继承关系

我们可以定义自己的logger：`log4j.logger.yukai=DEBUG,stdout`

其中，yukai指定了这个logger的名字，可以在代码中使用它：

```
public static Logger logger = LoggerFactory.getLogger("yukai");
```

假如我们同时定义这样一个logger：`log4j.logger.yukai.child=DEBUG,stdout`

就表示yukai.child这个logger继承了yukai这个logger，更java中的包有些类似

在代码中使用：

```
public static Logger logger = LoggerFactory.getLogger("yukai.child");
```

使用了该logger会默认实现自身的设定和父Logger的设定。比如使用该logger打印了一条debug信息，同样的打印动作会执行两次，因为父logger的打印动作也会实现。

上面提到的rootlogger就是所有looger的根logger。

我们经常在代码中使用 `public static Logger logger = LoggerFactory.getLogger(Test.calss);`这样的方式，因此我们可以通过指定包名的logger来控制某个包下面所有的logger输出。比如：

我们指定：`log4j.logger.space.kyu=DEBUG,stdout`,就表示space.kyu包下面的所有logger(以LoggerFactory.getLogger(Test.calss);这种方式获取的)都继承该logger的设定。这在分层的应用或功能性应用中有可以用到。

### MDC的使用

> 在一个高访问量的 Web 应用中，经常要在同一时刻处理大量的用户请求。Web 服务器会为每一个请求分配一个线程，每一个线程都会向日志系统输入一些信息，通常日志系统都是按照时间顺序而不是用户顺序排列这些信息的，这些线程的交替运行会让所有用户的处理信息交错在一起，让人很难分辨出那些记录是同一个用户产生的。另外，高可用性的网站经常会使用负载均衡系统平衡网络流量，这样一个用户的操作记录很可能会分布在多个 Web 服务器上，如果我们没有一种方法来标示一条记录是哪个用户产生的，从这众多的日志信息中筛选出对我们有用的东西将是一项艰巨的工作。

NDC或MDC就是用来解决这个问题的。

MDC 可以看成是一个与当前线程绑定的哈希表，可以往其中添加键值对。
MDC 中包含的内容可以被同一线程中执行的代码所访问。当前线程的子线程会继承其父线程中的 MDC 的内容。
当需要记录日志时，只需要从 MDC 中获取所需的信息即可。MDC 的内容则由程序在适当的时候保存进去。
对于一个 Web 应用来说，通常是在请求被处理的最开始保存这些数据。

```
public class App {
	private static final Logger logger = LoggerFactory.getLogger(App.class);

	public static void main(String[] args) {
		new App().log("main thread");
		new Thread(){
			public void run() {
				new App().log("sub thread");
			};
		}.start();
	}

	public void log(String arg) {
		MDC.put("username", "Yukai");
		logger.info("This message from : {}", arg);
	}
}
```

输出

Yukai 2017-02-21 22:10:54 [INFO] space.kyu.log_test.App - This message from : main thread
Yukai 2017-02-21 22:10:54 [INFO] space.kyu.log_test.App - This message from : sub thread

## 参考

[SLF4J user manual](https://www.slf4j.org/manual.html)

[JDK Logging深入分析](http://blog.csdn.net/qingkangxu/article/details/7514770)

[jdk-logging、log4j、logback日志介绍及原理](http://my.oschina.net/pingpangkuangmo/blog/406618)

[commons-logging与jdk-logging、log4j1、log4j2、logback的集成原理](http://my.oschina.net/pingpangkuangmo/blog/407895)

[slf4j与jdk-logging、log4j1、log4j2、logback的集成原理](http://my.oschina.net/pingpangkuangmo/blog/408382)

[slf4j、jcl、jul、log4j1、log4j2、logback大总结](http://my.oschina.net/pingpangkuangmo/blog/410224)

[Java 日志管理最佳实践](https://www.ibm.com/developerworks/cn/java/j-lo-practicelog/)