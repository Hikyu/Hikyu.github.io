layout: post
title: 记一次苦逼经历--关于spring项目打包为jar运行
date: 2016-09-19 21:41:48
categories: 技术
tags: 
- 服务器
- spring
---

上周二刚从外包那里接手了一个的项目，主要是实现了一个web服务器，客户端可以以http请求的方式通过该服务器获取一些数据库的信息，技术上主要是使用了SpringBoot和REST API。周三就来新的需求了，实现一个接口，大概看了下代码，感觉soeasy(虽然之前从没有接触过springboot和spring，说来惭愧。不过这也说明了使用框架的好处，可以快速上手)。

中秋假期结束之后把这个接口弄完了。Eclipse里面跑起来完全没有问题。自信心爆棚。该服务器要求以jar包的方式运行，那就打个包吧。结果苦逼的经历开始了。

由于项目没有使用任何工具构建，没有maven，也没有Gradle。想着就凑合着用Eclipse里面自带的export导出jar包的功能吧。于是:右键工程，选择export。然后java->JAR file

{% asset_img 1.png export %}

jar包打好了。把依赖什么的都放到jar所在的同一个目录，紧接着使用 java -cp interfaceService.jar;lib/* com.XXX.Application  执行。

服务器跑起来了。nice

浏览器输入URL，回车，出现了这样的画面：

{% asset_img 2.png 404 %}

<!-- more -->

what? 404?赶紧看看服务器打印的日志，发现dispatcherServlet初始化完之后就没有其他动作了，也没有报错信息。跟在eclipse中正常执行的情况对比了一下，eclipse在打印完这几句Log之后就开始进入controller方法了。

{% asset_img 3.png log %}

初步怀疑是找不到对应的controller。

输入关键字：springboot jar 和404页面的提示，谷歌之。

找出来一堆答案，基本都是说没有正确添加注解那一类的意思。回头看看代码，该加注解的地方都加了。而且eclipse里跑着没问题啊，说明不是注解的问题。

感觉应该是打包的问题。把没用的.classpath等文件都排除，重新打包。再次执行，结果一样。

把lib和properties文件都打到包里，执行，还是没用。

{% asset_img 4.png export %}

然后，上图这几个勾选框吸引了我的目光，查了一下这几个框勾选之后的作用，感觉跟这个关系不大，但是也都选上试了一下，失败。

接着又以各种姿势谷歌了一遍，毫无结果。此刻心情比较郁闷，上网刷会微博吧，有点晕...

接下来重新振作精神，再打一次包。

抱着随便试试的心情，把下面的的框也选上了。

{% asset_img 5.png export %}

结果，这次竟然成功了！服务器返回了正确的结果。激动...原来就因为Add Directory Entries这个单选框没勾选就浪费了我两个多小时！

然后各种姿势测了一下，没问题了。

Add Directory Entries谷歌之。神了，出现了很多与我这个情况一样的描述和解决办法。看来还是有人掉过坑啊！

浏览了一下大家的分析，结果就是：**当使用export方式打jar包来运行spring项目时，一定要记得把Add Directory Entries这个单选框勾选上！否则会扫描不到指定的controller**

原因也很简单：当勾选Add Directory Entries这个选项时，生成的jar会添加文件夹信息。spring就可以扫描到相关的包信息。具体的解释看这篇文章：[spring 扫描包不起作用](http://www.voidcn.com/blog/wangjun5159/article/p-6159159.html)

其实这次遇到的问题也不算是技术上的问题，但前前后后也花了将近三个小时才解决。有三点认识：

1.搜索技巧很重要，如果早一点能用spring、扫描包等关键字去搜索的话，问题早已经解决了。

2.打包尽量用构建工具，避免重复劳动还不易出错。Gradle使用学习中...

3.应该从问题的根源上想才会得到解决方法。比如，如果知道了spring获取controller的实现方式，或许能更快解决这个问题。(spring真的是一点都不懂，需要学习)

以上



