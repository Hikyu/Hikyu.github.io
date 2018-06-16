---
title: gitlab备份恢复方案
date: 2018-06-17 06:34:35
categories: 
- 技术
- 工具
tags: 
- git
---

最近公司内部的gitlab私服打算上线了，其中，数据备份是很重要的一课。

研究制定了一下备份恢复的方案～记录一下

<!-- TOC -->

- [备份策略](#备份策略)
    - [宿主机备份](#宿主机备份)
    - [远程备份](#远程备份)
- [备份](#备份)
    - [配置备份环境](#配置备份环境)
        - [配置共享文件夹](#配置共享文件夹)
            - [安装 VBoxLinuxAdditions](#安装-vboxlinuxadditions)
            - [设置共享文件夹](#设置共享文件夹)
        - [配置 rsync](#配置-rsync)
            - [安装 rsync](#安装-rsync)
            - [配置 rsync 服务](#配置-rsync-服务)
    - [备份 Gitlab](#备份-gitlab)
        - [备份配置](#备份配置)
        - [备份数据](#备份数据)
        - [编写备份脚本](#编写备份脚本)
        - [设置定时备份](#设置定时备份)
- [恢复](#恢复)
    - [恢复 Gitlab](#恢复-gitlab)
        - [要求](#要求)
        - [恢复 gitlab 配置](#恢复-gitlab-配置)
        - [恢复 gitlab 数据](#恢复-gitlab-数据)
- [管理员须知](#管理员须知)
    - [备份日志](#备份日志)
    - [恢复测试](#恢复测试)

<!-- /TOC -->

## 备份策略

{% asset_img structure.png 备份 %}

有 machine-A、machine-B、machine-C 三台实体机，统一为windows系统；

vm-A、vm-B、vm-C、vm-D、vm-E 为Linux系统虚拟机，其中:

vm-A 提供 gitlab 服务，vm-B 提供 redmine 服务；

vm-C 为远程备份服务器；

vm-D 是 vm-B 的备份镜像，vm-E 是vm-A的备份镜像。

vm-D 和 vm-E 平时处于关闭状态，只有在 vm-A 或 vm-B 不可用，或者做备份恢复测试时再进行启用。

注：虚拟机管理工具统一使用 VirtualBox

<!-- more -->

### 宿主机备份

vm-A 设置定时任务将每天的 gitlab 备份传送到其宿主机 machine-A 上；

vm-B 设置定时任务将每天的 redmine 备份传送到其宿主机 machine-B 上。

### 远程备份
   
vm-A 设置定时任务将每天的 gitlab 备份传送到 vm-C 上；

vm-B 设置定时任务将每天的 redmine 备份传送到 vm-C 上。

## 备份 

- 宿主机备份

  vm-A 与宿主机 machine-A 建立共享文件夹，其中 vm-A 目录 /gitlab 映射到 machine-A 目录 E:\gitlab；

  vm-B 与宿主机 machine-B 建立共享文件夹，其中 vm-B 目录 /redmine 映射到 machine-B 目录 E:\redmine；

  vm-A 定时将 gitlab 备份拷贝到其 /gitlab 目录；vm-B 定时将 redmine 备份拷贝到其 /redmine 目录。

- 远程备份

  vm-C 与宿主机 machine-C 建立共享文件夹，其中：
  
  vm-C 目录 /gitlab 映射到 machine-C 目录 E:\gitlab；
  
  vm-C 目录 /redmine 映射到 machine-C 目录 E:\redmine。

{% asset_img cshare.png 备份 %}
  
  vm-C 开启 rsync 服务，vm-A 与 vm-B 作为 rsync 客户端，定时使用 rsync 将备份推送到 vm-C 的 /gitlab 和 /redmine 目录。

### 配置备份环境

根据宿主机备份和远程备份两种策略，配置备份环境。

#### 配置共享文件夹

由上文可知，vm-A、vm-B、vm-C均需要进行共享文件夹的设置。下面以 vm-A 为例进行演示：

##### 安装 VBoxLinuxAdditions

1. 安装 linux-headers

  有两种解决办法：
   
  一、安装与当前 kernel 相同版本的 kernel-headers 和 kernel-devel 
   
  ```
  yum remove kernel-headers -y
  yum install kernel-headers-$(uname -r) kernel-devel-$( uname -r) -y
  yum install gcc make -y
  ```
   
  二、升级到最新内核版本
   
  ```
  yum update kernel -y
  yum install kernel-headers kernel-devel gcc make -y
  # 重启虚拟机
  sudo reboot
  # 查看安装的内核版本和kernel-headers版本
  rpm -qa|grep -e  kernel-devel  -e  kernel-headers 
  uname -r
  ```
 
2. 添加虚拟光驱

  在虚拟机关闭状态下，`右键虚拟机->设置->存储->添加虚拟光驱`：
 
  选择 VirtualBox 安装目录，默认为 `C:\Program Files\Oracle\VirtualBox`，选择光  盘映像文件 `VBoxGuestAdditions.iso`。
 
 {% asset_img iso.png 备份 %}
 
3. 安装增强功能
 
  启动虚拟机，挂载刚刚添加的虚拟光驱：
  
  ```
  sudo mkdir /winshare
  sudo mount /dev/cdrom /winshare
  cd /winshare
  sudo ./VBoxLinuxAdditions.run
  ```

##### 设置共享文件夹

右键虚拟机->设置->共享文件夹：

 {% asset_img share.png 备份 %}

配置共享文件夹路径和名称

进入虚拟机，执行

```
sudo mkdir /gitlab
sudo mount -t vboxsf gitlabwin /gitlab
```

此时，共享文件夹配置完毕，vm-A 目录 /gitlab 映射到宿主机 E:\gitlab

#### 配置 rsync 

##### 安装 rsync

vm-A、vm-B、vm-C 需要安装 rsync:

centos：

`sudo yum install rsync`

ubuntu：

`sudo apt-get install rsync`

##### 配置 rsync 服务

vm-C 作为远程备份服务器，需要配置并启动 rsync daemon。

以下操作均在 vm-C 上进行：

1. 编辑 rsyncd.conf 

  `sudo vim /etc/rsyncd.conf`

  ```
  uid = root
  gid = root
  log file=/var/log/rsyncd.log
  max connections = 4
  pid file = /var/run/rsyncd.pid

  [gitlab]
      path=/gitlab/backups
      secrets file=/etc/rsyncd.secrets
      auth users=root
      read only=false
  [gitlab]
      path=/redmine/backups
      secrets file=/etc/rsyncd.secrets
      auth users=root
      read only=false
  ```
  
  uid 与 gid 确定了访问 path 指定目录的权限，即 uid 和 gid 指定的用户必须拥有 path 指定目录的读写权限

  path 指定了备份目录

  secrets file 指定了用户密码文件

  auth users 需要是在 rsyncd.secrets 中定义的用户名

2. 编辑 rsyncd.secrets

   sudo vim /etc/rsyncd.secrets

   ```
   root:123456
   ```
   
   rsyncd.secrets 中的用户名和密码可自定义
   
   编辑完毕后需要修改 rsyncd.secrets 的访问权限：

   ```
   sudo chmod 600 rsyncd.secrets
   ```

3. 启动 rsync 服务

   ```
   # 设置开机启动
   sudo systemctl enable rsyncd.service
   # 启动 rsync --daemon
   sudo systemctl start rsyncd.service
   # 开放rsync服务端口
   sudo firewall-cmd --permanent --add-service=rsyncd
   # 重启防火墙
   sudo firewall-cmd --reload
   # 关闭selinux，避免产生权限问题
   # 永久关闭
   sudo vim /etc/selinux/config # SELINUX=disabled
   # 临时关闭
   sudo setenforce 0
   ```

4. 测试

   在 vm-A 或 vm-B 执行：

   `rsync -avz --progress test root@vm-C::gitlab`

   其中， test 为测试文件

   输入密码，正常情况下文件传送成功。若失败，检查端口和权限等是否配置正确。

-------------------------
  
### 备份 Gitlab

#### 备份配置

备份 /etc/gitlab 文件夹下的内容。

目的：备份双因素认证用户登录信息、备份 Gitlab-CI 中的安全变量

```
sudo sh -c 'umask 0077; tar -cf $(date "+etc-gitlab-%s.tar") -C /etc/gitlab'
```

这部分内容只需要在gitlab服务配置好之后，备份一次即可。

#### 备份数据

备份 Git 仓库和 SQL 数据。

- 修改默认备份路径：

```
sudo vim /etc/gitlab/gitlab.rb
# 默认备份路径 /var/opt/gitlab/backups
# gitlab_rails['backup_path'] = '/mnt/backups' // 修改为指定的备份路径
sudo gitlab-ctl reconfigure
```

- 修改备份过期时间

```
sudo vim /etc/gitlab/gitlab.rb
# limit backup lifetime to 7 days - 604800 seconds
# gitlab_rails['backup_keep_time'] = 604800
sudo gitlab-ctl reconfigure
```

- 执行备份

```
sudo gitlab-rake gitlab:backup:create
```

这部分内容需要设置定时任务，每天进行备份。

#### 编写备份脚本

脚本如下（以root用户执行）：

`vim /etc/gitlab/backup.sh`

```bash
#/bin/sh

backupsLocal = /var/opt/gitlab/backups
export RSYNC_PASSWORD=123456
backupsRemote = root@vm-C::gitlab
backupsWin = /gitlab
gitlabRakeLog = /var/log/gitlab-rake.log
rsyncLog = /var/log/gitlab-rsync.log

# 执行gitlab备份
/opt/gitlab/bin/gitlab-rake gitlab:backup:create > $gitlabRakeLog 2>&1
# 同步备份到共享文件夹
/usr/bin/rsync -avz --progress --delete $backupsLocal $backupsWin > $rsyncLog 2>&1
# 同步备份到远程rsync服务器
/usr/bin/rsync -avz --progress --delete $backupsLocal $backupsRemote >> $rsyncLog 2>&1
```

修改脚本权限：

`chmod +x backup.sh`

#### 设置定时备份

```
su -
crontab -e
```

增加内容如下：(每天1点执行一次远程备份)

```
0 1 * * * /usr/bin/sh /etc/gitlab/backup.sh
```

-----------------------------

## 恢复

### 恢复 Gitlab

#### 要求

1. 执行备份与恢复的 Gitlab 版本要一致！

2. 恢复前至少执行过一次 `sudo gitlab-ctl reconfigure` 命令

3. gitlab 处于运行状态（如未启动，执行 `sudo gitlab-ctl start`）

#### 恢复 gitlab 配置

```
# Rename the existing /etc/gitlab, if any
sudo mv /etc/gitlab /etc/gitlab.$(date +%s)
# Change the example timestamp below for your configuration backup
sudo tar -xf etc-gitlab-1399948539.tar -C /
```

- 拷贝备份数据到 `gitlab_rails['backup_path']` 指定的位置

```
# /var/opt/gitlab/backups/ 是默认的位置
sudo cp 1493107454_2017_04_25_9.1.0_gitlab_backup.tar /var/opt/gitlab/backups/
```
#### 恢复 gitlab 数据

- 停止与数据库交互的进程

```
sudo gitlab-ctl stop unicorn
sudo gitlab-ctl stop sidekiq
# Verify
sudo gitlab-ctl status
```

- 恢复gitlab数据并重启

```
# This command will overwrite the contents of your GitLab database!
sudo gitlab-rake gitlab:backup:restore BACKUP=1493107454_2017_04_25_9.1.0
sudo gitlab-ctl restart
sudo gitlab-rake gitlab:check SANITIZE=true
```

--------------------

## 管理员须知

### 备份日志

管理员需要定期查看备份情况：

分别检查 machine-A E:\gitlab、machine-B E:\redmine、machine-C E:\redmine E:\gitlab 是否有当天或前一天的备份内容。

若出现备份失败的情况，查看当天的备份日志：

- Gitlab

gitlab 备份日志位于 vm-A /var/log/gitlab-rake.log，rsync 日志位于 vm-A /var/log/gitlab-rsync.log

查看当天的备份日志，在 vn-A 执行：

```
sudo less /var/log/gitlab-rake.log
```

定期检查周期建议不超过三天。

### 恢复测试

管理员需定期检查 gitlab 备份是否可用：

在 machine-C 上启动 vm-E，参考[恢复 Gitlab](#恢复-gitlab)章节，使用 machine-C E:\gitlab 目录下最新的备份文件进行恢复测试。

若 gitlab 能正常启动，且登录 gitlab 可以看到最近日期的提交记录，则证明备份可用。

定期检查周期建议不超过一周。
