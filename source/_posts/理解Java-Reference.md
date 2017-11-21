---
layout: posts
title: 理解Java-Reference
date: 2017-11-21 09:28:46
categories: 
- 技术
- 编程
tags: 
- java
---
最近重读《深入理解Java虚拟机》，讲到Java中的几种引用类型，结合源码总结梳理一遍。

## 引用类型

JDK1.2之后，Java扩充了引用的概念，将引用分为强引用、软引用、弱引用和虚引用四种。

- 强引用

  类似于"Object a = new Object()"这类的引用，只要垃圾强引用存在，垃圾回收器就不会回收掉被引用的对象。

- 软引用

  对于软引用关联的对象，在系统将要发生内存溢出异常之前，会把这些对象列入垃圾回收范围中进行回收。如果这次回收还没有足够内存，则抛出内存异常。

  使用SoftReference类实现软引用

- 弱引用

  强度比软引用更弱，被弱引用关联的对象只能存活到下一次垃圾回收发生之前。当发生GC时，无论当前内存是否足够，都会回收掉只被弱引用关联的对象。

  使用WeakReference类实现弱引用

- 虚引用

  一个对象是否有虚引用的存在，完全不会对其生存时间构成影响，也无法通过虚引用取得一个对象的实例。为一个对象设置虚引用关联的唯一目的就是能够在这个对象被垃圾回收器回收掉后收到一个通知。

  使用PhantomReference类实现虚引用

<!-- more -->

## 使用场景

强引用代码中随处可见，对于其他几种引用则不太熟悉，他们有什么作用呢？

假设有这样一个需求：每次创建一个数据库Connection的时候，需要将用户信息User与之关联。典型的用法就是在一个全局的Map中存储Connection和User的映射。

```java
public class ConnManager {
    private Map<Connection,User> m = new HashMap<Connection,User>();

    public void setUser(Connection s, User u) {
        m.put(s, u);
    }
    public User getUser(Connection s) {
        return m.get(s);
    }
    public void removeUser(Connection s) {
        m.remove(s);
    }
}
```

这种方法的问题是User的生命周期与Connection挂钩，我们无法准确预支Connection在什么时候结束，所以需要在每个Connection关闭之后，手动从Map中移除键值对，否则Connection和User将一直被Map引用，即使Connection的生命周期已经结束了，GC也无法回收对应的Connection和User。这些对象留在内存中不受控制，可能会造成内存溢出。

那么，如何避免手动的从Map中删除对象呢？

利用 WeakHashMap 即可实现：

```java
public class ConnManager {
    private Map<Connection,User> m = new WeakHashMap<Connection,User>();

    public void setUser(Connection s, User u) {
        m.put(s, u);
    }
    public User getUser(Connection s) {
        return m.get(s);
    }
}
```

WeakHashMap 与 HashMap类似，但是在其内部，key是经过WeakReference包装的。使用WeakHashMap情况会变得怎样呢？

每当垃圾回收发生时，那些已经结束生命周期的Connection对象(没有强引用指向它)不受WeakHashMap中key(WeakReference)的影响，可以直接回收掉。同时，WeakHashMap利用ReferenceQueue(下文会提到) 可以做到删除那些已经被回收的Connection对应的User。是不是做到了内存的自动管理呢？

## 可达性分析算法

Java执行GC时，需要判断对象是否存活。判断一个对象是否存活使用了"可达性分析算法"。

基本思路就是通过一系列称为`GC Roots`的对象作为起点，从这些节点开始向下搜索，搜索所走过的路径称为引用链，当一个对象到GC Roots没有任何引用链相连，即从GC Roots到这个对象不可达时，证明此对象不可用。

{% asset_img keda.jpg 可达性分析算法 %}

可以作为GC Roots的对象包括：

- 虚拟机栈中引用的对象

- 方法区中类静态属性引用的对象

- 方法区中常量引用的对象

- 本地方法栈JNI引用的对象

往往到达一个对象的引用链会存在多条，垃圾回收时会依据两个原则来判断对象的可达性：

- 单一路径中，以最弱的引用为准

- 多路径中，以最强的引用为准

{% asset_img reachable.png 可达性分析算法 %}

## Reference && ReferenceQueue

SoftReference，WeakReference，PhantomReference拥有共同的父类Reference，看一下其内部实现：

Reference的构造函数最多可以接受两个参数：`Reference(T referent, ReferenceQueue<? super T> queue)`

referent：即Reference所包装的引用对象

queue：此Reference需要注册到的引用队列

ReferenceQueue本身提供队列的功能，ReferenceQueue对象同时保存了一个Reference类型的head节点，Reference封装了next字段，这样就是可以组成一个单向链表。

ReferenceQueue主要用来确认Reference的状态。Reference对象有四种状态：

- active

  GC会特殊对待此状态的引用，一旦被引用的对象的可达性发生变化（如失去强引用，只剩弱引用，可以被回收），GC会将引用放入pending队列并将其状态改为pending状态

- pending

  位于pending队列，等待ReferenceHandler线程将引用入队queue

- enqueue

  ReferenceHandler将引用入队queue

- inactive

  引用从queue出队后的最终状态，该状态不可变

Reference与ReferenceQueue之间是如何工作的呢？

Reference里有个静态字段pending，同时还通过静态代码块启动了Reference-handler thread。当一个Reference的referent被回收时，垃圾回收器会把reference添加到pending这个链表里，然后Reference-handler thread不断的读取pending中的reference，把它加入到对应的ReferenceQueue中。

当reference与referenQueue联合使用的主要作用就是当reference指向的referent回收时，提供一种通知机制，通过queue取到这些reference，来做额外的处理工作。

## PhantomReference的一个使用案例

上文提到 **当reference与referenQueue联合使用的主要作用就是当reference指向的referent回收时，提供一种通知机制，通过queue取到这些reference，来做额外的处理工作**。通过PhantomReference的一个例子来加深体会：用PhantomReference来自动关闭文件流

使用PhantomReference封装引用

```java
public class ResourcePhantomReference<T> extends PhantomReference<T> {

    private List<Closeable> closeables;

    public ResourcePhantomReference(T referent, ReferenceQueue<? super T> q, List<Closeable> resource) {
        super(referent, q);
        closeables = resource;
    }

    public void cleanUp() {
        if (closeables == null || closeables.size() == 0)
            return;
        for (Closeable closeable : closeables) {
            try {
                closeable.close();
                System.out.println("clean up:"+closeable);
            } catch (IOException e) {
                e.printStackTrace();
            }
        }
    }
}
```

守护者线程利用ReferenceQueue做自动清理

```java
public class ResourceCloseDeamon extends Thread {

    private static ReferenceQueue QUEUE = new ReferenceQueue();

    //保持对reference的引用,防止reference本身被回收
    private static List<Reference> references=new ArrayList<>();
    @Override
    public void run() {
        this.setName("ResourceCloseDeamon");
        while (true) {
            try {
                ResourcePhantomReference reference = (ResourcePhantomReference) QUEUE.remove();
                reference.cleanUp();
                references.remove(reference);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }
    }

    public static void register(Object referent, List<Closeable> closeables) {
        references.add(new ResourcePhantomReference(referent,QUEUE,closeables));
    }
}
```

封装的文件操作

```java
public class FileOperation {

    private FileOutputStream outputStream;

    private FileInputStream inputStream;

    public FileOperation(FileInputStream inputStream, FileOutputStream outputStream) {
        this.outputStream = outputStream;
        this.inputStream = inputStream;
    }

    public void operate() {
        try {
            inputStream.getChannel().transferTo(0, inputStream.getChannel().size(), outputStream.getChannel());
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}
```

测试

```java
ublic class PhantomTest {

    public static void main(String[] args) throws Exception {
        //打开回收
        ResourceCloseDeamon deamon = new ResourceCloseDeamon();
        deamon.setDaemon(true);
        deamon.start();

        // touch a.txt b.txt
        // echo "hello" > a.txt

        //保留对象,防止gc把stream回收掉,其不到演示效果
        List<Closeable> all=new ArrayList<>();
        FileInputStream inputStream;
        FileOutputStream outputStream;

        for (int i = 0; i < 100000; i++) {
            inputStream = new FileInputStream("/Users/robin/a.txt");
            outputStream = new FileOutputStream("/Users/robin/b.txt");
            FileOperation operation = new FileOperation(inputStream, outputStream);
            operation.operate();
            TimeUnit.MILLISECONDS.sleep(100);

            List<Closeable>closeables=new ArrayList<>();
            closeables.add(inputStream);
            closeables.add(outputStream);
            all.addAll(closeables);
            ResourceCloseDeamon.register(operation,closeables);
            //用下面命令查看文件句柄,如果把上面register注释掉,就会发现句柄数量不断上升
            //jps | grep PhantomTest | awk '{print $1}' |head -1 | xargs  lsof -p  | grep /User/robin
            System.gc();

        }
    }
}
```

参考自[Java Reference详解](https://my.oschina.net/robinyao/blog/829983)

## WeakHashMap

WeakHashMap实现原理很简单，它除了实现标准的Map接口，里面的机制也和HashMap的实现类似。从它entry子类中可以看出，它的key是用WeakReference封装的。

WeakHashMap里声明了一个queue，Entry继承WeakReference,构造函数中用key和queue关联构造一个weakReference。当key所封装的对象被GC回收后，GC自动将key注册到queue中。

WeakHashMap中有代码检测这个queue，取出其中的元素，找到WeakHashMap中相应的键值对进行remove。这部分代码就是expungeStaleEntries方法：

```java
private void expungeStaleEntries() {
    for (Object x; (x = queue.poll()) != null; ) {
        synchronized (queue) {
            @SuppressWarnings("unchecked")
                Entry<K,V> e = (Entry<K,V>) x;
            int i = indexFor(e.hash, table.length);
            Entry<K,V> prev = table[i];
            Entry<K,V> p = prev;
            while (p != null) {
                Entry<K,V> next = p.next;
                if (p == e) {
                    if (prev == e)
                        table[i] = next;
                    else
                        prev.next = next;
                    // Must not null out e.next;
                    // stale entries may be in use by a HashIterator
                    e.value = null; // Help GC
                    size--;
                    break;
                }
                prev = p;
                p = next;
            }
        }
    }
}
```

这段代码会在resize,getTable,size里执行，清除失效的entry。

## FinalReference

在Reference的子类中，还有一个名为FinalReference的类，这个类用来做什么呢？

FinalReference仅仅继承了Reference，没有做其他的逻辑，只是将访问权限声明为package，所以我们不能够直接使用它。

需要关注的是其子类 Finalizer，看一下他的实现：

首先，哪些类对象是Finalizer reference类型的referent呢？ 只要类覆写了Object 上的finalize方法，方法体非空。那么这个类的实例都会被Finalizer引用类型引用。这个工作是由虚拟机完成的，对于我们来说是透明的。

Finalizer 中有两个字段需要关注：

queue：`private static ReferenceQueue queue = new ReferenceQueue()` 即上文提到的ReferenceQueue，用来实现通知

unfinalized：`private static Finalizer unfinalized` 维护了一个未执行finalize方法的reference列表。维护静态字段unfinalized的目的是为了一直保持对未未执行finalize方法的reference的强引用，防止被gc回收掉。

在Finalizer的构造函数中通过add()方法把Finalizer引用本身加入到unfinalized列表中，同时关联finalizee和queue,实现通知机制。

Finalizer静态代码块里启动了一个deamon线程 FinalizerThread，FinalizerThread run方法不断的从queue中去取Finalizer类型的reference，然后调用Finalizer的runFinalizer方法，该方法最后执行了referent所重写的finalize方法。

```java
private void runFinalizer(JavaLangAccess jla) {
    synchronized (this) {
        if (hasBeenFinalized()) return;
        remove();
    }
    try {
        Object finalizee = this.get();
        if (finalizee != null && !(finalizee instanceof java.lang.Enum)) {
            jla.invokeFinalize(finalizee);
            /* Clear stack slot containing this variable, to decrease
               the chances of false retention with a conservative GC */
            finalizee = null;
        }
    } catch (Throwable x) { }
    super.clear();
}
```

观察上面的代码，`hasBeenFinalized()`判断了finalize是否已经执行，如果执行，则把这个referent从unfinalized队列中移除。**所以，任何一个对象的finalize方法只会被系统自动调用一次。**当下一次GC发生时，由于unfinalized已经不再持有该对象的referent，故该对象被直接回收掉。

从上面的过程也可以看出，覆盖了finalize方法的对象至少需要两次GC才可能被回收。第一次GC把覆盖了finalize方法的对象对应的Finalizer reference加入referenceQueue等待FinalizerThread来执行finalize方法。第二次GC才有可能释放finalizee对象本身，前提是FinalizerThread已经执行完finalize方法了，并把Finalizer reference从Finalizer静态unfinalized链表中剔除，因为这个链表和Finalizer reference对finalizee构成的是一个强引用。

## 参考

[Java Reference详解](https://my.oschina.net/robinyao/blog/829983)