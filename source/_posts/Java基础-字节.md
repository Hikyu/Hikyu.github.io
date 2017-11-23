---
layout: post
title: Java基础-字节
date: 2017-11-23 09:32:34
categories: 
- 技术
- 编程
tags:
- java
---
这两天在实施一个加密通信方案时，涉及到了字节的读写和转换，有一些知识点需要学习和记录下来...

## 原码 反码 补码

原码：第一位表示符号，其余位表示数值。比如8位2进制：

[+1]原 = 0000 0001

[-1]原 = 1000 0001

第一位是符号位，8位2进制的取值范围：

[11111111, 01111111] = [-127, 127]

反码：正数的反码是等于原码，负数的反码是在其原码的基础上，符号位不变，其余位取反：

[+1] = [00000001]原 = [00000001]反

[-1] = [10000001]原 = [11111110]反

补码：正数的补码等于原码，负数的补码是在其原码的基础上，符号位不变，其余位取反，然后加1：

[+1] = [00000001]原 = [00000001]反 = [00000001]补

[-1] = [10000001]原 = [11111110]反 = [11111111]补

在Java中，存储的数值都是有符号的，同时也是使用补码存储的。

<!-- more -->

```java
public static void main(String[] args) {
	int a = -1;
	System.out.println(Integer.toBinaryString(a));
}
```

输出：

```
11111111111111111111111111111111
```

[Primitive Data Types](https://docs.oracle.com/javase/tutorial/java/nutsandbolts/datatypes.html):

```
byte: The byte data type is an 8-bit signed two's complement integer. It has a minimum value of -128 and a maximum value of 127 (inclusive). The byte data type can be useful for saving memory in large arrays, where the memory savings actually matters. They can also be used in place of int where their limits help to clarify your code; the fact that a variable's range is limited can serve as a form of documentation.

short: The short data type is a 16-bit signed two's complement integer. It has a minimum value of -32,768 and a maximum value of 32,767 (inclusive). As with byte, the same guidelines apply: you can use a short to save memory in large arrays, in situations where the memory savings actually matters.

int: By default, the int data type is a 32-bit signed two's complement integer, which has a minimum value of -231 and a maximum value of 231-1. In Java SE 8 and later, you can use the int data type to represent an unsigned 32-bit integer, which has a minimum value of 0 and a maximum value of 232-1. Use the Integer class to use int data type as an unsigned integer. See the section The Number Classes for more information. Static methods like compareUnsigned, divideUnsigned etc have been added to the Integer class to support the arithmetic operations for unsigned integers.

long: The long data type is a 64-bit two's complement integer. The signed long has a minimum value of -263 and a maximum value of 263-1. In Java SE 8 and later, you can use the long data type to represent an unsigned 64-bit long, which has a minimum value of 0 and a maximum value of 264-1. Use this data type when you need a range of values wider than those provided by int. The Long class also contains methods like compareUnsigned, divideUnsigned etc to support arithmetic operations for unsigned long.

float: The float data type is a single-precision 32-bit IEEE 754 floating point. Its range of values is beyond the scope of this discussion, but is specified in the Floating-Point Types, Formats, and Values section of the Java Language Specification. As with the recommendations for byte and short, use a float (instead of double) if you need to save memory in large arrays of floating point numbers. This data type should never be used for precise values, such as currency. For that, you will need to use the java.math.BigDecimal class instead. Numbers and Strings covers BigDecimal and other useful classes provided by the Java platform.

double: The double data type is a double-precision 64-bit IEEE 754 floating point. Its range of values is beyond the scope of this discussion, but is specified in the Floating-Point Types, Formats, and Values section of the Java Language Specification. For decimal values, this data type is generally the default choice. As mentioned above, this data type should never be used for precise values, such as currency.

boolean: The boolean data type has only two possible values: true and false. Use this data type for simple flags that track true/false conditions. This data type represents one bit of information, but its "size" isn't something that's precisely defined.

char: The char data type is a single 16-bit Unicode character. It has a minimum value of '\u0000' (or 0) and a maximum value of '\uffff' (or 65,535 inclusive).
```

## 有符号 无符号

上文可以看出，Java 中的 byte 是 1 字节，short 是 2 字节，int 是 4 字节，long 是 8 字节。他们都是有符号的数值。

类型 | 最小值 | 最大值
-----|--------|------
byte|-2^7|2^7-1
short|-2^15|2^15-1
int|-2^31|2^31-1
long|-2^63|2^63-1

发现byte类型跟上文所说的取值范围[-127, 127]不太一样，这是因为使用了补码的缘故。查看[原码, 反码, 补码 详解](https://www.cnblogs.com/zhangziqiu/archive/2011/03/30/ComputerCode.html)了解。

C 语言中的整数类型都提供了对应的"无符号"版本，第一位不再表示符号位。比如C语言中的无符号类型byte，其取值范围为[0, 256]。

所以，当C程序向Java程序通过网络传递了一个无符号数时，我们需要怎么存他呢？

答案就是：使用比要用的无符号类型更大的有符号类型。

比如：使用 short 来处理无符号的字节，使用 long 来处理无符号整数等。下面看一个例子，使用int(4字节)存储一个无符号byte(1字节)：

```java
public static void main(String[] args) {
	int a = 250;// 无符号byte的取值范围[0, 256]
	byte b = (byte) a; // 强制转换，直接截取int低8位
    // b 相当于C后台发来的无符号数
	int  c = b & 0xff; 
	System.out.println(c);// 250
}
```

上面的程序中，b 当做C后台发来的无符号数，最后我们使用int存下了这个无符号的byte。为什么需要 `b & 0xff`这步操作呢？

```java
public static void main(String[] args) {
	int a = 250;// 无符号byte的取值范围[0, 256]
	byte b = (byte) a; // 强制转换，直接截取int低8位
    // b 相当于C后台发来的无符号数
	int  c = b; 
	System.out.println(c);// -6
}
```

可以看到，无符号byte直接转为int，丢失了原本的数值。为什么执行 `b & 0xff`这步操作就可以了呢？ 看下文

## 符号位扩展

上文中，b直接转换为 int，丢失了无符号byte原本的数值。是因为，byte在向int转换的过程中，发生了符号位扩展：

[250]无符号 = 1111 1010

转为4字节int：

1111 1111 1111 1111 1111 1111 1111 1010 = [-6]补

在Java中，当较窄的整型扩展为较宽的整型时，发生符号位扩展：

**对于正数而言，将需要扩展的高位全部赋为0；**

**对于负数而言，将需要扩展的高位全部赋为1。**

观察下面的代码：

```java
System.out.println((int)(char)(byte)-1); //65535
```

为什么没有输出-1呢？

因为**如果最初的类型是char，那么不管他将要被提升成什么类型，都执行0扩展，即需要扩展的高位全部赋0。**

byte是有符号的类型，所以在将byte数值-1（二进制为：11111111）提升到char时，会发生符号位扩展，又符号位为1，所以就补8个1，最后为16个1；然后从char到int的提升时，由于是
char型提升到其他类型，所以采用零扩展而不是符号扩展，结果int数值就成了65535。

总结：

>窄的整型转换成较宽的整型时符号扩展规则：如果最初的数值类型是有符号的，那么就执行符号扩展（即如果符号位
>为1，则扩展为1，如果为零，则扩展为0）；如果它是char，那么不管它将要被提升成什么类型，都执行零扩展。

回顾上文提到的`0xff`问题：int  c = b & 0xff;

对于0xff，是Java中的字面常量，本身是个int值。0xff 表示为 11111111 ，Java对于这种字面常量，不把他前面的1看做符号位，当发生符号位扩展时，扩展成的是"000...ff"。

当 执行 b & 0xff 时，b发生符号位扩展：

1111 1111 1111 1111 1111 1111 1111 1010
&
0000 0000 0000 0000 0000 0000 1111 1111
=
0000 0000 0000 0000 0000 0000 1111 1010
= [250]补

## 逻辑右移 算数右移

Java中有三种移位操作：左移、算数右移、逻辑右移

注意： short, byte,char 在移位之前首先将数据转换为int，然后再移位

算数右移：>>，有符号的移位操作，右移之后的空位用符号位补充，如果是正数用 0 补充，负数用1补充。

-4>>1

[-4]原= 10000000 00000000 00000000 00000100
[-4]补= 11111111 11111111 11111111 11111100
0 向右移出 1 位后 11111111 11111111 11111111 11111110 = [-2]补

逻辑右移：>>>，不管正数、负数，左端都用0补充。

-1>>>1
[-1]原= 10000000 00000000 00000000 00000001
[-1]补= 11111111 11111111 11111111 11111111
1 向右移出1位 01111111 11111111 11111111 11111111 = [2^31-1]补

算数左移：<<，左移后右端用0补充。

## 字节序

字节顺序是指占用内存多于一个字节类型的数据在内存中的存放顺序，有小端、大端两种顺序。

- 小端字节序（little endian）：低字节数据存放在内存低地址处，高字节数据存放在内存高地址处；

- 大端字节序（bigendian）：高字节数据存放在低地址处，低字节数据存放在高地址处。

int value = 0x01020304;采用不同的字节序，在内存中的存储情况如下：

小端字节序：

内存地址编号|字节内容
-----------|-------
0x00001000|04
0x00001001|03
0x00001002|02
0x00001003|01

大端字节序：

内存地址编号|字节内容
-----------|-------
0x00001000|01
0x00001001|02
0x00001002|03
0x00001003|04

显然大字节序，比较符合人类思维习惯。

JAVA字节序都为大端字节序，所谓JAVA字节序，是指在JAVA虚拟机中多字节类型数据的存放顺序。

java.nio包中提供了 `ByteOrder.nativeOrder()`方法来查看主机的字节序。

还可以指定ByteBuffer读写操作时的字节序：`byteBuffer.order(ByteOrder.LITTLE_ENDIAN)`

## 例子

byte 数组 转为 int （默认为大端字节序）

```java
// 第一种方法
public int convertByteToInt(byte[] b){           
    int value= 0;
    for(int i=0; i<b.length; i++)
       value = (value << 8) | b[i];     
    return value;       
}
// 第二种方法
public static int byteArrayToInt(byte[] b) {  
    return   b[3] & 0xFF |  
            (b[2] & 0xFF) << 8 |  
            (b[1] & 0xFF) << 16 |  
            (b[0] & 0xFF) << 24;  
}
// 第三种方法
ByteBuffer.wrap(byteBarray).getInt();
```

int 转为 byte 数组 （默认为大端字节序）

```java
// 第一种方法
private byte[] intToByteArray ( final int i ) throws IOException {
    ByteArrayOutputStream bos = new ByteArrayOutputStream();
    DataOutputStream dos = new DataOutputStream(bos);
    dos.writeInt(i);
    dos.flush();
    return bos.toByteArray();
}
// 第二种方法
public byte[] intToBytes( final int i ) {
    ByteBuffer bb = ByteBuffer.allocate(4);
    bb.putInt(i);
    return bb.array();
}
// 第三种方法
public static byte[] intToByteArray(int a) {
    return new byte[] {
        (byte) ((a >> 24) & 0xFF),
        (byte) ((a >> 16) & 0xFF),
        (byte) ((a >> 8) & 0xFF),
        (byte) (a & 0xFF)
    };
}
```

从流中读取指定长度的整数：

```java
 public static int ReceiveIntegerR(InputStream input, int siz) throws IOException {
    int n = 0;
    for (int i = 0; i < siz; i++) {
        int b = input.read();
        if (b < 0)
            throw new IOException();
        n = b | (n << 8);
    }
    return n;
}
```

向流中写入指定长度的整数：

```java
public static void SendInteger(OutputStream output, int val, int siz) throws IOException {
    byte[] buf = new byte[siz];
    while (siz-- > 0) {
        buf[siz] = (byte) (val & 0xff);
        val >>= 8;
    }
    output.write(buf);
}
```
