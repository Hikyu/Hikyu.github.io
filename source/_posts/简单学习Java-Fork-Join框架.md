---
layout: post
title: 简单学习Java-Fork/Join框架
date: 2017-11-30 16:20:27
categories:
- 技术
- 编程
tags:
- java
- 多线程 
---
# Fork/Join

## 分治思想

分治法的设计思想是：将一个难以直接解决的大问题，分割成一些规模较小的相同问题，以便各个击破，分而治之。

分治策略是：对于一个规模为n的问题，若该问题可以容易地解决（比如说规模n较小）则直接解决，否则将其分解为k个规模较小的子问题，这些子问题互相独立且与原问题形式相同，递归地解这些子问题，然后将各子问题的解合并得到原问题的解。这种算法设计策略叫做分治法。

分治法在每一层递归上都有三个步骤：

- 分解：将原问题分解为若干个规模较小，相互独立，与原问题形式相同的子问题；

- 解决：若子问题规模较小而容易被解决则直接解，否则递归地解各个子问题

- 合并：将各个子问题的解合并为原问题的解。

<!-- more -->

归并排序运用了分治思想：

{% asset_img gui.jpg 归并排序 %}

```java
public class MergeSort {
	static int number = 0;
	int[] arr;

	public static void main(String[] args) {
		int[] a = { 26, 5, 98, 108, 28, 99, 100, 56, 34, 1 };
		printArray("排序前：", a);
		MergeSort mergeSort = new MergeSort(a);
		mergeSort.sort();
		printArray("排序后：", a);
	}

	private static void printArray(String pre, int[] a) {
		System.out.print(pre + "\n");
		for (int i = 0; i < a.length; i++)
			System.out.print(a[i] + "\t");
		System.out.println();
	}

	public MergeSort(int[] a) {
		this.arr = a;
	}

	public void sort() {
		sort(arr, 0, arr.length - 1);
	}

	private void sort(int[] a, int left, int right) {
		if (left >= right)
			return;

		int mid = (left + right) / 2;
		sort(a, left, mid);
		sort(a, mid + 1, right);
		merge(a, left, mid, right);
	}

	private void merge(int[] a, int left, int mid, int right) {

		int[] tmp = new int[a.length];
		int r1 = mid + 1;
		int tIndex = left;
		int cIndex = left;
		// 逐个归并
		while (left <= mid && r1 <= right) {
			if (a[left] <= a[r1])
				tmp[tIndex++] = a[left++];
			else
				tmp[tIndex++] = a[r1++];
		}
		// 将左边剩余的归并
		while (left <= mid) {
			tmp[tIndex++] = a[left++];
		}
		// 将右边剩余的归并
		while (r1 <= right) {
			tmp[tIndex++] = a[r1++];
		}
		System.out.println("第" + (++number) + "趟排序:\t");
		// 从临时数组拷贝到原数组
		while (cIndex <= right) {
			a[cIndex] = tmp[cIndex];
			// 输出中间归并排序结果
			System.out.print(a[cIndex] + "\t");
			cIndex++;
		}
		System.out.println();
	}

}
```

## fork/join

Java1.7 提供的fork/join框架运用了上面提到的分治思想。

{% asset_img fork.png fork %}

{% asset_img join.png join %}

fork/join框架由两部分组成：

- ForkJoinTask：我们要使用ForkJoin框架，必须首先创建一个ForkJoin任务。它提供在任务中执行fork()和join()操作的机制，通常情况下我们不需要直接继承ForkJoinTask类，而只需要继承它的子类，Fork/Join框架提供了以下两个子类：

    RecursiveAction：用于没有返回结果的任务。

    RecursiveTask ：用于有返回结果的任务。

- ForkJoinPool ：ForkJoinTask需要通过ForkJoinPool来执行，任务分割出的子任务会添加到当前工作线程(ForkJoinWorkerThread)所维护的双端队列中，进入队列的头部。

    ForkJoinPool提供了三种接口来提交任务：

    execute(ForkJoinTask): Arrange asynchronous execution

    invoke(ForkJoinTask): Await and obtain result

    submit(ForkJoinTask): Arrange exec and obtain Future

fork/join框架还运用到了一个技术：工作窃取

每个工作线程都有一个工作队列，这个队列是双端队列。对于该线程，新的任务进入队列头部，执行任务则从头部取出。若该线程的工作队列为空，也就是没有任务可以执行，则从其他线程的工作队列的尾部窃取任务执行。这样做很大程度上减少了对队列的访问冲突。

{% asset_img work.png 工作窃取 %}

下面分别参考两个使用了fork/join框架的例子，针对RecursiveAction和RecursiveTask：

网络爬虫

```java
public class WebCrawer implements LinkHandler {

    private final Collection<String> visitedLinks = Collections.synchronizedSet(new HashSet<String>());
    private String url;
    private ForkJoinPool mainPool;

    public WebCrawer(String startingURL, int maxThreads) {
        this.url = startingURL;
        mainPool = new ForkJoinPool(maxThreads);
    }

    private void startCrawling() {
        mainPool.invoke(new LinkFinderAction(this.url, this));
    }

    @Override
    public int size() {
        return visitedLinks.size();
    }

    @Override
    public void addVisited(String s) {
        visitedLinks.add(s);
    }

    @Override
    public boolean visited(String s) {
        return visitedLinks.contains(s);
    }

    /**
     * @param args the command line arguments
     */
    public static void main(String[] args) throws Exception {
        new WebCrawer("http://www.baidu.com", 8).startCrawling();
    }
}

interface LinkHandler {

    /**
     * Returns the number of visited links
     * @return
     */
    int size();

    /**
     * Checks if the link was already visited
     * @param link
     * @return
     */
    boolean visited(String link);

    /**
     * Marks this link as visited
     * @param link
     */
    void addVisited(String link);
}

class LinkFinderAction extends RecursiveAction {

    private String url;
    private LinkHandler cr;
    /**
     * Used for statistics
     */
    private static final long t0 = System.nanoTime();

    public LinkFinderAction(String url, LinkHandler cr) {
        this.url = url;
        this.cr = cr;
    }

    @Override
    public void compute() {
        if (!cr.visited(url)) {
            System.out.println(url);
            try {
                List<RecursiveAction> actions = new ArrayList<RecursiveAction>();
                URL uriLink = new URL(url);
                Parser parser = new Parser(uriLink.openConnection());
                NodeList list = parser.extractAllNodesThatMatch(new NodeClassFilter(LinkTag.class));

                for (int i = 0; i < list.size(); i++) {
                    LinkTag extracted = (LinkTag) list.elementAt(i);

                    if (!extracted.extractLink().isEmpty()
                            && !cr.visited(extracted.extractLink())) {

                        actions.add(new LinkFinderAction(extracted.extractLink(), cr));
                    }
                }
                cr.addVisited(url);

                if (cr.size() == 1500) {
                    System.out.println("Time for visit 1500 distinct links= " + (System.nanoTime() - t0));
                }

                //invoke recursively
                invokeAll(actions);
            } catch (Exception e) {
                //ignore 404, unknown protocol or other server errors
            }
        }
    }
}
```

词频统计

```java
class Document {
    private final List<String> lines;
    
    Document(List<String> lines) {
        this.lines = lines;
    }
    
    List<String> getLines() {
        return this.lines;
    }
    
    static Document fromFile(File file) throws IOException {
        List<String> lines = new LinkedList<>();
        try(BufferedReader reader = new BufferedReader(new FileReader(file))) {
            String line = reader.readLine();
            while (line != null) {
                lines.add(line);
                line = reader.readLine();
            }
        }
        return new Document(lines);
    }
}

/* ......................................................................................... */

class Folder {
    private final List<Folder> subFolders;
    private final List<Document> documents;
    
    Folder(List<Folder> subFolders, List<Document> documents) {
        this.subFolders = subFolders;
        this.documents = documents;
    }
    
    List<Folder> getSubFolders() {
        return this.subFolders;
    }
    
    List<Document> getDocuments() {
        return this.documents;
    }
    
    static Folder fromDirectory(File dir) throws IOException {
        List<Document> documents = new LinkedList<>();
        List<Folder> subFolders = new LinkedList<>();
        for (File entry : dir.listFiles()) {
            if (entry.isDirectory()) {
                subFolders.add(Folder.fromDirectory(entry));
            } else {
                documents.add(Document.fromFile(entry));
            }
        }
        return new Folder(subFolders, documents);
    }
}

/* ......................................................................................... */

public class WordCounter {    

/* ......................................................................................... */

    String[] wordsIn(String line) {
        return line.trim().split("(\\s|\\p{Punct})+");
    }
    
    Long occurrencesCount(Document document, String searchedWord) {
        long count = 0;
        for (String line : document.getLines()) {
            for (String word : wordsIn(line)) {
                if (searchedWord.equals(word)) {
                    count = count + 1;
                }
            }
        }
        return count;
    }
    
/* ......................................................................................... */
    
    Long countOccurrencesOnSingleThread(Folder folder, String searchedWord) {
        long count = 0;
        for (Folder subFolder : folder.getSubFolders()) {
            count = count + countOccurrencesOnSingleThread(subFolder, searchedWord);
        }
        for (Document document : folder.getDocuments()) {
            count = count + occurrencesCount(document, searchedWord);
        }
        return count;
    }

/* ......................................................................................... */

    class DocumentSearchTask extends RecursiveTask<Long> {
        private final Document document;
        private final String searchedWord;
        
        DocumentSearchTask(Document document, String searchedWord) {
            super();
            this.document = document;
            this.searchedWord = searchedWord;
        }
        
        @Override
        protected Long compute() {
            return occurrencesCount(document, searchedWord);
        }
    }

/* ......................................................................................... */

    class FolderSearchTask extends RecursiveTask<Long> {
        private final Folder folder;
        private final String searchedWord;
        
        FolderSearchTask(Folder folder, String searchedWord) {
            super();
            this.folder = folder;
            this.searchedWord = searchedWord;
        }
        
        @Override
        protected Long compute() {
            long count = 0L;
            List<RecursiveTask<Long>> forks = new LinkedList<>();
            for (Folder subFolder : folder.getSubFolders()) {
                FolderSearchTask task = new FolderSearchTask(subFolder, searchedWord);
                forks.add(task);
                task.fork();
            }
            for (Document document : folder.getDocuments()) {
                DocumentSearchTask task = new DocumentSearchTask(document, searchedWord);
                forks.add(task);
                task.fork();
            }
            for (RecursiveTask<Long> task : forks) {
                count = count + task.join();
            }
            return count;
        }
    }
        
/* ......................................................................................... */
    
    private final ForkJoinPool forkJoinPool = new ForkJoinPool();
    
    Long countOccurrencesInParallel(Folder folder, String searchedWord) {
        return forkJoinPool.invoke(new FolderSearchTask(folder, searchedWord));
    }

/* ......................................................................................... */
    
    public static void main(String[] args) throws IOException {
    	args = new String[3];
    	args[0] = "D:\\code\\driver";
    	args[1] = "java";
        WordCounter wordCounter = new WordCounter();
        Folder folder = Folder.fromDirectory(new File(args[0]));
        
//        int repeatCount = Integer.decode(args[2]);
        int repeatCount = 1;
        long counts;
        long startTime;
        long stopTime;
        
        long[] singleThreadTimes = new long[repeatCount];
        long[] forkedThreadTimes = new long[repeatCount];
        
        for (int i = 0; i < repeatCount; i++) {
            startTime = System.currentTimeMillis();
            counts = wordCounter.countOccurrencesOnSingleThread(folder, args[1]);
            stopTime = System.currentTimeMillis();
            singleThreadTimes[i] = (stopTime - startTime);
            System.out.println(counts + " , single thread search took " + singleThreadTimes[i] + "ms");
        }
        
        for (int i = 0; i < repeatCount; i++) {
            startTime = System.currentTimeMillis();
            counts = wordCounter.countOccurrencesInParallel(folder, args[1]);
            stopTime = System.currentTimeMillis();
            forkedThreadTimes[i] = (stopTime - startTime);
            System.out.println(counts + " , fork / join search took " + forkedThreadTimes[i] + "ms");
        }
        
        System.out.println("\nCSV Output:\n");
        System.out.println("Single thread,Fork/Join");        
        for (int i = 0; i < repeatCount; i++) {
            System.out.println(singleThreadTimes[i] + "," + forkedThreadTimes[i]);
        }
        System.out.println();
    }
}
```

上面的代码分别参考自[Java Tip: When to use ForkJoinPool vs ExecutorService](https://www.javaworld.com/article/2078440/enterprise-java/java-tip-when-to-use-forkjoinpool-vs-executorservice.html)和[Fork and Join: Java Can Excel at Painless Parallel Programming Too!](http://www.oracle.com/technetwork/articles/java/fork-join-422606.html)

fork/join框架适用于以下几种场景：

1. 可以通过将任务分割-合并得到结果，fork/join可以并行处理子问题，提高处理效率。

2. fork/join善于处理并行问题。可并行处理问题要么是彼此完全独立的问题，要么是可分解单独处理的问题。可分解单独处理的问题即1中提到的，彼此完全独立的问题譬如 事件类型（不需要join）的任务（[akka](https://doc.akka.io/docs/akka/2.5.6/scala/dispatchers.html)）。

3. fork/join应该用于处理cup密集型的计算任务。fork/join不适用于执行包含阻塞io的任务类型。

ForkJoin与MapReduce很类似，都是基于分治思想，用于执行并行任务。他们之间的差异在于：

- MapReduce用于分布式环境(利用很多机器做分布式计算)，ForkJoin用于单机多核(充分利用多处理器)。

- MapReduce一开始就先切分好任务然后再执行，并且彼此间在最后合并之前不需要通信，而ForkJoin任务自己知道该如何切分自己，递归地切分到一组合适大小的子任务来执行。

## 参考

[10: ♦ ExecutorService Vs Fork/Join & Future Vs CompletableFuture Interview Q&As](https://www.java-success.com/10-%E2%99%A6-executorservice-vs-forkjoin-future-vs-completablefuture-interview-qa/)

[Fork and Join: Java Can Excel at Painless Parallel Programming Too!](http://www.oracle.com/technetwork/articles/java/fork-join-422606.html)

[Java Tip: When to use ForkJoinPool vs ExecutorService](https://www.javaworld.com/article/2078440/enterprise-java/java-tip-when-to-use-forkjoinpool-vs-executorservice.html)