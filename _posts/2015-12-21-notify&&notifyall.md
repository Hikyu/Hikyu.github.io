---
layout: post
title:  "notify && notifyAll"
date:   2015-12-21 22:10:55
categories: java ���߳� 
---

# notify �� notifyAll 

������������ô�������
���߳����ɣ�����Ҫ���ǰ�˳��ִ�С�
�����ų�������

```
class SyncTag {
	public int threadNO;
	public SyncTag() {
	    threadNO = 0;
	}
}
class ThreadA extend Thread{
	SyncTag syncTag;
	int scriptNO;
	ThreadA(SyncTag syncTag,int scriptNO){
			this.syncTag=syncTag;
			this.scriptNO=scriptNO;
	}
	public void Run(){
			synchronized (syncTag) {
                if (syncTag.threadNO != scriptNO) {
                        try {
                                syncTag.wait();
                        } catch (InterruptedException e) {
                                    e.printStackTrace();
                        }
                }
                dosomething();
                syncTag.threadNO++;
                syncTag.notifyAll();
			}
	}
}
public class Test{
	public static void main(String args[]){
		    SyncTag syncTag=new SyncTag();
			 	for(int i=0;i<10;++i){
				 	ThreadA t=new ThreadA(syncTag,i);
					 t.start();
			}
	}
}
```

���ȴ��������Ԥ�ϵ���������ʮ���̵߳�ִ��˳��Ȼ�ǻ��ҵģ�����ġ���Ȼ������֮��ʵ���˴���ִ�С�
�о�һ���������� notify ��notifyAll �ڵ���
������ ͬ������syncTag����notify���� ��ʱ�򣬻�����N��ȴ���Դ�߳��е�һ������ ������ͬ�������wait ��������������Щ�̣߳������ڻ����ĸ��̣߳��ǲ�ȷ���ġ�
�������߳���Ȼ����������Ҫ��notify ���� notifyAll ���ѡ�
		 
������ͬ������syncTag����notifyAll���� ��ʱ�����н���wait ��������������Щ�̶߳��������ˡ������е�һ��������ͬ������syncTag��������ִ����ȥ��
ʣ�µ�û�л�������߳�������ȴ��������������ͬ���ǣ���Щ�ȴ����߲㲻����Ҫnotify����notifyAllȥ�����ˣ�һ��ӵ�������̷߳���������Щ�߳̾�һӵ���ϣ�ȥ��ռ�������������У�
û��������ʵ���š�
		 
�����notify �� notifyAll���ߵ�����.
		 
��ô�������������Ƿ�����Ϊʹ����notifyAll ��ԭ���أ���ʵ�����ǡ���ʹ�Ҹĳ�notify ����Щ�߳�Ҳû�а���˳��ȥ���С�
ԭ�����ڣ���ĳ����ִ�е��̣߳��߳�0��������notify ����notifyAll ֮��ĳ���̱߳�ѡ���ˡ��������ѡ�е��̲߳���һ�����߳�1.��Ϊ����ĳ���߳�֮������������ȥ����Ƿ����
syncTag.threadNO == scriptNO ���������ֻҪ�������ˣ���ǡ��ӵ��������������ִ����ȥ�ˡ�����ֻ��Ҫ������ִ��֮ǰ�ټ��һ���Ƿ� ����syncTag.threadNO == scriptNO ���������
��������ϣ��ͼ���wait.������ִ�С�
�ܼ򵥣��� 

{% highlight ruby linenos %}
if (syncTag.threadNO != scriptNO) {
    try {
			syncTag.wait();
		} catch (InterruptedException e) {
								e.printStackTrace();
		}
}
{% endhighlight %}

�ⲿ�ִ��� ��Ϊ�� 

{% highlight ruby linenos %}
while (syncTag.threadNO != scriptNO) {
		try {
				syncTag.wait();
		} catch (InterruptedException e) {
				e.printStackTrace();
		}
}
{% endhighlight %}

�������ͽ���ˡ�
	 
## **����**��
��������һ����������ǰ�������ķ����Ѵ�����ˣ���ͬʱ������� notifyAll ��Ϊ notify.�����ֳ����ˣ�
����һ�£�����߳�0ִ�����֮�����syncTag.notify����������ĳ���̣߳��߳�3��������������߳���ǡ�ò����� syncTag.threadNO == scriptNO
�����������ô����̣߳��߳�3�������wait. ���ʱ�����е��̶߳��� wait,����û��һ���߳������У�Ҳû�������߳��ܹ����� notify����notifyAll����������
�е�һ�������������������޾��ĵȴ���
		 
���ԣ�����ʹ��notify����notifyAll �͵þ��������������ˡ�