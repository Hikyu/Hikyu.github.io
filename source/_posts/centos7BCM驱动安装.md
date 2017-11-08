---
layout: post
title: centos7BCM驱动安装
date: 2017-02-25 11:22:45
categories: 
- 技术
- Linux
tags: linux
---
> 前段时间安装了centos后，一直使用网线上网。今天是周末，安装了一下无线驱动，可以愉快的使用无线wifi上网啦～

## 查看无线驱动

```
iwconfig
```
如果没有iwconfig命令，则先安装：

```
sudo yum install wireless-tools
```

{% asset_img iwconfig.png iwconfig %}

如上图显示有类似wlp7s0这样的信息，则表示无线驱动已经安装好了。若没有，则全部为no wireless extensions.

没有安装无线驱动，进行下面的操作。

<!-- more -->

## 查看网卡型号

```
lspci |grep -i network 
```

显示：

```
07:00.0 Network controller: Broadcom Limited BCM43142 802.11b/g/n (rev 01)
```

表示是BCM的网卡

## 查看内核信息

```
uname -r
```
显示内核信息：
```
3.10.0-514.6.1.el7.x86_64
```
注意上面的发行版版本为el6,后面64为64位操作系统

## 编译安装驱动程序

下面只针对el7 64的情况，其他配置的系统参考：[wl-kmod](http://elrepo.org/tiki/wl-kmod)

1.安装工具
```
yum group install 'Development Tools'

yum install redhat-lsb kernel-abi-whitelists

yum install kernel-devel-$(uname -r)
```

2.切换到普通用户，配置构建树
```
mkdir -p ~/rpmbuild/{BUILD,RPMS,SPECS,SOURCES,SRPMS}

echo -e "%_topdir $(echo $HOME)/rpmbuild\n%dist .el$(lsb_release -s -r|cut -d"." -f1).local" >> ~/.rpmmacros
```

3.下载 wl-kmod*nosrc.rpm 到任意目录，比如 ～/package
[http://elrepo.org/linux/elrepo/el7/SRPMS/wl-kmod-6_30_223_271-3.el7.elrepo.nosrc.rpm](http://elrepo.org/linux/elrepo/el7/SRPMS/wl-kmod-6_30_223_271-3.el7.elrepo.nosrc.rpm)

4.下载合适的驱动
[http://www.broadcom.com/support/802.11]( http://www.broadcom.com/support/802.11)

选择64位的驱动，下载到~/rpmbuild/SOURCES/目录

5.构建kmod-wl
```
 rpmbuild --rebuild --target=`uname -m` --define 'packager yukai' ~/package/wl-kmod*nosrc.rpm
```

其中，yukai是当前登陆用户，~/package/是第三步下载的rpm文件位置

6.安装kmod-wl

```
rpm -Uvh /home/yukai/rpmbuild/RPMS/x86_64/kmod-wl*rpm
```

第五步构建完成之后,在～/rpmbuild/RPMS/x86_64目录会有kmod-wl*rpm文件生成，安装它即可

7.删除不用的文件

保存/home/yukai/rpmbuild/RPMS/x86_64/kmod-wl*rpm文件，然后删除～/rpmbuild/

```
rm -rf ～/rpmbuild/
```

8.重启即可

{% asset_img demo.png demo %}