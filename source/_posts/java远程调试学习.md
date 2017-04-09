---
layout: post
title: java远程调试学习
date: 2016-12-07 21:55:48
categories: 编程
tags: 
- java 
- 调试
---

> 集群前后台协议需要做一些修改，我负责jdbc这边的修改。按照协议内容修改完代码之后却面临一个测试的问题：修改后的后台又部署在北京，但北京并不是所有的机器都对天津这边开放，只给提供一台机器A，就是集群的服务器。
> 这样的话,就无法创建节点的连接，测试没有办法进行。

> 一开始用了最简单的办法，把打好的jar包通过远程ssh放到A上面，再通过ssh去跑用例，打印结果看看正确与否。但是这样的效率真的太低了，每做一次修改都要打包、部署、运行、分析log。于是借这个机会学习一下java程序的远程调试。以下为总结。


## 一些概念

JDPA: java平台调试架构

JVMTI: JVM端调试接口

JDI: java端调试接口

JDWP: java调试网络协议

{% asset_img jdpa.png jdpa %}

JPDA 定义了一套如何开发调试工具的接口和规范。

JPDA 由三个独立的模块 JVMTI、JDWP、JDI 组成。

调试者通过 JDI 发送接受调试命令。

JDWP 定义调试者和被调试者交流数据的格式。

JVMTI 可以控制当前虚拟机运行状态。

上图中的前端工具就是我们要用到的调试工具。如JDB、Eclipse等等。这些工具实现了JDI接口，通过这些工具我们可以达到在命令行或者图形界面下调试的目的。

关于这部分，只是简单的了解一下概念，更多的关于JDPA的介绍：[JDPA体系](http://www.ibm.com/developerworks/cn/views/java/libraryview.jsp?search_by=%E6%B7%B1%E5%85%A5+Java+%E8%B0%83%E8%AF%95%E4%BD%93%E7%B3%BB)

<!-- more -->

## 使用JDB进行本地调试

JDB 是jdk自带的一个调试工具，用于命令行下调试java程序

jdb.exe就位于jdk安装目录的bin目录下，安装好jdk并设置好环境变量之后就可以愉快的使用jdb了。

```
C:\Users\kyu>jdb -help
用法: jdb <options> <class> <arguments>

其中, 选项包括:
    -help             输出此消息并退出
    -sourcepath <由 ";" 分隔的目录>
                      要在其中查找源文件的目录
    -attach <address>
                      使用标准连接器附加到指定地址处正在运行的 VM
    -listen <address>
                      等待正在运行的 VM 使用标准连接器在指定地址处连接
    -listenany
                      等待正在运行的 VM 使用标准连接器在任何可用地址处连接
    -launch
                      立即启动 VM 而不是等待 'run' 命令
    -listconnectors   列出此 VM 中的可用连接器
    -connect <connector-name>:<name1>=<value1>,...
                      使用所列参数值通过指定的连接器连接到目标 VM
    -dbgtrace [flags] 输出信息供调试jdb
    -tclient          在 HotSpot(TM) 客户机编译器中运行应用程序
    -tserver          在 HotSpot(TM) 服务器编译器中运行应用程序

转发到被调试进程的选项:
    -v -verbose[:class|gc|jni]
                      启用详细模式
    -D<name>=<value>  设置系统属性
    -classpath <由 ";" 分隔的目录>
                      列出要在其中查找类的目录
    -X<option>        非标准目标 VM 选项

<class> 是要开始调试的类的名称
<arguments> 是传递到 <class> 的 main() 方法的参数

要获得命令的帮助, 请在jdb提示下键入 'help'
```

上面是启动JDB的语法说明。

现假设运行程序的工程目录如下：

```
JDBTest
  |----bin(编译生成的class文件)
  |     |----*.class
  |----src(源文件)
  |     |----*.java
  |----lib(依赖的第三方jar)
  |     |----*.jar
```

开始启动JDB调试：

Y:\project\JavaProject\JDBTest>jdb -classpath ./bin/;./lib/* -sourcepath ./src/ test.JDBTest

`注意，如果有多个文件，windows下使用 ";" 分隔每个文件或目录，Linux下使用 ":" 分隔每个文件或目录`

`-classpath` 指定了类路径，`-sourcepath` 指定了源文件的路径

回车，出现如下信息：

```
Y:\project\JavaProject\JDBTest>jdb -classpath ./bin/;./lib/* -sourcepath ./src/ test.JDBTest
正在初始化jdb...
> 
```
此时，JDB调试器等待用户的输入，输入`help`，出现如下信息：

```
Y:\project\JavaProject\JDBTest>jdb -classpath ./bin/;./lib/* -sourcepath ./src/ test.JDBTest
正在初始化jdb...
> help
** 命令列表 **
connectors                -- 列出此 VM 中可用的连接器和传输

run [class [args]]        -- 开始执行应用程序的主类

threads [threadgroup]     -- 列出线程
thread <thread id>        -- 设置默认线程
suspend [thread id(s)]    -- 挂起线程 (默认值: all)
resume [thread id(s)]     -- 恢复线程 (默认值: all)
where [<thread id> | all] -- 转储线程的堆栈
wherei [<thread id> | all]-- 转储线程的堆栈, 以及 pc 信息
up [n frames]             -- 上移线程的堆栈
down [n frames]           -- 下移线程的堆栈
kill <thread id> <expr>   -- 终止具有给定的异常错误对象的线程
interrupt <thread id>     -- 中断线程

print <expr>              -- 输出表达式的值
dump <expr>               -- 输出所有对象信息
eval <expr>               -- 对表达式求值 (与 print 相同)
set <lvalue> = <expr>     -- 向字段/变量/数组元素分配新值
locals                    -- 输出当前堆栈帧中的所有本地变量

classes                   -- 列出当前已知的类
class <class id>          -- 显示已命名类的详细资料
methods <class id>        -- 列出类的方法
fields <class id>         -- 列出类的字段

threadgroups              -- 列出线程组
threadgroup <name>        -- 设置当前线程组

stop in <class id>.<method>[(argument_type,...)]
                          -- 在方法中设置断点
stop at <class id>:<line> -- 在行中设置断点
clear <class id>.<method>[(argument_type,...)]
                          -- 清除方法中的断点
clear <class id>:<line>   -- 清除行中的断点
clear                     -- 列出断点
catch [uncaught|caught|all] <class id>|<class pattern>
                          -- 出现指定的异常错误时中断
ignore [uncaught|caught|all] <class id>|<class pattern>
                          -- 对于指定的异常错误, 取消 'catch'
watch [access|all] <class id>.<field name>
                          -- 监视对字段的访问/修改
unwatch [access|all] <class id>.<field name>
                          -- 停止监视对字段的访问/修改
trace [go] methods [thread]
                          -- 跟踪方法进入和退出。
                          -- 除非指定 'go', 否则挂起所有线程
trace [go] method exit | exits [thread]
                          -- 跟踪当前方法的退出, 或者所有方法的退出
                          -- 除非指定 'go', 否则挂起所有线程
untrace [methods]         -- 停止跟踪方法进入和/或退出
step                      -- 执行当前行
step up                   -- 一直执行, 直到当前方法返回到其调用方
stepi                     -- 执行当前指令
next                      -- 步进一行 (步过调用)
cont                      -- 从断点处继续执行

list [line number|method] -- 输出源代码
use (或 sourcepath) [source file path]
                          -- 显示或更改源路径
exclude [<class pattern>, ... | "none"]
                          -- 对于指定的类, 不报告步骤或方法事件
classpath                 -- 从目标 VM 输出类路径信息

monitor <command>         -- 每次程序停止时执行命令
monitor                   -- 列出监视器
unmonitor <monitor#>      -- 删除监视器
read <filename>           -- 读取并执行命令文件

lock <expr>               -- 输出对象的锁信息
threadlocks [thread id]   -- 输出线程的锁信息

pop                       -- 通过当前帧出栈, 且包含当前帧
reenter                   -- 与 pop 相同, 但重新进入当前帧
redefine <class id> <class file name>
                          -- 重新定义类的代码

disablegc <expr>          -- 禁止对象的垃圾收集
enablegc <expr>           -- 允许对象的垃圾收集

!!                        -- 重复执行最后一个命令
<n> <command>             -- 将命令重复执行 n 次
# <command>               -- 放弃 (无操作)
help (或 ?)               -- 列出命令
version                   -- 输出版本信息
exit (或 quit)            -- 退出调试器

<class id>: 带有程序包限定符的完整类名
<class pattern>: 带有前导或尾随通配符 ('*') 的类名
<thread id>: 'threads' 命令中报告的线程编号
<expr>: Java(TM) 编程语言表达式。
支持大多数常见语法。

可以将启动命令置于 "jdb.ini" 或 ".jdbrc" 中
位于 user.home 或 user.dir 中
>
```
上面的帮助信息说明了如何进行JDB调试，解释一下其中的几个：

step: -- 执行当前行 相当于Eclipse中的F5

step up: -- 一直执行, 直到当前方法返回到其调用方 相当于Eclipse中的F7

next: -- 步进一行 (步过调用) 相当于Eclipse中的F6

cont: -- 从断点处继续执行 相当于Eclipse中的F8

此时，继续输入：

```
> stop at test.JDBTest:7
正在延迟断点test.JDBTest:7。
将在加载类后设置。
> run
运行test.JDBTest
设置未捕获的java.lang.Throwable
设置延迟的未捕获的java.lang.Throwable
>
VM 已启动: 设置延迟的断点test.JDBTest:7

断点命中: "线程=main", test.JDBTest.main(), 行=7 bci=0
7               JDBTest jdbTest = new JDBTest();

main[1]
```
stop at test.JDBTest:7 表示在这个类文件的第7行处打一个断点

接着，输入run，就开始进入调试步骤了。现在可以输入上面帮助中的语法来了解当前程序的执行情况了。一试便知

`注意, 若想要在调试时能够正常输出调试信息如变量值等等，需要在编译java文件时指定 -g 参数，否则无法获得其运行时的调试信息`

另外，使用list可以打印当前断点处的源代码，如果没有在启动JDB时指定源代码路径 -sourcepath ./src/ ，那么会提示没有源代码信息，无法输出。此时可以使用命令 use ./src/ 来指定源代码路径，再使用list命令时可以正常打印了。

以上就是使用JDB调试本地程序的方法，具体的使用可根据实际情况参照语法说明去执行。

## 使用JDB进行远程调试

如果程序不是运行在本机，而是在其他机器或者现场的时候，可以使用java提供的远程调试功能。

假设程序现运行在主机 192.168.101.72 这台机器上，该机器为linux环境，且只可以通过ssh作为一个普通用户连接。我们想要在自己的机器上调试运行在192.168.101.72这台机器上的程序。

### 启动要调试的程序

在192.168.101.72这台主机上以下面的方式启动java程序：还是以JDBTest为例

`java -Xdebug -Xrunjdwp:transport=dt_socket,server=y,address=8899 -classpath ./bin/:./lib/*  test.JDBTest`

此时，命令行输出

`Listening for transport dt_socket at address: 8899`

并处于等待状态

下面是几个参数的解释：

-Xdebug 启用调试特性。 

-Xrunjdwp:<sub-options> 在目标 VM 中加载 JDWP 实现。它通过传输和 JDWP 协议与独立的调试器应用程序通信。下面介绍一些特定的子选项。
从 Java V5 开始，您可以使用 -agentlib:jdwp 选项，而不是 -Xdebug 和 -Xrunjdwp。但如果连接到 V5 以前的 VM，只能选择 -Xdebug 和 -Xrunjdwp。下面简单描述 -Xrunjdwp 子选项。

transport 这里通常使用套接字传输。但是在 Windows 平台上也可以使用共享内存传输。

server 如果值为 y，目标应用程序监听将要连接的调试器应用程序。否则，它将连接到特定地址上的调试器应用程序。

address 这是连接的传输地址。如果服务器为 n，将尝试连接到该地址上的调试器应用程序。否则，将在这个端口监听连接。

suspend 如果值为 y，目标 VM 将暂停，直到调试器应用程序进行连接。

### 本机连接远程程序并启动调试

在本机上命令行下输入：

`jdb -connect com.sun.jdi.SocketAttach:hostname=192.168.101.72,port=8899`

然后就进入了调试界面，你可以像调试本机程序那样使用JDB的一些命令来调试了。当退出调试程序时，远程主机上的程序也就退出了。


## 使用Eclipse进行远程调试

可以使用Eclipse进行远程调试，就上上面使用JDB一样。

### 启动要调试的程序

与JDB远程调试一样，启动远程主机上的程序：

`java -Xdebug -Xrunjdwp:transport=dt_socket,server=y,address=8899 -classpath ./bin/:./lib/*  test.JDBTest`

### 本机启动Eclipse进行调试

首先要右键工程->java compiler

{% asset_img setting.png jdpa %}

上图中的几个选项最好全部打勾，否则调试时会出现无法打断点或者获取不到行号等问题(关于这几个选项的含义在之前的总结中有提到)

接着，右键工程->Debug As->Run Configurations, 在出现的对话框中选择Remote Java Application, 右键->New, 出现如下界面：

{% asset_img remote.png jdpa %}

在Connect页中，选择对应的java 工程，Connection Type选择 Socket Attach，然后填写远程主机的ip和端口，这里应该填写192.168.101.72和8899。
在Source页中可以添加源代码，如用到的第三方jar的源代码或者引用的工程，调试时就可以进入到这部分代码查看。在Common页可以设置编码的配置。

接下来点击Debug按钮，就可以愉快的在本机调试远程程序了，就像调试本地程序那样。只不过可能有一点一点慢，不过比打Log的方式要好很多了。

## 参考

[使用 Eclipse 远程调试 Java 应用程序](https://www.ibm.com/developerworks/cn/opensource/os-eclipse-javadebug/)

[JDB的简单使用](http://www.ibm.com/developerworks/cn/java/joy-jdb/)

[深入 Java 调试体系: 第 1 部分，JPDA 体系概览 ](https://www.ibm.com/developerworks/cn/java/j-lo-jpda1/)
