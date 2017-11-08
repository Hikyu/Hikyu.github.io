---
layout: post
title: VncServer的安装与使用
date: 2017-10-01 08:49:00
categories:
- 技术
- Linux
tags: linux
---

> 因为新做的版本发布系统需要部署在内网，找了两台空闲的机器做了Centos7的系统，并搭建读写分离的环境。因为读写分离环境的搭建需要用到可视化工具，所以决定在这两台机器上搭一个vnc服务。

centos7，IP 192.168.1.57

## 安装

1. 安装VNCServer

```
yum install tigervnc-server -y
```

2. 设置防火墙

```
sudo firewall-cmd --permanent --add-service vnc-server
sudo systemctl restart firewalld.service
```

<!-- more -->

## 普通方式启动

- 单用户单连接

**server端:**

比如你想要连入vnc的用户为Java

```
su java
vncpasswd //配置java用户vnc密码，比如123456
vncserver :n //启动vncserver，其中，n为大于等于1的整数比如 vncserver :1(可以不填，vnc会自动分配一个序号)
```

**client端:**

安装[VNC Viewer](https://www.realvnc.com/en/connect/download/viewer/)

打开VNC Viewer，File->New connection，其中：

VNC Server: 192.168.1.57:n //其中，n为VNCServer启动时的参数，比如192.168.1.57:1

Name: 随意填写

点击OK，弹出密码对话框，填入VNCServer密码 比如123456

此时以Java用户的身份进入GUI界面

- 单用户多连接

同一用户多个连接连入VNCServer：

上述几步是以Java用户的身份连入VNCServer，如果需要多个连接都是以Java用户的身份连入VNCServer：

**server端:**

```
su Java
vncserver :n //此时n应该填2，以此类推
```

**client端:**

VNC Server: 192.168.1.57:n //此时n应该为2，依次类推

- 多用户

不同用户连入VNCServer：

如果要使用不同身份的用户接入VNC，比如root:

**server端:**

```
su
vncpasswd //配置root用户vnc密码，比如123456
vncserver :n //启动vncserver，其中，n为大于等于1的整数且尚未被分配，比如 vncserver :3
```

**client端:**

VNC Server: 192.168.1.57:n //此时n应该为3，接入VNC后身份为root

## 服务方式启动

将VNCServer配置为服务，可以开机启动

```
# 配置.service文件，注意":1"相当于"vncserver :n"中的参数":n"
cp /lib/systemd/system/vncserver@.service /etc/systemd/system/vncserver@:1.service
```

观察一下文件 /etc/systemd/system/vncserver@:1.service，发现配置说明：

```
# Quick HowTo:
# 1. Copy this file to /etc/systemd/system/vncserver@.service
# 2. Replace <USER> with the actual user name and edit vncserver
#    parameters appropriately
#   ("User=<USER>" and "/home/<USER>/.vnc/%H%i.pid")
# 3. Run `systemctl daemon-reload`
# 4. Run `systemctl enable vncserver@:<display>.service`
``` 

1. 首先将<USER>中的USER替换为指定的用户，有两处需要替换:

```
User=<USER>
PIDFile=/home/<USER>/.vnc/%H%i.pid
```

替换为java:

```
User=java
# 注意，如果是root，配置为PIDFile=/root/.vnc/%H%i.pid
PIDFile=/home/java/.vnc/%H%i.pid
```

2. 重启systemd

```
systemctl daemon-reload
```

3. 设置vnc密码

```
su java
vncpasswd
```

4. 开启服务

```
sudo systemctl enable vncserver@:1.service
sudo systemctl start vncserver@:1.service
```
