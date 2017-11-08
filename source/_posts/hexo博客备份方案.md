---
layout: post
title: hexo博客备份方案
date: 2017-04-11 21:40:40
categories:
- 技术
- 工具
tags: 
- hexo
---
周末的时候给博客换了一个[主题](https://github.com/iissnan/hexo-theme-next)，现在的博客看起来比之前的要清爽多了。
 
{% asset_img blog.png blog %}
<!-- more -->

hexo是把生成的一套html发布到服务器上面的，我使用了github来托管自己的博客，每次发布时只把生成的html等文件发布到github，源代码并不会一同发到上面。

如果是换电脑的话就很不方便了，再加上之前使用hexo generate -d发布博客的时候出了点问题，所以抽空写了一个专门用来发布博客和保存源代码的脚本，在此记录。

## 脚本

```
# hexo generate -d 命令失效，将hexo分支推送到了master分支。使用此脚本进行部署
# 将此脚步置于与blog同级目录下。
# 部署
root="/home/yukai/project/blog"
folder="$root/blogdeploy"
blog="$root/Hikyu.github.io"
if [ ! -d "$folder" ]; then
  echo "初始化..."
  mkdir "$folder"
  cp -R "$blog/.git/" "$folder/.git/"
  cd "$folder"
  git checkout master
fi
echo "博客生成..."
cd "$blog"
git checkout hexo
hexo generate
cp -R "$blog"/public/* "$folder"
echo "博客发布..."
cd "$folder"
git add --all .
git commit -m 'update'
git push origin master
echo "备份博客源码到hexo分支..."
cd "$blog"
git add --all .
git commit -m 'update'
git push origin hexo
```
将上述脚本保存为deploy.sh。

使用时需要将变量`root`设为博客目录的父目录。

如果博客目录还不存在(换电脑)，需要使用`git clone`命令把博客源代码下载下来。

修改博客源码后，执行 `sudo ./deploy.sh`进行博客发布与备份。

## 原理
 
- 发布博客
  
  `hexo generate -d` 可以将博客编译后发布到服务器。其原理就是将源代码中`public`目录下的内容推送到远程分支上面。

  我们使用`master`分支保存发布的博客(github也规定了要发布的博客必须为master分支)。
  
  首先建立推送博客的目录`$folder`，并且将博客目录`$blog`下`.git`文件夹拷贝到`$folder`；
  
  切换到博客目录`$blog`，然后生成博客，将生成的`public`目录的内容拷贝到`$folder`；

  将`$folder`中的内容推送到远程分支master，完成发布。

- 源码备份

  使用新的分支`hexo`来保存我们的博客源代码。

  切换到博客目录`$blog`，并切换分支到hexo；

  将博客目录`$blog`中的源代码内容推动到远程分支`hexo`，完成备份。


   
