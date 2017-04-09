---
layout: post
title: java异常的学习
date: 2016-12-13 21:46:52
tags: java
---

>最近的写代码的过程中，遇到很多异常的处理，以前上大学的时候写代码，遇到异常直接给个try catch了事，只是停留在看懂异常能够找出异常抛出点的水平。真正写代码的时候，不了解java的异常机制给自己编程带来很多不便，基础知识很重要！学习之～～

## 异常分类

{% asset_img java.png java异常体系 %}

java异常中的异常大体上可分为两类：Error 与 Exception，他们都继承自Throwable

<!-- more -->

### Error：

Error表示一些无法恢复的错误，会导致应用程序中断。比如我们喜闻乐见的OutOfMemoryError(内存溢出)， StackOverflowError(堆栈溢出)等，就是一种Error类型的异常。面对这种类型的异常在我们的应用程序中一般是无法挽救的，将直接导致程序错误退出。因此我们在代码中一般不必去特别关心这种类型的异常。

[Error类型的异常及其子类](https://docs.oracle.com/javase/7/docs/api/java/lang/Error.html)

### Exception:

Exception是一般常见的异常，我们的应用程序可以处理这些异常，比如NullPointerException、IndexOutOfBoundsException等等。发生这些异常时，可以选择通过捕获这些异常进行处理，使程序可以继续往下执行。

Exception又可以分为CheckException(检测型异常)与UncheckException(非检测型异常)。

在Exception的子类当中，非检测型异常为RuntimeException及其子类，剩下的异常则为检测型异常。

#### 检测型异常

所谓检测型异常，表示其接受编译器的检测，比如

```
public void readFile(String filePath){
        //编译无法通过
		File file = new File(filePath);
		FileReader fileReader = new FileReader(file);//FileNotFoundException
		BufferedReader bReader = new BufferedReader(fileReader);
		String line = null;
		while ((line = bReader.readLine()) != null) {//IOException
			System.out.println(line);
		}
}
```
编译上述代码，编译器会报错，编译无法通过。
如果是用Eclipse等ide去写这段代码，ide通常就会告诉你这段代码有错误。原因是上述代码会抛出检测型异常IOException。有以下两种修复错误的方法：

```
//第一种
public void readFile(String filePath) throws IOException{
		File file = new File(filePath);
		FileReader fileReader = new FileReader(file);
		BufferedReader bReader = new BufferedReader(fileReader);
		String line = null;
		while ((line = bReader.readLine()) != null) {
			System.out.println(line);
		}
}
//第二种
public void readFile(String filePath) {
		File file = new File(filePath);
		try {
			FileReader fileReader = new FileReader(file);
			BufferedReader bReader = new BufferedReader(fileReader);
			String line = null;
			while ((line = bReader.readLine()) != null) {
				System.out.println(line);
			}
		} catch (IOException e) {
			// TODO: handle exception
		}
}
```

第一种方式通过声明throws关键字将该异常继续向上抛出，这种方式下，该方法就抛出了检测型异常，他的调用者就会遇到一样的问题，调用者可以选择使用这种方式继续向调用链上层抛出，或者采用第二种方式处理异常。

第二种方式通过将抛出异常的代码使用try..catch块包裹起来，处理该异常。这种方式下他的调用者无需再次处理该异常。

上面这种类型的异常就是检测型异常，我们必须显示的去处理他，代表的有SQLException、IOException等等。

#### 非检测型异常

与检测型异常相对的，编译阶段不会检测这种类型的异常，当代码中有这种类型的异常抛出时，我们不需要像上面那样显示的处理他，比如：

```
public void test() {
        //编译可以通过
		throw new NullPointerException();
}
```
通过throw关键字抛出了一个NullPointerException异常，该异常是RunTimeException的子类，是一个非检测类型的异常。这种类型的异常一般是由程序逻辑错误引起的，比如空指针或者数组越界等等。

对于非检测类型的异常，我们也可以去使用try..catch捕获他，从而进行一些处理。如果我们没有捕获处理这个异常，系统会把异常一直往上层抛，一直到最上层，如果是多线程就由Thread.run()抛出，如果是单线程就被main()抛出。抛出之后，如果是线程，**这个线程也就退出了**。如果是主程序抛出的异常，**那么这整个程序也就退出了**。

Error实际上也是一种非检测型异常。

## 异常处理

### 关键字

了解了异常的分类，我们就可以愉快的处理异常了。记得上大学的时候写的代码，由于不理解java的异常机制，每当遇到检测型异常时，ide会要求在代码中处理这种情况。于是简单的try..catch解决，并在catch块中 e.printStackTrace()，就解决了IDE的报警问题。现在想来，这种代码如果运行在生产环境中，将会多么可怕。

通过上面的总结，我们已经了解了四个关键字：try catch throw throws.

throw表示将要抛出一个异常，后面跟一个Throwable的实例，throws置于函数的声明当中，表示该函数将会抛出何种类型的异常。

try catch 一般配合使用，还有一个关键字finally,也是与try catch 配合使用的。有这三种使用方式：

try..catch  try..finally try..catch..finally

catch 可以有多个，try只能有一个，finally可选。

finally用于保证一些资源的释放，因为一般情况下，finally中的语句总会在方法返回之前得到执行。

### try catch finally执行顺序

try catch finally的执行顺序为 try->catch->finally。

有多个catch时，按照catch块的先后顺序进行匹配，一旦一个异常与一个catch块匹配，则不会再与后面的catch块进行匹配。
因此，如果我们使用多个catch块捕获异常时，如果多个catch块捕获的异常具有继承关系，注意把继承链中低层次(也就是子类)的放在前面，把继承链中高层次的(也就是父类)放在后面。
这样做的目的很简单，就是尽量使异常被适合的catch所捕获，这样处理起来比较明确。

finally块中的代码一般是在try与catch内的控制转移语句执行之前执行的，用来做一些资源释放的操作。控制转移语句包括：return、throw、break 和 continue。

关于finally块的详细解析，参考[关于 Java 中 finally 语句块的深度辨析](https://www.ibm.com/developerworks/cn/java/j-lo-finally/)

另外有一点需要注意：不要在finally中return，因为finally中的return会覆盖已有的返回值，比如try或者catch中的返回值。比如：

```
public class TestException {
    public static void main(String[] args) {
        String str = new TestException().readFile();
        System.out.println(str);
    }
 
    public String readFile() {
        try {
            FileInputStream inputStream = new FileInputStream("D:/test.txt");
            int ch = inputStream.read();
            return "try";
        } catch (FileNotFoundException e) {
            System.out.println("file not found");
            return "FileNotFoundException";
        }catch (IOException e) {
            System.out.println("io exception");
            return "IOException";
        }finally{
            System.out.println("finally block");
            //return "finally";
        }
    }
}
```
D:/test.txt 并不存在，执行结果为:file not found    finally block   FileNotFoundException
去掉finally中的注释，执行结果为：file not found    finally block   finally


## 一些建议

了解了异常机制的基本原理，不一定能够很好的处理异常。当我们遇到异常需要处理的时候，需要遵循几个原则，才能写出更好的代码：

### 不要使用空的catch块

正如前面所说，上学的时候遇到异常时，直接try..catch了事，只是简单地e.printStackTrace(),把堆栈打印出来了。这样可能对定位异常比较有帮助，但是对异常的处理却没有帮助，既没有处理异常，上层代码也无法得知异常的抛出，
程序会继续运行，有可能出现无法预料的结果。当然，如果程序的逻辑容忍异常可以不用处理，那么可以不处理异常，简单的输出到日志记录即可。处理还需视实际情况而定。

### 在能够处理异常的地方处理异常

换句话说，就是在高层代码中处理异常。尽量将异常抛给上层调用者，由上层调用者统一进行处理。这样会使得程序流程比较清晰。

### 日志打印

只在必要的地方打印日志，如只在异常发生的地方输出日志，然后将异常抛到上层。这样比较容易定位异常，避免每次向上抛出异常时都打印日志，反复打印同一个异常会使得日志变得混乱

### 检测异常与非检测异常的选择

为可恢复的条件使用检查型异常，为编程错误使用运行时异常

在web项目中，我们经常把代码层次分为controller，service,dao等几层。在dao层中一搬会抛出SQLException,这就使得他的调用者必须显示的捕获该异常或者继续抛出。这样提高了代码的耦合性，污染了上层代码。
在比如接口的声明当中，我们为方法声明了一个检测型异常，那么他的所有实现类都必须作出同样的声明，即使实现类不会抛出异常。而且，所有的调用者都必须显示的捕获异常或者抛出异常，异常就会扩散开来，会使代码变得混乱。
所以我们应该正确的选择检测型异常和非检测型异常。个人认为，检测型异常的意义就在于提醒用户进行处理，比如一些资源的释放等等。如果该异常出现的很普遍，需要提醒调用者进行处理，那么就是用检测型异常，否则，就使用非检测型异常。

对于已经抛出的检测型异常，我们可以进行封装处理，比如对于第一种情况，污染上层代码的问题：

```
//处理前
public Data getDataById(Long id) throw SQLException {
 //根据 ID 查询数据库
}

//处理后
public Data getDataById(Long id) {
     try{
            //根据 ID 查询数据库
     }catch(SQLException e){
            //利用非检测异常封装检测异常，降低层次耦合
            throw new RuntimeException(SQLErrorCode, e);
     }finally{
            //关闭连接，清理资源
     }
}

```
我们将一个检测型异常封装成了非检测型异常向上抛出。

### 不要使用Exception捕捉所有潜在的异常

针对具体的异常进行处理，而不是使用Exception捕获所有的异常。这样不利于异常情况的处理，并且如果再次向上抛出时可能会丢书原有的异常信息。 

### 抛出与抽象相适应的异常

换句话说，一个方法所抛出的异常应该在一个抽象层次上定义，该抽象层次与该方法做什么相一致，而不一定与方法的底层实现细节相一致。例如，一个从文件、数据库或者 JNDI 装载资源的方法在不能找到资源时，应该抛出某种 ResourceNotFound 异常（通常使用异常链来保存隐含的原因），而不是更底层的 IOException 、 SQLException 或者 NamingException 。

我们有时候在捕获一个异常后抛出另一个封装后的异常信息，并且希望将原始的异常信息也保持起来，
throw抛出的是一个新的异常信息，这样势必会导致原有的异常信息丢失，如何保持？
在Throwable及其子类中的构造器中都可以接受一个cause参数，该参数保存了原有的异常信息，通过getCause()就可以获取该原始异常信息。

### 多线程中的异常

在java多线程程序中，所有线程都不允许抛出未捕获的检测型异常（比如sleep时的InterruptedException),
也就是说各个线程需要自己把自己的检测型处理掉。
这一点是通过java.lang.Runnable.run()方法声明(因为此方法声明上没有throw exception部分)进行了约束。
但是线程依然有可能抛出非检测型异常，当此类异常跑抛出时，线程就会终结，
而对于主线程和其他线程完全不受影响，且完全感知不到某个线程抛出的异常(也是说完全无法catch到这个异常)。

如果我们不考虑线程内可能出现的异常而导致线程的终结，那么就有可能造成意想不到的后果。如果是使用线程池的话，就有可能导致线程泄漏，这样的错误可能难以察觉，
最终导致程序挂掉或者内存溢出等等意想不到的问题，但是往往不好追踪问题出现的原因。
[Java 理论与实践: 嗨，我的线程到哪里去了？](https://www.ibm.com/developerworks/cn/java/j-jtp0924/)这篇文章很好的展示了一个多线程发生异常后产生的一系列后果。

对于线程可以自己处理的异常，比较好解决。我们可以在线程内部捕获异常，作一些处理，防止线程退出。比如，[Java 理论与实践: 嗨，我的线程到哪里去了？](https://www.ibm.com/developerworks/cn/java/j-jtp0924/)这篇文章中的一个示例：

```
private class SaferPoolWorker extends Thread {
    public void run() {
        IncomingResponse ir;
        while (true) {
            ir = (IncomingResponse) queue.getNext();
            PlugIn plugIn = findPlugIn(ir.getResponseId());
            if (plugIn != null) {
        try {
                    plugIn.handleMessage(ir.getResponse());
                }
                catch (RuntimeException e) {
                    // Take some sort of action; 
                    // - log the exception and move on
                    // - log the exception and restart the worker thread
                    // - log the exception and unload the offending plug-in
                }
            }
            else
                log("Unknown plug-in for response " + ir.getResponseId());
        }
    }
}
```
但是，当子线程发生异常时，我们需要父线程或者主线程可以感知子线程的异常，也就是得到子线程产生的异常，然后做一些处理。[Java线程池异常处理最佳实践](http://blog.onlycatch.com/post/Java%E7%BA%BF%E7%A8%8B%E6%B1%A0%E5%BC%82%E5%B8%B8%E5%A4%84%E7%90%86%E6%9C%80%E4%BD%B3%E5%AE%9E%E8%B7%B5)这篇文章给出了很好的总结，
摘抄其总结如下：
```
处理线程池中的异常有两种思路： 
1）提交到线程池中的任务自己捕获异常并处理，不抛给线程池 
2）由线程池统一处理
对于execute方法提交的线程，有两种处理方式 
1）自定义线程池并实现afterExecute方法 
2）给线程池中的每个线程指定一个UncaughtExceptionHandler,由handler来统一处理异常。
对于submit方法提交的任务，异常处理是通过返回的Future对象进行的。
```

## 其他

还发现了一个比较有趣的异常处理情况，虽然可能很少碰到，但是碰到了可以参考作者的思路。

[技巧：当不能抛出异常时](https://www.ibm.com/developerworks/cn/java/j-ce/)这篇文章介绍了一种不是很常见的情况：即不能处理，也不能抛出异常(包括非检测型异常)时怎么办？

## 参考

[Java 异常处理的误区和经验总结](http://www.ibm.com/developerworks/cn/java/j-lo-exception-misdirection/)

[Java异常处理和设计](http://www.importnew.com/18994.html)

[Java 理论与实践: 关于异常的争论](https://www.ibm.com/developerworks/cn/java/j-jtp05254/)

