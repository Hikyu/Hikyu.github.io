---
layout: post
title: ssh的两种用法
date: 2017-02-23 20:05:03
categories: 
- 技术
- Linux
tags:
- linux
---
> 工作中在远程主机上进行一些操作时，经常使用ssh进行远程登录。后来使用github时，也会用到ssh。其中涉及到了ssh的两种用法，记录一下~

> 本文主要参考自阮一峰老师的博客：[SSH原理与运用（一）：远程登录](http://www.ruanyifeng.com/blog/2011/12/ssh_remote_login.html)

ssh是每台linux机器的标准配置。ssh是一种协议，SSH在计算机之间构建网络连接，确保连接双方身份的真实性，同时，它还保证在此连接上传送的数据到达时不会被人更改，不会被他人窃听。

ssh有多种实现，我们一般使用的是openssh，这是一款免费开源的ssh工具。一般在我们使用的linux发行版中，已经预设了这个软件了，所以可以直接使用它。如果是在windows中使用ssh客户端连接远程linux ssh服务，
我使用一款名为MobaXterm的工具。

<!-- more -->
## 密码登录

这是我们使用远程linux机器时最一般的登录方式。使用user这个用户登录到主机host:

ssh user@host

ssh默认端口是22，如果远程主机ssh服务端口不是22的话，可以通过-p参数修改连接端口：

ssh -p 8899 user@host

整个的登录过程：

1.远程主机收到客户端的登录请求，把自己的公钥发给用户。

2.客户端使用这个公钥，将登录密码加密后，发送回来。

3.远程主机用自己的私钥，解密登录密码，如果密码正确，就同意客户端登录。

这样的登录方式有一个问题，那就是如果有人截获了客户端的登录请求（比如使用公共WiFi），然后将自己的公钥发给了客户端，就可以冒充远程主机获取客户端的密码了。
Https协议是有CA证书中心作公证的，ssh协议并不存在这样的机构，所以就有中间人攻击的风险。

为了应对这种风险，当客户端第一次登陆远程主机时，会有类似的提示：

```
The authenticity of host 'test.linux.org (192.168.1.100)' can't be established. 
RSA key fingerprint is 46:cf:06:6a:ad:ba:e2:85:cc:d9:c4:8d:15:bb:f3:ec. 
Are you sure you want to continue connecting (yes/no)?
```
意思就是要你核对远程主机的公钥指纹，从而证明他的身份。那么我们如何判断这个公钥指纹是不是远程主机的公钥产生的指纹呢？答案是没有好办法，只能由用户自己想办法核对，比如远程主机在网站上贴出了自己的公钥指纹。

当我们输入yes之后，会出现：

```
Warning: Permanently added 'test.linux.org,192.168.1.100' (RSA) to the list of known 
```
表示我们已经认可了该主机。

此时要求我们输入登录用户的密码，密码正确则登录。

当远程主机的公钥被接受以后，它就会被保存在文件$HOME/.ssh/known_hosts之中。下次再连接这台主机，系统就会认出它的公钥已经保存在本地了，从而跳过警告部分，直接提示输入密码。

每个SSH用户都有自己的known_hosts文件，此外系统也有一个这样的文件，通常是/etc/ssh/ssh_known_hosts，保存一些对所有用户都可信赖的远程主机的公钥。

## 公钥登录

### 步骤

ssh还提供了另一种登录方式，就是公钥登录，避免了输入密码的麻烦。

所谓"公钥登录"，原理很简单，就是用户将自己的公钥储存在远程主机上。登录的时候，远程主机会向用户发送一段随机字符串，用户用自己的私钥加密后，再发回来。远程主机用事先储存的公钥进行解密，如果成功，就证明用户是可信的，直接允许登录shell，不再要求密码。

这种方法要求用户必须提供自己的公钥。如果没有现成的，可以直接用ssh-keygen生成一个：

ssh-keygen

运行结束以后，在$HOME/.ssh/目录下，会新生成两个文件：id_rsa.pub和id_rsa。前者是你的公钥，后者是你的私钥。

这时再输入下面的命令，将公钥传送到远程主机host上面：

ssh-copy-id user@host

然后，打开远程主机/etc/ssh/sshd_config这个文件，检查以下几项：

RSAAuthentication yes
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys

然后重启ssh服务就可以了：

service sshd restart

### authorized_keys

远程主机将用户的公钥，保存在登录后的用户主目录的$HOME/.ssh/authorized_keys文件中。公钥就是一段字符串，只要把它追加在authorized_keys文件的末尾就行了。

这里不使用上面的ssh-copy-id命令，改用下面的命令，解释公钥的保存过程：

ssh user@host 'mkdir -p .ssh && cat >> .ssh/authorized_keys' < ~/.ssh/id_rsa.pub

这条命令由多个语句组成，依次分解开来看：

1. "ssh user@host"，表示登录远程主机；

2. 单引号中的mkdir .ssh && cat >> .ssh/authorized_keys，表示登录后在远程shell上执行的命令：

3. "mkdir -p .ssh"的作用是，如果用户主目录中的.ssh目录不存在，就创建一个；

4. 'cat >> .ssh/authorized_keys' < ~/.ssh/id_rsa.pub的作用是，将本地的公钥文件~/.ssh/id_rsa.pub，重定向追加到远程文件authorized_keys的末尾。

写入authorized_keys文件后，公钥登录的设置就完成了。

## 参考

[簡易 Telnet 與 SSH 主機設定](http://linux.vbird.org/linux_server/0310telnetssh/0310telnetssh.php)

[SSH原理与运用（一）：远程登录](http://www.ruanyifeng.com/blog/2011/12/ssh_remote_login.html)