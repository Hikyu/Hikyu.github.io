---
layout: post
title: maven学习笔记(二)
date: 2017-04-19 11:58:03
categories: 
- 技术
- 工具
tags: 
- java
- maven
---

## 依赖

dependency标签可以声明以下一些元素：

```xml
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
<!-- more -->
groupId、artifactId、version：声明了依赖的基本坐标

type: 依赖的类型，对应于项目坐标定义中的packaging，比如说jar

scope：依赖的范围

optional：是否是可选依赖

exclusions: 排除传递性依赖

- 依赖范围(scope)

  Maven有三套classpath，编译项目主代码、编译测试代码、实际运行。依赖范围就是用来控制依赖与这三种classpath的关系.有以下几个选项：

| 依赖范围     | 对主代码classpath有效 | 对测试classpath有效 | 对运行时classpath有效 |
|----------|-----------------|----------------|-----------------|
| compile  | Y               | Y              | Y               |
| test     | N               | Y              | N               |
| provided | Y               | Y              | N               |
| runtime  | N               | Y              | Y               |
| system   | Y               | Y              | N               |

- 传递性依赖
  
  我们在项目的pom.xml文件中声明了直接依赖，如果声明的这些依赖还依赖于其他第三方组件，在maven中，我们不用考虑这些间接依赖，也不用担心引入多余的依赖。Maven会解析各个直接依赖的pom，将那些必要的间接依赖以传递性依赖的方式引入到当前项目的classpath中。

  依赖范围不仅能够控制依赖与三种classpath的关系，还会对传递性依赖产生影响。比如设A依赖于B，B依赖于C，A对于B是第一直接依赖，B对于C是第二直接依赖，A对与C是传递性依赖。第一直接依赖与第二直接依赖的依赖范围决定了传递性依赖的依赖范围。如下图，最左边第一列表示第一直接依赖范围，最上面一行表示第二直接依赖范围，中间交叉单元格表示传递性依赖范围

| compile  | test     | provided | runtime  |          |
|----------|----------|----------|----------|----------|
| compile  | compile  |          |          | runtime  |
| test     | test     |          |          | test     |
| provided | provided |          | provided | provided |
| runtime  | runtime  |          |          | runtime  |

  比如，account-email 项目有一个com.icegree:greemail:1.3.1b的直接依赖，这是第一直接依赖，其依赖范围是test；而greemail又有一个javax.mail:mail:1.4的直接依赖，这是第二直接依赖，其依赖的范围是compile。根据上面的表格可以推断，javax.mail:mail:1.4是account-email的一个范围是test的传递依赖。

- 依赖调解

  对于一个构件，存在于不同依赖路径上。选择哪个路径上的构件就是依赖调解要解决的问题，有两种策略：

  1. 路径近者优先。 比如，项目A有这样的依赖关系：A->B->C->x(1.0)、A->D->X(2.0)，对于两个版本的X，如果都引入就会造成依赖重复。根据路径近者优先的策略，X(2.0)会被引入；

  2. 第一声明者优先。 路径近者优先的策略不能解决所有问题，如果出现路径长度相同的情况，那么maven就会选择依赖声明在前的那个路径上的版本。

- 可选依赖(optional)
  
  假设有这样的依赖关系：项目A依赖于项目B，项目B依赖于项目X，Y，B对于X和Y都是可选依赖：A-B、B->X(可选)、B->Y(可选)。那么此时，由于X、Y都是可选依赖，依赖性将不会传递，也就是说，A中不会引入X和Y。

  有这样一种情况符合可选依赖的场景：项目B是一个持久层的工具包，支持多种数据库，X、Y就是其依赖的数据库驱动程序，但是我们的项目A在使用这个工具包B的时候，只依赖一种数据库，故我们不需要将X和Y全部引入。这种情况下需要我们在项目A中声明实际使用的数据库驱动依赖。

- 排除依赖(exclusions)
 
  传递性依赖为我们的项目隐式的引入了很多依赖，如果我们不想引入某个传递性依赖(自己选择依赖版本)，就可以使用排除依赖。

  ```xml
  <dependency>
		<groupId>org.slf4j</groupId>
		<artifactId>slf4j-api</artifactId>
		<version>1.7.7</version>
  </dependency>
  <dependency>
		<groupId>org.slf4j</groupId>
		<artifactId>slf4j-log4j12</artifactId>
		<version>1.7.7</version>
		<exclusions>
			<exclusion>
			    <groupId>org.slf4j</groupId>
			    <artifactId>slf4j-api</artifactId>
			</exclusion>
		</exclusions>
  </dependency>
  ```
  上面的代码声明了一个排除依赖。我们的项目所依赖的slf4j-log4j12会引入slf4j-api这个传递性依赖。出于版本或者其他考虑，现在不想引入这个依赖，而是由我们显示的声明，那么就可以像上面的代码那样做。

- 查看依赖

  通过执行`mvn dependency:list`可以查看项目已经解析的依赖；
  通过执行`mvn dependency:tree`可以查看项目的依赖树；
  通过执行`mvn dependency:analyze`可以查看项目中没有使用，却显示声明的依赖和项目中显示使用了却没有显示声明的依赖。

  在Eclispe中，可以双击pom.xml，在Dependencies和Dependency Hierarchy选项卡查看项目的依赖情况。

## 仓库

- 仓库分类

  对于maven来说，仓库分为两类：本地仓库和远程仓库。本地仓库即存在于我们本地机器上的构件仓库，远程仓库就是远程机器上的构件仓库。我们的依赖(jar)都是从仓库当中下载得到的。

  当maven对我们的项目执行编译或者测试时，如果需要使用依赖文件，他总是基于坐标使用本地仓库的依赖文件。如果本地仓库存在此构件，则直接使用；如果本地仓库不存在此构件，或者需要更新的版本，maven会去远程仓库查找，发现需要的构件之后，下载到本地仓库再使用。如果本地仓库和远程仓库都没有需要的构件，则报错。

  中央仓库是Maven核心自带的远程仓库，包含了绝大部分开源构件。默认情况下，当本地仓库没有maven需要的构件时，他就会从中央仓库下载。

- 仓库配置

  在linux上本地仓库的默认路径为：`~/.m2/repository/`  如果想要自定义本地仓库地址，可以编辑 `~/.m2/setting.xml`, 设置localRepository元素值为想要的地址：

  ```
  <localRepository>/path/to/local/repo</localRepository>
  ```

  某些情况下，中央仓库无法满足项目需求，项目需要的构件可能存在于另一个远程仓库上，这是，可以在pom中配置该仓库：

  ```xml
  <repositories>
		<repository>
			<id>JBOSS</id>
			<name>Jboss</name>
			<url>http://repository.jnoss.com/maven2</url>
			<releases>
				<enabled>true</enabled>
			</releases>
			<snapshots>
				<enabled>false</enabled>
			</snapshots>
		</repository>
	</repositories>
  ```
  上面的例子中声明了一个id为JBOSS的远程仓库，任何一个仓库声明的id都必须是唯一的。release的enable值为true，表示开启Jboss仓库发布版本的下载支持；snapshots的enable值为false，表示关闭Jboss仓库快照版本的下载支持。

  可以声明多个远程仓库，maven会遍历这些仓库去查找所需的构件。
  
## 聚合与继承

- 聚合

  一个项目中往往不止一个模块，比如有core、util等等模块的划分。每个模块是一个独立的工程，提供了对外的接口供调用，各个模块之间有相互依赖的关系。那么，如果我们想要一次性构建项目中的两个两个模块，而不是到两个模块各自的目录下面执行mvn命令，这时候就需要maven的聚合。

  为了能够使用一条命令就构建core和util两个模块，我们需要额外创建一个名为aggregator的模块，然后通过该模块构建整个项目的所有模块。aggregator本身作为一个maven项目，必须有自己的pom：

  ```xml
  <project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
	<modelVersion>4.0.0</modelVersion>
	<groupId>com.test.app</groupId>
	<artifactId>app-aggregator</artifactId>
	<version>1.0-SNAPSHOT</version>
	<packaging>pom</packaging>
	<modules>
		<module>app-core</module>
		<module>app-util</module>
	</modules>
  </project>
  ```
  对于聚合模块来说，packaging的值必须为pom，否则无法构建。用户可以通过在一个打包为pom的Maven项目中声明任意数量的module元素来实现模块的聚合。

  这里每一个module的值都是一个当前pom的相对目录。比如app-aggregator的pom路径为`~/app/app-aggregator/pom.xml`，那么app-core就对应目录`~/app/app-aggregator/app-core/`,app-util就对应目录`~/app/app-aggregator/app-util/`，这两个目录各自包含pom.xml、src/main/java等内容，可以独立构建。

  从聚合模块运行mvn命令，maven就会解析聚合模块的pom，分析要构建的模块，并计算出一个构建顺序，然后根据这个顺序依次构建各个模块。

- 继承
  
  在面向对象的设计中，可以在父类中声明一些字段，由子类继承使用。类似的，pom也可以声明这样一种父子结构。

  我们继续在`~/app/app-aggregator/`目录下创建一个名为app-parent的子目录，在该子目录中声明一个pom:

  ```xml
  <project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
	<modelVersion>4.0.0</modelVersion>
	<groupId>com.test.app</groupId>
	<artifactId>app-parent</artifactId>
	<version>1.0-SNAPSHOT</version>
	<packaging>pom</packaging>
	<name>App parent</name>
  </project>
  ```
  修改app-core继承app-parent
  ```xml
  <project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
	<modelVersion>4.0.0</modelVersion>
	<parent>
		<groupId>com.test.app</groupId>
		<artifactId>app-parent</artifactId>
		<version>1.0-SNAPSHOT</version>
		<relativePath>../app-parent/pom.xml</relativePath>
	</parent>
	<artifactId>app-core</artifactId>
	<packaging>pom</packaging>
	<name>App core</name>
  </project>
  ```
  上述pom中parent元素声明父模块，groupId、artifactId、version指定了父模块的坐标。relativePath指定了父模块pom的相对路径。

  app-core中没有声明version和groupId，他隐式的从父模块继承了这两个元素。

  下面是可继承的pom元素：

  ```
  groupId ：项目组 ID ，项目坐标的核心元素；  
  version ：项目版本，项目坐标的核心元素；  
  description ：项目的描述信息；  
  organization ：项目的组织信息；  
  inceptionYear ：项目的创始年份；  
  url ：项目的 url 地址  
  develoers ：项目的开发者信息；  
  contributors ：项目的贡献者信息；  
  distributionManagerment ：项目的部署信息；  
  issueManagement ：缺陷跟踪系统信息；  
  ciManagement ：项目的持续继承信息；  
  scm ：项目的版本控制信息；  
  mailingListserv ：项目的邮件列表信息；  
  properties ：自定义的 Maven 属性；  
  dependencies ：项目的依赖配置；  
  dependencyManagement ：醒目的依赖管理配置；  
  repositories ：项目的仓库配置；  
  build ：包括项目的源码目录配置、输出目录配置、插件配置、插件管理配置等；  
  reporting ：包括项目的报告输出目录配置、报告插件配置等。  
  ```

- 依赖管理与插件管理

  上面的列表中包含了dependencies元素，表示依赖会被继承。因此，我们可以将模块的公有依赖配置到父模块pom中，子模块就可以移除这些依赖，但这样带来一个问题，如果我们新增了模块也继承父模块的话，新增的子模块也就有可能引入了他不需要的依赖。

  为了解决这个问题，maven提供了dependencyManagement元素。在dependencyManagement元素下声明的依赖不会被实际引入：app-parent/pom.xml

  ```xml
  <project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
	<modelVersion>4.0.0</modelVersion>
	<groupId>com.test.app</groupId>
	<artifactId>app-parent</artifactId>
	<version>1.0-SNAPSHOT</version>
	<packaging>pom</packaging>
	<name>App parent</name>

	<dependencyManagement>
		<dependencies>
			<dependency>
				<groupId>com.googlecode.java-diff-utils</groupId>
				<artifactId>diffutils</artifactId>
				<version>1.2.1</version>
			</dependency>
		</dependencies>
	</dependencyManagement>
  </project>
  ```
  使用dependencyManagement声明的依赖既不会给app-parent引入依赖，也不会给他的子模块引入依赖，不过这段配置会被继承：app-core/pom.xml
  ```xml
  <project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
	<modelVersion>4.0.0</modelVersion>
	<parent>
		<groupId>com.test.app</groupId>
		<artifactId>app-parent</artifactId>
		<version>1.0-SNAPSHOT</version>
		<relativePath>../app-parent/pom.xml</relativePath>
	</parent>
	<artifactId>app-core</artifactId>
	<packaging>pom</packaging>
	<name>App core</name>

	<dependencies>
		<dependency>
			<groupId>com.googlecode.java-diff-utils</groupId>
			<artifactId>diffutils</artifactId>
		</dependency>
	</dependencies>
  </project>
  ```
  可以看到子模块只需要声明dependency的groupId、artifactId，不用声明version，虽然只省去了一行配置，但是统一了项目依赖的版本，降低依赖冲突的机会。

  如果子模块没有声明diffutils，diffutils就不会被引入。

  maven还提供了pluginManagement元素帮助管理插件。与dependencyManagement的原理相同。

- 超级pom

  实际上，我们声明的pom都隐式的继承自超级pom，位于`MAVEN_HOME/lib/maven-model-builder-x.jar`中的`org/apache/maven/model/pom-4.0.0.xml`。

  在超级pom中定义了仓库和插件仓库，都是中央仓库的地址，定义了项目的主代码目录，测试目录等等项目的结构。

  我们可以模仿超级pom在我们自己的pom中声明这些元素，从而自定义项目结构。
 
## 属性与Profile

### 属性

属性有点类似于java中的变量。我们可以在pom中使用${属性名}的方式引用属性的值，从而消除重复，也能降低错误发生的概率。

maven属性有6类：

- 内置属性

  主要有${basedir}表示项目根目录，即包含pom.xml的目录；${version}表示项目的版本

- pom属性

  ${project.build.directory}表示主源码路径;

  ${project.build.sourceEncoding}表示主源码的编码格式;

  ${project.build.sourceDirectory}表示主源码路径;

  ${project.build.finalName}表示输出文件名称;

  ${project.version}表示项目版本,与${version}相同;

- 自定义属性

```xml
  <properties>
		<project.my>hello</project.build.sourceEncoding>
  </properties>
```
在pom中的其他地方使用${project.my}就会被替换成hello

- settings属性

  与pom属性同理，用户以settings开头的属性引用settings.xml文件中的xml元素值，如${settings.localRepository}指向本地仓库地址

- java系统属性

  所有java系统属性都可以使用maven属性引用。如${user.home}指向用户目录

- 环境变量属性

  所有环境变量都可以用以env开头的属性引用。如${env.JAVA_HOME}

### 资源过滤

一般情况下，我们习惯于在src/main/resources/目录下放置配置文件，在配置文件中，我们可能配置数据库的url，用户名密码等信息。但是在不同的环境中，这些数据库的配置常常会变动，比如在测试环境或者运行环境中。比较原始的做法手动更改这些配置，但是这样的方法比较低下也容易出错。maven可以在构建过程中针对不同的环境激活不同的配置。

首先需要使用maven属性将会发生变化的部分提取出来：在数据库配置文件中

```
db.jdbc.driver=${db.driver}
db.jdbc.url=${db.url}
```

这里定义了两个属性：db.driver、db.url

既然定义了maven属性，我们需要在某个地方为其赋值。与自定义属性不同的是，这里需要做的是使用profile将其包裹：

```xml
<profiles>
		<profile>
			<id>pro_A</id>
			<properties>
				<db.driver>com.mysql.jdbc.Driver</db.driver>
				<db.url>jdbc:mysql://localhost:3306</db.url>
			</properties>
		</profile>
</profiles>
```

那么这个profile是在哪里声明的呢？有三个地方：

- pom.xml: pom中的profile只对当前项目有效

- 用户settings.xml: 用户目录下`.m2/settings.xml`中的profile对该用户的所有maven项目有效

- 全局settings.xml: maven安装目录下`conf/settings.xml`中的profile对本机上所有maven项目有效

在配置文件中定义了maven属性，也在profile中为其赋值了，此时要做的是打开资源过滤：

资源文件的处理实际上是maven-resources-plugin插件所做的事情，他的默认行为只是将项目主资源文件复制到主代码编译输出目录中，将测试资源文件复制到测试代码编译输出目录中。我们需要一些配置，使得该插件能够解析资源文件中的maven属性，开启资源过滤。

maven默认的资源目录是在超级pom中定义的，要开启资源目录过滤，需要如下配置：

```xml
<build>
  <resources>
        <resource>
          <directory>${project.basedir}/src/main/resources</directory>
          <filtering>true</filtering>
        </resource>
  </resources>
</build>
```
上述代码为主资源目录开启了资源过滤，类似的我们可以为多个资源目录提供过滤配置：
```xml
<build>
  <resources>
        <resource>
          <directory>${project.basedir}/src/main/resources</directory>
          <filtering>true</filtering>
        </resource>
        <resource>
          <directory>${project.basedir}/src/main/sql</directory>
          <filtering>true</filtering>
        </resource>
  </resources>
</build>
```
在配置文件中定义了maven属性，在profile中为属性赋值，并且为资源目录开启了资源过滤，接下来只需要在命令行激活profile：`mvn clean test -Ppro_A`.

mvn命令中的-P参数激活了一个名为pro_A的profile。maven在构建项目的时候就会使用profile中的属性值替换在配置文件中的属性定义，然后将其复制到编译输出目录当中。

### profile

我们可以想到，针对不同的环境定义不同的profile，然后在不同的环境中通过命令行激活对应的profile，就能达到灵活切换配置的目的。除了命令行手动激活profile以外，还有下面几种方式能够激活profile：

- 默认激活

  ```xml
  <profiles>
		<profile>
			<id>pro_A</id>
			<activation>
			<activeByDefault>true</activeByDefault>
			</activation>
			<properties>
				<db.driver>com.mysql.jdbc.Driver</db.driver>
				<db.url>jdbc:mysql://localhost:3306</db.url>
			</properties>
		</profile>
	</profiles>
  ```
  activeByDefault指定profile自动激活。但是如果pom中的任意一个profile通过其他方式被激活了，那么默认的激活配置失效。

- 属性激活

  ```xml
  <profiles>
		<profile>
			<id>pro_A</id>
			<activation>
				<property>
					<name>test</name>
					<value>x</value>
				</property>
			</activation>
			<properties>
				<db.driver>com.mysql.jdbc.Driver</db.driver>
				<db.url>jdbc:mysql://localhost:3306</db.url>
			</properties>
		</profile>
	</profiles>
  ```
  属性test存在且值为x时激活该profile。利用这个特性可以在命令行同时激活多个profile：`mvn clean test -Dtest=x`

- settings文件激活

  ```xml
  <settings>
     <activeProfiles>
       <activeProfile>pro_x</activeProfile>
     </activeProfiles>
  </settings>
  ```
  在settings.xml文件中配置，表示其配置的profile对所有项目处于激活状态。

在profile中不仅可以添加或者修改maven属性，还可以对其他maven元素进行设置。

- pom中的profile可以使用的元素：
  
  ```xml
  <repositories></repositories>
	<pluginRepositories></pluginRepositories>
	<distributionManagement></distributionManagement>
	<dependencies></dependencies>
	<dependencyManagement></dependencyManagement>
	<modules></modules>
	<properties></properties>
	<reporting></reporting>
	<build>
		<plugins></plugins>
		<defaultGoal></defaultGoal>
		<resources></resources>
		<testResources></testResources>
		<finalName></finalName>
	</build>
  ```

- 其他profile可以使用的元素

  ```xml
  <repositories></repositories>
  <pluginRepositories></pluginRepositories>
  <properties></properties>
  ```
