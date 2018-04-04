---
layout: post
title: 可能会用到的Git技巧(1)
date: 2018-03-01 14:56:57
categories: 
- 技术
- 工具
tags: 
- git
---

{% asset_img git.jpg git %}

> 最近在看 gitlab 的源码，因为公司希望把 gitlab-ee 的 merge squash 功能集成到 gitlab-ce 上来，供公司内部使用....
> 这个任务交给了我，现在这个功能已经改的差不多了，中间也了解了一些可能会用到的 git 技巧，现在记录下来

## git cherry-pick

[git cherry-pick](https://git-scm.com/docs/git-cherry-pick) 可以应用某个分支的某些提交到另一个分支上去。

<!-- more -->

比如，在我们的工作流中，有两个分支分别是特性分支 feature 和发布分支 stable。feature 新增了某个功能并进行了提交且通过了测试。过了一段时间到了发布日，此时我们想要将该功能集成到发布分支 stable 上面进行发布。将 feature 直接合并到 stable？ 不行，stable分支只想集成这个功能，而特性分支很可能已经进行了别的提交。这种情况就需要用到     cherry-pick 的功能。cherry-pick 在 git 工作流中的使用比较常见。

```
git checkout stable
git cherry-pick <commit id>
``` 

首先我们需要在 feature 分支上通过 `git log` 查询得到我们需要的提交的 commitID，比如 41e59d4(这个提交位于 feature 分支当中)。

然后切换到 stable 分支，执行 git `cherry-pick 41e59d4` 如果没有冲突，就会正常提交。

如果出现了冲突:

```
$ git cherry-pick 41e59d4
error: could not apply 41e59d4... feature
hint: after resolving the conflicts, mark the corrected paths
hint: with 'git add <paths>' or 'git rm <paths>'
hint: and commit the result with 'git commit'
```

先使用 `git status` 查看哪些文件出现了冲突：

```
$ git status
On branch stable
You are currently cherry-picking commit 41e59d4.
  (fix conflicts and run "git cherry-pick --continue")
  (use "git cherry-pick --abort" to cancel the cherry-pick operation)

Unmerged paths:
  (use "git add <file>..." to mark resolution)

        both modified:   test.txt

no changes added to commit (use "git add" and/or "git commit -a")
```

解决完冲突后，执行 `git add` 和 `git commit` 完成合并。

如果是一次 cherry-pick 多个 commit，则执行 `git cherry-pick --continue` 继续 cherry-pick。如果想要返回到执行 cherry-pick 前的状态，执行 `git cherry-pick --abort`。

## git bisect

设想如下场景：我们刚刚发布了一个新版本，运行了一段时间后偶然发现了某个表现不太正常。但是在上一个版本中是不存在这种表现的。新版本与上一个版本中间有一百多次的提交，如何确定是哪一次提交出了问题呢？

答案就是使用 `git bisect` 命令。

首先运行 `git bisect start` 启动，然后使用 `git bisect bad` 来告诉系统当前的提交已经有问题了。然后必须告诉 bisect 已知的最后一次正常状态是哪次提交，使用 `git bisect good [good_commit]`：

```
git bisect start
git bisect bad
git bisect good v1.0
Bisecting: 6 revisions left to test after this
[ecb6e1bc347ccecc5f9350d878ce677feb13d3b2] error handling on repo
```

Git 发现在你标记为正常的提交(v1.0)和当前的错误版本之间有大约12次提交，于是它检出中间的一个。在这里，你可以运行测试来检查问题是否存在于这次提交。如果是，那么它是在这个中间提交之前的某一次引入的；如果否，那么问题是在中间提交之后引入的。如果这里是没有错误的，那么就运行 `git bisect good` 命令，如果这次提交已经出现了问题，运行 `git bisect bad`。

运行了上面的命令之后，就会此次提交和上个错误提交的中间点(git bisect good)或者和上个正常提交的中间点(git bisect bad)。这也是二分查找的原理。

反复执行上面的过程，最终可以找到第一个错误提交的 commit：

```
b047b02ea83310a70fd603dc8cd7a6cd13d15c04 is first bad commit
```

再通过 `git show b047b02ea8` 就能看到这次错误提交的全部内容。

这样就可以找出缺陷被引入的根源。

## git update-index --assume-unchanged 

我们的代码中经常会包含一些配置文件，每个成员的配置文件都有所不同。我们每次 `git push` 或 `git merge`时都有可能会重置这些配置文件，这样在每次合并远端代码后都需要我们手动修改他。更合理的办法是告诉 Git 忽略这些本地配置文件的变更：

```
git update-index --assume-unchanged <your_file_path>
```

我们也可以重新跟踪被忽略的文件：

```
git update-index --no-assume-unchanged <your_file_path>
```

注意，与 .gitignore 文件的作用不同，.gitignore 文件作用于 Untracked Files，也就是那些从来没有被 Git 记录过的文件(自添加以后，从未 add 及 commit 过的文件)，比如日志文件、临时文件等。这些文件是不需要上传到远程仓库的。

而 `git update-index --assume-unchanged <your_file_path>` 忽略的文件是已经存在于代码仓库中，也是代码本身的一部分，比如配置文件等。

## git log

[git log](https://git-scm.com/docs/pretty-formats) 命令可一接受一个 `--pretty` 选项，来确定输出的格式.

```
%H	提交对象（commit）的完整哈希字串
%h	提交对象的简短哈希字串
%T	树对象（tree）的完整哈希字串
%t	树对象的简短哈希字串
%P	父对象（parent）的完整哈希字串
%p	父对象的简短哈希字串
%an	作者（author）的名字
%ae	作者的电子邮件地址
%ad	作者修订日期（可以用 -date= 选项定制格式）
%ar	作者修订日期，按多久以前的方式显示
%cn	提交者(committer)的名字
%ce	提交者的电子邮件地址
%cd	提交日期
%cr	提交日期，按多久以前的方式显示
%s	提交说明
```

比如，`git shortlog --format='%H|%cn|%s' | grep '#2230'` 可以查找 commit 内容包括某个特定字符的提交。`git shortlog` 相当于 `git log --pretty=short`

`git log --pretty=format:'%h %ad | %s%d [%an]' --graph --date=short` 是一个不错的格式化log的命令，我们可以把他做成 alias：

```
git config --global alias.lg "log --pretty=format:'%h %ad | %s%d [%an]' --graph --date=short"
```

这样，我们就可以直接输入 `git lg` 查看格式化的 git log 啦。

---

遇到文件重命名的情况,使用 `git log --follow <filename>`更为合适，详细内容查看[git log --follow奇遇记](https://x-front-team.github.io/2016/12/22/git-log-follow%E5%A5%87%E9%81%87%E8%AE%B0/)


## git blame

`git blame` 命令可以查看某个文件现在的代码是由谁在哪一天修改的。使用 `-L` 参数可以指定文件的某几行的修改情况。

`git blame -L 12,22 simplegit.rb`

```
^4832fe2 (Scott Chacon  2008-03-15 10:31:28 -0700 12)  def show(tree = 'master')
^4832fe2 (Scott Chacon  2008-03-15 10:31:28 -0700 13)   command("git show #{tree}")
^4832fe2 (Scott Chacon  2008-03-15 10:31:28 -0700 14)  end
^4832fe2 (Scott Chacon  2008-03-15 10:31:28 -0700 15)
9f6560e4 (Scott Chacon  2008-03-17 21:52:20 -0700 16)  def log(tree = 'master')
79eaf55d (Scott Chacon  2008-04-06 10:15:08 -0700 17)   command("git log #{tree}")
9f6560e4 (Scott Chacon  2008-03-17 21:52:20 -0700 18)  end
9f6560e4 (Scott Chacon  2008-03-17 21:52:20 -0700 19)
42cf2861 (Magnus Chacon 2008-04-13 10:45:01 -0700 20)  def blame(path)
42cf2861 (Magnus Chacon 2008-04-13 10:45:01 -0700 21)   command("git blame #{path}")
42cf2861 (Magnus Chacon 2008-04-13 10:45:01 -0700 22)  end
```

第一列是最后一次修改那行(也就是现在看到的修改)的那次提交的 commitID，第二列和第三列分别是作者的姓名和修改日期，第四列是修改的行号，最后一列显示了这行当前的内容。

注意类似 `^4832fe2` 的提交表示这个提交是文件第一次被加入项目时的提交，从那以后这行就未被改变过。

有时候，我们不仅仅想关注当前某个文件的某行是由谁在什么时候修改的，我们还想看到某行的修改历史。这个时候可以使用 `git log -L start,end:file` 达到这个目的。

`git log -L 17,37:./services/merge_requests/merge_service.rb`

```sh
commit 190ea021cd1fd89d20c9548a72034a7b941413ca
Merge: bddbb90fd9 011558ea4a
Author: Sean McGivern <sean@mcgivern.me.uk>
Date:   Mon Nov 20 15:08:50 2017 +0000

    Merge branch 'osw-merge-process-logs' into 'master'

    Add logs for monitoring the merge process

    See merge request gitlab-org/gitlab-ce!15425


commit 011558ea4ac59bce74c18d2f7c55ac257de111c6
Author: Oswaldo Ferreira <oswaldo@gitlab.com>
Date:   Thu Nov 16 12:49:01 2017 -0200

    Add logs for monitoring the merge process

diff --git a/app/services/merge_requests/merge_service.rb b/app/services/merge_requests/merge_service.rb
--- a/app/services/merge_requests/merge_service.rb
+++ b/app/services/merge_requests/merge_service.rb
@@ -13,28 +15,29 @@
     def execute(merge_request)
       if project.merge_requests_ff_only_enabled && !self.is_a?(FfMergeService)
         FfMergeService.new(project, current_user, params).execute(merge_request)
         return
       end

       @merge_request = merge_request

       unless @merge_request.mergeable?
         return handle_merge_error(log_message: 'Merge request is not mergeable', save_message_on_model: true)
       end

       @source = find_merge_source

       unless @source
         return handle_merge_error(log_message: 'No source for merge', save_message_on_model: true)
       end

       merge_request.in_locked_state do
         if commit
           after_merge
           clean_merge_jid
           success
         end
       end
+      log_info("Merge process finished on JID #{merge_jid} with state #{state}")
     rescue MergeError => e
       handle_merge_error(log_message: e.message, save_message_on_model: true)
     end

......
```

如上，`git log -L 17,37:./services/merge_requests/merge_service.rb` 这个命令会显示 merge_service.rb 17到37行， 由近到远的修改历史。还会列出相邻两次 commit 的 diff 内容。其中 `a/app/services/merge_requests/merge_service.rb` 代表前一次提交，`b/app/services/merge_requests/merge_service.rb` 代表后一次提交。

