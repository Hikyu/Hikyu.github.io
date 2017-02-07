---
layout: post
title: Vps使用笔记
date: 2017-02-07 21:34:16
categories: 工具
tags: linux
---
> 今天折腾了一天，总算是把翻墙的梯子搭起来了，租了国外的vps，然后在上面搭建了shadowsocks服务，手机和电脑就可以使用shadowsocks客户端的方式科学上网了。
> Shadowsocks 是一个由很多人参与的开源项目，感谢shadowsocks作者[@clowwindy](https://github.com/clowwindy/shadowsocks).关于shadowssocks和vpn等等翻墙方式的区别,不再一一赘述，本文只是记录梯子搭建的过程

## 购买VPS

VPS的概念我也不是特别清楚，就把他当成主机好了，类似于阿里云等等。

购买之后，会分配给你root账户密码，你就拥有了一台国外机房的主机。

VPS 可以参考 [有哪些便宜稳定，速度也不错的Linux VPS 推荐？](https://www.zhihu.com/question/20800554),我买了Vultr 日本机房的vps,充了5美刀先试试。具体的购买方法自行谷歌

## 搭建shadowsocks服务

### 升级内核

我选择了Centos7的Linux发型版本作为操作系统。

使用MobaXterm(或者是其他ssh工具)连接到分配给你的主机(root密码购买成功时会给出),

首先升级一下内核：wget -O- https://zhujiwiki.com/usr/uploads/2016/12/install_bbr_centos.sh | bash

完成之后，重启：

reboot

重新登录，查看内核版本：

uname -r

不出意外已经更新到了最新版本。接着执行：

sysctl -a|grep congestion_control

如果输出选项包含：net.ipv4.tcp_congestion_control = bbr 表示安装成功，否则需要手动开启bbr模式：

```
echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
sysctl -p
sysctl
net.ipv4.tcp_available_congestion_control
```

再次查看：

sysctl -a|grep congestion_control

### 搭建服务

搭建服务可以选择使用别人写好的现成的脚本，也可以自己搭建，下面介绍这两种方法：

#### 使用现成脚本

执行以下命令：

```wget --no-check-certificate https://raw.githubusercontent.com/teddysun/shadowsocks_install/master/shadowsocks.sh
chmod +x shadowsocks.sh
./shadowsocks.sh 2>&1 | tee shadowsocks.log
```

首先会提示你输入密码和端口，然后开始安装。安装完成后代表shadowsocks服务已经开启了。此时可以使用shadowsocks客户端去连接这个服务器了。

脚本可用的命令：

启动：/etc/init.d/shadowsocks start

停止：/etc/init.d/shadowsocks stop

重启：/etc/init.d/shadowsocks restart

状态：/etc/init.d/shadowsocks status

卸载：./shadowsocks.sh uninstall

支持多用户的方法：修改配置文件:/etc/shadowsocks.json

```
{    
    "server":"0.0.0.0",
    "local_address":"127.0.0.1",
    "local_port":1080,
    "port_password":{
         "8989":"password0",
         "9001":"password1",
         "9002":"password2",
         "9003":"password3",
         "9004":"password4"
    },
    "timeout":300,
    "method":"aes-256-cfb",
    "fast_open": false
}```

#### 自行搭建

首先安装shadowsocks服务：

```
yum install python-setuptools && easy_install pip
pip install shadowsocks
```

显示 “Successfully installed shadowsocks-2.6.10″。意味着Shadowsocks已经成功安装。

接着，创建一个Shadowsocks配置文件。输入以下命令：

vi /etc/shadowsocks.json

然后在该文件中输入：

```
{
    "server":"your_server_ip",
    "server_port":8388,
    "local_address": "127.0.0.1",
    "local_port":1080,
    "password":"auooo.com",
    "timeout":300,
    "method":"aes-256-cfb",
    "fast_open": false
}
```

上面各项配置的含义已经很明显了，除了server(vps的ip)、server_port和password之外，其他默认即可。保存该文件。执行：

ssserver -c /etc/shadowsocks.json -d start

服务就启动了，如果想要关闭，执行：

ssserver -c /etc/shadowsocks.json -d stop

支持多用户的方法与上面的类似

#### 端口问题

有时候服务正常启动了，但是发现客户端还是没有办法翻墙。这时要注意检查vps开放的端口：

Centos升级到7之后，使用firewalld代替了原来的iptables作为防火墙。

启动：systemctl start  firewalld

重启：firewall-cmd --reload

查看状态：systemctl status firewalld 或者 firewall-cmd --state  

查看开放的端口：firewall-cmd --list-ports

增加开放端口：firewall-cmd --add-port=9001/tcp --permanent   (重启生效)

9001：要开放的端口

tcp：协议

--permanent：永久生效，没有此参数重启后失效其他命令自行查找

## 锐速加速

[锐速破解版linux一键自动安装包（8月7日更新）](https://www.91yun.org/archives/683)

文章开头的更新内核使用bbr加速或者锐速加速都可以，没试过哪种方式效果更好一些

## vps使用ssh密钥登录

使用ssh root账户和密码登录的方式是vps一开始会给出的登录主机的方式，这种方式比较简单，但是容易被别人暴力破解登录密码，控制我们的主机。

所以，应该使用ssh密钥登录的方式来增强安全性。

### 修改root密码

第一步应该先把默认的root密码修改为自己的密码，最好复杂一点。

确保自己记住了这个密码。

passwd

### 创建用户

可以先创建一个非root用户：

```
useradd yukai
```

创建账户密码：

```
passwd yukai 
```

给予账户sudo权限：

```
visudo
```

在 root ALL=(ALL)  ALL 下新增一行：

yukai ALL=(ALL)  ALL

切换到yukai这个账户：

su - yukai 

### 创建密钥

```
ssh-keygen -t rsa
```

在 /home/yukai 下生成了一个隐藏目录：.ssh, 执行：

```
cd ~/.sshcat id_rsa.pub >> authorized_keys
chmod 600 authorized_keys
```

将 id_rsa文件下载下来保存到本地(使用MobaXterm等工具)

### 使用密钥认证登录

打开MobaXterm工具，新建一个session，选择ssh，在Advanced SSH settings选项中选择 use private keygen复选框，并把上一步下载好的id_rsa选择进来。

以用户yukai登录，提示输入密钥文件的密码，输入生成密钥时所填的密码，如果能够登录，则设置正确了

### 禁用root用户登录和密码登录

确保自己记住了root密码，并且上一步密钥认证方式登录成功。

```
sudo vi /etc/ssh/sshd_config
```
找到以下几项，进行如下设置：

```
RSAAuthentication yes
PubkeyAuthentication yes
PermitRootLogin no
PasswordAuthentication no
```

重启ssh服务：

```
service sshd restart
```

### 多台主机管理

可以将生成的密钥文件authorized_keys保存到多个主机的相同位置：~/.ssh

然后进行上面的配置。此时就可以使用一份私钥文件id_rsa登录多个主机了。

## ss多用户管理

前端使用ss-panel，后台使用shadowsocks-manyuser

教程参见：

[可能是最好的 ss-panel 部署教程](https://blessing.studio/build-shadowsocks-sharing-site-with-ss-panel/)

[ShadowSocks多用户管理系统搭建（moeSS+manyuser）](https://blog.linuxeye.com/426.html)

## 在Linux上使用shadowsocks服务翻墙

### 开启shadowsocks客户端

确认安装了shadowsocks服务并从配置好的shadowsocks服务器端获得配置文件: /etc/shadowsocks/config.json

```
{
        "server":"remote-shadowsocks-server-ip-addr",
        "server_port":443,
        "local_address":"127.0.0.1",
        "local_port":1080,
        "password":"your-passwd",
        "timeout":300,
        "method":"aes-256-cfb",
        "fast_open":false,
        "workers":1
}
```
在config.json所在目录下运行sslocal即可：

sslocal -c /etc/shadowsocks/config.json

也可以手动指定参数运行：

sslocal -s 服务器地址 -p 服务器端口 -l 本地端端口 -k 密码 -m 加密方法

### 使用chrome代理

在chrome应用商店中查找 Proxy SwitchyOmega,并安装该扩展

新建情景模式，代理协议选择SOCKS5，代理服务器选择 127.0.0.1， 代理端口选择上一步中的local_port,即1080

启用该扩展程序，此时可顺利使用google了 

## 附录

### 安装vim

vim编辑器需要安装三个包：

```
vim-enhanced-7.0.109-7.el5
vim-minimal-7.0.109-7.el5
vim-common-7.0.109-7.el5
```

输入  `rpm -qa|grep vim` 这个命令，如何vim已经正确安装，则会显示上面三个包的名称

如果缺少了其中某个，比如说： vim-enhanced这个包少了，执行：`yum -y install vim-enhanced` 命令，它会自动下载安装

如果上面三个包一个都没有显示，则直接输入命令：

```
yum -y install vim*
```

### 安装net-tools

```
yum install net-tools
```

### 更改文件所有者

chown -R www.www ./    将本路径下所有文件所有者改为www组的www

## 参考

[Shadowsocks Python版一键安装脚本](https://teddysun.com/342.html)

[使用 Shadowsocks 自建翻墙服务器，实现全平台 100% 翻墙无障碍](https://www.loyalsoldier.me/fuck-the-gfw-with-my-own-shadowsocks-server/)

[http://shadowsocks.org/](http://shadowsocks.org/en/download/clients.html)

[shadowsocks（影梭）不完全指南](http://www.auooo.com/2015/06/26/shadowsocks%EF%BC%88%E5%BD%B1%E6%A2%AD%EF%BC%89%E4%B8%8D%E5%AE%8C%E5%85%A8%E6%8C%87%E5%8D%97/)
