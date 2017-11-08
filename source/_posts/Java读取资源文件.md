---
layout: post
title: Java读取资源文件
date: 2017-10-31 19:56:22
categories: 
- 技术
- 编程
tags:
- java
- 类加载
---
> 写java代码时常常需要加载一些外部的资源，通常我们会使用全路径名加载一份资源，比如：C:\Users\Yukai\Desktop\abc.jpg . 但是，有些时候我们需要加载的是源代码路径下的资源或者配置文件等等，更习惯于使用相对路径，或者直接给一个文件名，就希望能够找到我们需要的配置文件。如何做到？常见的方法是使用了 class.getResource 或 classloader.getResource

## class.getResource && classloader.getResource ?

这两个方法看起来很相似，他们直接有什么区别？

直接上网搜索能够得到一些答案，但都不如查看源代码来的直接：

<!-- more -->

`Class.getResourceAsStream(String name)`

```java
public InputStream getResourceAsStream(String name) {
    name = resolveName(name);
    ClassLoader cl = getClassLoader0();
    if (cl==null) {
        // A system class.
        return ClassLoader.getSystemResourceAsStream(name);
    }
    return cl.getResourceAsStream(name);
}
```

上面的代码可以看出， `Class.getResourceAsStream(String name)` 最终还是调用了 `classloader.getResourceAsStream(String name)` 。但是两者还是有一些区别的，注意 `name =resolveName(name)`这一行， `Class.getResourceAsStream(String name)`在这里做了一些处理：

`Class.resolveName(String name)`

```java
private String resolveName(String name) {
    if (name == null) {
        return name;
    }
    if (!name.startsWith("/")) {
        Class<?> c = this;
        while (c.isArray()) {
            c = c.getComponentType();
        }
        String baseName = c.getName();
        int index = baseName.lastIndexOf('.');
        if (index != -1) {
            name = baseName.substring(0, index).replace('.', '/')
                +"/"+name;
        }
    } else {
        name = name.substring(1);
    }
    return name;
}
```

现在看这段代码还有点云里雾绕，不妨写几行代码测试一下，看看这段代码到底在干嘛：

```java
public class App {
    public static void main(String[] args) {
        System.out.println("App.class.getClassLoader().getResource(\"\") : " + App.class.getClassLoader().getResource(""));
        System.out.println("App.class.getClassLoader().getResource(\"/\") : " + App.class.getClassLoader().getResource("/"));
        System.out.println("App.class.getResource(\"\") : " + App.class.getResource(""));
        System.out.println("App.class.getResource(\"/\") : " + App.class.getResource("/"));
    }
}
```

输出：

```java
App.class.getClassLoader().getResource("") : file:/D:/workspace/eclipse/cluster/TestClassloader/bin/
App.class.getClassLoader().getResource("/") : null
App.class.getResource("") : file:/D:/workspace/eclipse/cluster/TestClassloader/bin/space/yukai/
App.class.getResource("/") : file:/D:/workspace/eclipse/cluster/TestClassloader/bin/
```

虽然上面的代码使用了getResource，但与getResourceAsStream大同小异。

可以看到，

`calssloder.getResource("")`方法返回了classpath根路径（eclipse工程中，编译生成的类文件存放在/bin目录下）;

`calssloder.getResource("/")`方法返回null，说明calssloder.getResource不支持以"/"开头的参数;

`class.getResource("")`方法返回了App.class所在的路径;

`class.getResource("/")`与`calssloder.getResource("")`表现一致，返回了classpath的根路径

再回顾上面的代码，是否有一点明白了呢？

工程目录结构如下图：

{% asset_img project.png project %}

- 读取根目录下的tmp（src/）:

```
// 第一种方法
InputStream in = App.class.getResourceAsStream("/tmp");
// 第二种方法
InputStream in =ClassLoader.getSystemClassLoader().getResourceAsStream("tmp");
```

- 读取App类同级目录下的tmp（src/space/yukai）

```
// 第一种方法
InputStream in = App.class.getResourceAsStream("tmp");
// 第二种方法
InputStream in =ClassLoader.getSystemClassLoader().getResourceAsStream("space/yukai/tmp");
//第三种方法
InputStream in = App.class.getResourceAsStream("/space/yukai/tmp");
```

- 读取MyClassloader同级目录下的tmp（src/space/yukai/classloader）:

```java
// 第一种方法
InputStream in = App.class.getResourceAsStream("classloader/tmp");
// 第二种方法
InputStream in =ClassLoader.getSystemClassLoader().getResourceAsStream("space/yukai/classloader/tmp");
//第三种方法
InputStream in = App.class.getResourceAsStream("/space/yukai/classloader/tmp");
```

## classloader.getResource

上面提到了`Class.getResourceAsStream(String name)` 最终还是调用了`classloader.getResourceAsStream(String name)`，那么`classloader.getResourceAsStream(String name)`是如何寻找我们要读取的资源呢？

`classloadergetResourceAsStream(String name)`

```java
public InputStream getResourceAsStream(String name) {
    URL url = getResource(name);
    try {
        return url != null ? url.openStream() : null;
    } catch (IOException e) {
        return null;
    }
}

public URL getResource(String name) {
    URL url;
    if (parent != null) {
        url = parent.getResource(name);
    } else {
        url = getBootstrapResource(name);
    }
    if (url == null) {
        url = findResource(name);
    }
    return url;
}
```

上面`getResource(String name)`中的代码是否有中熟悉的感觉？这不就是[classloader的双亲委托机制](http://yukai.space/2017/04/06/java%E7%B1%BB%E5%8A%A0%E8%BD%BD/)么？

首先使用自己的父类加载器寻找资源，如果父类加载器为null，表示此时的类加载器是启动类加载器，故调用`getBootstrapResource(name)`方法查询资源。如果所有的祖先类加载器都找不到指定的资源，那么调用该类加载器的`findResource(name)`方法。

那么这些类加载器是去哪查询资源是否存在呢？与加载类时查询的路径一致，对于我们的应用来说，我们应该关心AppClassLoader，我们自定义的资源往往存放于其查询的路径上，也就是classpath指定的路径。

## classpath

在上文的例子中，classpath指向eclipse自动生成的/bin目录。我们如何在eclipse中添加我们自定义的classpath呢？

有两种方法：

- 工程右键->Build Path->Configure Build Path->Source标签->点击右侧AddFolder  可以将工程目录下的文件夹设置为Source目录

比如常见的Maven中的resources目录，就是Source目录。

设置为Source目录之后，eclipse在编译源文件时，会自动将Source目录下的文件拷贝到/bin目录，自然也就是classpath下了。

这种方法的限制就是只能把工程目录下的文件夹添加进去。

- 设置运行时classpath

在菜单栏点击run->Run Configurations->Classpath

{% asset_img classpath.png classpath %}

如图所示，点击右侧Advanced按钮，可以添加文件夹到运行时classpath。

当然，如果是在命令行下直接运行java程序的话，可以使用`-classpath`选项指定classpath

在maven中，可以使用下面的方法指定jar包的classpath：

```xml
<plugin>
	<groupId>org.apache.maven.plugins</groupId>
	<artifactId>maven-jar-plugin</artifactId>
	<configuration>
		<finalName>ReleaseTool</finalName>
		<archive>
			<manifest>
				<!-- 为依赖包添加路径, 这些路径会写在MANIFEST文件的Class-Path下 -->
				<addClasspath>true</addClasspath>
				<classpathPrefix>lib/</classpathPrefix>
				<mainClass>com.oscar.releasetool.app.App</mainClass>
			</manifest>
			<manifestEntries>
				<!-- 在Class-Path下添加配置文件的路径 -->
				<Class-Path>./</Class-Path>
			</manifestEntries>
		</archive>
		<excludes>
			<exclude>config.json</exclude>
		</excludes>
	</configuration>
</plugin>
```

---

我们可以将配置文件放到任何需要的地方，然后将配置文件所在的目录添加到classpath，使用classloader.getResourceAsStream方法来读取。利用这种方法可以做到配置文件与jar包分离，并且配置文件所在的目录是可以自定义的。Spring读取application.properties使用的是同样的原理。

可以使用下面的代码查看当前classpath:

```java
String classpath = System.getProperty("java.class.path");
String[] classpathEntries = classpath.split(File.pathSeparator);
for (String str1 : classpathEntries) {
    System.out.println(str1);
}
```

## 读取jar包所在的位置

有时候需要知道jar包所在的位置，比如我们的项目需要一个默认的日志文件输出路径，这个路径就可以是运行时jar包所在的目录。如何获取jar包所在的目录？

```
URL url = App.class.getProtectionDomain().getCodeSource().getLocation();
String path = url.toURL().getPath();
```

注意，上面的方法仅适用jdk1.5及以上
