---
layout: post
title: webservice相关
date: 2017-03-15 11:22:45
categories: 技术
tags: web
---
> 上周最后三天去北京培训了Hadoop，了解了一些目前流行的分布式组件。在谈到这些组件的交互过程中，经常会提到RPC，webservice等关键词，所以简单了解了一下这些关键词的含义~

## [WebService](https://zh.wikipedia.org/wiki/Web_services)

webservice，拆开来看就是 web（网络）和service（服务），先了解一下什么是服务：

计算机的后台进程提供了某种功能，我们把提供了这种功能的进程称为守护进程（Daemon），提供的功能称为服务。比如，我们启动了数据库，数据库进程就会一直运行在后台监听连接数据库的动作，这种监听连接的功能就是一种服务。

服务分为本地服务和网络服务。使用同一台机器上提供的服务就是本地服务，通过网络连接到另一台计算机使用它提供的服务就是网络服务。

所以，webservice 就是通过网络使用了其他服务器提供的某种功能或获取了某些资源。

这样一来，webservice就很常见了。比如我们做了一个显示天气情况的app，使用了百度地图提供的定位功能，使用了其他服务商提供的天气数据，这些都属于webservice。

webservice可以包含以下几个实现：

RPC：面向过程

RMI：面向对象

REST：面向资源

[Web Service tutorial](http://www.java2blog.com/2013/03/web-service-tutorial.html)

## [RPC](https://zh.wikipedia.org/wiki/%E9%81%A0%E7%A8%8B%E9%81%8E%E7%A8%8B%E8%AA%BF%E7%94%A8)

### 概念

> 远程过程调用（英语：Remote Procedure Call，缩写为 RPC）是一个计算机通信协议。
该协议允许运行于一台计算机的程序调用另一台计算机的子程序，而程序员无需额外地为这个交互作用编程。
如果涉及的软件采用面向对象编程，那么远程过程调用亦可称作远程调用或远程方法调用。

上面的解释摘自维基百科

RPC属于webservice的一种，就是在一个进程中调用另一个进程中的服务。就像调用本地方法一样调用远程服务器的方法。

RPC有很多实现，包括XML-RPC、JSON-RPC、JAX-RPC等等。

一次RPC调用过程就是向服务器发送一个过程调用的方法和参数，得到服务器返回的方法执行结果。RPC的本质就是一次远程调用，但更强调透明调用。RPC是跨语言的。

### 使用

以[Json-Rpc](http://www.jsonrpc.org) 为例，看一下RPC是如何工作的：

使用java中的json-rpc实现[jsonrpc4j](https://github.com/briandilley/jsonrpc4j)：（也有其他语言的实现）

Create your service interface:
```
package com.mycompany;
public interface UserService {
    User createUser(String userName, String firstName, String password);
    User createUser(String userName, String password);
    User findUserByUserName(String userName);
    int getUserCount();
}
```
Implement it:
```
package com.mycompany;
public class UserServiceImpl
    implements UserService {

    public User createUser(String userName, String firstName, String password) {
        User user = new User();
        user.setUserName(userName);
        user.setFirstName(firstName);
        user.setPassword(password);
        database.saveUser(user)
        return user;
    }

    public User createUser(String userName, String password) {
        return this.createUser(userName, null, password);
    }

    public User findUserByUserName(String userName) {
        return database.findUserByUserName(userName);
    }

    public int getUserCount() {
        return database.getUserCount();
    }

}
```
Server
```
class UserServiceServlet
    extends HttpServlet {

    private UserService userService;
    private JsonRpcServer jsonRpcServer;

    protected void doPost(HttpServletRequest req, HttpServletResponse resp) {
        jsonRpcServer.handle(req, resp);
    }

    public void init(ServletConfig config) {
        //this.userService = ...
        this.jsonRpcServer = new JsonRpcServer(this.userService, UserService.class);
    }

}
```
Client
```
JsonRpcHttpClient client = new JsonRpcHttpClient(
    new URL("http://example.com/UserService.json"));

UserService userService = ProxyUtil.createClientProxy(
    getClass().getClassLoader(),
    UserService.class,
    client);

User user = userService.createUser("bob", "the builder");
```

上面的例子只是最简单的访问方式，在分布式环境中，RPC还涉及到服务寻址，负载均衡等等问题。

更加详细的RPC介绍，可以参考[RPC 是什么](http://blog.brucefeng.info/post/what-is-rpc)

### 为什么是RPC

在网上查看RPC资料的时候，就想到一个问题，既然RPC这么复杂，为什么不使用HTTP接口调用的方式来进行网络通信呢？以前做一些小demo的时候使用HttpClient就完全OK了。

看到一个很有意思的讨论：[为什么需要RPC，而不是简单的HTTP接口](https://www.oschina.net/question/271044_2155059)

RPC调用简单，适用于业务逻辑比较复杂的情况，比如分布式环境当中。RPC强调透明调用,也利于解耦。

### 原理

[QiuRPC](https://github.com/i1see1you/QiuRPC)：一个通用的网络RPC框架

[你应该知道的 RPC 原理](http://blog.jobbole.com/92290/)

## [SOAP](https://zh.wikipedia.org/wiki/SOAP)

XML-RPC只能使用有限的数据类型种类和一些简单的数据结构。于是就出现了SOAP(Simple Object Access Protocol)。

SOAP (Simple Object Access Protocol) 顾名思义，是一个严格定义的信息交换协议，用于在Web Service中把远程调用和返回封装成机器可读的格式化数据。

事实上SOAP数据使用XML数据格式，定义了一整套复杂的标签，以描述调用的远程过程、参数、返回值和出错信息等等。而且随着需要的增长，又不得增加协议以支持安全性，这使SOAP变得异常庞大，背离了简单的初衷。另一方面，各个服务器都可以基于这个协议推出自己的API，即使它们提供的服务及其相似，定义的API也不尽相同，这又导致了WSDL的诞生。

WSDL (Web Service Description Language) 也遵循XML格式，用来描述哪个服务器提供什么服务，怎样找到它，以及该服务使用怎样的接口规范，简言之，服务发现。

现在，使用Web Service的过程变成，获得该服务的WSDL描述，根据WSDL构造一条格式化的SOAP请求发送给服务器，然后接收一条同样SOAP格式的应答，最后根据先前的WSDL解码数据。绝大多数情况下，请求和应答使用HTTP协议传输，那么发送请求就使用HTTP的POST方法。

[Working Soap client example](http://stackoverflow.com/questions/15948927/working-soap-client-example)

[SOAP Messaging Models and Examples](https://docs.oracle.com/cd/E19340-01/820-6767/aeqfx/index.html)

通过soap demo体会soap与rpc的区别

## [RMI](https://zh.wikipedia.org/wiki/Java%E8%BF%9C%E7%A8%8B%E6%96%B9%E6%B3%95%E8%B0%83%E7%94%A8)

RMI其实也属于RPC的一种，是面向对象的。RMI只能在java里玩，不支持跨语言。与RPC不同的是，RMI可以返回java对象以及基本的数据类型，RPC不允许返回对象，RPC服务的信息由外部数据表示。RMI的优势在于依靠Java序列化机制，对开发人员屏蔽了数据编排和解排的细节，要做的事情非常少。

用代码说话：

RMI采用的是典型的客户端-服务器端架构。首先需要定义的是服务器端的远程接口，这一步是设计好服务器端需要提供什么样的服务。对远程接口的要求很简单，只需要继承自RMI中的Remote接口即可。Remote和Serializable一样，也是标记接口。远程接口中的方法需要抛出RemoteException。定义好远程接口之后，实现该接口即可。如下面的Calculator是一个简单的远程接口。
```
public interface Calculator extends Remote {
    String calculate(String expr) throws RemoteException;
}  
```
实现了远程接口的类的实例称为远程对象。创建出远程对象之后，需要把它注册到一个注册表之中。这是为了客户端能够找到该远程对象并调用。
```
public class CalculatorServer implements Calculator {
    public String calculate(String expr) throws RemoteException {
        return expr;
    }
    public void start() throws RemoteException, AlreadyBoundException {
        Calculator stub = (Calculator) UnicastRemoteObject.exportObject(this, 0);
        Registry registry = LocateRegistry.getRegistry();
        registry.rebind("Calculator", stub);
    }
}
```
CalculatorServer是远程对象的Java类。在它的start方法中通过UnicastRemoteObject的exportObject把当前对象暴露出来，使得它可以接收来自客户端的调用请求。再通过Registry的rebind方法进行注册，使得客户端可以查找到。

客户端的实现就是首先从注册表中查找到远程接口的实现对象，再调用相应的方法即可。实际的调用虽然是在服务器端完成的，但是在客户端看来，这个接口中的方法就好像是在当前JVM中一样。这就是RMI的强大之处。
```
public class CalculatorClient {
    public void calculate(String expr) {
        try {
            Registry registry = LocateRegistry.getRegistry("localhost");
            Calculator calculator = (Calculator) registry.lookup("Calculator");
            String result = calculator.calculate(expr);
            System.out.println(result);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
} 
```
在运行的时候，需要首先通过rmiregistry命令来启动RMI中用到的注册表服务器。

为了通过Java的序列化机制来进行传输，远程接口中的方法的参数和返回值，要么是Java的基本类型，要么是远程对象，要么是实现了 Serializable接口的Java类。当客户端通过RMI注册表找到一个远程接口的时候，所得到的其实是远程接口的一个动态代理对象。当客户端调用其中的方法的时候，方法的参数对象会在序列化之后，传输到服务器端。服务器端接收到之后，进行反序列化得到参数对象。并使用这些参数对象，在服务器端调用实际的方法。调用的返回值Java对象经过序列化之后，再发送回客户端。客户端再经过反序列化之后得到Java对象，返回给调用者。这中间的序列化过程对于使用者来说是透明的，由动态代理对象自动完成。除了序列化之外，RMI还使用了动态类加载技术。当需要进行反序列化的时候，如果该对象的类定义在当前JVM中没有找到，RMI会尝试从远端下载所需的类文件定义。可以在RMI程序启动的时候，通过JVM参数java.rmi.server.codebase来指定动态下载Java类文件的URL。  

## [REST](https://zh.wikipedia.org/wiki/REST)

REST只是一种软件架构的风格，而不是一种协议或者其他。

REST基于HTTP协议，一般使用JSON传输数据。REST是面向资源的，资源由URI来表示。

以下解释参考自[理解RESTful架构](http://www.ruanyifeng.com/blog/2011/09/restful.html)

---
要理解RESTful架构，最好的方法就是去理解Representational State Transfer这个词组到底是什么意思，它的每一个词代表了什么涵义。如果你把这个名称搞懂了，也就不难体会REST是一种什么样的设计。

资源（Resources）

REST的名称"表现层状态转化"中，省略了主语。"表现层"其实指的是"资源"（Resources）的"表现层"。

所谓"资源"，就是网络上的一个实体，或者说是网络上的一个具体信息。它可以是一段文本、一张图片、一首歌曲、一种服务，总之就是一个具体的实在。你可以用一个URI（统一资源定位符）指向它，每种资源对应一个特定的URI。要获取这个资源，访问它的URI就可以，因此URI就成了每一个资源的地址或独一无二的识别符。

所谓"上网"，就是与互联网上一系列的"资源"互动，调用它的URI。

表现层（Representation）

"资源"是一种信息实体，它可以有多种外在表现形式。我们把"资源"具体呈现出来的形式，叫做它的"表现层"（Representation）。

比如，文本可以用txt格式表现，也可以用HTML格式、XML格式、JSON格式表现，甚至可以采用二进制格式；图片可以用JPG格式表现，也可以用PNG格式表现。

URI只代表资源的实体，不代表它的形式。严格地说，有些网址最后的".html"后缀名是不必要的，因为这个后缀名表示格式，属于"表现层"范畴，而URI应该只代表"资源"的位置。它的具体表现形式，应该在HTTP请求的头信息中用Accept和Content-Type字段指定，这两个字段才是对"表现层"的描述。

状态转化（State Transfer）

访问一个网站，就代表了客户端和服务器的一个互动过程。在这个过程中，势必涉及到数据和状态的变化。

互联网通信协议HTTP协议，是一个无状态协议。这意味着，所有的状态都保存在服务器端。因此，如果客户端想要操作服务器，必须通过某种手段，让服务器端发生"状态转化"（State Transfer）。而这种转化是建立在表现层之上的，所以就是"表现层状态转化"。

客户端用到的手段，只能是HTTP协议。具体来说，就是HTTP协议里面，四个表示操作方式的动词：GET、POST、PUT、DELETE。它们分别对应四种基本操作：GET用来获取资源，POST用来新建资源（也可以用于更新资源），PUT用来更新资源，DELETE用来删除资源。

综述

综合上面的解释，我们总结一下什么是RESTful架构：
（1）每一个URI代表一种资源；
（2）客户端和服务器之间，传递这种资源的某种表现层；
（3）客户端通过四个HTTP动词，对服务器端资源进行操作，实现"表现层状态转化"。

---

参考[RESTful API 设计指南](http://www.ruanyifeng.com/blog/2014/05/restful_api.html)设计Rest API

github的API设计就是REST风格的。

网上关于REST和PRC的争论有很多,总的来说有以下几个：

安全性上：SOAP安全性高于REST

成熟度上：SOAP在成熟度上优于REST

效率和易用性上：REST更胜一筹

## 参考

[你应该知道的 RPC 原理](http://blog.jobbole.com/92290/)

[RPC 是什么](http://blog.brucefeng.info/post/what-is-rpc)

[Web service是什么？](http://www.ruanyifeng.com/blog/2009/08/what_is_web_service.html)

[Java深度历险（十）——Java对象序列化与RMI](http://www.infoq.com/cn/articles/cf-java-object-serialization-rmi)