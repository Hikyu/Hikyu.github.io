---
layout: post
title: Java-NIO-Reactor
date: 2017-09-13 09:53:08
categories: 
- 技术
- 编程
tags: 
- java
- NIO
---

>接着学习java-NIO。这次要从宏观架构上来学习NIO，并涉及到一个模型：Reactor线程模型。

## 传统的BIO模式

{% asset_img bio.png bio %}

<!-- more -->

```java
class Server {
    public static void main() {
        ExecutorService executor = Excutors.newFixedThreadPollExecutor(100);//线程池

        ServerSocket serverSocket = new ServerSocket();
        serverSocket.bind(8088);
        while(!Thread.currentThread.isInturrupted()){//主线程死循环等待新连接到来
            Socket socket = serverSocket.accept();
            executor.submit(new ConnectIOnHandler(socket));//为新的连接创建新的线程
        }
    }
    static class ConnectIOnHandler implements Runnable {
        private Socket socket;
        public ConnectIOnHandler(Socket socket){
           this.socket = socket;
        }
        public void run(){
          while(!Thread.currentThread.isInturrupted()&&!socket.isClosed()){
              String someThing = socket.read();//读取数据
              if(someThing!=null){
                 ......//处理数据
                 socket.write()....//写数据
              }

          }
        }
    }
}
```

上面的代码中，我们在主线程中处理客户端的连接请求，然后为每个建立的连接分配一个线程去执行。socket.read()、socket.write()是同步阻塞的，我们开启了多线程，就可以让CPU去处理更多的连接，这也是多线程的本质：

1. 利用了多核的并行处理能力

2. 当io阻塞系统，但CPU空闲时，利用多线程使用CPU资源

上面的方案也有其致命缺陷，因为其本质还是依赖线程:

1. 线程创建和销毁的代价很高

2. 线程很占内存

3. 线程的切换带来的资源消耗。有可能恰好轮到一个线程的时间片，但此时这个线程被io阻塞，这时会发生线程切换(无意义的损耗)

4. 上面的线程池定义了100个线程，意味着同时只能为100个用户服务。倘若服务器同故障节点通信，由于其io是阻塞的，如果所有可用线程被故障节点阻塞，那么新的请求在队列中排队,直到连接超时。

所以，当面对数十万的连接请求，传统的BIO是无能为力的。

## NIO工作原理

回顾前面的学习内容 [Linux网络IO模型](http://yukai.space/2017/07/10/Linux%E7%BD%91%E7%BB%9CIO%E6%A8%A1%E5%9E%8B/)

{% asset_img io.png io %}

BIO的read过程：发起系统调用，试图从内核空间读取数据到用户空间，如果数据没有就绪(数据还没有从硬件拷贝到内核)，一直阻塞，直到返回数据

NIO的处理过程：发起系统调用，试图从内核空间读取数据到用户空间，如果数据没有就绪，直接返回0，永远也不会阻塞

需要注意的是：

1. 从内核拷贝数据到用户空间这个io操作是阻塞的，而且需要消耗CPU(性能非常高，基本不耗时)

2. BIO等待内核数据就绪的过程是空等，不需要CPU 

## Reactor与NIO相结合

所谓的Reactor模式，核心就是事件驱动，或者j叫回调的方式。这种方式就是，应用业务向一个中间人注册一个回调（event handler），当IO就绪后，就这个中间人产生一个事件，并通知此handler进行处理。

那么由谁来充当这个中间人呢？是由一个不断等待和循环的单独进程（线程）来做这件事，它接受所有handler的注册，并负责先操作系统查询IO是否就绪，在就绪后就调用指定handler进行处理，这个角色的名字就叫做Reactor。

回想一下 [Linux网络IO模型](http://yukai.space/2017/07/10/Linux%E7%BD%91%E7%BB%9CIO%E6%A8%A1%E5%9E%8B/) 中提到的 IO复用，一个线程可以同时处理多个Connection，是不是正好契合Reactor的思想。所以，在java中可以使用NIO来实现Reactor模型。

### 单线程Reactor

{% asset_img single_reactor.jpg 单线程Reactor %}

- Reactor：负责响应事件，将事件分发给绑定了该事件的Handler处理；

- Handler：事件处理器，绑定了某类事件，负责执行对应事件的Task对事件进行处理；

- Acceptor：Handler的一种，绑定了connect事件。当客户端发起connect请求时，Reactor会将accept事件分发给Acceptor处理。

看一下其对应的实现：

```java
class Reactor implements Runnable {
    final Selector selector;
    final ServerSocketChannel serverSocket;
    Reactor(int port) throws IOException { //Reactor初始化
        selector = Selector.open();
        serverSocket = ServerSocketChannel.open();
        serverSocket.socket().bind(new InetSocketAddress(port));
        serverSocket.configureBlocking(false); //非阻塞
        SelectionKey sk = serverSocket.register(selector, SelectionKey.OP_ACCEPT); //分步处理,第一步,接收accept事件
        sk.attach(new Acceptor()); //attach callback object, Acceptor
    }

    public void run() { 
        try {
            while (!Thread.interrupted()) {
                selector.select();
                Set selected = selector.selectedKeys();
                Iterator it = selected.iterator();
                while (it.hasNext())
                    dispatch((SelectionKey)(it.next()); //Reactor负责dispatch收到的事件
                selected.clear();
            }
        } catch (IOException ex) { /* ... */ }
    }

    void dispatch(SelectionKey k) {
        Runnable r = (Runnable)(k.attachment()); //调用之前注册的callback对象
        if (r != null)
            r.run();
    }

    class Acceptor implements Runnable { // inner
        public void run() {
            try {
                SocketChannel c = serverSocket.accept();
                if (c != null)
                new Handler(selector, c);
            }
            catch(IOException ex) { /* ... */ }
        }
    }
}

final class Handler implements Runnable {
    final SocketChannel socket;
    final SelectionKey sk;
    ByteBuffer input = ByteBuffer.allocate(MAXIN);
    ByteBuffer output = ByteBuffer.allocate(MAXOUT);
    static final int READING = 0, SENDING = 1;
    int state = READING;

    Handler(Selector sel, SocketChannel c) throws IOException {
        socket = c; c.configureBlocking(false);
        // Optionally try first read now
        sk = socket.register(sel, 0);
        sk.attach(this); //将Handler作为callback对象
        sk.interestOps(SelectionKey.OP_READ); //第二步,接收Read事件
        sel.wakeup();
    }
    boolean inputIsComplete() { /* ... */ }
    boolean outputIsComplete() { /* ... */ }
    void process() { /* ... */ }

    public void run() {
        try {
            if (state == READING) read();
            else if (state == SENDING) send();
        } catch (IOException ex) { /* ... */ }
    }

    void read() throws IOException {
        socket.read(input);
        if (inputIsComplete()) {
            process();
            state = SENDING;
            // Normally also do first write now
            sk.interestOps(SelectionKey.OP_WRITE); //第三步,接收write事件
        }
    }
    void send() throws IOException {
        socket.write(output);
        if (outputIsComplete()) sk.cancel(); //write完就结束了, 关闭select key
    }
}
```

NIO由原来的阻塞读写（占用线程）变成了单线程轮询事件，找到可以进行读写的网络描述符进行读写。除了事件的轮询是阻塞的（没有可干的事情必须要阻塞），剩余的I/O操作都是纯CPU操作，没有必要开启多线程。

缺点：

1. 一个连接里完整的网络处理过程一般分为accept、read、decode、process(compute)、encode、send这几步，如果在process这个过程中需要处理大量的耗时业务，比如连接DB或者进行耗时的计算等，整个线程都被阻塞，无法处理其他的链路

2. 单线程，不能充分利用多核处理器

3. 单线程处理I/O的效率确实非常高，没有线程切换，只是拼命的读、写、选择事件。但是如果有成千上万个链路，即使不停的处理，一个线程也无法支撑

4. 单线程，一旦线程意外进入死循环或者抛出未捕获的异常，整个系统就挂掉了

对于缺点1，通常的解决办法是将decode、process、encode扔到后台业务线程池中执行，避免阻塞reactor。但对于缺点2、3、4，单线程的reactor是无能为力的。

### 多线程的Reactor

{% asset_img muti_reactor.jpg 多线程Reator %}

- 有专门一个reactor线程用于监听服务端ServerSocketChannel，接收客户端的TCP连接请求；

- 网络IO的读/写操作等由一个worker reactor线程池负责，由线程池中的NIO线程负责监听SocketChannel事件，进行消息的读取、解码、编码和发送。

- 一个NIO线程可以同时处理N条链路，但是一个链路只注册在一个NIO线程上处理，防止发生并发操作问题。

注意，socketchannel、selector、thread三者的对应关系是：

socketchannel只能注册到一个selector上，但是一个selector可以被多个socketchannel注册；

selector与thread一般为一一对应。

```java
Selector[] selectors; // 一个selector对应一个线程
int next = 0;
class Acceptor {
    public synchronized void run() { ...
        Socket connection = serverSocket.accept();
        if (connection != null)
            new Handler(selectors[next], connection);
        if (++next == selectors.length) next = 0;
    }
}
```

### 主从多线程Reactor

{% asset_img accpetor_muti_reactor.jpg 主从多线程Reactor %}

在绝大多数场景下，Reactor多线程模型都可以满足性能需求；但是在极个别特殊场景中，一个NIO线程负责监听和处理所有的客户端连接可能会存在性能问题。比如，建立连接时需要进行复杂的验证和授权工作等。

- 服务端用于接收客户端连接的不再是个1个单独的reactor线程，而是一个boss reactor线程池；

- 服务端启用多个ServerSocketChannel监听不同端口时，每个ServerSocketChannel的监听工作可以由线程池中的一个NIO线程完成。

### NIO实战

- 参考老外写的一个 Java-NIO-Server：[Java NIO: Non-blocking Server](http://tutorials.jenkov.com/java-nio/non-blocking-server.html)，代码在  [github上](https://github.com/jjenkov/java-nio-server)。不错的一个参考，解决了NIO中半包粘包的问题，但是代码可读性不高；

- [另外一个NIO-Server](https://www.ibm.com/developerworks/cn/java/l-niosvr/nioserver.zip)，代码比较简单，可读性较高，代码风格值得学习。但避开了半包粘包的问题，也不算是正真意义上的Reactor模型。

## 参考

[Scalable IO in Java](http://gee.cs.oswego.edu/dl/cpjslides/nio.pdf)

[netty学习系列：NIO Reactor模型 & Netty线程模型](http://www.jianshu.com/p/38b56531565d)

[Java NIO浅析](https://tech.meituan.com/nio.html)