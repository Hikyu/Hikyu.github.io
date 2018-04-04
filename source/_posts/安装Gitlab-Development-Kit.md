---
layout: post
title: 安装Gitlab-Development-Kit
date: 2018-01-25 14:56:57
categories: 
- 技术
- 工具
tags: 
- git
---

> Gitlab-CE是开源项目，意味着我们可以针对官方的Gitlab源码进行二次开发，从而定制出符合自己的开发习惯或开发流程的代码管理工具。

> 一般来说只要把Gitlab-CE的代码仓库clone到本地，就可以在上面修改代码了。Gitlab-CE的地址：https://gitlab.com/gitlab-org/gitlab-ce/ 。但是，只有源代码是不能够直接在本地上跑起来的，整个开发环境还需要安装很多依赖，以及配置数据库。Gitlab为了方便开发者，提供了一个Gitlab开发工具Gitlab-Development-Kit，其地址是：https://gitlab.com/gitlab-org/gitlab-development-kit 。Gitlab-Development-Kit可以帮助开发者很方便地在本地搭建起开发环境，并且把Gitlab运行起来。


- 系统环境
  
  ubuntu-16.04.3-desktop-amd64

<!-- more -->

> The preferred way to use GitLab Development Kit is to install Ruby and dependencies on your 'native' OS. We strongly recommend the native install since it is much faster than a virtualized one. Due to heavy IO operations a virtualized installation will be much slower running the app and the tests.

最好【不要】使用虚拟机安装，而是直接安装在你本机系统上面，要不然会很慢(真的很慢~)。

如果需要在Windows下开发，也只能是安装在Windows10所带的Linux子系统下~~

## [Prepare](https://gitlab.com/gitlab-org/gitlab-development-kit/blob/master/doc/prepare.md)

1. 添加新用户 gitdev

```sh
adduser gitdev
# 赋予gitdev用户sudo权限
```

下面的安装使用gitdev用户执行。

2. 安装[git](https://git-scm.com/download/linux)

```sh
add-apt-repository ppa:git-core/ppa
apt update
apt install git
git --version # 2.15.1
```

3. 安装[RVM](https://rvm.io/)

```sh
# 安装curl
sudo apt-get update
sudo apt install curl

# 安装RVM
gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
\curl -sSL https://get.rvm.io | bash -s stable
source ~/.bashrc
source ~/.bash_profile
```

4. 安装Ruby

检查GDK要求的[Ruby版本](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/.ruby-version):目前是2.3.6

```sh
# 安装Ruby2.3.6
rvm install 2.3.6
# 设置默认Ruby
rvm use 2.3.6
# 验证
ruby -v
```

5. 安装Node

```sh
curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
sudo apt-get install -y nodejs
node -v # 8.9.4
```

6. 安装Yarn

```sh
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt-get update && sudo apt-get install yarn
yarn -v # 1.3.2
```

7. 安装 bunlder

```sh
gem install bundler
```
8. 安装Golang

```sh
sudo add-apt-repository ppa:longsleep/golang-backports
sudo apt-get update
sudo apt-get install golang-go
```

9. 安装其他软件

```sh
# Add apt-add-repository helper script
sudo apt-get install software-properties-common python-software-properties
# This PPA contains an up-to-date version of Go
sudo add-apt-repository ppa:longsleep/golang-backports
sudo apt-get update

sudo apt-get install git postgresql postgresql-contrib libpq-dev redis-server libicu-dev cmake g++ libre2-dev libkrb5-dev libsqlite3-dev ed pkg-config
```

## [Set-Up-Gdk](https://gitlab.com/gitlab-org/gitlab-development-kit/blob/master/doc/set-up-gdk.md)

1. Fork 一份 [Gitlab-CE](https://gitlab.com/gitlab-org/gitlab-ce) 的代码到自己账户的仓库，例如：[https://gitlab.com/Hikyu/gitlab-ce.git](https://gitlab.com/Hikyu/gitlab-ce.git)

2. 新建一个用于开发 Gitlab-CE 代码的文件夹，例如：/home/gitdev/project/gdk

3. 进入上述文件夹，执行：

```sh
gem install gitlab-development-kit
gdk init
```

4. 进入 ./gitlab-development-kit，执行：

```sh
gdk install gitlab_repo=https://gitlab.com/Hikyu/gitlab-ce.git
support/set-gitlab-upstream
```

5. 启动 gitlab-development-kit

```sh
gdk run

# 管理员用户密码： root 5iveL!fe
```

## 遇到的问题

- 执行 `gdk install gitlab_repo=https://gitlab.com/Hikyu/gitlab-ce.git` 报错：`support/bootstrap-rails failed Makefile:246: recipe for target 'postgresql/data' failed make: *** [postgresql/data] Error 1`

  重新执行一次该命令，错误消失了...

- 执行 `gdk run`，报错：`gitaly.socket: bind: no such file or directory`

  编辑 /home/gitdev/project/gdk/gitlab-development-kit/gitaly/config.toml，修改两处：

  ```sh
  修改
  /home/gitdev/project/gdk/gitlab-development-kitdev/project/gdk/gitlab-development-kit/gitaly.socket
  为
  /home/gitdev/project/gdk/gitlab-development-kit/gitlab-development-kit/gitaly.socket

  修改
  /home/gitdev/project/gdk/gitlab-development-kitdev/project/gdk/gitlab-development-kit/gitaly/bin
  为
  /home/gitdev/project/gdk/gitlab-development-kit/gitlab-development-kit/gitaly/bin
  ```

  估计是个bug
