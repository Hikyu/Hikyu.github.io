---
layout: post
title: maven学习笔记
date: 2017-04-17 20:51:25
categories: 工具
tags: java
---

> 上周末两天时间基本上将《Maven实战》这本书看完了。《Maven实战》是很棒的一本介绍maven相关知识的书籍。读完之后，对学到的maven相关的内容做一个梳理总结。

## Maven基础

有关[Maven](http://maven.apache.org/)如何安装和设置，不在这里啰嗦了，可以到[官网](http://maven.apache.org/)下载最新版本然后安装。

Maven是一个异常强大的构建工具，能够帮助我们自动化构建过程，从清理、编译、测试到生成报告，打包和部署。我们要做的只是使用Maven配置好项目，然后输入简单的命令，Maven会帮我们处理这些任务。

Maven项目的核心是pom.xml。Pom定义了项目的基本信息，用于描述项目如何构建，声明项目依赖等。下面是一个例子：
<!-- more -->

```
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
	<modelVersion>4.0.0</modelVersion>

	<groupId>space.yukai.mergetool</groupId>
	<artifactId>mergetool-core</artifactId>
	<version>0.0.1-SNAPSHOT</version>
	<packaging>jar</packaging>
    <name>MergeTool</name>

	<name>space.yukai</name>
	<url>http://maven.apache.org</url>

	<properties>
		<project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
	</properties>

	<build>
		<plugins>
			<plugin>
				<groupId>org.apache.maven.plugins</groupId>
				<artifactId>maven-compiler-plugin</artifactId>
				<configuration>
					<source>1.8</source>
					<target>1.8</target>
				</configuration>
			</plugin>
		</plugins>
	</build>
	<dependencies>
		<dependency>
			<groupId>junit</groupId>
			<artifactId>junit</artifactId>
			<version>4.4</version>
			<scope>test</scope>
		</dependency>

		<!-- https://mvnrepository.com/artifact/commons-io/commons-io -->
		<dependency>
			<groupId>commons-io</groupId>
			<artifactId>commons-io</artifactId>
			<version>2.5</version>
		</dependency>
	</dependencies>
</project>

```

Maven不仅是一个构建工具，还是一个依赖管理工具和项目信息管理工具。我们的java项目或多或少都会依赖一些第三方的类库，而maven提供了中央仓库，能够帮助我们自动下载构件。

Maven通过一个坐标系统准确的定位每一个构件(artifact)，也就是通过一组坐标Maven能够找到任何一个java类库(如jar包)。

在Maven的世界中，任何的jar、pom、或war都是通过这些坐标进行区分的。上面代码中开头的groupId、artifactId、version定义了这个项目的基本坐标。

- groupId定义了项目属于哪个组，这个组往往和项目所在的组织有关联。比如Googlecode上面建立了一个项目app，那么groupId就应该为com.googlecode.app

- artifactId定义了当前项目在组中的唯一Id。比如为app中不同的子项目分配artifactId，如app-core、app-util、app-web

- version指定了项目当前的版本。SNAPSHOT表示项目还处于开发中，是不稳定的版本

- packaging指定了项目的打包方式，默认为jar

- name定义了项目名称

上面dependency标签中的内容就是本项目声明的依赖。可以看到dependency标签中声明了groupId、artifactId、version这三个属性，比如commons-io，Maven解析到这个依赖时，就会根据这个坐标去本地仓库查找这个坐标下的依赖是否已经被下载，如果没有下载，那么到中央仓库去下载依赖的jar包到本地仓库，然后把下载好的jar包路径添加到classpath当中。这些工作都是自动进行的，我们要做的，只是在pom.xml中声明这个依赖即可。

Maven在项目构建过程和过程的各个阶段的工作都是由插件实现的，并且大部分的插件都是现成的。我们只需要声明项目的基本元素，Maven就会执行内置的构建过程。上面代码中plugin标签中的内容，是对maven-compiler-plugin这个插件进行的配置。

## Archetype

Maven提倡 "约定优于配置"。遵循Maven的一些约定，我们可以快速的创建项目并完成构建。对于遵循约定的Maven项目，我们可以快速的了解其结构，减轻了我们的学习成本。

比如：在项目的根目录放置pom.xml，在src/main/java目录放置项目主代码，在src/test/java放置项目测试代码。我们称这些基本的目录结构为项目骨架。通过Archetype插件可以帮助我们快速的创建出项目骨架。

运行`mvn archetype:generate`命令，选择我们的项目骨架。

```
C:\Users\kyu\Desktop\test>mvn archetype:generate
[INFO] Scanning for projects...
[INFO]
[INFO] ------------------------------------------------------------------------
[INFO] Building Maven Stub Project (No POM) 1
[INFO] ------------------------------------------------------------------------
[INFO]
[INFO] >>> maven-archetype-plugin:3.0.1:generate (default-cli) @ standalone-pom >>>
[INFO]
[INFO] <<< maven-archetype-plugin:3.0.1:generate (default-cli) @ standalone-pom <<<
[INFO]
[INFO] --- maven-archetype-plugin:3.0.1:generate (default-cli) @ standalone-pom ---
[INFO] Generating project in Interactive mode
[INFO] No archetype defined. Using maven-archetype-quickstart (org.apache.maven.archetypes:maven-archetype-quickstart:1.0)
Choose archetype:
1: remote -> am.ik.archetype:maven-reactjs-blank-archetype (Blank Project for React.js)
2: remote -> am.ik.archetype:msgpack-rpc-jersey-blank-archetype (Blank Project for Spring Boot + Jersey)
3: remote -> am.ik.archetype:mvc-1.0-blank-archetype (MVC 1.0 Blank Project)
4: remote -> am.ik.archetype:spring-boot-blank-archetype (Blank Project for Spring Boot)
5: remote -> am.ik.archetype:spring-boot-docker-blank-archetype (Docker Blank Project for Spring Boot)
6: remote -> am.ik.archetype:spring-boot-gae-blank-archetype (GAE Blank Project for Spring Boot)
7: remote -> am.ik.archetype:spring-boot-jersey-blank-archetype (Blank Project for Spring Boot + Jersey)
8: remote -> at.chrl.archetypes:chrl-spring-sample (Archetype for Spring Vaadin Webapps)
9: remote -> br.com.address.archetypes:struts2-archetype (an archetype web 3.0 + struts2 (bootstrap + jquery) + JPA 2.1 with struts2 login system)
10: remote -> br.com.address.archetypes:struts2-base-archetype (An Archetype with JPA 2.1; Struts2 core 2.3.28.1; Jquery struts plugin; Struts BootStrap plugin; json Struts plugin;
.
.
.
1813: remote -> us.fatehi:schemacrawler-archetype-plugin-command (-)
1814: remote -> us.fatehi:schemacrawler-archetype-plugin-dbconnector (-)
1815: remote -> us.fatehi:schemacrawler-archetype-plugin-lint (-)
Choose a number or apply filter (format: [groupId:]artifactId, case sensitive contains): 955:
```

默认为maven-archetype-quickstart(955)。选择该Archetype，Maven会提示输入创建项目的groupId、artifactId、version及包名package。

在当前目录下，Archetype插件会创建以artifactId命名的子目录：

{% asset_img mvn.png artifact %}

可以看出，使用约定俗成的Archetype，不仅使用Maven插件代替了原本需要手工处理的劳动，同时节省了时间，降低了错误发生的概率。

也可以定义自己的项目骨架，在创建项目的时候，就可以直接使用该Archetype。

## 生命周期

Maven的生命周期对所有的构建过程进行了抽象和统一。这个生命周期包括项目的清理、初始化、编译、测试、打包、集成测试、验证、部署和站点生成等所有的构建步骤。所有的项目构建，都可以映射到这样一个生命周期上。

Maven只是抽象出了生命周期，生命周期中实际的任务都是交给插件完成的，类似于设计模式中的模板方法模式。

Maven拥有三套独立的生命周期：clean、default、site。每个生命周期包含一些阶段：

- clean

  pre-clean  执行一些清理前需要完成的工作

  clean  清理上一次构建生成的文件

  post-clean   执行一些清理后需要完成的工作

- default
  
  validate	检查工程配置是否正确，完成构建过程的所有必要信息是否能够获取到。

  initialize	初始化构建状态，例如设置属性。

  generate-sources	生成编译阶段需要包含的任何源码文件。

  process-sources	处理源代码，例如，过滤任何值（filter any value）。

  generate-resources	生成工程包中需要包含的资源文件。

  process-resources	拷贝和处理资源文件到目的目录中，为打包阶段做准备。

  compile	编译工程源码。

  process-classes	处理编译生成的文件，例如 Java Class 字节码的加强和优化。

  generate-test-sources	生成编译阶段需要包含的任何测试源代码。

  process-test-sources	处理测试源代码，例如，过滤任何值（filter any values)。

  test-compile	编译测试源代码到测试目的目录。

  process-test-classes	处理测试代码文件编译后生成的文件。

  test	使用适当的单元测试框架（例如JUnit）运行测试。

  prepare-package	在真正打包之前，为准备打包执行任何必要的操作。

  package	获取编译后的代码，并按照可发布的格式进行打包，例如 JAR、WAR 或者 EAR 文件。

  pre-integration-test	在集成测试执行之前，执行所需的操作。例如，设置所需的环境变量。

  integration-test	处理和部署必须的工程包到集成测试能够运行的环境中。

  post-integration-test	在集成测试被执行后执行必要的操作。例如，清理环境。

  verify	运行检查操作来验证工程包是有效的，并满足质量要求。

  install	安装工程包到本地仓库中，该仓库可以作为本地其他工程的依赖。

  deploy	拷贝最终的工程包到远程仓库中，以共享给其他开发人员和工程。

- site

  pre-site  执行一些生成项目站点前需要完成的工作

  site  生成项目站点文档

  post-site  执行一些生成项目站点前需要完成的工作

  site-deploy  将生成的站点发布到服务器

每个生命周期的阶段是有顺序的，后面的阶段依赖前面的阶段。使用maven最直接的交互方式就是调用这些生命周期的阶段。比如，当用户调用pre-clean时，只有pre-clean阶段得以执行，当调用clean时，pre-clean和clean依次执行，当调用post-clean时，pre-clean、clean和post-clean依次执行。

虽然每个生命周期内的阶段是有顺序和前后依赖的，但是三套生命周期之间是互相独立的。比如，当用户调用clean生命周期的clean阶段时，不会触发default生命周期的任何阶段，反之，当用户调用default生命周期的compile阶段时，也不会触发clean生命周期的任何阶段。

`mvn clean install`，该命令调用了clean生命周期clean阶段与default生命周期install 阶段。实际执行的阶段为clean生命周期的pre-clean、clean阶段，以及default生命周期从validate到install所有阶段。

## 插件目标

Maven的核心仅仅定义了抽象的生命周期，具体的任务是由插件来完成的。

每个插件可以完成多个功能，每个功能就是插件的一个目标。比如maven-dependency-plugin可以列出项目依赖树，列出所有已解析的依赖等等。这两个目标对应的命令为：

`mvn dependency:tree`，`mvn dependency:list`。冒号前面是插件前缀，冒号后面是插件目标。

所以，我们知道了mvn命令有两种调用方式，一种调用其生命周期，一种直接调用插件目标。

插件的生命周期与插件相互绑定，完成实际的构建任务。调用生命周期实际上也是执行了多个插件目标。

- 内置绑定

  Maven核心已经对一些主要的生命周期阶段绑定了很多插件目标，当用户通过命令行调用生命周期的时候，对应的插件目标就会执行相应的任务。

  比如，clean生命周期有pre-clean、clean、post-clean三个阶段，clean生命周期阶段与插件目标的绑定关系如下：

  生命周期阶段 | 插件目标
  ------------|-----------
  pre-clean   |
  clean       |maven-clean-plugin:clean
  post-clean  |

  执行命令`mvn post-clean`，输出如下：

  ```
  [INFO] ------------------------------------------------------------------------
  [INFO] Building space.yukai 0.0.1-SNAPSHOT
  [INFO] ------------------------------------------------------------------------
  [INFO] 
  [INFO] --- maven-clean-plugin:2.5:clean (default-clean) @ space.yukai ---
  [INFO] ------------------------------------------------------------------------
  [INFO] BUILD SUCCESS
  [INFO] ------------------------------------------------------------------------
  [INFO] Total time: 0.409 s
  [INFO] Finished at: 2017-04-17T16:37:08+08:00
  [INFO] Final Memory: 7M/106M
  [INFO] ------------------------------------------------------------------------
  ```
  从输出中可以看到，执行的插件目标仅为`maven-clean-plugin:clean`

- 自定义绑定

  除了内置绑定之外，用户可以自己选择将某个插件目标绑定到生命周期的某个阶段。

  比如，我们可以自行配置创建项目的源码jar包。maven-source-plugin的jar-no-fork目标可以将项目的主代码打包成jar文件。我们将其绑定到clean生命周期的post-clean阶段测试一下：

  ```
  <plugin>
		<groupId>org.apache.maven.plugins</groupId>
		<artifactId>maven-source-plugin</artifactId>
		<executions>
			    <execution>
				    <id>attach-source</id>
				    <phase>post-clean</phase>
				        goals>
				        <goal>jar-no-fork</goal>
				    </goals>
			 </execution>
		</executions>
  </plugin>
  ```

  运行`mvn post-clean`，输出：

  ```
  [INFO] ------------------------------------------------------------------------
  [INFO] Building space.yukai 0.0.1-SNAPSHOT
  [INFO] ------------------------------------------------------------------------
  [INFO] 
  [INFO] --- maven-clean-plugin:2.5:clean (default-clean) @ space.yukai ---
  [INFO] Deleting Y:\code\versionmergetool\VersionMergeTool\target
  [INFO] 
  [INFO] --- maven-source-plugin:3.0.1:jar-no-fork (attach-source) @ space.yukai ---
  [INFO] Building jar: Y:\code\versionmergetool\VersionMergeTool\target\space.yukai-0.0.1-SNAPSHOT-sources.jar
  [INFO] ------------------------------------------------------------------------
  [INFO] BUILD SUCCESS
  [INFO] ------------------------------------------------------------------------
  [INFO] Total time: 1.082 s
  [INFO] Finished at: 2017-04-17T16:55:32+08:00
  [INFO] Final Memory: 7M/111M
  [INFO] ------------------------------------------------------------------------
  ```

  可以看到，当执行post-clean阶段的时候，maven-source-plugin:jar-no-fork 创建了一个以-sources.jar结尾的源码包。

为了了解插件有哪些配置，我们可以使用maven-help-plugin来获取插件信息。

运行命令`mvn help:describe -Dplugin=compiler`

```
[INFO] Scanning for projects...
[INFO]
[INFO] ------------------------------------------------------------------------
[INFO] Building mvntest-test 1.0-SNAPSHOT
[INFO] ------------------------------------------------------------------------
[INFO]
[INFO] --- maven-help-plugin:2.2:describe (default-cli) @ mvntest-test ---
[INFO] org.apache.maven.plugins:maven-compiler-plugin:3.6.1

Name: Apache Maven Compiler Plugin
Description: The Compiler Plugin is used to compile the sources of your
  project.
Group Id: org.apache.maven.plugins
Artifact Id: maven-compiler-plugin
Version: 3.6.1
Goal Prefix: compiler

This plugin has 3 goals:

compiler:compile
  Description: Compiles application sources

compiler:help
  Description: Display help information on maven-compiler-plugin.
    Call mvn compiler:help -Ddetail=true -Dgoal=<goal-name> to display
    parameter details.

compiler:testCompile
  Description: Compiles application test sources.

For more information, run 'mvn help:describe [...] -Ddetail'

[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time: 5.944s
[INFO] Finished at: Mon Apr 17 17:02:52 CST 2017
[INFO] Final Memory: 11M/110M
[INFO] ------------------------------------------------------------------------
```
可以得到插件maven-compiler-plugin的信息及相关目标。还可以加上detail参数输出更详细的信息`mvn help:describe -Dplugin=compiler -Ddetail`

- 前缀

  笔记开头说了，在maven的世界中，所有的构件都是由坐标来确定的，构件包括依赖的jar或者插件。那么我们上面的`mvn help:describe -Dplugin=compiler`中并没有指定插件的坐标，为什么能够正常的运行呢？

  其实`mvn help:describe -Dplugin=compiler`就等效于`mvn org.apache.maven.plugins:maven-help-plugin:2.2:describe -Dplugin=compiler`。help就是maven-help-plugin的前缀，maven能够根据这个前缀找到对应的artifactId，从而解析得到groupId和version，所有能够精确的定位某个插件。compiler也是前缀。

## 依赖

dependency标签可以声明以下一些元素：

```
<dependency>
	<groupId>...</groupId>
	<artifactId>...</artifactId>
	<version>...</version>
	<scope>...</scope>
    <type>...</type>
	<optional>...</optional>
	<exclusions>
		 <exclusion>...</exclusion>
	</exclusions>
</dependency>
```
groupId、artifactId、version：声明了依赖的基本坐标

type: 依赖的类型，对应于项目坐标定义中的packaging，比如说jar

scope：依赖的范围

optional：是否是可选依赖

exclusions: 排除传递性依赖

- 依赖范围(scope)

  Maven有三套classpath，编译项目主代码、编译测试代码、实际运行。依赖范围就是用来控制依赖与这三种classpath的关系.有以下几个选项：

  依赖范围 | 对主代码classpath有效 | 对测试classpath有效 | 对运行时classpath有效
  --------|----------------------|--------------------|----------------------
  compile |         Y            |         Y          |           Y  
  test    |         N            |         Y          |           N
  provided|         Y            |         Y          |           N
  runtime |         N            |         Y          |           Y
  system  |         Y            |         Y          |           N

- 传递性依赖
  
  我们在项目的pom.xml文件中声明了直接依赖，如果声明的这些依赖还依赖于其他第三方组件，在maven中，我们不用考虑这些间接依赖，也不用担心引入多余的依赖。Maven会解析各个直接依赖的pom，将那些必要的间接依赖以传递性依赖的方式引入到当前项目的classpath中。

  依赖范围不仅能够控制依赖与三种classpath的关系，还会对传递性依赖产生影响。比如设A依赖于B，B依赖于C，A对于B是第一直接依赖，B对于C是第二直接依赖，A对与C是传递性依赖。第一直接依赖与第二直接依赖的依赖范围决定了传递性依赖的依赖范围。

## 仓库
## 构建
## 聚合与继承

## 属性与Profile