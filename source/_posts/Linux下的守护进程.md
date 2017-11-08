---
layout: post
title: Linux下的守护进程
date: 2017-10-01 08:47:51
categories: 
- 技术
- Linux
tags: linux
---

> 这两天在搭建VNC服务的时候，遇到一个简单的问题，却困扰了我有一会：网上的教程大部分是修改.service文件，然后启动服务，但是我发现使用vncserver这个命令也可以达到同样的目的，这两者之间有什么区别呢？查了一些资料，简单的做一个总结。

## 工作管理

一般情况下，我们可能会在命令行下这样启动一个程序，以新做的版本管理系统为例：

```
java -jar VersionManager.jar
```
<!-- more -->

现在，内网中的其他机器可以通过80端口访问本机提供的web服务了。一切都很正常。

注意到一个问题，新启动的程序独占了命令行窗口，并随时打印一些程序运行期间的log出来。
如果想在同一个命令行窗口再执行其他命令，那么需要Ctrl+c停止这个web服务才可以。

这个时候的web服务称为`前台任务`，一旦我们退出这个命令行窗口，该服务也随之关闭，无法访问。

如何将其变成一个后台执行的任务，从而不影响命令行再执行其他命令呢？

```
java -jar VersionManager.jar &
```

只要在命令的尾部加上符号&，启动的进程就会成为"后台任务"。"后台任务"有两个特点：

1. 继承当前 session （对话）的标准输出（stdout）和标准错误（stderr）。因此，后台任务的所有输出依然会同步地在命令行下显示。

2. 不再继承当前 session 的标准输入（stdin）。你无法向这个任务输入指令了。如果它试图读取标准输入，就会暂停执行（halt）。

所以，我们以上述方式启动web服务，他的运行日志依然会打印在屏幕上面。但是与前台任务的一个区别就是，现在可以在命令行执行其他命令了，所有的输出都会混杂在一起打印在屏幕上。

有没有办法解决这种问题呢？那就是重定向：

```
java -jar VersionManager.jar >info.log 2>&1 &
```

上述命令把web服务输出的标准输出和标准错误信息都重定向到了info.log这个文件，屏幕上不会再有任何的信息被打印出来了。你也可以像之前那样查看web服务的输出信息：

```
tail -f info.log
```

此时，web服务的输出又动态的在屏幕上打印出来了。

如果要让正在运行的"前台任务"变为"后台任务"，可以先按ctrl + z，然后执行bg命令。(让最近一个暂停的"后台任务"继续执行)

如何查看**当前session**有哪些后台任务在运行呢？

```
$ jobs -l //打印pid
[1]- 17000 运行中               nohup java -jar VersionManager.jar > logs/info.log 2>&1 &
[2]+ 22738 停止                  vim cron.log
```

将指定的后台任务变成前台执行：

```
fg 2 //继续编辑cron.log
```

最后做一个小结：

```
查看后台任务：jobs -l
将后台任务取回前台：fg number //number为任务号
暂停前台任务，并将任务放到后台：ctrl + z
暂停的后台任务继续执行：bg number //number为任务号
结束前台任务：ctrl + c
结束后台任务：kill pid //pid可以通过jobs -l进行查看
```

## 脱机管理

通过上面的内容，我们了解到如何将一个任务放在后台执行。后台任务都是基于当前session的，如果我们退出了当前的session(关闭了命令行窗口或执行exit)，后台任务还会执行吗？

> 想起了之前有个现场的技术支持人员打电话跟我反映，一个rest服务总是无规律的宕掉。刚开始我也想不通，后来才想到是上面提到的原因...

看一下session退出的时候发生了什么：

1. 用户准备退出 session

2. 系统向该 session 发出SIGHUP信号

3. session 将SIGHUP信号发给所有子进程

4. 子进程收到SIGHUP信号后，自动退出

上面的流程可以解释，随着session退出，前台任务也会结束。那么后台任务是否也会收到SIGHUP信号后退出呢？

这由 Shell 的huponexit参数决定的。

```
shopt | grep huponexit
```

执行上面的命令，就会看到huponexit参数的值。如果显示`off`，表示session 退出的时候，不会把SIGHUP信号发给"后台任务"，从而"后台任务"不会随着 session 一起退出。

但是，为了确保我们的web服务变成一个可靠的守护进程，我们应该显式的指出 session 退出的时候，不把SIGHUP信号发给"后台任务"：

### nohup

```
nohup java -jar VersionManager.jar &
```

`nohup`对`java -jar VersionManager.jar`命令做了几件事：

- 阻止SIGHUP信号发到这个进程。

- 关闭标准输入。该进程不再能够接收任何输入，即使运行在前台。

- 重定向标准输出和标准错误到文件nohup.out。

一般情况下，我们会重定向web服务的输出：

```
nohup java -jar VersionManager.jar >info.log 2>&1 &
```

至此，我们的web服务已经变成了一个可靠的守护进程。

### tmux

还有一种方法，那就是使用tmux。tmux可以在当前session里新建一个session。当前的session退出不会影响到新建的session。重新登录之后还可以连上之前建立的session。

```
// 新建 session
$ tmux new -s session_name

// 切换到指定 session
$ tmux attach -t session_name

// 列出所有 session
$ tmux list-sessions

// 退出当前 session，返回前一个 session 
$ tmux detach

// 杀死指定 session
$ tmux kill-session -t session-name
```

参考[如何使用Tmux提高终端环境下的效率](https://linux.cn/article-3952-1.html)

## systemd服务

> systemd 是 Linux 下的一款系统和服务管理器。Systemd 并不是一个命令，而是一组命令，涉及到系统管理的方方面面。

在centos7中，我们也许会使用systemd来管理我们的一些程序，比如ssh:

```
// 启动ssh服务
systemctl start sshd.service
// 设置ssh服务开机启动
systemctl enable sshd.service
...
```

我们也可以通过systemd来管理我们的守护进程，成为真正意义上的系统服务。

关于systemd的使用不再赘述，参考[Systemd (简体中文)](https://wiki.archlinux.org/index.php/systemd_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87))

## 参考

[Linux 守护进程的启动方法](http://www.ruanyifeng.com/blog/2016/02/linux-daemon.html)

