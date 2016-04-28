---
layout: post
categories: java 多线程
---

> 今天测试那边在做压力测试的时候，发现新版本的Jdbc占用CPU很高，导致并发量降低，研究半天，发现出问题的地方在于每条语句执行过后都会调用ThreadLocal的get方法。研究一番ThreadLocal...

