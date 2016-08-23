---
layout: post
title:  "java中的equals与hashcode"
categories: 编程
tags: 
- java
date:   2016-04-28 12:48:55
---

>最近读了HashMap的源码，对HashCode与equals有了一定的了解，总结一下，顺便理一下HashMap中的核心算法。

## 什么是hashcode,hashcode的作用是什么

hashcode并不是java中独有的。设想一下，如果让你设计一个算法，根据关键码去得到一个集合中的某个值或者这个关键码所在的位置。普通的做法就是挨个比较，高级一点的使用二分检索或者树形检索等算法。但是以上的检索算法都跟集合的长度N有关，当问题规模N很大时，这些检索的效率可能十分低下。

理想的情况是，根据关键码，我们就可以定位记录所在的位置，而不用去挨个进行比较。也就是说，在关键码与记录存放的位置之间做一种映射。这个映射的方法就是hash(哈希)函数，或者叫散列函数，也就是java中的hashCode()方法，他所返回的值就是hashcode，也就是记录所在的位置。

按照散列的存储方式构造的存储结构叫做散列表。散列表中的一个位置称之为一个槽。

hashCode()方法存在于java.lang.Object类当中，任何类都可以继承修改这个方法。hashCode()方法返回调用它的实例的hashCode值，是个int值。

注：以下代码均来自jdk1.7

String中hashCode()方法的实现：

```java
public int hashCode() {
        int h = hash;
        if (h == 0 && value.length > 0) {
            char val[] = value;

            for (int i = 0; i < value.length; i++) {
                h = 31 * h + val[i];
            }
            hash = h;
        }
        return h;
}
```

## 什么是equals(Object obj)方法

equals(Object obj)方法同样来自Object类。在Object类中，他是这样实现的：

```java
public boolean equals(Object obj) {
        return (this == obj);
}
```

也就是说，默认的equals(Object obj)方法直接将要比较的两个对象的内存地址进行了比较，一致则返回true。

这个方法主要用来实现两个对象间的比较，确认他们在逻辑上是否相等。我们同样可以实现自己的equals(Object obj)方法。

String中equals(Object obj)方法的实现：

```java
public boolean equals(Object anObject) {
        if (this == anObject) {
            return true;
        }
        if (anObject instanceof String) {
            String anotherString = (String) anObject;
            int n = value.length;
            if (n == anotherString.value.length) {
                char v1[] = value;
                char v2[] = anotherString.value;
                int i = 0;
                while (n-- != 0) {
                    if (v1[i] != v2[i])
                            return false;
                    i++;
                }
                return true;
            }
        }
        return false;
}
```

## 在java中hashcode方法与equals方法的作用

首先看一下HashMap中的put方法：

```java
public V put(K key, V value) {
        if (table == EMPTY_TABLE) {
            inflateTable(threshold);
        }
        if (key == null)
            return putForNullKey(value);
        int hash = hash(key);//得到hash值
        int i = indexFor(hash, table.length);//找到槽
        for (Entry<K,V> e = table[i]; e != null; e = e.next) {
            Object k;
            if (e.hash == hash && ((k = e.key) == key || key.equals(k))) {
                V oldValue = e.value;
                e.value = value;
                e.recordAccess(this);
                return oldValue;
            }
        }

        modCount++;
        addEntry(hash, key, value, i);
        return null;
    }

```

我们从 int hash = hash(key); 这一行看起，这行起才是put方法的核心。

首先 int hash = hash(key); key就是我们之前提到的关键码，我们看看HashMap中的这个hash方法做了些什么：

```java
final int hash(Object k) {
        int h = hashSeed;
        if (0 != h && k instanceof String) {
            return sun.misc.Hashing.stringHash32((String) k);
        }

        h ^= k.hashCode();

        // This function ensures that hashCodes that differ only by
        // constant multiples at each bit position have a bounded
        // number of collisions (approximately 8 at default load factor).
        h ^= (h >>> 20) ^ (h >>> 12);
        return h ^ (h >>> 7) ^ (h >>> 4);
}
```

可以看到，这个方法里调用了key本身的hashCode方法，得到了他的hashcode，然后对该hashcode进行了一些操作，最终返回操作后的int值。返回的这个值就是HashMap要用到的hashcode值，他指向了记录所在的位置。那么现在有一个问题：为什么要专门调用这个hash(Onject key)方法来对key的hashcode进行包装然后再使用呢？可以直接使用key的hashcode的呀，这样做看起来不是多此一举吗？其实这跟记录在散列表中的存放方式有关系(HashMap底层存储就是一个散列表数组),有兴趣可以看看[这个](https://www.zhihu.com/question/20733617)

接下来，int i = indexFor(hash, table.length);找到所谓的槽，也就是记录存在的位置。

要理解接下来的代码，我们就需要知道哈希算法的另一个概念：冲突。

散列函数可能对于不相等的关键码计算出相同的hashcode，该现象称为冲突。怎么理解呢？比如我们有这样一个串abcd，我们给出这样一个散列函数：将每一个字符的ascii值加起来除以字符的个数，得到他们的平均值就是这个串的hashcode。那么，可以保证没有其他的串经过这样的算法得到相同的hashcode吗？反过来说，能否给出一个散列函数，其可以保证对于所有调用它的对象都可以返回一个唯一的hashcode？恐怕这是很难做到的吧。此时就会产生冲突。从另一个角度来讲，我们的散列表长度是有限的，有用这有限的空间存储更多的记录，势必会产生冲突。这也是我们理解hashcode的一个重要的点：**不同的对象(equals返回false)可以有相同的hashcode**。

那么，产生冲突怎么办呢？产生冲突之后，不同的对象在散列表中找到了相同的位置，为了解决这个问题，我们将这个槽中的内容设计成一个链表，当产生冲突的时候，就将新的元素放到链表中，他看起来是这样的：

{% asset_img entry.png 冲突 %}

其中：A，B，C分别为三条记录，他们就是产生冲突的三条记录。1,2,3....为散列表的索引位置。

接下来的代码  `for (Entry<K,V> e = table[i]; e != null; e = e.next)`就容易理解了。找到记录所对应的槽之后，遍历这个链表直到找到与关键码相同的位置(可能之前已经有以这个关键码为key的value插入)。如果遍历完链表还没有找到这样的值，说明还不存在此关键码对应的记录，直接插入即可：`addEntry(hash, key, value, i);`.

那么，怎么判断两个关键码在逻辑上是否相同呢？

`if (e.hash == hash && ((k = e.key) == key || key.equals(k)))`

可以看到，首先判断关键码的hashcode与链表记录的关键码hashcode是否相同：e.hash == hash 。为什么要加这样的判断我们之前也提到了，那就是冲突造成同一个槽里有不同的对象存在，这些对象的hashcode可能相同，也可能不同(hashcode经过取模运算散列到同一个位置)。我们知道**不同的对象(equals返回false)可以有相同的hashcode**。相同的对象hashcode也必须相等吗？试想一下，如果两个对象相同，但是他们的hashcode不同，那么这两个对象很有可能被散列在不同的槽里，造成了同一个对象重复存储的问题。所以，我们又得出一个重要结论：**相同的对象(equals返回true)hashcode一定相等**。

`e.hash == hash && ((k = e.key) == key`这段代码首先判断hashcode是否相等，然后判断关键码是否相等。注意，是判断**关键码是否相等**，直接比较内存地址，如果满足以上条件，那么可以断定两个关键码相同，是我们要找的记录。

`key.equals(k)`：如果上述两个条件没有满足，并不能够断定这两个关键码相等，此刻要使用equals方法判断这两个关键码是否相同。如果相同，说明是我们要找的记录。

`if (e.hash == hash && ((k = e.key) == key || key.equals(k)))`这句代码中其实包含了一种短路思想，\|\| 之前的判断如果生效，那么之后的key.equals(k)就不会再执行。很明显内存地址的比较要比equals方法高效的多。这也是Hashmap提高查找效率的一个重要手段。

至此，我们应该对equals和hashcode有了一个相对清晰的认识：hashcode提高了查找指定对象的效率。euqals定义了两个对象之间是否在逻辑上相同。hashcode只在HashMap，HashSet等这样使用了散列思想的地方用到，而equals在判断两个对象之间是否相同时需要用到，比如排序等。

## 总结

通过上面的分析，我们知道了hashcode与equals的几个关键：

#### 1.**不同的对象(equals返回false)可以有相同的hashcode**

#### 2.**相同的对象(equals返回true)hashcode一定相等**

#### 3.**若重新定义了上面两种方法中的一种，那么另一种方法也需要重新定义**（对1、2的遵守）

[关于如何重写equals方法与hashCode方法](http://stackoverflow.com/questions/27581/what-issues-should-be-considered-when-overriding-equals-and-hashcode-in-java)

## equals与==

"==" 比较的是两个对象的内存地址，是物理意义上的相等

equals比较的是两个对象逻辑意义上的相等，是逻辑意义上的相等

两个对象进行比较：

**== 返回true，则equals一定返回true**；

**equals返回true，== 不一定返回true**。







