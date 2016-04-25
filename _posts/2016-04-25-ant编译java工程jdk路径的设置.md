---
layout: post
categories: java ant
---

> 今天工作的时候涉及到使用ant对项目进行编译，打包。此前只知道ant是一个构建工具（当然，现在也是），也基本上没有接触过。但是build.xml是从仓库下载的已经配置好的文件。本来想着只要在eclipse轻轻一点Ant Build 就万事大吉，但是这个打包却折腾了我两个小时。

打包过程中总是报：

{% highlight ruby linenos %}
[javac] 警告: [options] 未与 -source 1.5 一起设置引导类路径
[javac] E:\doc\oscartools\driver\oscarJavaDriver\jdbc\V1.0\build\com\oscar\Driver.java:50: 错误: com.oscar.Driver不是抽象的, 并且未覆盖java.sql.Driver中的抽象方法getParentLogger()
[javac] public class Driver implements java.sql.Driver {
....
{% endhighlight %}

类似这样的一堆错误。

没有过多的思考，百度之...出现了一堆没用的资料和争论。80%的时间花在了看这些人扯淡上面（或许正真的大神并不关注这些问题）。

严重的浪费时间和影响心情，遂放弃。

静下来想想，工程的java build path使用1.5，java compiler 使用1.5，没什么问题啊。。。

后来灵光一现，build.xml中的javac难道与java home有关（原谅我现在才想到）？java home使用jdk为1.7，遂改为1.5。

重启eclipse，悲催，eclipse要求jdk必须大于等于1.7。

等等，如果不同的工程依赖不同的jdk的话，修改java home并不是一个明智的解决方案，一定可以针对某个工程修改它所依赖的javac，谷歌之 ‘ant set java_home in build.xml’

果然，stackoverflow拯救了我，只需要在build.xml文件中javac标签下添加

{% highlight ruby linenos %}
executable="C:\Program Files\Java\jdk1.5.0_22/bin/javac"
fork="yes"
{% endhighlight %}

Build Successfull.

这次的总结并不是为了学习ant(有学习Gradle的计划)，只是从这次解决问题的过程中，学会了：

1.不要用百度

2.先思考问题原因，再寻找解决方案

3.学习英语，尽量用英文搜索

## 参考

[Change JDK for running <ANT> task from within build xml][ip]

[ip]:http://stackoverflow.com/questions/17594075/change-jdk-for-running-ant-task-from-within-build-xml

