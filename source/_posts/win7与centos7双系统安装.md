layout: post
title: win7与centos7双系统安装
date: 2017-02-18 21:10:00
categories: 技术
tags: linux
---
> 之前会有同学让帮忙重装操作系统，正好计划重新装一下自己电脑的系统，折腾了win7与linux双系统，在此记录。以后就可以给他们看这篇笔记自己去装啦~

> ps: 由于是双系统的安装操作，而不是虚拟机，所以并未截图，是纯文字说明。如果不清楚，可以参考最下面的参考链接

## 安装win7

### 下载win7镜像文件：

[系统之家win7下载](http://www.xitongzhijia.net/win7/)

选择一款进行下载，我选择了`雨林木风 GHOST WIN7 SP1 X64 装机旗舰版 V2017.02（64位）`

### 制作U盘启动工具

下载启动盘制作工具：

[老毛桃u盘启动盘制作工具](http://www.laomaotao.org/lmtxz/933.html)

下载装机版，进行安装

启动盘制作工具安装完成，且镜像下载完毕之后，启动老毛桃，选择U盘启动->默认模式

插入一个可用的U盘，在选择设备这项中，选择插入的U盘设备，注意不要选错

其他选项默认，点击 开始制作 进行启动盘的制作。

启动盘制作完毕之后，将下载好的iso文件拷入U盘

### 安装win7

插入制作好的启动盘，重启电脑

开机画面出现时，按下F12，boot options(我的电脑是DELL的，其他品牌电脑自行查找)

选择USB启动

老毛桃启动盘正常启动，此时选择第二项，win8pe,点击进入win8pe

1. 首先进行分区，选择分区工具，可以自由设置分区数目和分区大小(我分了3个区，一个用来装win7(C)，一个用来做Windows的资料盘(D)，另外一个用来安装Linux(E))

双击win8pe桌面上的“diskgenius分区工具”图标，在弹出的窗口中点击“快速分区”，即可启动分区工具，具体的分区方法参考官网介绍：[老毛桃分区工具的使用](http://www.laomaotao.org/lmtjc/245.html)

2. 设置好分区后，鼠标左键双击打开桌面上的“老毛桃PE装机工具”，选择“还原分区”，映像文件路径选择上一步拷入U盘的镜像，然后选择要装入的分区(C盘)，点击确认开始自动装机。

3. 系统自动重启几次之后，就安装好了，可以卸载一些不必要的系统自带软件，此时的操作系统已经是激活的版本了（我下载的镜像是），各种需要的驱动也都安装完毕，简单省事。

## 安装centos7

### 查看磁盘分区情况

右键计算机->管理，打开计算机管理程序。选择磁盘管理，查看分区情况。

选择之前分好的E盘，右键“删除卷”，使之状态变为“可用空间”，以便centos安装程序识别。

### 制作U盘启动工具

下载centos7镜像文件（DVD版本即可）

[CentOS-7-x86_64-DVD-1611.iso](http://101.96.8.151/mirror.centos.org/centos/7/isos/x86_64/CentOS-7-x86_64-DVD-1611.iso)

下载烧录U盘工具

[ImageUsb](http://www.osforensics.com/tools/write-usb-images.html)

插入一个可用的U盘

启动 imageusb.exe，

step1 选择要写入的U盘;

step2 选择 write image to USB driver;

step3 选择下载好的centos7镜像文件

step4 点击 write ，开始烧录启动盘

启动盘烧录完毕后，可以开始安装centos

### 安装centos7

插入制作好的启动盘，重启电脑

开机画面出现时，按下F12 (我的电脑是DELL的，其他品牌电脑自行查找)

选择USB启动

选择第一项，Install CentOs 7 ，回车，开始安装CentOS 7

之后就进入了简单的可视化安装界面，有几点需要注意：

1.分区选择

如果是像上面一样分了3个区，两个被Windows使用，还剩一个分区未被使用，
那么可以选择自动选择分区，centos安装程序会自动选择好这块未被使用的分区（将“/”目录挂载到这个分区上面）

也可以自定义分区，建议分四个区：/   /boot  /home swap（如果有这么些分区的话）

2.在之后的安装信息摘要中，注意“软件”-“软件选择”，默认是最小安装，即不安装桌面环境，若选择此项，则只有命令行界面，应该选择带有UI界面的选项。

之后就是很简单的安装了

### 配置引导程序

再次启动电脑之后，会发现自动进入Linux，没有win7系统的选项，此时需要配置引导程序

首先添加ntfs支持

```
wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo

yum update;yum install ntfs-3g
```

安装完毕后打开终端，运行`grub2-mkconfig -o /boot/grub2/grub.cfg`

就会重新生成引导项，重启电脑即可

## 参考

[老毛桃u盘安装原版win7系统详细教程](http://www.laomaotao.org/jiaocheng/upzybwin7.html)

[老毛桃分区工具的使用](http://www.laomaotao.org/lmtjc/245.html)

[CentOS 7.0系统安装配置图解教程](http://www.osyunwei.com/archives/7829.html)
