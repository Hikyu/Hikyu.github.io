---
layout: post
title: 理解JavaScript作用域链
date: 2017-09-16 09:59:34
categories: 
- 技术
- 编程
tags: javascript
---

> 最近在读《JavaScript权威指南》，读到“函数作用域和声明提前”这部分内容时有点晕，上网查了一些资料，算是弄明白了，所以把自己的理解记下来~

## 作用域

1. 全局作用域

在代码中任何地方都能访问到的对象拥有全局作用域，一般来说以下几种情形拥有全局作用域:

- 最外层函数和在最外层函数外面定义的变量拥有全局作用域，例如：

```javascript
var a="global";
function doSomething(){
    var b="local";
    function innerSay(){
        alert(b);
    }
    innerSay();
}
alert(a); //global
alert(b); //脚本错误
doSomething(); //local
innerSay() //脚本错误
```

<!-- more -->

- 所有末定义直接赋值的变量自动声明为拥有全局作用域，例如：

```javascript
function doSomething(){
    var a="local";
    b="global";
    alert(a);
}
doSomething(); //local
alert(b); //global
alert(a); //脚本错误
```

- 所有window对象的属性拥有全局作用域

一般情况下，window对象的内置属性都拥有全局作用域，例如window.name、window.location、window.top等等。

2. 局部作用域

和全局作用域相反，局部作用域一般只在固定的代码片段内可访问到，最常见的例如函数内部，所有在一些地方也会看到有人把这种作用域称为函数作用域，例如下列代码中的a和函数innerSay都只拥有局部作用域。

```javascript
function doSomething(){
    var a="local";
    function innerSay(){
        alert(a);
    }
    innerSay();
}
alert(a); //脚本错误
innerSay(); //脚本错误
```

## 执行上下文

在JavaScript中有三种代码运行环境：

- Global Code

    JavaScript代码开始运行的默认环境

- Function Code

    代码进入一个JavaScript函数

- Eval Code

    使用eval()执行代码

为了表示不同的运行环境，JavaScript中有一个执行上下文(Execution context，EC)的概念。也就是说，当JavaScript代码执行的时候，会进入不同的执行上下文，这些执行上下文就构成了一个执行上下文栈(Execution context stack，ECS)。

```javascript
var a = "global var";

function foo(){
    console.log(a);
}

function outerFunc(){
    var b = "var in outerFunc";
    console.log(b);

    function innerFunc(){
        var c = "var in innerFunc";
        console.log(c);
        foo();
    }

    innerFunc();
}

outerFunc()
```

代码首先进入Global Execution Context，然后依次进入outerFunc，innerFunc和foo的执行上下文，执行上下文栈就可以表示为：

{% asset_img context.png context %}

当JavaScript代码执行的时候，第一个进入的总是默认的Global Execution Context，所以说它总是在ECS的最底部。

对于每个Execution Context都有三个重要的属性，变量对象(VO)，作用域链(Scope chain)和this。

{% asset_img vo.png vo %}

## 问题提出

```javascript
var a = 'global';
function echo() {
     alert(a);
     var a = 'local';
     alert(a);
     alert(b);
}

echo();
```

运行结果为：

```javascript
undefined
local
[脚本出错]
```

是不是跟你预想的不同？

## 理解作用域链

任何执行上下文时刻的作用域, 都是由作用域链(scope chain)来实现：

1. 在一个函数被定义的时候, 这个函数对象的[[scope]]属性会指向它定义时刻的执行上下文的scope chain

2. 在一个函数对象被调用的时候，会创建一个活动对象(AO)，然后将这个活动对象做为此时执行上下文的作用域链(scope chain)最前端, 并将这个函数对象的[[scope]]加入到scope chain中

例子：

```javascript
function add(num1,num2) {
    var sum = num1 + num2;
    return sum;
}
```

{% asset_img add.png add %}

在执行func的定义语句的时候, 会创建一个这个函数对象的[[scope]]属性， 并将这个[[scope]]属性, 指向定义它的执行上下文的作用域链上。 此时因为add定义在全局环境, 所以此时的scope chain只是指向全局活动对象window active object

```javascript
var total = add(5,10);
```

{% asset_img total.png total %}

在调用add的时候, 会创建一个活动对象(假设为aObj)，并创建arguments属性, 然后会给这个对象添加俩个命名属性aObj.num1, aObj.num2; 对于每一个在这个函数中申明的局部变量和函数定义, 都作为该活动对象的同名命名属性

然后将调用参数赋值给形参数，对于缺少的调用参数，赋值为undefined

然后将这个活动对象做为scope chain的最前端, 并将add的[[scope]]属性所指向的,scope chain, 加入到当前scope chain

有了上面的作用域链, 在发生标识符解析的时候, 就会逆向查询当前scope chain列表的每一个活动对象的属性，如果找到同名的就返回。找不到，那就是这个标识符没有被定义。

- 变量对象(VO)与活动对象(AO)

变量对象是在函数被调用，但是函数尚未执行的时刻被创建的，这个创建变量对象的过程实际就是函数内数据(函数参数、内部变量、内部函数)初始化的过程。

未进入执行阶段之前，变量对象中的属性都不能访问。但是进入执行阶段之后，变量对象转变为了活动对象，里面的属性都能被访问了，然后开始进行执行阶段的操作。所以活动对象实际就是变量对象在真正执行时的另一种形式。

## 实例

```javascript
function factory() {
     var a = 'local';
     var intro = function(){
          alert(a);
     }
     return intro;
}

function app(para){
     var a = para;
     factory();
}

app('global');
```

执行代码，在刚进入app函数体时，scope chain为：

```javascript
[[scope chain]] = [
{
     para : 'global',
     a    : undefined,
     arguments : ['global']
}, {
     window call object
}
]
```

当调用进入factory的函数体的时候，此时的scope chain为:

```javascript
[[scope chain]] = [
{
     a     : undefined,
     intor : undefined
}, {
     window call object
}
]
```

在**定义intro函数**的时候，intro函数的[[scope]]为:

```javascript
[[scope chain]] = [
{
     a     : 'local',
     intor : undefined
}, {
     window call object
}
]
```

当调用进入intor的时候， 此时的scope chain为:

```javascript
[[scope chain]] = [
{
     intro call object
}, {
     a     : 'local',
     intor : undefined
}, {
     window call object
}
]
```

运行结果为：

```javascript
local
```

## 问题解决

回到"问题提出"部分：

当echo函数被调用的时候, echo的活动对象已经被预编译过程创建, 此时echo的活动对象为:

```javascript
[callObj] = {
name : undefined
}
```

当第一次alert的时候, 发生了标识符解析, 在echo的活动对象中找到了name属性, 所以这个name属性, 完全的遮挡了全局活动对象中的name属性

## 参考

[JavaScript的执行上下文](http://www.cnblogs.com/wilber2013/p/4909430.html)

[JavaScript 开发进阶：理解 JavaScript 作用域和作用域链](http://www.cnblogs.com/lhb25/archive/2011/09/06/javascript-scope-chain.html)

[Javascript作用域原理](http://www.laruence.com/2009/05/28/863.html)

[图解Javascript——变量对象和活动对象](http://www.cnblogs.com/ivehd/p/vo_ao.html)
