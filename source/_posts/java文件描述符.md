---
layout: post
title: java文件描述符
date: 2017-07-07 20:54:29
categories: 
- 技术
- 编程
tags: 
- java
- NIO
---

## 文件描述符

在Linux中，进程是通过文件描述符（file descriptors，简称fd）而不是文件名来访问文件的，文件描述符实际上是一个整数。

内核中，对应于**每个进程**都有一个文件描述符表，表示这个进程打开的所有文件。文件描述符就是这个表的索引。

文件描述表中每一项都是一个指针，指向一个用于描述打开的文件的数据块———file对象，file对象中描述了文件的打开模式，读写位置等重要信息。

{% asset_img filedescriptors.png file descriptors %}

<!-- more -->

当进程打开一个文件时，内核就会**创建一个新的file对象**。因此，我们在进程中使用多线程打开同一个文件，每个线程会有各自的文件描述符，每个线程也会有保存自己的读取位置，互不影响。

需要注意的是，file对象不是专属于某个进程的，不同进程的文件描述符表中的指针可以指向相同的file对象，从而共享这个打开的文件。比如，如果在调用fork之前父进程已经打开文件，则fork后子进程有一个父进程描述符表的副本。父子进程共享相同的打开文件集合，因此共享相同的文件位置。

file对象有引用计数，记录了引用这个对象的文件描述符个数，只有当引用计数为0时，内核才销毁file对象，因此某个进程关闭文件，不影响与之共享同一个file对象的进程。

每个file结构体都指向一个file_operations结构体，这个结构体的成员都是函数指针，指向实现各种文件操作的内核函数。比如在用户程序中read一个文件描述符，read通过系统调用进入内核，然后找到这个文件描述符所指向的file结构体，找到file结构体所指向的file_operations结构体，调用它的read成员所指向的内核函数以完成用户请求。在用户程序中调用lseek、read、write、ioctl、open等函数，最终都由内核调用file_operations的各成员所指向的内核函数完成用户请求。file_operations结构体中的release成员用于完成用户程序的close请求，之所以叫release而不叫close是因为它不一定真的关闭文件，而是减少引用计数，只有引用计数减到0才关闭文件。

file对象中包含一个指针，指向dentry对象。“dentry”是directory entry（目录项）的缩写，dentry对象代表一个独立的文件路径，如果一个文件路径被打开多次，那么会建立多个file对象，但它们都指向同一个dentry对象。为了减少读盘次数，内核缓存了目录的树状结构，称为dentry cache，其中每个节点是一个dentry结构体。

每个dentry结构体都有一个指针指向inode结构体。inode结构体保存着从磁盘inode读上来的信息。在上图的例子中，有两个dentry，分别表示/home/akaedu/a和/home/akaedu/b，它们都指向同一个inode，说明这两个文件互为硬链接。inode结构体中保存着从磁盘分区的inode读上来信息，例如所有者、文件大小、文件类型和权限位等。

每个进程刚刚启动的时候，文件描述符0是标准输入，1是标准输出，2是标准错误。如果此时去打开一个新的文件，它的文件描述符会是3。

## java中的FileDescriptor

在java中，有着与文件描述符对应的一个类对象：FileDescriptor。我们看一下FileDescriptor与Channel的关系：

FileInputStream.getChannel():

```java
public FileChannel getChannel() {
        synchronized (this) {
            if (channel == null) {
                channel = FileChannelImpl.open(fd, path, true, false, this);

                /*
                 * Increment fd's use count. Invoking the channel's close()
                 * method will result in decrementing the use count set for
                 * the channel.
                 */
                fd.incrementAndGetUseCount();
            }
            return channel;
        }
}
```

其中的`FileChannelImpl.open(fd, path, true, false, this)`参数fd就是FileDescriptor实例。

看一下他是怎么产生的：

```java
public FileInputStream(File file) throws FileNotFoundException {
        String name = (file != null ? file.getPath() : null);
        SecurityManager security = System.getSecurityManager();
        if (security != null) {
            security.checkRead(name);
        }
        if (name == null) {
            throw new NullPointerException();
        }
        if (file.isInvalid()) {
            throw new FileNotFoundException("Invalid file path");
        }
        fd = new FileDescriptor();
        fd.incrementAndGetUseCount();
        this.path = name;
        open(name);
}

static {
    initIDs();
}
```

注意到`initIDs()`这个静态方法：

```java
jfieldID fis_fd; /* id for jobject 'fd' in java.io.FileInputStream */

JNIEXPORT void JNICALL
Java_java_io_FileInputStream_initIDs(JNIEnv *env, jclass fdClass) {
    fis_fd = (*env)->GetFieldID(env, fdClass, "fd", "Ljava/io/FileDescriptor;");
}
```

在`FileInputStream`类加载阶段，`fis_fd`就被初始化了，`fid_fd`相当于是`FileInputStream.fd`字段的一个内存偏移量，便于在必要时操作内存给它赋值。

看一下FileDescriptor的实例化过程：

```java
public /**/ FileDescriptor() {
        fd = -1;
        handle = -1;
        useCount = new AtomicInteger();
}

static {
    initIDs();
}
```
FileDescriptor也有一个`initIDs`，他和`FileInputStream.initIDs`的方法类似，把设置`IO_fd_fdID`为`FileDescriptor.fd`字段的内存偏移量。

```java
/* field id for jint 'fd' in java.io.FileDescriptor */
jfieldID IO_fd_fdID;
/**************************************************************
 * static methods to store field ID's in initializers
 */
JNIEXPORT void JNICALL
Java_java_io_FileDescriptor_initIDs(JNIEnv *env, jclass fdClass) {
    IO_fd_fdID = (*env)->GetFieldID(env, fdClass, "fd", "I");
}
```

接下来再看`FileInputStream`构造函数中的`open(name)`方法，字面上看，这个方法打开了一个文件，他也是一个本地方法，open方法直接调用了fileOpen方法，fileOpen方法如下:

```java
void fileOpen(JNIEnv *env, jobject this, jstring path, jfieldID fid, int flags)
{
    WITH_PLATFORM_STRING(env, path, ps) {
        FD fd;
#if defined(__linux__) || defined(_ALLBSD_SOURCE)
        /* Remove trailing slashes, since the kernel won't */
        char *p = (char *)ps + strlen(ps) - 1;
        while ((p > ps) && (*p == '/'))
            *p-- = '\0';
#endif
        // 打开一个文件并获取到文件描述符
        fd = handleOpen(ps, flags, 0666);
        if (fd != -1) {
            SET_FD(this, fd, fid);
        } else {
            throwFileNotFoundException(env, path);
        }
    } END_PLATFORM_STRING(env, ps);
}
```

其中的handleOpen函数打开了一个文件描述符，相当于和文件建立了联系，并且将返回的文件描述符描述符赋值给了局部变量fd,然后调用了SET_FD宏:

```java
#define SET_FD(this, fd, fid) \
    if ((*env)->GetObjectField(env, (this), (fid)) != NULL) \
        (*env)->SetIntField(env, (*env)->GetObjectField(env, (this), (fid)),IO_fd_fdID, (fd))
```

注意到`IO_fd_fdID`，他是`FileDescriptor.fd`字段的内存偏移量。这个方法相当于设置`FileDescriptor.fd`的值等于文件描述符fd。

需要注意的是，FileDescriptor有两个字段：handle和fd，上面的代码表示我们只设置了fd字段为文件描述符，没有提到handle字段，这是因为：

在 win32 的实现中将 创建好的 文件句柄 设置到 handle 字段，在 linux 版本中则使用的是 FileDescriptor 的 fd 字段。

由此，可知 handle 和 fd 是共存的但并不同时在使用，在 win32 平台上使用 handle 字段，在 linux 平台上使用 fd 字段。

所以，FileInputStream打开文件的过程总结如下：

- 创建 FileDescriptor 对象

每一个 FileInputStream 有一个 FileDescriptor，代表这个流底层的文件的fd

- 调用 native 方法 open, 打开文件

- 内部调用 handleOpen 打开文件，返回文件描述符 fd

初始化 FileDescriptor 对象

- 将 文件描述符 fd 设置到，FileDescriptor 对象的 fd 中

## 再谈java文件读取

在[java-NIO-Buffer](http://yukai.space/2017/06/28/java-NIO-Buffer/)这篇文章中我们提到了`FileInputStream.read`方法，再来回顾一下：

```java
JNIEXPORT jint JNICALL  
Java_java_io_FileInputStream_readBytes(JNIEnv *env, jobject this,  
        jbyteArray bytes, jint off, jint len) {//除了前两个参数，后三个就是readBytes方法传递进来的，字节数组、起始位置、长度三个参数  
return readBytes(env, this, bytes, off, len, fis_fd);  
}

jint
readBytes(JNIEnv *env, jobject this, jbyteArray bytes,
          jint off, jint len, jfieldID fid)
{
    jint nread;
    char stackBuf[BUF_SIZE];
    char *buf = NULL;
    FD fd;
 
    if (IS_NULL(bytes)) {
        JNU_ThrowNullPointerException(env, NULL);
        return -1;
    }
 
    if (outOfBounds(env, off, len, bytes)) {
        JNU_ThrowByName(env, "java/lang/IndexOutOfBoundsException", NULL);
        return -1;
    }
 
    if (len == 0) {
        return 0;
    } else if (len > BUF_SIZE) {
        buf = malloc(len);// buf的分配
        if (buf == NULL) {
            JNU_ThrowOutOfMemoryError(env, NULL);
            return 0;
        }
    } else {
        buf = stackBuf;
    }
 
    fd = GET_FD(this, fid);
    if (fd == -1) {
        JNU_ThrowIOException(env, "Stream Closed");
        nread = -1;
    } else {
        nread = IO_Read(fd, buf, len);// buf是使用malloc分配的直接缓冲区，也就是堆外内存
        if (nread > 0) {
            (*env)->SetByteArrayRegion(env, bytes, off, nread, (jbyte *)buf);// 将直接缓冲区的内容copy到bytes数组中
        } else if (nread == JVM_IO_ERR) {
            JNU_ThrowIOExceptionWithLastError(env, "Read error");
        } else if (nread == JVM_IO_INTR) {
            JNU_ThrowByName(env, "java/io/InterruptedIOException", NULL);
        } else { /* EOF */
            nread = -1;
        }
    }
 
    if (buf != stackBuf) {
        free(buf);
    }
    return nread;
}
```
上述代码中的`fis_fd`是不是很眼熟？他就是`FileInputStream.fd`字段的内存偏移量。注意到`fd = GET_FD(this, fid);`这个方法，获取到其对应的文件描述符，然后使用该文件描述符读取文件内容，填充缓冲区。由此可见，java底层读取文件都是通过文件描述符来进行的。比如：

文章开始提到**每个进程刚刚启动的时候，文件描述符0是标准输入，1是标准输出，2是标准错误。如果此时去打开一个新的文件，它的文件描述符会是3**，FileDescriptor中的fd为0，1，2时也表示同样的意义。

```java
FileOutputStream fileOutputStream = new FileOutputStream(FileDescriptor.out);
fileOutputStream.write('hello world');// 控制台打印 hello world，因为fileOutputStream使用了标准输出的文件描述符
```

## 参考

[linux 文件描述符表 打开文件表 inode vnode](http://blog.csdn.net/kennyrose/article/details/7595013)

[linux中文件描述符fd和文件指针flip的理解](http://www.cnblogs.com/Jezze/archive/2011/12/23/2299861.html)

[JNI探秘--FileDescriptor、FileInputStream 解惑](https://vinoit.me/2016/09/14/JNI-explore-FileDescriptor-and-FileInputStream/)
