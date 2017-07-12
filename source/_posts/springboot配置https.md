---
layout: post
title: springboot配置https
date: 2017-07-12 22:19:17
categories: 技术
tags: 密码学
---
> 这两天打算在组内做个培训，关于Https方面的。于是一直在查资料，理解，顺便把今天了解的内容总结一下。

> 之前已经写过两篇有关ssl方面的笔记：[关于加密的一点总结](http://yukai.space/2016/08/22/%E5%85%B3%E4%BA%8E%E5%8A%A0%E5%AF%86%E7%9A%84%E4%B8%80%E7%82%B9%E6%80%BB%E7%BB%93/)，[ssl总结](http://yukai.space/2016/09/25/ssl%E6%80%BB%E7%BB%93/)。当时的理解现在看来还有一些欠缺的地方，温故而知新嘛！

## 数字签名

> 数字签名是一种类似写在纸上的普通的物理签名，但是使用了公钥加密领域的技术实现，用于鉴别数字信息的方法。(很空洞有木有~)

数字签名的作用：**身份认证与完整性检验**

下面模拟一个场景，小明给小红写一封信。

1. 首先将摘要信息用发送者小明的私钥加密，生成数字签名，与原始信息一起传送给接收者小红。(什么是摘要信息，公钥私钥在前面的笔记中提到了，不再赘述)

2. 小红使用小明的公钥对小明私钥加密后的摘要信息进行解密，如果解密成功，则说明接收到的内容确实由小明发出。这就完成了发送者小明的身份认证。

3. 小红对收到的原始信息使用信息摘要算法得到其哈希值，与2中解密后的摘要信息进行比较，如果一致，证明原始信息未经篡改。保证了信息完整性（完整性检验）。

{% asset_img 1.png 小明写信 %}

{% asset_img 2.png 小红写信 %}

上面的过程有一个明显的疑问，就是小红是如何得到小明提供的公钥呢？

- 把公钥放到互联网的某个地方的一个下载地址，事先给客户去下载？

- 每次和客户开始通信时，服务器把公钥发给客户？

客户无法确定这个下载地址是不是服务器发布的，你凭什么就相信这个地址下载的东西就是服务器发布的而不是别人伪造的呢，万一下载到一个假的怎么办？另外要所有的客户都在通信前事先去下载公钥也很不现实。

任何人都可以自己生成一对公钥和私钥，他只要向客户发送他自己的私钥就可以冒充服务器了。

所以。数字证书出现了。

## 数字证书

> 数字证书是一种权威性的电子文档，可以由权威公正的第三方机构，即CA（例如中国各地方的CA公司）中心签发的证书，也可以由企业级CA系统进行签发。

小红无法确定自己获得的公钥是不是小明的，她想到了一个办法：

要求小明去找“证书中心”（certificate authority，简称CA），为公钥做认证。证书中心用自己的私钥，对小明的公钥和一些相关信息一起加密，生成"数字证书"（Digital Certificate）。

小明以后再给小红写信，只要在签名的同时，再附上数字证书就行了。

小红收信后，用CA的公钥解开数字证书，就可以拿到小明真实的公钥了，然后就能证明“数字签名”是否真的是小明签的。

{% asset_img 1.png 小明写信 %}

{% asset_img 4.png 小红写信 %}

## Https演化

上面小明给小红写信的过程类似于https的工作原理。首先我们知道，所谓https是在http协议的基础上加了一层ssl/tls协议：

{% asset_img https.png https %}

ssl/tls能起到什么作用呢？

- 所有信息都是加密传播，第三方无法窃听（窃听风险）

- 具有校验机制，一旦被篡改，通信双方会立刻发现（篡改风险）

- 配备身份证书，防止身份被冒充（冒充风险）

如何做到以上几点，参考之前的[笔记](http://yukai.space/2016/08/22/%E5%85%B3%E4%BA%8E%E5%8A%A0%E5%AF%86%E7%9A%84%E4%B8%80%E7%82%B9%E6%80%BB%E7%BB%93/)中关于通信演化过程的内容。

https通信的过程如下图：

{% asset_img ssl.png https %}

握手阶段服务器发送了自己的证书，确认了服务器的身份并且双方商议好了对称加密的算法好密钥，应用数据传输阶段就使用对称加密算法加密信息进行通信了。

## 证书链

在握手阶段，服务器会把自己的证书发送到客户端(以浏览器为例)，那么客户端是怎么使用这个证书确认服务器的身份的呢？

首先观察一下证书里有什么内容：

{% asset_img zhengshu.png 数字证书 %}

上图只截取了一部分，我们看几个比较重要的：

Issuer (证书的发布机构)

指出是什么机构发布的这个证书，也就是指明这个证书是哪个公司创建的(只是创建证书，不是指证书的使用者)。

 - Valid from , Valid to (证书的有效期)

也就是证书的有效时间，或者说证书的使用期限。 过了有效期限，证书就会作废，不能使用了。

- Public key (公钥)

公钥是用来对消息进行加密的，也就是服务器使用的公钥。

- Subject (使用者)

这个证书是发布给谁的，或者说证书的所有者，一般是某个人或者某个公司名称、机构的名称、公司网站的网址等。 

- Thumbprint, Thumbprint algorithm (指纹以及指纹算法)

这个是用来保证证书的完整性的，也就是说确保证书没有被修改过。 其原理就是在发布证书时，发布者根据指纹算法(一个hash算法)计算整个证书的hash值(指纹)并和证书放在一起，使用者在打开证书时，自己也根据指纹算法计算一下证书的hash值(指纹)，如果和刚开始的值对得上，就说明证书没有被修改过，因为证书的内容被修改后，根据证书的内容计算的出的hash值(指纹)是会变化的。

- Signature algorithm (签名所使用的算法)

指纹的加密结果就是数字签名。 注意，这个指纹会使用证书发布机构的私钥用签名算法(Signature algorithm)加密后生成数字签名和证书放在一起。

Signature algorithm就是指的这个数字证书的数字签名所使用的加密算法，这样就可以使用证书发布机构的证书里面的公钥，根据这个算法对指纹进行解密。

什么是证书链呢？

{% asset_img zhengshulian.jpeg 证书链 %}

上图中的Issuer's DN即证书颁发机构，这样的证书颁发机构可能不止一个，上图表示一个3级证书链。

Owner's DN 代表服务器发来的证书，浏览器得到这个证书之后根据Issuer's DN获得该证书的颁发机构的证书，以此类推，最终得到根证书。比如 A->B->C->root

什么是根证书呢？一般是内嵌在操作系统中的，公认的可以信任的证书机构颁发的自签名证书。这些证书发布机构自己持有与他自己的数字证书对应的私钥，他会用这个私钥加密所有他发布的证书的指纹作为数字签名。浏览器无条件的信任根证书。

得到根证书后，拿到其公钥，然后使用这个公钥对证书链的上一级证书c依据Signature algorithm对指纹的加密结果(签名)进行解密，得到证书c的指纹。解密成功，证明c确实是由root颁发的，然后使用Thumbprint algorithm计算一下证书c的指纹，如果和解密得到的指纹相同，证明证书没有被篡改。因此，证书c是可以信任的。以此类推，证明证书A是可以信任的。也就是服务器发来的证书是可以信任的。

问题一：服务器可不可以随便下载一个认证的证书自己使用呢？

证书中包含了服务器端的公钥，浏览器会使用该公钥加密一个随机字符串要求服务器解密。服务器没有该证书的私钥，故解密失败

问题二：可不可以篡改一个已经认证的服务器为我所用？

证书中包含了证书的指纹，证书一经篡改就会被察觉

可以看到，https已经是很安全了。但是要注意，一旦信任根证书，则意味着信任了该证书所签发的所有下级证书，所以，安装根证书一定要谨慎！

## 使用keytool生成证书

使用下面的方法生成一个二级证书链：

- 生成根证书密钥
```
keytool -genkey -alias CA -keyalg RSA -validity 365 -keystore server.keystore -storepass 123456 -keypass 123456 
keytool -list -v -keystore server.keystore
```
- 生成自签名证书密钥
```
keytool -genkey -keystore server.keystore  -alias server -keyalg RSA -validity 365 -storepass 123456 -keypass 123456 
keytool -list -keystore server.keystore -alias server
```
- 提交申请
```
keytool -certreq -keystore server.keystore -alias server -storepass 123456 -file server.certreq 
keytool -printcertreq -file server.certreq -v
```
- 颁发证书
```
// 新升级的chrome58，要求证书中至少包含一个[Subject Alternative Name](https://support.dnsimple.com/articles/what-is-ssl-san/)
keytool -gencert -keystore server.keystore -alias CA -ext san=ip:192.168.1.70 -infile server.certreq -outfile server.crt -storepass 123456
```
- 自签名证书导入keystore
```
keytool -importcert -keystore server.keystore -alias server -file server.crt -storepass 123456
keytool -list -keystore server.keystore -v -alias server
```
- 导出根证书
```
keytool -export -alias CA -keystore server.keystore -file CA.crt -storepass 123456
```

目录下得到以下几个文件：

```
CA.crt //根证书
server.certreq // server证书申请
server.crt // server证书
server.keystore //密钥库
```
## Chrome导入根证书

设置->高级->管理证书->受信任的根证书颁发机构->导入

## springboot配置https

在application.properties中增加以下配置：(跟上一步对应)

```
server.ssl.key-store=server.keystore

server.ssl.key-store-password=123456

server.ssl.keyStoreType=JKS

server.ssl.keyAlias:server
```

### 开启http

配置好https后发现http方式无法访问，服务器强制使用https方式，可以在 @Configuration注解的类中增加下面的配置同时开启http

```java
@Bean
public EmbeddedServletContainerFactory servletContainer() {
    TomcatEmbeddedServletContainerFactory tomcat = new TomcatEmbeddedServletContainerFactory() {
        @Override
        protected void postProcessContext(Context context) {
          SecurityConstraint securityConstraint = new SecurityConstraint();
          securityConstraint.setUserConstraint("CONFIDENTIAL");
          SecurityCollection collection = new SecurityCollection();
          collection.addPattern("/*");
          securityConstraint.addCollection(collection);
          context.addConstraint(securityConstraint);
        }
      };
    
    tomcat.addAdditionalTomcatConnectors(initiateHttpConnector());
    return tomcat;
}
private Connector initiateHttpConnector() {
    Connector connector = new Connector("org.apache.coyote.http11.Http11NioProtocol");
    connector.setScheme("http");
    connector.setPort(8080);
    connector.setSecure(false);
    connector.setRedirectPort(8443);
    
    return connector;
  }
```

### http重定向到https

```java
@Value("${server.port}")
	private int port;

@Bean
public EmbeddedServletContainerFactory servletContainer() {
		TomcatEmbeddedServletContainerFactory tomcat = new TomcatEmbeddedServletContainerFactory() {
			@Override
			protected void postProcessContext(Context context) {
				SecurityConstraint securityConstraint = new SecurityConstraint();
				securityConstraint.setUserConstraint("CONFIDENTIAL");
				SecurityCollection collection = new SecurityCollection();
				collection.addPattern("/*");
				securityConstraint.addCollection(collection);
				context.addConstraint(securityConstraint);
			}
		};
		tomcat.addAdditionalTomcatConnectors(initiateHttpConnector());
		return tomcat;
}

private Connector initiateHttpConnector() {
		Connector connector = new Connector("org.apache.coyote.http11.Http11NioProtocol");
		connector.setScheme("http");
		connector.setPort(getHttpPort());
		connector.setSecure(false);
		connector.setRedirectPort(port);
		return connector;
}
	
private int getHttpPort() {
		return 80;
}

```

https配置到此完成，美滋滋：

{% asset_img res.png 效果 %}


