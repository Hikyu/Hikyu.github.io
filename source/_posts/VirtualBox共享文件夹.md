---
title: VirtualBox设置共享文件夹
date: 2018-05-02 20:50:30
categories: 
- 技术
- Linux
tags: linux
---

> 最近在做 Gitlab 备份，Gitlab本身运行在虚拟机当中，备份策略是使用 Rsync 备份到远程主机一份；同时在宿主机备份一份。宿主机使用了windows，想到了一个较为简单的办法，即设置共享文件夹，将需要备份的内容定时复制到共享文件夹即可。在设置共享文件夹的过程中遇到一些问题，在此记录下来。

因为虚拟机所在的 IP 无法访问外网，只能访问公司内部网络。所以在进行下面的操作之前，需要配置一下 yum 的代理：

我在本机开启了 shadowsocks 服务，ip：192.168.1.70，port：1090

虚拟机内执行：

`sudo vim /etc/yum.conf`

增加下面内容：

```
proxy=socks5h://192.168.1.70:1090
```

保存，退出。yum代理设置成功。

## 虚拟机安装增强功能

- 安装 linux-headers

   有两种解决办法：

   <!-- more -->

   1. 安装与当前 kernel 相同版本的 kernel-headers 和 kernel-devel 

   ```
   yum remove kernel-headers -y
   yum install kernel-headers-$(uname -r) kernel-devel-$( uname -r) -y
   yum install gcc make -y
   ```

   2. 升级到最新内核版本

   ```
   yum update kernel -y
   yum install kernel-headers kernel-devel gcc make -y
   # 重启虚拟机
   # 查看安装的内核版本和kernel-headers版本
   rpm -qa|grep -e  kernel-devel  -e  kernel-headers 
   uname -r
   ```

- 添加虚拟光驱

  在虚拟机关闭状态下，右键虚拟机->设置->存储->添加虚拟光驱：

  选择 VirtualBox 安装目录，默认为 `C:\Program Files\Oracle\VirtualBox`，选择光  盘映像文件 VBoxGuestAdditions.iso。

 {% asset_img iso.png 添加虚拟光驱 %}

- 安装增强功能

   启动虚拟机，挂载刚刚添加的虚拟光驱：
     
   ```
    sudo mkdir /winshare
    sudo mount /dev/cdrom /winshare
    cd /winshare
    sudo ./VBoxLinuxAdditions.run

    # 输出如下
    # Verifying archive integrity... All good.
    # Uncompressing VirtualBox 5.2.6 Guest Additions for Linux........
    # VirtualBox Guest Additions installer
    # Removing installed version 5.2.6 of VirtualBox Guest Additions...
    # Copying additional installer modules ...
    # Installing additional modules ...
    # VirtualBox Guest Additions: Building the VirtualBox Guest Additions kernel modules.
    # VirtualBox Guest Additions: Running kernel modules will not be replaced until the system    restarted
    # VirtualBox Guest Additions: Starting.
   ```

## 设置共享文件夹

右键虚拟机->设置->共享文件夹：

{% asset_img share.png 设置共享文件夹 %}

配置共享文件夹路径和名称。

进入虚拟机，执行：

```
sudo mkdir /gitlabwin
sudo mount -t vboxsf gitlabwin /gitlabwin
```

此时，共享文件夹配置完毕，/gitlabwin 映射到宿主机 E:\gitlab

可以在 /gitlabwin 下面新建文件，然后查看宿主机 E:\gitlab 是否存在对应的文件。

## 开机自动挂载

目前还没有找到好的解决办法，参考[这里](https://segmentfault.com/q/1010000005600781/a-1020000005616990)

如果对挂载的目录没有特殊要求，可以选择自动挂载，右键虚拟机->设置->共享文件夹

共享文件夹会开机自动挂载到`/media/sf_XXX` 目录。

## 设置挂载目录权限

> VirtualBox shared folders present a very simplified file system implementation, just enough to read/write files from/to the guest. Many applications can error when using shared folders, because they expect advanced features, like file locking or access controls, which don't exist for shared folders.

由于共享文件夹并不是虚拟机的本地目录，我们在虚拟机中可以配置共享文件夹的权限是有限的。

手动挂载或自动挂载的目录，所属用户默认为root，组为vboxsf，并且使用 `chmod chown` 等命令是无法改变的。

如果想要配置挂载目录的权限，需要在手动挂载的时候指定一些选项：

```java
// uid gid指定挂载目录的所属用户和组
sudo mount -t vboxsf -o uid=1000,gid=1000  <folder name given in VirtualBox>
// fmode指定文件权限，dmode指定目录权限
// 注意，若同时指定挂载目录的所属用户和组，则fmode和dmode选项失效
sudo mount -t vboxsf -o fmode=700,dmode=700  <folder name given in VirtualBox>
```