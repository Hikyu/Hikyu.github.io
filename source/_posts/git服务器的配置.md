---
layout: post
title: git服务器的配置
date: 2017-09-06 09:46:49
categories: 工具
tags: 
- git
---

> 公司一直在使用Starteam作版本控制，这是个很古老的工具，也有不少的BUG...最近为公司搭建了Git服务器试用，把搭建的过程记录下来...

## ssh配置

可以使用ssh协议搭建ssh服务，适合于几个人的小团队，每个人都拥有读写的权限。

### 配置git服务器
通过创建一个专门的git用户，作为访问git服务的账户
```
$ ssh root@192.168.1.110
$ sudo adduser git
$ su git
$ cd
$ mkdir .ssh && chmod 700 .ssh
$ touch .ssh/authorized_keys && chmod 600 .ssh/authorized_keys
```

<!-- more -->

### **配置客户机**

1. 安装git
2. 本机生成ssh key
```
右键，打开Git Bash Here
$ ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
Generating public/private rsa key pair.
Enter a file in which to save the key (/c/Users/you/.ssh/id_rs[Press enter]
Enter passphrase (empty for no passphrase): [Type a passphrase]
Enter same passphrase again: [Type passphrase again]
```  
3. 将公钥传送到远程主机上(git服务器所在的主机)
   $ ssh ssh-copy-id git@192.168.1.110

### **新建仓库**

以JDBC为例，仓库目录结构参照 Starteam:oscar5.7-> OSCAR7.0_64BITS_DEV-> OSCAR_RELEASE_2012

- **新建裸仓库**
```
$ ssh git@192.168.1.110
$ cd git
$ mkdir OSCAR_RELEASE_2012/Cross_Platform/jdbc.git
$ cd OSCAR_RELEASE_2012/Cross_Platform/jdbc.git
$ git init --bare
Initialized empty Git repository in /home/git/git/OSCAR_RELEASE_2012/Cross_Platform/jdbc.git/
```
- **将项目推送到远程仓库**
客户机yukai：
```
右键，打开Git Bash Here
$ cd jdbc  //进入JDBC源码所在的根目录
$ git init
$ git add .
$ git commit -m 'initial commit'
$ git remote add origin git@192.168.1.110:/home/git/git/OSCAR_RELEASE_2012/Cross_Platform/jdbc.git/
$ git push origin master
```
- **克隆git服务器上的仓库**
客户机fuqiuying：
```
右键，打开Git Bash Here
$ git clone git@192.168.1.110:/home/git/git/OSCAR_RELEASE_2012/Cross_Platform/jdbc.git/
```

- **修改git用户登录shell**

需要注意的是，目前所有（获得授权的）开发者用户都能以系统用户 git 的身份登录服务器从而获得一个普通 shell

借助一个名为 git-shell 的受限 shell 工具，你可以方便地将用户 git 的活动限制在与 Git 相关的范围内
layout: post
如果将 git-shell 设置为用户 git 的登录 shell，那么用户 git 便不能获得此服务器的普通 shell 访问权限

```
$ cat /etc/shells #查看git-shell是否已经存在于 /etc/shells 文件中
$ which git-shell #查看git-shell的安装位置
$ sudo vim /etc/shells #将上一步查询得到的git-shell安装位置加入到/etc/shells文件末尾
$ sudo chsh git #执行此命令，修改git用户的shell，会提示输入修改的shell，这里修改为git-shell的安装位置
```
这样，用户 git 就只能利用 SSH 连接对 Git 仓库进行推送和拉取操作，而不能登录机器并取得普通 shell。 如果试图登录，你会发现尝试被拒绝，像这样：
```
$ ssh git@gitserver
fatal: Interactive git shell is not enabled.
hint: ~/git-shell-commands should exist and have read and execute access.
Connection to gitserver closed.
```

## gitlab配置

gitlab可以说是一个翻版的GitHub，拥有权限管理，review等功能。适合于公司内部使用。

centos7为例：

- **配置安装环境**
```
$ sudo yum install curl policycoreutils openssh-server openssh-clients
$ sudo systemctl enable sshd
$ sudo systemctl start sshd
$ sudo yum install postfix
$ sudo systemctl enable postfix
$ sudo systemctl start postfix
$ sudo firewall-cmd --permanent --add-service=http
$ sudo systemctl reload firewalld
```
- **下载并安装**
```
$ curl -sS http://packages.gitlab.com.cn/install/gitlab-ce/script.rpm.sh | sudo bash
$ sudo yum install gitlab-ce
```
- **配置gitlab**
```
$ sudo vim /etc/gitlab/gitlab.rb
# external_url="192.168.1.110:8888"
```
- **开放端口并应用配置**
```
$ sudo firewall-cmd --zone=public --add-port=8888/tcp --permanent
$ sudo firewall-cmd --reload
$ firewall-cmd --list-all
$ sudo gitlab-ctl reconfigure
```
- **检测是否安装成功**
```
$ sudo gitlab-ctl status
[sudo] password for firehare: 
run: nginx: (pid 13334) 16103s; run: log: (pid 4244) 22211s
run: postgresql: (pid 4153) 22280s; run: log: (pid 4152) 22280s
run: redis: (pid 4070) 22291s; run: log: (pid 4069) 22291s
run: sidekiq: (pid 4234) 22212s; run: log: (pid 4233) 22212s
run: unicorn: (pid 4212) 22218s; run: log: (pid 4211) 22218s
```

- **gitlab汉化**

```
$ sudo cat /opt/gitlab/embedded/service/gitlab-rails/VERSION
```
假设当前版本为 v9.5.2，并确认汉化版本库是否包含该版本的汉化标签(-zh结尾)，也就是是否包含 v9.5.2-zh。

如果版本相同，首先在本地 clone 仓库。

```
# 克隆汉化版本库
$ git clone https://gitlab.com/xhang/gitlab.git
# 如果已经克隆过，则进行更新
$ git fetch
```
然后比较汉化标签和原标签，导出 patch 用的 diff 文件。
```
$ git diff v9.5.2 v9.5.2-zh > ../9.5.2-zh.diff
```
上传 9.5.2-zh.diff 文件到服务器
```
$ cd ..
$ sudo gitlab-ctl stop
$ sudo yum -y install patch
$ sudo patch -d /opt/gitlab/embedded/service/gitlab-rails -p1 < 9.5.2-zh.diff
```
重启gitlab
```
$ sudo gitlab-ctl start
$ sudo gitlab-ctl reconfigure
```

{% asset_img result.png gitlab %}

- 参考
 
[git book](https://git-scm.com/book/zh/v2/%E6%9C%8D%E5%8A%A1%E5%99%A8%E4%B8%8A%E7%9A%84-Git-%E9%85%8D%E7%BD%AE%E6%9C%8D%E5%8A%A1%E5%99%A8)

[gitlab中文网](https://www.gitlab.com.cn/installation/#centos-7)

[gitlab汉化](https://gitlab.com/xhang/gitlab)
