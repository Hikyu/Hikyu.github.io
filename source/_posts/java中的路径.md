---
layout: post
title: "java中的路径"
categories: 编程
date: 2016-12-04 19:03:00
---

>每次写java代码的时候，免不了需要加载一些外部资源，比如配置文件等等。每当需要读取这些文件时，都是去网上谷歌，写过就忘。于是今天来总结一些java中有关路径的一些用法。

## 绝对路径

无论是在linux还是windows中，路径都分为绝对路径和相对路径两种。

绝对路径就是系统中唯一能够定位资源的某个URI，即完整的描述文件的路径就是绝对路径。比如：

linux中的绝对路径：/home/yukai/test.txt

windows中的绝对路径：E:\yukai\test.txt

绝对路径都是以根目录起始的。

## 相对路径

相对路径即目标文件相对与某个基准目录的路径。比如:

存在文件： 

A: /home/yukai/test.txt 

B: /home/yukai/test1.txt 

C: /home/yukai/test/test.txt

那么：

若基准目录为A, B的路径表示为"test1.txt"

若基准目录为B, C的路径表示为"test/test.txt"

若基准目录为C, B的路径表示为"../test1.txt"

另外，“./”表示当前目录，“../”表示上级目录

<!-- more -->

## java io定位文件资源

那么，我们在java中如何读取某个文件？上代码：

```
// 目录结构
src
 |
 |--test
 |   |
 |   |--PathTest.java 
 |
resource
 |
 |--data.txt
```

```java
public class PathTest {

	public static String  dataFilePath = "resource/data.txty";
	
	public static String getUserDir() {
		//打印运行程序的目录，即启动java程序的目录
		String userDir = System.getProperty("user.dir");
		System.out.println("运行java的工作目录 System.getProperty(\"user.dir\")： " + userDir);
		return userDir;
	}
	
	public static void testDataPath1() {
		String msg = ">> Path = System.getProperty(\"user.dir\") + \"resource/data.txt\"";
		String userDir = getUserDir();
		//等同于 "resource/data.txt"
		String filePath = userDir + System.getProperty("file.separator") + dataFilePath;
		printFileContent(filePath ,msg);
	}
	
	public static void testDataPath2() {
		String msg = "Path = \"resource/data.txt\"";
		String filePath = dataFilePath;
		printFileContent(filePath, msg);
	}
	
	public static void testDataPath3() {
		String msg = "Path = \"./resource/data.txt\"";
		String filePath = "./resource/data.txt";
		printFileContent(filePath, msg);
	}
	
	private static void printFileContent(String filePath, String msg) {
		System.out.println("****************************");
		System.out.println(msg);
		File file = new File(filePath);
		InputStream stream;
		try {
			stream = new FileInputStream(file);
			BufferedReader reader = new BufferedReader(new InputStreamReader(stream));
			String line = null;
			while ((line = reader.readLine()) != null) {
				System.out.println(line);
			}
		} catch (Exception e) {
			e.printStackTrace();
		} finally {
			System.out.println("****************************");
		} 
	}
	
	public static void main(String[] args) {
		testDataPath1();
		testDataPath2();
		testDataPath3();
	}

}
```
其中`testDataPath2`、`testDataPath1`、`testDataPath3`这三个方法的效果是一样的。

`System.getProperty("user.dir")`这个方法获取了当前的工作目录，也就是启动jvm的目录。例如：

ps: 更多关于System.getProperty()的介绍：[System Properties](http://docs.oracle.com/javase/tutorial/essential/environment/sysprop.html)

你的java程序位于：/home/yukai/code/test.jar 

若你在目录/home/yukai下使用命令 `java -cp code/test.jar test.PathTest` 启动java程序时，目录/home/yukai就是你的工作目录。

在`testDataPath2`当中，直接使用"resource/data.txty"来作为文件读取路径时，java会默认为基准目录为当前的工作目录，"resource/data.txty"此时就是相对于这个基准目录的路径。
也就是说，java会把工作目录与"resource/data.txty"拼接起来，作为一个绝对路径去读取文件，也就是`testDataPath1`中的例子。

有Eclipse中启动你的java工程的目录就是工程根目录，工程根目录也就是工作目录，如果你读取文件的方式类似于`testDataPath2`的话，他会在工程根目录下找你的文件。
有时候我们会遇到，在Eclipse中读取文件没有问题，但是打成jar包之后运行(像上面运行jar包的例子)就会报找不到文件的错误。那么此时就要检查你的当前工作目录下(/home/yukai)是否有这些文件的存在了。

## File.getPath & File.getAbsolutePath & File.getCanonicalPath

```java
public static void testGetPath() {
		File file = new File("./resource/data.txt");
		System.out.println("File.getPath(): " + file.getPath());
		System.out.println("File.getAbsolutePath(): "+ file.getAbsolutePath());
		try {
			System.out.println("File.getCanonicalPath(): " + file.getCanonicalPath());
		} catch (Exception e) {
			e.printStackTrace();
		}
}
```

上述代码运行结果：

```
File.getPath(): ./resource/data.txt
File.getAbsolutePath(): /home/yukai/workspace/test/./resource/data.txt
File.getCanonicalPath(): /home/yukai/workspace/test/resource/data.txt
```
摘抄一段[stackoverflow](http://stackoverflow.com/questions/1099300/whats-the-difference-between-getpath-getabsolutepath-and-getcanonicalpath)上的答案:

```
getPath() gets the path string that the File object was constructed with, and it may be relative current directory.

getAbsolutePath() gets the path string after resolving it against the current directory if it's relative, resulting in a fully qualified path.

getCanonicalPath() gets the path string after resolving any relative path against current directory, and removes any relative pathing (. and ..), and any file system links to return a path which the file system considers the canonical means to reference the file system object to which it points.
```

## 读取classpath下的文件

```java
public static void getClassPath() {
		System.out.println("PathTest.class.getResource(\"/\"): " + PathTest.class.getResource("/"));
		System.out.println("PathTest.class.getResource(\"\"): " + PathTest.class.getResource(""));
		
		System.out.println("PathTest.class.getClassLoader().getResource(\"/\"): " + PathTest.class.getClassLoader().getResource("/"));
		System.out.println("PathTest.class.getClassLoader().getResource(\"\"): " + PathTest.class.getClassLoader().getResource(""));
}
```

运行结果(Eclipse)：

```
//以“/”开头，表示相对于package根目录
PathTest.class.getResource("/"): file:/home/yukai/workspace/test/bin/
//不以“/”开头，表示相对于class文件所在目录
PathTest.class.getResource(""): file:/home/yukai/workspace/test/bin/test/
//
PathTest.class.getClassLoader().getResource("/"): null
//getClassLoader().getResource("")不以“/”开头，相对于package根目录
PathTest.class.getClassLoader().getResource(""): file:/home/yukai/workspace/test/bin/
```
## 获取jar包路径

java开发中常常需要取得程序生成的jar包所在的路径，比如生成一些log文件的时候，需要把该程序生成的log放到jar包的的同级目录下。
此时，我们需要知道jar包所在的位置，注意，不是启动jvm实例的位置。

```
URL url = Config.class.getProtectionDomain().getCodeSource().getLocation();
String path = new URI(url.getProtocol(), url.getHost(), url.getPath(), url.getQuery(), null).getPath(); 
if (path != null) {   
   if (path.endsWith("/") || path.endsWith("\\")) {      
          path = path.substring(0, path.length() - 1);    
   }    
   if (path.endsWith(".jar")) {        
          int index = path.lastIndexOf("/");
          if (index != -1) {           
                path = path.substring(0, index);
          }
          defultLogPath = path + File.separator + "log";
   } else { 
       defultLogPath = path + File.separator + ".." + File.separator + "log" ;
   }
}
```

## Path.java

jdk1.7之后，新增了一个类File,位于java.nio.file下，该类提供了一些路径的操作。

具体的使用不一一介绍，用到时可查找oracle的官方手册，已经写的很详细了：[Path Operations](https://docs.oracle.com/javase/tutorial/essential/io/pathOps.html)
