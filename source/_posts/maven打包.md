---
layout: post
title: 使用maven打包
date: 2017-10-15 19:56:22
categories: 工具
tags:
- maven
---

> 前段时间做的web项目涉及到了打包的问题，记录一下使用maven打包的过程...

## 项目打包为fatjar

什么是fatjar？做过java项目的都知道，一个项目从开发到部署，一般需要经过打包，把一些资源文件和类文件压缩到一块，形成一个单独的文件，叫做jar（或者war）。如果这个项目依赖了一些第三方的jar包，在最终的部署阶段，这些jar有两种存在方式：

- 一种是单独放到一个与项目jar包并行的文件夹中（一般叫做lib），然后使用`-classpath`将这个文件夹下的jar加入到classpath

```
  ---
    |--VersionManager.jar
    |
    |--lib
        |
        |--a.jar
        |
        |--b.jar
```

<!-- more -->

`java -cp lib/*;VersionManager.jar com.oscar.App`

a.jar与b.jar分别为依赖的第三方jar包，VersionManager.jar是项目jar，com.oscar.App是启动类

注意，window下的变量分隔符为";"，而linux下则为":"

- 一种是直接把依赖的第三方jar包与项目打包到一块，形成一个单独的jar

`java -cp VersionManager.jar com.oscar.App`

显然，fatjar的运行命令看起来更简洁一些。如何使用maven打包fatjar？

```xml
<build>
    <plugins>
        <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-assembly-plugin</artifactId>
            <version>CHOOSE LATEST VERSION HERE</version>
            <configuration>
                <descriptorRefs>
                    <descriptorRef>jar-with-dependencies</descriptorRef>
                </descriptorRefs>
            </configuration>
            <executions>
                <execution>
                    <id>assemble-all</id>
                    <phase>package</phase>
                    <goals>
                        <goal>single</goal>
                    </goals>
                </execution>
            </executions>
        </plugin>
    </plugins>
</build>
```

上面的配置将打包fatjar的目标绑定到了package阶段。使用`maven package`命令，在项目target目录下会生成两个jar文件：*with-dependencies.jar就是生成的 "fatjar"，另一个则是不包含第三方依赖的普通jar包。

## 项目单独打包

有时候，fatjar并不是完美的发布方案。想到下面两个原因：

1. 由于fatjar包含了所有第三方的依赖，这个单独的jar包往往会变得很大。修改了一些代码上的bug之后，需要远程部署到生产环境，如果jar包很大，传输起来不是很方便。

2. 依赖的第三方jar拥有一些输出日志的功能。比如，在项目中依赖了某个jdbc的jar包，而这个jar提供了可以通过一些连接参数动态的输出sql日志到jdbc jar所在的同级目录的功能。此时如果jdbc的jar被打包到fatjar当中，输出日志时会报错。

考虑到上面两种情况，我们还是需要第一种部署方案：

```
---
  |
  |--src/main/java
  |             |
  |             |--.java
  |             
  |--src/main/resource
                |
                |--application.yml
                |
                |--log4j.properties
              
  
```

```xml
<build>
	<plugins>
        <!-- 指定编译时使用的jdk版本 -->
		<plugin>
			<groupId>org.apache.maven.plugins</groupId>
			<artifactId>maven-compiler-plugin</artifactId>
			<version>3.1</version>
			<configuration>
				<source>1.8</source>
				<target>1.8</target>
			</configuration>
		</plugin>
		<!-- 将依赖的jar拷贝到lib目录下 -->
		<plugin>
			<groupId>org.apache.maven.plugins</groupId>
			<artifactId>maven-dependency-plugin</artifactId>
			<executions>
				<execution>
					<id>copy-dependencies</id>
					<phase>package</phase>
					<goals>
						<goal>copy-dependencies</goal>
					</goals>
					<configuration>
						<outputDirectory>${project.build.directory}/lib</outputDirectory>
					</configuration>
				</execution>
			</executions>
		</plugin>
        <!-- 拷贝项目src/main/resources/目录下的指定配置文件到conf目录下 -->
		<plugin>
			<groupId>org.apache.maven.plugins</groupId>
			<artifactId>maven-resources-plugin</artifactId>
			<executions>
				<execution>
					<id>copy-resource</id>
					<phase>package</phase>
					<goals>
						<goal>copy-resources</goal>
					</goals>
					<configuration>
						<encoding>UTF-8</encoding>				
						<outputDirectory>${project.build.directory}/conf</outputDirectory>
						<resources>
							<resource>
								<directory>src/main/resources/</directory>
								<filtering>true</filtering>
								<includes>
									<include>application.yml</include>
									<include>log4j.properties</include>
								</includes>
							</resource>
						</resources>
					</configuration>
				</execution>
			</executions>
		</plugin>
        <!-- 指定打包时的一些选项 -->
		<plugin>
			<groupId>org.apache.maven.plugins</groupId>
			<artifactId>maven-jar-plugin</artifactId>
			<configuration>
				<finalName>VersionManager</finalName>
				<archive>
					<manifest>
						<!-- 为依赖包添加路径, 这些路径会写在MANIFEST文件的Class-Path下 -->
						<addClasspath>true</addClasspath>
						<classpathPrefix>lib/</classpathPrefix>
						<mainClass>com.oscar.tempVersionManager.web.App</mainClass>
					</manifest>
					<manifestEntries>
						<!-- 在Class-Path下添加配置文件的路径 -->
						<Class-Path>conf/</Class-Path>
					</manifestEntries>
				</archive>
				<excludes>
					<exclude>application.yml</exclude>
					<exclude>log4j.properties</exclude>
				</excludes>
			</configuration>
		</plugin>
	</plugins>
</build>
```

注意几点：

- 将依赖的jar包复制到target/lib目录下

- 将application.yml、log4j.properties复制到target/conf目录下

- 将lib目录下的jar包加入到MANIFEST.MF配置的classpath中

- 将conf目录下的文件添加到MANIFEST.MF配置的classpath中

- application.yml、log4j.properties将不被打包到jar中

- 配置生成jar包的名字为VersionManager

通过上面几点的配置，最终在target目录下生成了conf/，lib/，VersionManager.jar

将这三个文件拷贝到生产环境当中，然后执行java命令：

`nohup java -jar VersionManager.jar >logs/info.log 2>&1 &`

logs目录为日志文件的输出目录。

nohup的使用参阅[Linux下的守护进程](http://yukai.space/2017/10/01/Linux%E4%B8%8B%E7%9A%84%E5%AE%88%E6%8A%A4%E8%BF%9B%E7%A8%8B/)

## 存在的问题

以上两种方式都存在一个问题，那就是无论是`maven-assembly-plugin`还是`maven-dependency-plugin`都会忽略下面的形式的依赖：

```xml
<dependency>
    <groupId>com.oscar</groupId>
    <artifactId>starteam100</artifactId> 
    <version>1.0</version> 
    <scope>system</scope> 
    <systemPath>${project.basedir}/lib/starteam100.jar</systemPath> 
</dependency>
```

[stackoverflow](https://stackoverflow.com/questions/2229757/maven-add-a-dependency-to-a-jar-by-relative-path)给出了解决方案：

```
If you really want this (understand, if you can't use a corporate repository), then my advice would be to use a "file repository" local to the project and to not use a system scoped dependency. The system scoped should be avoided, such dependencies don't work well in many situation (e.g. in assembly), they cause more troubles than benefits.

So, instead, declare a repository local to the project:

<repositories>
  <repository>
    <id>my-local-repo</id>
    <url>file://${basedir}/my-repo</url>
  </repository>
</repositories>

Install your third party lib in there using install:install-file with the localRepositoryPath parameter:


 mvn install:install-file -Dfile=<path-to-file> -DgroupId=<myGroup> \ 
                         -DartifactId=<myArtifactId> -Dversion=<myVersion> \
                         -Dpackaging=<myPackaging> -DlocalRepositoryPath=<path>

Update: It appears that install:install-file ignores the localRepositoryPath when using the version 2.2 of the plugin. However, it works with version 2.3 and later of the plugin. So use the fully qualified name of the plugin to specify the version:

mvn org.apache.maven.plugins:maven-install-plugin:2.3.1:install-file \
                         -Dfile=<path-to-file> -DgroupId=<myGroup> \ 
                         -DartifactId=<myArtifactId> -Dversion=<myVersion> \
                         -Dpackaging=<myPackaging> -DlocalRepositoryPath=<path>
maven-install-plugin documentation

Finally, declare it like any other dependency (but without the system scope):

<dependency>
  <groupId>your.group.id</groupId>
  <artifactId>3rdparty</artifactId>
  <version>X.Y.Z</version>
</dependency>

This is IMHO a better solution than using a system scope as your dependency will be treated like a good citizen (e.g. it will be included in an assembly and so on).

Now, I have to mention that the "right way" to deal with this situation in a corporate environment (maybe not the case here) would be to use a corporate repository.
```

## 类路径下查找配置文件

上面的打包过程中，把配置文件application.yml、log4j.properties拷贝到/conf目录下，主要是为了可以在不用更新jar的情况下修改一些配置，只要重启进程便可以生效。否则，如果配置文件被打包到jar中，修改配置文件就会变得比较麻烦。

但是，代码中如何能够读取到指定的配置文件呢？spring中有一个类提供了在classpath中读取指定文件的功能：

`File dumpFile = new org.springframework.core.io.ClassPathResource("application.yml").getFile();`

但是每次做项目的时候不一定都会依赖spring。看了一下源码，写了一个类似的比较简单的util类，帮助我们在代码中读取类路径下的配置文件：

```java
import java.io.IOException;
import java.net.URL;

import org.apache.commons.io.IOUtils;

public class ClassPathResource {
	private ClassLoader classLoader;
	private String path;

	public ClassPathResource(String path) {
		this.path = path;
	}

	public byte[] getBytes() throws IOException {
		URL url = resolveURL();
		byte[] byteArray = IOUtils.toByteArray(url.openStream());
		return byteArray;
	}
	
	public String getString() throws IOException {
		return new String(getBytes());
	}

	private URL resolveURL() {
		if (this.classLoader == null) {
			classLoader = getDefaultClassLoader();
		}
		URL url = classLoader.getResource(path);
		if (url != null) {
			return url;
		}
		url = ClassLoader.getSystemResource(path);
		if (url == null) {
			throw new IllegalArgumentException(String.format("Error opening %s", path));
		}
		return url;
	}

	private ClassLoader getDefaultClassLoader() {
		ClassLoader cl = null;
		try {
			cl = Thread.currentThread().getContextClassLoader();
		} catch (Throwable ex) {
		}
		if (cl == null) {
			cl = ClassPathResource.class.getClassLoader();
			if (cl == null) {
				try {
					cl = ClassLoader.getSystemClassLoader();
				} catch (Throwable ex) {
				}
			}
		}
		return cl;
	}
}
```

以上