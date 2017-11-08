---
layout: post
title: ssl使用总结
date: 2016-09-25 10:09:10
categories: 
- 技术
- 加密
tags: 
- java
- 加密
---

>这次维护的web服务器要求使用Https双向认证，了解了一下如何在客户端和服务器之间进行ssl的配置，在此记录。另外，这篇日志主要记录如何使用，并不深入底层原理。

## 简单认识ssl和证书

在理解这部分内容之前，建议先看看前面对的一篇总结：[关于加密的一点总结](http://yukai.space/2016/08/22/%E5%85%B3%E4%BA%8E%E5%8A%A0%E5%AF%86%E7%9A%84%E4%B8%80%E7%82%B9%E6%80%BB%E7%BB%93/)

SSL(Secure Sockets Layer 安全套接层),及其继任者传输层安全（Transport Layer Security，TLS）是为网络通信提供安全及数据完整性的一种安全协议。TLS与SSL在传输层对网络连接进行加密。

SSL协议提供的服务主要有：

1、认证用户和服务器，确保数据发送到正确的客户机和服务器；

2、加密数据以防止数据中途被窃取；

3、维护数据的完整性，确保数据在传输过程中不被改变。

其实，ssl就是一种协议。我们知道Http协议是明文传输的，安全性不高。Https就是在Http基础之上加一层ssl协议，来达到加密通信的目的。具体的ssl握手过程，可以参考[百度百科](http://baike.baidu.com/view/14121.htm#6)

附上一张图方便理解：

{% asset_img sslprocess.jpg sslprocess %}

图片来自网络

<!-- more -->

可以看到ssl握手过程中服务器向客户端发送了自己的证书。这个证书是加密过程的重要内容。在前面的[关于加密的一点总结](http://yukai.space/2016/08/22/%E5%85%B3%E4%BA%8E%E5%8A%A0%E5%AF%86%E7%9A%84%E4%B8%80%E7%82%B9%E6%80%BB%E7%BB%93/)这篇博客中，在关于数字证书的一节，我们知道了数字证书可以证明服务器的身份，服务器证书中包含了服务器的公钥，用于之后的通信。

那么，简单了解下证书的工作原理。

首先看一下证书中有哪些内容：

{% asset_img zhifubao.png 支付宝证书 %}

{% asset_img zhufubao1.png 支付宝证书 %}

{% asset_img zhufubao2.png 支付宝证书 %}

上面是我从谷chorme浏览器中截取的支付宝所使用证书的信息截图。

可以看到，里面有颁发者和使用者。颁发者就是颁发此证书的CA(证书颁发机构),使用者就是与我们通信的服务器，也就是该证书的持有者。证书中还包含了我们上面提到的公钥。

我们知道，证书能够证明服务器的身份，那么他是如何证明的呢？我们以浏览器为例：

首先，浏览器(客户端)接收到服务器发来的证书A之后，会去验证这个证书A是否被篡改或者是伪造的。浏览器首先会去操作系统中内置根证书库中搜索A的颁发者的证书。关于这一点要解释一下，数字证书的颁发机构也有自己的证书，这个证书就是根证书，这个根证书在我的系统刚安装好时，就被微软等公司默认安装在操作系统当中了。

如果在操作系统中找到了服务器证书中的颁发者的证书Root，那么继续下一步，否则，就知道这个服务器证书的颁发者是个不受信任的CA发布的，此时，浏览器会给出警告。若我们选择相信这个CA并继续，则继续下一步。

接下来，浏览器从Root中得到Root的公钥，然后用该公钥对A中的指纹算法和指纹进行解密。注意，为了保证安全，在证书的发布机构发布证书时，证书的指纹和指纹算法，都会加密后再和证书放到一起发布，以防有人修改指纹后伪造相应的数字证书。

那么什么是指纹算法和指纹呢？这个是用来保证证书的完整性的，也就是说确保证书没有被修改过。 其原理就是在发布证书时，发布者根据指纹算法(一个hash算法)计算整个证书的hash值(指纹)并和证书放在一起，使用者在打开证书时，自己也根据指纹算法计算一下证书的hash值(指纹)，如果和刚开始的值对得上，就说明证书没有被修改过，因为证书的内容被修改后，根据证书的内容计算的出的hash值(指纹)是会变化的。

此时就可以判断该证书是否是仿冒或者经过伪造篡改的。如没有，则证明这个服务器是可信任的。接下来就可以使用该服务器提供的公钥来进行通信了。

通过上面的分析我们知道了，ssl协议中，首先通过证书来证明服务器的身份，然后取出证书中的公钥，接下来就可以按照[关于加密的一点总结](http://yukai.space/2016/08/22/%E5%85%B3%E4%BA%8E%E5%8A%A0%E5%AF%86%E7%9A%84%E4%B8%80%E7%82%B9%E6%80%BB%E7%BB%93/)这篇博客中说到的通信方式通信了。这大概上就是ssl的原理，当然实际中ssl的细节还是要复杂很多。

了解了ssl的基本原理，对我们实现服务器的https通信有很大的帮助。

## Https 单向认证

单向认证就是服务器必须向客户端发送自己的证书来证明自己的身份，然后进行加密通信。现在服务器的基础框架是springboot，演示如何配置服务器和客户端：

服务器：

打开springboot的配置文件application.properties:

server.ssl.key-store=server.keystore

server.ssl.key-store-password=123456

server.ssl.keyStoreType=JKS

server.ssl.keyAlias:server

先解释一下上面几个配置：

.keystore: keystore文件中存储了密钥和证书。密钥包括私钥和公钥，而证书中只包含公钥。这个证书就是我们上面所说的证书。注意：密钥和证书是一一对应的。

password: 生成keystore文件时所填的密码。

keyStoreType: keystore类型。

keyAlias: 生成密钥的别名。

keysotre文件是怎么生成的呢？使用jdk自带的工具：keytool。生成keystore文件的命令如下：

`keytool -genkey -alias server -keyalg RSA -validity 365 -keystore server.keystore`

其中：-alias 指定生成密钥的别名，-keystore 指定生成的keystore文件的位置和名称。其他的参数的含义可以通过keytool -help来查找。

一个keystore文件中可以存储多个证书和证书对应的密钥，这些证书和其对应的密钥通过唯一的别名alias来指定，也就是说，通过alias可以导出证书。但是要注意，无法通过keytool导出私钥。

看一下如何从keystore文件中导出证书：

`keytool -export -alias server -keystore server.keystore -file serverCA.crt`

-alias指定了要导出的证书文件，-file 指定了要导出的证书文件的位置和名称。

了解了上面的几个配置，再结合之前对ssl原理的总结，不难知道：

我们指定的别名(server.ssl.keyAlias:server)之后,服务器通过该别名从keystore文件中获得对应的证书，并将其发送给客户端，同时使用keystore中alias对应的私钥(keytool虽然导不出私钥，但可以通过代码等方式获得)可以对与客户端通信的内容进行加密和解密。这便是keystore文件的作用：存储证书和私钥。

服务器端的配置完成了。现在有一个问题，虽然服务器可以发送证书到客户端了，但是客户端并不会信任我们这个证书。如果这个时候通过浏览器以https的方式访问服务器，浏览器会提醒你，此连接不受信任。那是因为虽然服务器将证书发送到了浏览器(客户端)，但是浏览器并不认为这个证书能够证明服务器的身份。那为什么https访问支付宝等网站没有报这个警告呢？想想上面的内容，浏览器或操作系统内置了颁发给支付宝证书的机构的根证书，通过这个根证书的公钥对支付宝发来的证书进行解密可以证明这个证书确实是由支付宝发过来的，从而证明了服务器的身份。

虽然浏览器并不能验证我们的证书，我们可以手动的把证书添加到浏览器的信任列表中。这个证书就是我们上面通过keytool导出的证书，将这个证书手动添加到浏览器信任列表里面，再次访问服务器就不会有警告啦。(具体的添加方式不再赘述)(从这点上也可以看出自签名证书的不安全性，有可能被假冒和伪造)

so,通过上面的方式我们已经将ssl单向验证配置好了。那么，如果客户端是自己用java写的呢？下面举一个例子，使用HttpsURLConnection实现：

首先生成客户端的信任证书库，用来存放客户端所信任的证书：

`keytool -keystore truststore.jks -alias client -import -trustcacerts -file serverCA.crt`

-file 指定要信任的证书，此例中应该是我们上面导出的证书serverCA.crt

-keystore 指定要生成的信任库路径和名称。

然后生成我们自己的信任证书管理器：

参考了网上的代码：

```java
public class MyX509TrustManager implements X509TrustManager {
	/*
	 * The default X509TrustManager returned by SunX509. We'll delegate
	 * decisions to it, and fall back to the logic in this class if the default
	 * X509TrustManager doesn't trust it.
	 */
	X509TrustManager sunJSSEX509TrustManager;

	public MyX509TrustManager() throws Exception {
		// create a "default" JSSE X509TrustManager.
		KeyStore ks = KeyStore.getInstance("JKS");
		//注意 src/clientTrustCA.jks就是上面生成的信任证书库
		ks.load(new FileInputStream("src/clientTrustCA.jks"), "123456".toCharArray());
		TrustManagerFactory tmf = TrustManagerFactory.getInstance("SunX509", "SunJSSE");
		tmf.init(ks);
		TrustManager tms[] = tmf.getTrustManagers();
		/*
		 * Iterate over the returned trustmanagers, look for an instance of
		 * X509TrustManager. If found, use that as our "default" trust manager.
		 */
		for (int i = 0; i < tms.length; i++) {
			if (tms[i] instanceof X509TrustManager) {
				sunJSSEX509TrustManager = (X509TrustManager) tms[i];
				return;
			}
		}
		/*
		 * Find some other way to initialize, or else we have to fail the
		 * constructor.
		 */
		throw new Exception("Couldn't initialize");
	}

	/*
	 * Delegate to the default trust manager.
	 */
	public void checkClientTrusted(X509Certificate[] chain, String authType) throws CertificateException {
		try {
			sunJSSEX509TrustManager.checkClientTrusted(chain, authType);
		} catch (CertificateException excep) {
			// do any special handling here, or rethrow exception.
		}
	}

	/*
	 * Delegate to the default trust manager.
	 */
	public void checkServerTrusted(X509Certificate[] chain, String authType) throws CertificateException {
		try {
			sunJSSEX509TrustManager.checkServerTrusted(chain, authType);
		} catch (CertificateException excep) {
			/*
			 * Possibly pop up a dialog box asking whether to trust the cert
			 * chain.
			 */
		}
	}

	/*
	 * Merely pass this through.
	 */
	public X509Certificate[] getAcceptedIssuers() {
		return sunJSSEX509TrustManager.getAcceptedIssuers();
	}
}
```
接着使用这个管理器：

```java
 TrustManager[] tm = { new MyX509TrustManager() };
 SSLContext sslContext = SSLContext.getInstance("SSL", "SunJSSE");
 sslContext.init(null, tm, new java.security.SecureRandom());
 // 从上述SSLContext对象中得到SSLSocketFactory对象
 SSLSocketFactory ssf = sslContext.getSocketFactory();

 // 创建URL对象
 URL myURL = new URL(url);
 // 创建HttpsURLConnection对象，并设置其SSLSocketFactory对象
 HttpsURLConnection httpsConn = (HttpsURLConnection) myURL.openConnection();
 httpsConn.setSSLSocketFactory(ssf);

```

接下来就可以使用这个HttpsURLConnection来访问服务器啦。

## Https双向认证

所谓的Https双向认证就是不仅仅客户端要验证浏览器的身份，浏览器也要向服务器证明自己的身份，也就是第一幅图片中的5。

理解了单向认证，双向认证实现起来也就不难了。

首先像我们之前一样使用keytool生成keystore文件client.keystore，这个文件是为客户端使用准备的。

然后通过client.keystore导出证书client.crt。

接着生成信任库文件serverTrust.jks,将client.crt导入其中。

在单向认证中我们给出了客户端单向认证时的java代码，用来下面给出双向认证的代码：

生成读取keystore的类：

```java
public class MyKeyManager{
	// 相关的 jks 文件及其密码定义
	 private final static String CERT_STORE="src/client.keystore";
	 private final static String CERT_STORE_PASSWORD="123456";
	 
	 public static KeyManager[] getKeyManagers() throws Exception{
		 // 载入 jks 文件
		 FileInputStream f_certStore=new FileInputStream(CERT_STORE); 
		 KeyStore ks=KeyStore.getInstance("jks"); 
		 ks.load(f_certStore, CERT_STORE_PASSWORD.toCharArray()); 
		 f_certStore.close(); 

		 // 创建并初始化证书库工厂
		 String alg=KeyManagerFactory.getDefaultAlgorithm(); 
		 KeyManagerFactory kmFact=KeyManagerFactory.getInstance(alg); 
		 kmFact.init(ks, CERT_STORE_PASSWORD.toCharArray()); 

		 KeyManager[] kms=kmFact.getKeyManagers(); 
		 return kms;
	 }
}
```

像上面单向认证中那样使用它：

```java 
 TrustManager[] tm = { new MyX509TrustManager() };
 KeyManager[] km = MyKeyManager.getKeyManagers();
 SSLContext sslContext = SSLContext.getInstance("SSL", "SunJSSE");
 sslContext.init(km, tm, new java.security.SecureRandom());
 // 从上述SSLContext对象中得到SSLSocketFactory对象
 SSLSocketFactory ssf = sslContext.getSocketFactory();

 // 创建URL对象
 URL myURL = new URL(url);
 // 创建HttpsURLConnection对象，并设置其SSLSocketFactory对象
 HttpsURLConnection httpsConn = (HttpsURLConnection) myURL.openConnection();
 httpsConn.setSSLSocketFactory(ssf);
```

然后使用HttpsURLConnection就可以使用了。但是此时服务器端还需要配置，因为客户端仅仅是将自己的证书发过去了，服务器应该如何信任它呢？

打开springboot的配置文件application.properties添加以下配置:

#Whether client authentication is wanted ("want") or needed ("need"). Requires a trust store.

server.ssl.client-auth=need

server.ssl.trust-store=serverTrust.jks 

server.ssl.trust-store-password=123456

其中，serverTrust.jks就是刚刚生成的服务器端信任库。

以上步骤全部做完，服务器和客户端就可以愉快的使用Https进行双向认证通信了。

## 关于证书的一些格式

在使用keytool和openssl的时候，会发现有好多种格式让人头晕眼花。不妨参考这篇文章：[那些证书相关的玩意儿(SSL,X.509,PEM,DER,CRT,CER,KEY,CSR,P12等)](http://www.cnblogs.com/guogangj/p/4118605.html)

我现在也不是理解的十分清楚，故不再赘述。

## 总结

感觉这篇博客没有把自己想要总结的内容全部记录下来，但是现在也不想再写了。服务器实际测试的时候是使用curl这样一个命令行浏览器进行的，使用curl作为客户端进行双向认证的时候也遇到了不少问题，总结了一份配置的[readme](https://github.com/Hikyu/SSL-Configuration/blob/master/ssl%E5%8F%8C%E5%90%91%E8%AE%A4%E8%AF%81%E9%85%8D%E7%BD%AE.md)，放在github上面，以作记录。readme中的配置方法可能还有一些瑕疵，有些格式转换可能会有冗余，但是整个配置是没有问题的，经过了自己的验证。证书这一块内容感觉还不是理解的特别透彻，尤其是ssl协议的交互和证书格式的一些问题，留作以后学习吧！真的不想看了...

## 参考

[数字证书原理](http://www.cnblogs.com/JeffreySun/archive/2010/06/24/1627247.html):这篇一定要看，总结的很好！

[浏览器和SSL证书通讯过程](http://www.live-in.org/archives/1302.html)

[Java安全通信：HTTPS与SSL](http://www.cnblogs.com/devinzhang/archive/2012/02/28/2371631.html)

[Java 安全套接字编程以及 keytool 使用最佳实践](http://www.ibm.com/developerworks/cn/java/j-lo-socketkeytool/)

[openssl生成SSL证书的流程](http://blog.csdn.net/liuchunming033/article/details/48470575)

[如何添加自签名SSL证书 自签名SSL证书存风险](https://freessl.wosign.com/911.html)

[keystore提取私钥和证书(重要×××)](http://www.360doc.com/content/11/1226/02/3700464_174996042.shtml)












