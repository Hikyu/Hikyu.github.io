---
title: Centos7美化
date: 2018-05-01 17:43:23
categories: 
- 技术
- Linux
tags: linux
---

五一假期比较闲，把我自己PC上的Centos7美化了一下，能够让自己看着舒服点。

先上一张效果图：

{% asset_img 1.png 桌面 %}

<!-- more -->

## 基础知识

- Gnome vs KDE

   KDE 和 GNOME 是 LINUX 里最常用的图形界面操作环境,他们不仅仅是一个窗口管理器那么简单, KDE 是 K Desktop    Environment 的缩写.他不仅是一个窗口管理器,还有很多配套的应用软件和方便使用的桌面环境,比如任务栏,开始菜单,桌面图标   等等.
   
   GNOME 是 GNU Network Object Model Environment 的缩写.和KDE一样,也是一个功能强大的综合环境.
   
   KDE 早于 Gnome 出现，但是 KDE 基于的 Qt 是不遵循 GPL 开源协议的，GNOME 选择完全遵循 GPL 的 GTK 图形界面库为基   础。Gnome 用的是GTK 库，KDE用的是 QT 库。

- QT vs GTK vs GTK+

   GTK，GTK + 和 Qt 都是 GUI 工具包。
   
   Qt 是一个跨平台的 C++ 图形用户界面库，与 Qt 基于C++语言不同，GTK 采用较传统的C语言。
   
   这三者类似于 Windows 下的 MFC。

- Gnome-shell

   GNOME shell 是 GNOME 桌面的用户界面，是 GNOME 3 的关键技术。它提供了一些基本的用户界面功能，比如切换窗口，启动应用程序或者显示通知。
   
   gnome shell 是一款类似gnome的桌面管理器，相对gnome 它更加智能。
   
   gnome shell 本质上来说，是窗口管理器、应用启动器、桌面布局的集合。

Centos7 使用 Gnome 作为桌面环境。

## 安装主题

首先打开 应用程序->工具->优化工具（或输入`gnome-tweak-tool`命令启动）：

{% asset_img 2.png 优化工具 %}

可以看到，我们可以对以下几个部分进行定制：

- 扩展

- GTK+ 

- 图标

- 光标

- Shell 主题

### 安装 Gnome 扩展

安装Firefox插件：

```
sudo yum install gnome-shell-browser-plugin
```

Firefox打开[https://extensions.gnome.org/](https://extensions.gnome.org/)，在线安装扩展。我安装了以下几款：

- [Clipboard Indicator](https://extensions.gnome.org/extension/779/clipboard-indicator/)

   剪贴板管理 

- [Coverflow Alt-Tab](https://extensions.gnome.org/extension/97/coverflow-alt-tab/)

   Alt+Tab 切换应用 3D 效果

- [Dash to Dock](https://extensions.gnome.org/extension/307/dash-to-dock/)

   定制你的启动器

- [Drop Down Terminal](https://extensions.gnome.org/extension/442/drop-down-terminal/)

   下拉式模拟终端

- [Dynamic Top Bar ](https://extensions.gnome.org/extension/885/dynamic-top-bar/)

   顶栏透明化

- [User Themes](https://extensions.gnome.org/extension/19/user-themes/)

   从文件夹加载 gnome-shell 主题

- [NetSpeed](https://extensions.gnome.org/extension/104/netspeed/)

   顶栏显示网速

扩展可以在优化工具中进行管理。

### 安装 GTK+ 主题

GTK+ 主题主要针对的是使用 GTK+ 图形库的应用程序进行定制。

在 [GTK3 Themes](https://www.gnome-look.org/browse/cat/135/ord/latest/) 中挑选自己喜欢的主题。

我选择了一款名为[X-Arc-Collection](https://www.gnome-look.org/p/1167049/) 的 GTK 主题。

下载主题到本地，然后将其解压到 `/usr/share/themes/`目录下。

通过优化工具在 GTK+ Theme 菜单下找到新安装的主题，选择即可。

### 安装图标主题

在 [Icon Themes](https://www.gnome-look.org/browse/cat/132/) 中挑选自己喜欢的图标主题。

我选择了一款名为 [ Papirus](https://www.gnome-look.org/p/1166289/) 的图标主题。

下载图标主题到本地，将其解压到 `/usr/share/icons/` 目录下。

通过优化工具在 Icon Theme 菜单下找到新安装的主题，选择即可。

### 安装光标主题

在 [Cursors](https://www.gnome-look.org/browse/cat/107/) 中挑选自己喜欢的光标主题。

我选择了一款名为 [Bibata](https://www.gnome-look.org/p/1197198/) 的光标主题。

下载图标主题到本地，将其解压到 `/usr/share/icons/` 目录下。

通过优化工具在 Cursor Theme 菜单下找到新安装的主题，选择即可。

### 安装 shell 主题

shell 主题主要针对顶栏进行定制。

先备份原来的主题目录 /usr/share/gnome-shell/theme/

```
cd  /usr/share/gnome-shell/
mv theme theme.backup
```

到[gnome-look](https://www.gnome-look.org)寻找喜欢的主题包，下载并拷贝到 /usr/share/gnome-shell/ 目录下，解压缩主题包并重命名为 theme。

在优化工具->Shell 主题中进行选择。

注意，如果没有安装[User Themes](https://extensions.gnome.org/extension/19/user-themes/)扩展，Shell 主题下拉框是灰色的不可编辑。

## 隐藏底栏

```
cd /usr/share/gnome-shell/
# 先备份
cp -r /usr/share/gnome-shell/extensions/  /usr/share/gnome-shell/extensions.backup/
cp -r /usr/share/gnome-shell/modes/   /usr/share/gnome-shell/modes.backup/
cp  -r /usr/share/gnome-shell/theme/  /usr/share/gnome-shell/theme.backup/
# 删除任务栏
rm -fr /usr/share/gnome-shell/extensions/window-list@gnome-shell-extensions.gcampax.github.com
```

## 安装搜狗输入法

启用了新的主题后，原来默认的ibus输入法显示不太友好，灰底白字，但是又无法配置底色和前景色，所以更换了一下输入法。

1. 下载搜狗输入法的rpm包

[http://pan.baidu.com/s/1c0yR6Ac](http://pan.baidu.com/s/1c0yR6Ac)

2. 加入epel源和mosquito-myrepo源

```
yum-config-manager --add-repo=https://copr.fedoraproject.org/coprs/mosquito/myrepo/repo/epel-(rpm -E %?rhel).repo
yum-config-manager --add-repo=https://copr.fedoraproject.org/coprs/mosquito/myrepo/repo/epel-7/mosquito-myrepo-epel-7.repo
```

3. 安装搜狗输入法

安装刚刚下载的rpm包

```
sudo rpm -ivh sogoupinyin-1.2.0.0056-1.fc22.x86_64.rpm
```

如果提示有依赖的安装包未安装，则先根据提示安装其依赖。直到可以完成安装。

4. 关闭 gnome-shell 对键盘的监听，然后切换输入法为fcitx

```
gsettings set org.gnome.settings-daemon.plugins.keyboard active false 
imsettings-switch fcitx
```