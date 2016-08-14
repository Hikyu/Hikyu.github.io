---
layout: post
date:   2016-07-18 12:48:55
title:  "ANT的使用"
categories: 工具
tags: 
- java
- ant
---

>之前写Android的时候一直想学习构建工具Gradle，但一直没有花功夫去研究。由于平时工作中使用的IDE为Eclipse，所以免不了和[Ant](http://ant.apache.org/)打交道。今天工作的时候需要自己使用Ant打包一个工程，遂研究一番。

## 教程

Ant是一个很成熟的构建工具了，网上也有许多教程。参考了很多。学习下面两篇教程可以快速上手。

[Ant Tutorial](http://www.tutorialspoint.com/ant/index.htm)

[Ant 实践](http://www.uml.org.cn/j2ee/j2ee091302.htm#content)

另外附上Ant常用命令：

[Overview of Apache Ant Tasks](https://ant.apache.org/manual/tasksoverview.html)

## 实践

下面是自己写的build.xml。存在这里，以后用到可以参考。

下面的例子用来编译、打包一个java工程，这个工程是一个Hibernate方言包的开发。该工程还引用到了其他jar包。

- **build.xml**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!--
    Oscar XcluseterHibernate Ant build file
-->
<project name="OSCAR-XCLUSETER-HIBERNATE" default="usage" basedir=".">
	<target name="build" depends="clean" />

	<target name="init" description="default init">
		<property file="build.properties" />

		<!-- Project Properties -->
		<property name="project" value="oscarXcluseterHibernate3" />
		<property name="name" value="OSCAR HIBERNATE" />
		<tstamp>
			<format property="year" pattern="yyyy" locale="zh_CN" />
			<format property="builddate" pattern="yyMMdd" locale="zh_CN" />
		</tstamp>
		<property name="version" value="${version.major}.${version.minor}.${version.revision}${version.suffix}" />
		<property name="version.number" value="${version.major}.${version.minor}.${version.revision}" />
		<property name="version.major.minor" value="${version.major}.${version.minor}" />

		<property name="final.name" value="${project}" />
		<property name="vesrion.build" value="build${builddate} ${version.subbuild} ${version.buildID} for ALL " />

		<!-- Build Defaults -->
		<property name="src.dir" value="${basedir}/src" />
		<property name="lib.dir" value="${basedir}/lib" />
		<property name="build.home" value="${basedir}" />
		<property name="build.src" value="${basedir}/build" />
		<property name="build.dest" value="${basedir}/antClasses" />
		<property name="build.release" value="${basedir}/release" />
		<property name="build.tmp" value="${basedir}/tmp" />

		<!-- JAR artifacts -->
		<property name="hiberante3.jar" value="${lib.dir}/hibernate3.jar" />

		<!-- Version info filter set -->
		<tstamp>
			<format property="DSTAMP" pattern="yyyyMMdd" locale="zh_CN" />
			<format property="TSTAMP" pattern="hhmm" />
		</tstamp>
		<filterset id="version.filters">
			<filter token="VERSION_NUMBER" value="${version.number}" />
			<filter token="BUNDLE_NAME" value="${vesrion.name}" />
			<filter token="BUNDLE_VERSION" value="${version}${DSTAMP}${TSTAMP}" />
			<filter token="BUILD_VERSION" value="${vesrion.build}" />
		</filterset>
		<path id="classpath">
			<pathelement location="${hiberante3.jar}" />
		</path>
	</target>

	<target name="usage" depends="init">
		<echo message="${name} Build file" />
		<echo message="-------------------------------------------------------------" />
		<echo message="" />
		<echo message=" available targets are:" />
		<echo message="" />
		<echo message="   package  --> generates oscarXcluseterHibernate file" />
		<echo message="   build    --> compiles the source code" />
		<echo message="   clean    --> cleans up the directory" />
		<echo message="" />
		<echo message=" See the comments inside the build.xml file for more details." />
		<echo message="-------------------------------------------------------------" />
		<echo message="" />
		<echo message="" />
	</target>

	<!-- Just build -->
	<target name="compile-prepare" depends="init" description="Prepare for compile">

		<!-- create directories -->
		<mkdir dir="${build.src}" />
		<mkdir dir="${build.dest}" />

		<!-- copy src files -->
		<copy todir="${build.src}" overwrite="yes">
			<fileset dir="${src.dir}">
				<exclude name="**/*.MF" />
			</fileset>
		</copy>
	</target>

	<target name="compile" depends="compile-prepare" description="compile the project">

		<!-- Compiles the source directory  -->
		<javac srcdir="${build.src}" 
			destdir="${build.dest}" 
			debug="${build.debug}" 
			deprecation="${build.deprecation}" 
			source="${build.source}" 
			target="${build.target}" 
			compiler="${build.compiler}" 
			optimize="${build.optimize}" 
			includes="**/*.java" 
			excludes="**/CVS/**,**/.svn/**" 
			encoding="GB18030"
			includeantruntime="false"
			executable="C:\Program Files\Java\jdk1.5.0_22\bin\javac"
			fork="yes">
			<classpath refid="classpath" />
		</javac>

		<!-- copy src files exclude java file-->
		<copy todir="${build.dest}" overwrite="yes">
			<fileset dir="${build.src}">
				<exclude name="**/*.java" />
			</fileset>
		</copy>
	</target>

	<target name="build-manifests" depends="init,compile-prepare">
		<!-- Filtering tokens for JAR manifests-->
		<filter token="source.jdk" value="${build.source}" />
		<filter token="target.jdk" value="${build.target}" />
		<mkdir dir="${build.tmp}" />
		<copy todir="${build.tmp}" overwrite="yes" filtering="yes" encoding="GB18030">
			<filterset refid="version.filters" />
			<fileset dir="src/META-INF" includes="MANIFEST.MF" />
		</copy>
	</target>

	<target name="package" depends="compile,build-manifests" description="create jar file">
		<mkdir dir="${build.release}" />
		<jar jarfile="${build.release}/${final.name}.jar" manifest="${build.tmp}/MANIFEST.MF" basedir="${build.dest}" includes="**" />
	</target>

	<target name="clean" depends="package">
		<delete dir="${build.src}" />
		<delete dir="${build.dest}" />
		<delete dir="${build.tmp}" />
	</target>
</project>

```

- **build.properties**

```java

# -----------------------------------------------------------------------------
# build.properties
#
# This is an example "build.properties" file, used to customize building 
# OSCAR-JDBC for your local environment.  It defines the location of all external
# modules that OSCAR-JDBC depends on.
# -----------------------------------------------------------------------------

# ----- Version Control Flags -----
vesrion.name=Main
version.major=1
version.minor=0
version.revision=0
version.suffix=x
version.subbuild=001
version.buildID=00000000

build.source=1.5
build.target=1.5
build.debug=false
build.optimize=true
build.compiler=javac1.5

```