---
layout: post
title: 可能会用到的Git技巧(2)
date: 2018-03-29 14:56:57
categories: 
- 技术
- 工具
tags: 
- git
---

## git worktree

我们知道如果工作目录修改到一半的话，是不能随便切换 branch 的。解决方法可以通过 `git stash` 先暂存起来，随后执行 `git stash apply` 恢复。

但是，如果我们想同时修改两个分支呢？或者同时测试两个分支。能想到的方法就是单独再 clone 一份代码到其他目录。但是这种方法不仅麻烦，而且形成了两个独立的 git 目录，双方的同步也比较费劲。

git 为我们提供了一个命令来解决这个问题，那就是 `git worktree add -b <新分支名> <新路径> <从此分支创建>`。

比如，我们正在某个 feature 分支开发，现在希望从 master 分出一个分支来解决某个紧急的 BUG：

```
git worktree add -b hotfix ../hotfix master
```

<!-- more -->

执行上面的命令，就会在上一层新建立一个 hotfix 目录，并新建一个分支 hotfix。

这两个工作目录在工作上看起来就像两个独立的仓库一样。因为所有工作目录共享一个仓库，所以一个更新意味着整个更新（A 目录里对分支做的改动，B 目录里切到此分支也是改动后的）。

使用 `git worktree` 创建的多个目录，不能有任何两个目录在同一个分支下，因为对于同一个分支的修改都会反映到各个工作目录当中，同时修改同一个分支就会造成混乱。

如果要删除其中一个工作目录，直接删除文件夹即可。随后使用命令清除已经被删的工作目录：

```
git worktree prune
```

## 变基

在 Git 中整合来自不同分支的修改主要有两种方法：merge 以及 rebase。

假设我们有两个分支 master 和 experiment，并在这两个分支上分别进行了提交：

{% asset_img basic-rebase-1.png rebase %}

现在我们希望把 experiment 上面的修改合并到 master 上去：

- 执行 merge 命令。 它会把两个分支的最新快照（C3 和 C4）以及二者最近的共同祖先（C2）进行三方合并，合并的结果是生成一个新的快照（合并提交）。

```
git checkout master 
git merge experiment
```

{% asset_img basic-rebase-2.png rebase %}

- 还有一种合并方法：[变基](https://git-scm.com/book/zh/v2/Git-%E5%88%86%E6%94%AF-%E5%8F%98%E5%9F%BA)，将提交到 experiment 分支上的所有修改都移至 master 分支上：提取在 C4 中引入的修改，然后在 C3 的基础上应用一次：

```
git checkout experiment
git rebase master
```

{% asset_img basic-rebase-3.png rebase %}

它的原理是首先找到这两个分支（即当前分支 experiment、变基操作的目标基底分支 master）的最近共同祖先 C2，然后对比当前分支相对于该祖先的【历次提交】，提取相应的修改并存为临时文件，然后将当前分支指向目标基底 C3, 最后以此将之前另存为临时文件的修改【依序应用】。

所以，变基的过程中，历次提交对于同一文件的修改可能产生冲突，如果遇到冲突，则解决冲突，然后执行：

```
git add .
git rebase --continue
```

如果想要跳过这个 patch，则执行 `git rebase --skip`。意味着这次提交将被抛弃。

直到所有 patch 应用完毕。

现在回到 master 分支，进行一次 fast-forward 合并。

```
git checkout master
git merge experiment
```

{% asset_img basic-rebase-4.png rebase %}

此时，C4' 指向的快照就和上面使用 merge 命令的例子中 C5 指向的快照一模一样了。变基的目的是为了确保在向远程分支推送时能保持提交历史的整洁,提交历史是一条直线没有分叉。

使用变基需要遵循一个原则：不要对在你的仓库外有副本的分支执行变基。

## 压缩提交

git 为我们提供了修改历史 commit 的功能，那就是 [交互式变基](https://git-scm.com/book/zh/v1/Git-%E5%B7%A5%E5%85%B7-%E9%87%8D%E5%86%99%E5%8E%86%E5%8F%B2)。

通常在本地进行修改的时候，可能提交的粒度很小。一旦修改完毕，需要把修改推送到远程分支上去，这个时候我们希望能把本地的提交压缩成为一个或几个提交，使得提交历史变得清晰，不那么冗余。这时就需要用到交互式变基中的 squash 功能。

假设我们本地的最近三次提交历史如下：

```
git log --pretty=format:"%h %s" HEAD~3..HEAD

a5f4a0d added cat-file
310154e updated README formatting and added blame
f7f3f6d changed my name a bit
```

我们希望把这三次提交压缩成一次提交：

```
git rebase -i HEAD~3
```

注意，`-i` 后面的 commitID 实际上是指向你要修改的提交的父提交，即我们要压缩的是 HEAD~2..HEAD 这三次提交。

运行这个命令会为我们的文本编辑器提供一个提交列表，看起来像下面这样:

```shell
pick f7f3f6d changed my name a bit
pick 310154e updated README formatting and added blame
pick a5f4a0d added cat-file

# Rebase 710f0f8..a5f4a0d onto 710f0f8
#
# Commands:
#  p, pick = use commit
#  e, edit = use commit, but stop for amending
#  s, squash = use commit, but meld into previous commit
#
# If you remove a line here THAT COMMIT WILL BE LOST.
# However, if you remove everything, the rebase will be aborted.
#
```

默认情况下，会省略 merge commit，详见[What exactly does git's “rebase --preserve-merges” do (and why?)
](https://stackoverflow.com/questions/15915430/what-exactly-does-gits-rebase-preserve-merges-do-and-why)

需要注意的是这些提交的顺序与我们通过log命令看到的是相反的，log命令显示的是由新到旧的提交，而上面显示的是由旧到新的几次提交。

可以看到其中分为两个部分，上方未注释的部分是填写要执行的指令，而下方注释的部分则是指令的提示说明。指令部分中由前方的命令名称、commit hash 和 commit message 组成。

现在我们只要知道 pick 和 squash 这两个命令即可。

- pick 的意思是要会执行这个 commit

- squash 的意思是这个 commit 会被合并到前一个commit

我们将上面打开的脚本修改成下面这样：

```
pick f7f3f6d changed my name a bit
squash 310154e updated README formatting and added blame
squash a5f4a0d added cat-file
```

输入:wq以保存并退出，同【变基】章节中介绍到的，其原理与【变基】类似，也是将【历次提交】的 patch 【依序应用】，所以可能会产生冲突。

冲突解决完毕后，这时我们会看到 commit message 的编辑界面：

```
# This is a combination of 3 commits.
# The first commit's message is:
changed my name a bit

# This is the 2nd commit message:

updated README formatting and added blame

# This is the 3rd commit message:

added cat-file
```

其中，非注释部分就是两次的 commit message， 我们要做的就是将这两个修改成新的 commit message。

输入wq保存并退出，此时就拥有了一个包含前三次提交的全部变更的单一提交。

## git merge --suqash

上面的交互式变基，提供了压缩提交的功能。还有一种场景下，我们也需要压缩合并，比如合并 B 分支上的修改到 A 分支，我们可以选择在合并时将 B 分支的多个提交压缩成一个提交，合并到 A 分支上形成【一个】提交节点。

```
git checkout A
git merge --squash B
```

{% asset_img squash.gif squash %}

此时 A 分支有一个线性的提交历史。

对比一下单纯的 merge：

```
git checkout A
git merge B
```

{% asset_img merge.gif merge %}

如果不想生成提交节点，而是想把修改合并过来不进行提交，方便再次修改后统一提交，可以指定`--no-commit`选项：

```
git merge --no-commit --squash B
```


## git apply patch

如果一个软件有了新版本，我们可以完整地下载新版本的代码进行编译安装，但是每次全新下载是有相当大的代价的。然而，每次更新变动的代码可能只有一点点。
因此，我们只要能够有两个版本代码的diff的数据，应该就可以以极低的代价更新程序了。这就是patch，它可以根据一个diff文件进行版本更新。

- 用 git diff 制作一个 patch

假设现在我们有两条分支，master 和 test，test 分支基于 master 分支而来，并且进行了几次新的提交。

```
git checkout test
git diff master > patch
```

我们现在得到了一个 patch 文件，内容是 test 分支与 master 分支的 diff 结果。

- 应用 patch

```
git checkout master
git apply patch
git commit -a -m "Patch Apply"
```

我们切换到 master 分支，将 patch 文件中的更新内容应用到 master 分支上，然后进行提交。

此时 master 分支的内容已经与 test 分支的内容一模一样了。

gitlab 提供了一个类似于 `git merge --suqash` 命令的功能：[Squash and merge](https://docs.gitlab.com/ee/user/project/merge_requests/squash_and_merge.html)。gitlab 内部的实现并不是使用了`git merge --suqash`命令，而是利用了 Git 提供的 patch 功能，原理如下：

首先找到提交的 merge request 中，source branch 和 target branch 的共同祖先节点，然后将 source branch 与 这个节点做对比得到 patch。

随后将这个 patch 应用到 target branch 的副本(git worktree)上面(在merge之前，已经保证解决了冲突)，然后将这个副本与 target branch 进行 merge。

这样的话，source branch 上面的多个提交就都看不到了，只形成了一个提交，达到了类似于 `git merge --suqash` 的效果。

git 还提供了 `git format-patch` 生成一个 git 专用的 patch，不再赘述。详细内容可以参考 [Git的Patch功能](https://www.cnblogs.com/y041039/articles/2411600.html)。
