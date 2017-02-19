---
layout: post
title: 理解java内存模型
date: 2017-02-19 19:32:40
categories: 技术
tags: java
---

> 使用java编写一个带GUI程序或者其他需要给用户传递文字信息的程序的时候，就很有可能需要用到国际化的知识，来总结一下。

所谓的国际化，就是使编写的程序可以适应不同的语言环境，比如，在中文环境下，可以与用户使用中文交互，在英文环境下则切换为英文。而这个切换过程不需要修改代码或者仅仅修改少量的代码。java给我们提供了这样的实现。

## java文件国际化

我们通过将与界面显示有关系的资源提取出来到资源文件中，然后读取不同的资源文件来达到国际化的目的。在java中，这些是通过ResourceBundle这个类来实现的。

ResourceBundle分为两种，一种是ListResourceBundle,另一种是PropertyResourceBundle。下面介绍这两种ResourceBundle的使用方法：

首先列出demo工程的代码结构：

```
TestResourceBundle
|
|--src
    |
    |--kyu
        |
        |--bundle
        |    |
        |    |--ListResourceTranslator.java
        |    |
        |    |--PropertyResourceTranslator.java
        |    |
        |    |--ResourceTranslator.java
        |
        |--test
        |   |
        |   |--App.java
        |
        |--Errors_en_Us.java
        |
        |--Errors_zh_CN.java
        |
        |--Errors.java
        |
        |--Errors_en_Us.properties
        |
        |--Errors_zh_CN.properties
        |
        |--Errors.properties
        
```

### PropertyResourceBundle

1. 首先需要建立若干语言的properties文件： 自定义名_语言代码_国别代码.properties

比如：errors_en_US.properties, errors_zh_CN.properties

其中的语言代码和国别代码，分别是你要国际化的语言。需要几种语言，就添加几个properties文件。

[国别代码](https://worldwide.espacenet.com/help?locale=cn_EP&method=handleHelpTopic&topic=countrycodes)

[语言代码](http://www.lingoes.cn/zh/translator/langcode.htm)

通过打印java所支持的语言和国家查看：

```
private static void printLocal() {
		Locale[] localeList = Locale.getAvailableLocales();
		for (int i = 0; i < localeList.length; i++) {
			System.out.println(localeList[i].getDisplayCountry() + ": " + localeList[i].getCountry());
			System.out.println(localeList[i].getDisplayLanguage() + ": " + localeList[i].getLanguage());
		}
}
```

2. 建立默认语言的properties文件：自定义名.properties

比如：errors.properties

当所需语言的properties文件不存在的时候就会默认读取这个文件中的内容

注意，资源文件都必须是ISO-8859-1编码，对于中文等非西方语系，可通过JDK自带的工具native2ascii进行处理，在Eclipse中也可以安装插件SimplePropertiesEditor来处理这类文件。

3. 使用

ResourceTranslator.java

```
package kyu.bundle;

import java.util.Locale;
import java.util.ResourceBundle;

public abstract class ResourceTranslator {
	protected ResourceBundle bundle;
	protected Locale lc;
	protected static final String PROP_FILE = "kyu.errors";

    public String translate(String id) {
        return bundle.getString(id);
    }
}
```

PropertyResourceTranslator.java

```
package kyu.bundle;

import java.util.Locale;
import java.util.PropertyResourceBundle;
import java.util.ResourceBundle;

public class PropertyResourceTranslator extends ResourceTranslator{
    public PropertyResourceTranslator() {
        lc = Locale.getDefault();
        bundle = PropertyResourceBundle.getBundle(PROP_FILE, lc);
    }
    
    public PropertyResourceTranslator(String language, String country) {
    	lc = new Locale(language, country);
        bundle = PropertyResourceBundle.getBundle(PROP_FILE, lc);
    }

}
```

App.java

```
package kyu.test;

import kyu.bundle.ListResourceTranslator;
import kyu.bundle.PropertyResourceTranslator;

public class App {
	public static void main(String[] args) {
		testPropertyResource();
	}

	private static void testPropertyResource() {
		PropertyResourceTranslator translatorDefault = new PropertyResourceTranslator();
		PropertyResourceTranslator translatorZH = new PropertyResourceTranslator("zh", "CN");
		PropertyResourceTranslator translatorEN = new PropertyResourceTranslator("en", "US");
		String def = translatorDefault.translate("ERROR-001");
		String zh = translatorZH.translate("ERROR-001");
		String en = translatorEN.translate("ERROR-001");
		
		System.out.println("test PropertyResourceBundle>>>>>>");
		System.out.println("default: " + def);
		System.out.println("zh: " + zh);
		System.out.println("en: " + en);
	}	
	
}
```
.properties文件内容：

```
Errors_en_Us.properties:
ERROR-001=error password

Errors.properties
ERROR-001=error password

Errors_zh_CN.properties
ERROR-001=密码错误
```

执行App.java的测试结果：

```
test PropertyResourceBundle>>>>>>
default: 密码错误
zh: 密码错误
en: error password
```

可以看到，通过指定Local构造函数的语言和国别代码，就能自动找到对应的.properties，并匹配其中的内容。

当使用Locale.getDefault()时，自动检测当前的系统环境，从而选择对应的语言。

还有一点要注意的是： 

PropertyResourceBundle.getBundle(PROP_FILE, lc); 

其中PROP_FILE，为properties文件的路径，此路径为properties文件的完整路径，即 所在完整包名.自定义名称

### ListResourceBundle

ListResourceBundle的使用与PropertyResourceBundle的使用大同小异，不过是将properties文件换成了.java文件

ListResourceTranslator.java

```
package kyu.bundle;

import java.util.ListResourceBundle;
import java.util.Locale;

public class ListResourceTranslator extends ResourceTranslator{
	public ListResourceTranslator() {
        lc = Locale.getDefault();
        bundle = ListResourceBundle.getBundle(PROP_FILE, lc);
    }
    
    public ListResourceTranslator(String language, String country) {
    	lc = new Locale(language, country);
        bundle = ListResourceBundle.getBundle(PROP_FILE, lc);
    }
}

```

ERRORS_en_US.java

```
package kyu;

import java.util.ListResourceBundle;

public class ERRORS_en_US extends ListResourceBundle{
	static final Object[][] contents = new String[][] { 
		{ "ERROR-001", "error password" } 
	};

	public Object[][] getContents() {
		return contents;
	}
}

```

ERRORS_zh_CN.java

```
package kyu;

import java.util.ListResourceBundle;

public class ERRORS_zh_CN extends ListResourceBundle {
	static final Object[][] contents = new String[][] { 
		{ "ERROR-001", "密码错误" } 
	};

	public Object[][] getContents() {
		return contents;
	}
}

```

继承了ListResourceBundle的类就相当于前面的properties文件，需要提供一个getContents()方法，返回对应的键值对。

同样的，要注意ListResourceBundle子类的命名规则，与properties文件相同，路径也与properties文件相同。

通过App.java的测试(将对应的bundle替换)，可以得到相同的测试结果。

### 使用Eclipse对java文件进行国际化

在需要国际化的类文件上点击右键->Source->Externalize Strings...

出现窗口，Eclipse会自动检测类文件中的字符串，在窗口中可以选择相应的字符串，最后自动生成类似于上面的PropertyResourceTranslator.java和properties文件，完成国际化。

其原理与以上所讲的相同，故不再详细说明。

## Eclipse RCP国际化

> 最近在使用Eclipse RCP这项技术开发程序，其中也有国际化相关的东西，总结下来。

[Eclipse RCP and Plugin Internationalization - Tutorial](http://www.vogella.com/tutorials/EclipseInternationalization/article.html)

上面这篇文章详细的说明了Eclipse RCP工程中的国际化问题，可以作为一个备忘录。下面介绍一下eclipse rcp中比较常用到的国际化方式：

### plugin.xml文件国际化

plugin.xml文件中保存了扩展点等相关的信息，当扩展点与界面UI相关时，就需要用到国际化

1. 在工程的根目录下面建立一个plugin.properties资源文件，此文件类似于我们上面提到的errors.properties。当然，也可以建立plugin_zh.properties等文件，这些文件名中的plugin是可以自由定义的。

2. 在 MANIFEST.MF文件中增加代码行：Bundle-Localization: plugin

   注意，这个plugin与上面的properties文件名保持一致。

3. plugin.xml配置文件对资源文件进行引用时, 在引用的key前面加一个%，比如：

```
<view
    id="org.jkiss.dbeaver.core.databaseNavigator"
    category="org.jkiss.dbeaver.core.category"
    class="org.jkiss.dbeaver.ui.navigator.database.DatabaseNavigatorView"
    allowMultiple="false"
    icon="icons/databases.png"
    name="%view.database.navigator.title"/>
<view
```

### 类文件国际化

与前面所介绍的java类文件国际化相同，也可以通过选择类文件点击右键->Source->Externalize Strings...

Eclipse IDE会自动帮你完成国际化的一些工作，同样也生成了相关的类和properties文件，但不同的是，生成的类文件内容类似于：

```
package test;

import org.eclipse.osgi.util.NLS;

public class Messages extends NLS {
        private static final String BUNDLE_NAME
                = "test.messages"; //$NON-NLS-1$
        public static String View_0;
        public static String View_1;
        static {
                // initialize resource bundle
                NLS.initializeMessages(BUNDLE_NAME, Messages.class);
        }

        private Messages() {
        }
}
```

当然，我们也可以手动建立这些文件进行国际化操作~~不再详细说明，可以通过观察IDE的行为进行我们手动的国际化操作~