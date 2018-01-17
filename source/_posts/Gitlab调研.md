---
layout: post
title: Gitlab调研
date: 2018-01-17 09:37:57
categories: 
- 技术
- 工具
tags: 
- giit
---

>最近公司想要替换原来的代码管理工具Starteam，一方面是这个 Starteam bug不少，用起来有不少问题，随着开发团队的扩大，工具跟不上现在的开发节奏了；另一方面近几年 Git 已经成为趋势，作为开发人员，总应该顺应潮流...所以调研了一下 Gitlab 这个开源的项目管理工具。我觉得有必要把一些理解记下来，以备不时之需。

## Gitlab Github Git 

- Github

提起开源，我们总能想到鼎鼎有名的 [Github](https://github.com/)。Github 是一个代码托管网站，提供源代码托管服务。简单点来说，就是你可以把自己的代码上传到 Github 进行保存，然后在别的地方下载下来进行修改。当然，Github 不仅仅可以托管代码，你可以把他类比成网盘，存放你想存的任何东西，Github 还提供了一些其他的服务，比如写文档、生成电子书、托管博客等等。

GitHub 同时提供付费账户和免费账户。这两种账户都可以创建公开的代码仓库，但是付费账户还可以创建私有的代码仓库。

<!-- more -->

- Gitlab

Gitlab 则是跟 Github 十分类似的网站。[Gitlub](https://gitlab.com/) 几乎提供了 Github 所拥有的一切功能。Gitlab 也提供付费账户和免费账户，与 Github 不同之处在于， Gitlab  的免费账户也可以创建私有代码仓库。

与 Github 不同之处在于，Gitlab 同时也是提供了自托管服务，即 Gitlab 也是一款应用程序。你可以下载 Gitlab 的源代码，在你本地的环境编译安装，生成与 gitlab.com 一样的网站。这意味着你可以在公司内部使用这款工具，而不用把代码上传到 Gitlab 或 Github 上面，保证了代码的私密性。

Gitlab 提供了社区版本和企业版本。 社区版本是免费的，企业版本是付费的。 与社区版本相比，企业版本提供了一些额外的功能。但是对于大多数小公司来说，免费版本已经足够使用了。

在[git服务器的配置](http://yukai.space/2017/09/06/git%E6%9C%8D%E5%8A%A1%E5%99%A8%E7%9A%84%E9%85%8D%E7%BD%AE/) 这篇总结中，已经提到了如何在本地搭建 Gitlab 的社区版本。

- Git

Gitlab 与 Github 都是围绕 Git 展开的。 Git 是一款分布式版本控制系统，用来进行版本控制。 Git 与 SVN 是一个层次的概念(VCS)，而 SVN 属于集中式的版本控制，Git 属于分布式的版本控制。

Gitlab 和 Github 以 Git 为核心，提供了远程代码托管的服务，同时展开了一些别的服务，比如项目管理、BUG 追踪等等。

## 几种工作流

随着 Git 的流行，出现了几种工作流。

>Git 作为一个源码管理系统，不可避免涉及到多人协作。
>协作必须有一个规范的工作流程，让大家有效地合作，使得项目井井有条地发展下去。"工作流程"在英语里，叫做"workflow"或者"flow"，原意是水流，比喻项目像水流那样，顺畅、自然地向前流动，不会发生冲击、对撞、甚至漩涡。

大致上有这样几种工作流：

- 集中式

- Git工作流

- Github工作流

- Gitlab工作流

目前公司采用的就是 集中式 的工作流。也是SVN的代码提交方式，即多人协作开发同一个主分支代码，所有的代码都提交到同一个分支。

这几种工作流的详细介绍可以参考下面的链接：

[Git 工作流程](http://www.ruanyifeng.com/blog/2015/12/git-workflow.html)

[git-workflows-and-tutorials](https://github.com/oldratlee/translations/blob/master/git-workflows-and-tutorials/README.md)

## Code review

多人协作，免不了要进行 Code review，即代码审查。Gitlab 提供了 Code review 的功能。

Gitlab 提供的 Code review 通过 [Merge requests](https://docs.gitlab.com/ee/user/project/merge_requests/) 来做。 你可能听过 Pull request ，这是 Github 提供的 Code review 手段，他俩的流程是一样的，只不过名字不同而已。

简单介绍一下 Gitlab Code review 流程：(假设我们现在针对master分支进行修改)

在此之前，先介绍一下[保护分支](https://docs.gitlab.com/ce/user/project/protected_branches.html)。

所谓的保护分支即给某个分支设立一些操作权限，包括 push、merge 的权限。你可以将权限分配给 [主程序员 或者 开发者](https://docs.gitlab.com/ee/user/permissions.html)。比如，我们现在设置 master 的保护权限为 **禁止任何人进行push**， **只允许主程序员进行merge**。这样设置意味着任何人都不能通过 push 的方式修改 Gitlab 远程仓库 master 分支的代码，同时所有人的修改都需要提交 merge request 给主程序员，由他将修改合并到主分支。

通过给 master 分支设置权限，可以起到杜绝恶意代码提交或滥提交的作用。

---

1. 新建远程分支

首先，你需要在 Gitlab 服务器上建立一个master分支的拷贝，有两种方式：fork到你自己的账户下(类似于Github协作的方式)，或者在 master 分支的基础上新建一个 分支。

我们采用第二种，新建一个bug修改的分支：bug_No1

2. 克隆远程分支到本地，并进行修改

我们将项目克隆(git clone)到自己的机器上。切换到 bug_No1 分支，开始修改bug。

过程大概是这样：git add -> git commit 、git add -> git commit、git add -> git commit...

3. 压缩提交，推送到远程分支

此时代码修改的差不多了，可以进行 Code review 了。但是在此之前，我们应该进行一个操作：压缩提交。这个不是必须的，但是是一个好的习惯：

在第2步中，我们进行了多次提交，这些提交反应了你修改 bug 过程的细节。这些细节是否有必要推送出去呢？有可能我们只是修改了一个分号也会进行一次提交，这些提交只会造成 review 人员的迷惑，所以在推送代码之前，有必要整理一下这些 commit，即使用[Git交互式变基](https://segmentfault.com/a/1190000007748862)的功能(git rebase -i)。

然后，将本地 bug_No1 分支push到 远程 bug_No1 分支。

4. 提交 merge request

登录 Gitlab，在项目中选择 `Merge Requests` 标签页，点击 New merge request:

{% asset_img merge_request.png merge_request %}

选择source branch为 bug_No1， target branch为 master，点击Compare branches and continue

可以添加一些描述，比如 `close #1`，表示如果这个merge request 被合并，就更新 issue #1 的状态为关闭。或者还可以在描述中 @别的开发人员，进行多人review。

选择reviewer，提交 merge request。

5. reviewer 查看 merge request

reviewer 和你@过的开发人员 会收到merge request的提醒，然后到 Gitlab 查看你的 merge request：

{% asset_img reviewer.png review%}

他可以选择 点击 Merge，表示合并此次提交到 master，或者在评论里评论你的代码，可以具体到某行，指出一些错误和建议。

6. 再次修改代码

你的 merge request 被别人评论之后，你就会收到邮件。根据评论，你可以在本地再次修改你 bug_No1上面的代码，git add -> git commit ...

然后再次push。注意，这次的push不要再进行压缩提交了，因为此时你的代码已经被分享到远端，你在本地修改了提交历史，是无法再次提交到远程仓库的。如果需要push到远程仓库，则需要强制推送，这样的话远程仓库的提交历史也改变了。这样会造成 reviewer 的疑惑，因为原先的一些提交已经不再了，会使review历史变得不清晰。

7. 再次 review

当你第二次push了你的代码之后，不再需要点击merge request了。Gitlab 会自动将此次的推送绑定到之前的 merge request 上。此时 reviewer 会收到邮件提醒，再次查看你的代码，并决定是否 merge。

6，7步可以多次进行。

8. merge 

reviewer 通过了此次 merge request，点击 merge，将 bug_No1 的代码合并到 master。如果有冲突(别人已经合并过了)，则需要解决冲突。

---

以上就是一次代码 review 的流程，其中还有一些问题：

1. 因为只有主程序员拥有 merge 的权限，那么主程序员需要解决每一次的 merge 冲突，有点蛋疼

   你可以为开发者也分配 merge 权限，但是这样显得不是那么严谨。自己给自己 review？

2. 每次 review->修改->review 造成了很多commit，这些commit也会随着 merge 被合并到master中

   我们在第一次推送 bug_No1 到远程仓库的时候，压缩了提交。但是一旦你的代码已经分享到远程仓库，那么再进行变基是不明智的。
   
   这样的话，每次review之后再 git add -> git commit ，我们对这些 commit 就无能为力了。一旦代码被 merge 到 master 非分支，你再查看 master 的 commits 时就会发现很多这样 review 代码之后的提交，是不是很蛋疼(这有点强迫症的意味)？

对于这两点问题，我想到了一个解决方案：[Fast-forward merge requests ](https://docs.gitlab.com/ee/user/project/merge_requests/fast_forward_merge.html)

简单来说，就是 master 分支只接受 Fast-forward 的方式合并的代码。什么是快速推进(Fast-forward)？参考[图解4种git合并分支方法](http://yanhaijing.com/git/2017/07/14/four-method-for-git-merge/)

当你的代码 bug_No1 不能以快速推进的方式合并到 master 分支的时候，意味着可能出现了冲突：

{% asset_img ff_merge_rebase_locally.png 冲突%}

注意上面图片中的提醒：To merge this request, first rebase locally.

需要你在本地执行[变基](https://git-scm.com/book/zh/v2/Git-%E5%88%86%E6%94%AF-%E5%8F%98%E5%9F%BA)。什么是变基(rebase)？还是参考[图解4种git合并分支方法](http://yanhaijing.com/git/2017/07/14/four-method-for-git-merge/)

此时，提交 merge request 的开发者就有责任解决这个冲突：在本地执行下面的指令

```bash
git checkout bug_No1
// 之前提到的交互式变基也是变基的一种，我们现在在变基master的同时执行压缩提交，就能解决上面的第二个问题
git rebase -i master
git push --force
```

因为执行了变基，本地分支 bug_No1 的提交历史已经发生了改变，想要推送到远程仓库 bug_No1 分支时，就需要执行强制推送。

{% asset_img ff_merge_rebase.png 冲突解决%}

此时，主程序员只需要点一下 Rebase 按钮即可，不再会有合并冲突了。

这种解决方案其实也不是完美的，原因之前也提到了，使用了变基之后，提交历史改变了，而且需要强制推送，`--force` 总是让人嗅到危险的味道。此外，对于使用变基还是合并，一直有一些争议，使用变基的缺点大致有两个：1.回滚的时候可能比较麻烦 2.无法反应真实的合并历史

---

对于上面提到的第二个问题，`Gitlab 企业版`提供了解决方案：[Squash and merge](https://www.google.com/url?sa=t&rct=j&q=&esrc=s&source=web&cd=1&ved=0ahUKEwjb_bqNz9zYAhVIxlQKHSXYCQUQFggrMAA&url=https%3A%2F%2Fdocs.gitlab.com%2Fee%2Fuser%2Fproject%2Fmerge_requests%2Fsquash_and_merge.html&usg=AOvVaw3-4GTewcTnmjCxe5eM3MF1)

实际上就是在 bug_No1 Merge 到 master 分支时，使用了`git merge –squash bug_No1`命令。什么是squash？还是参考[图解4种git合并分支方法]

这个功能其实是比较常用的一个功能点，[Gitlab issue](https://gitlab.com/gitlab-org/gitlab-ce/issues/34591
) 上有针对这个的讨论。很可惜社区版本并不支持这个功能。

## Gitlab 与 Redmine

Gitlab 本身的 issue 功能已经很强大了，但是还有一些瑕疵，比如 issue 状态不够多(只有新建和关闭)并且无法自定义(虽然可以使用Label，但是Label之间并不具有状态那样的互斥关系)。另外，公司原本使用 TD 作为bug追踪工具，TD 的bug序列号是全局唯一的，而 Gitlab issue 的序列号是与项目绑定的，并不是全局唯一，造成了从 T D迁移到 Gitlab issue 变得十分困难。

综上，决定使用 [Redmine](https://www.redmine.org/) 作为 bug 追踪工具。

#### 安装

安装 Redmine 可以使用两种方式：原生安装 或 使用 bitnami 一键安装。

原生安装比较繁琐，这里直接选择 bitnami 的方式安装。

下载 bitnami redmine 安装包 [Redmine Installers](https://bitnami.com/stack/redmine/installer#linux)，双击，根据GUI提示安装即可。

Redmine 与 Gitlab 集成分为两部分，如下：

#### 配置 [Gitlab Redmine Service](https://docs.gitlab.com/ce/user/project/integrations/redmine.html)

Gitlab 项目与 Redmine 项目是一一对应的。

进入 Gitlab 的项目服务设置页面：settings->integrations，找到 redmine 的设置：

```
Active：True
Trigger：Push
Project url：Redmine 中相关的项目地址，例如 http://192.168.1.100:8888/redmine/projects/test
Issues url：一般是 Project url + issues，例如 http://192.168.1.100:8888/redmine/issues/:id
New issue url：通常是 Issues url + new，例如 http://192.168.1.100:8888/redmine/projects/test/issues/new
```

保存设置，这样的话当你点击 merge request 等描述或者评论中 #number 时，就会自动跳转到redmine相关issue页面。

#### 配置 Gitlab Redmine Webhook

这个配置是要做到 Redmine 中的本地版本仓库自动同步 Gitlab 远程仓库，同时能够识别commit中的关键字，比如`fixed #1`，从而自动管理issue状态。

- Redmine 配置 Git

  管理员身份登录 Redmine，进入 管理->配置->版本库
  
```
  Enabled SCM 中，我们要使用的 Gitlab，因此需要启用 Git 。如果 Git 不可选，则需要确认是否安装了 git，并在   Redmine 的 configuuration.yml 中进行设置
  Fetch commits automatically：True，这个选项只是在用户打开仓库页面时候会获取仓库内容
  Enable WS for repository management：True
  Repository management WS API key：这里需要生成一个 API Key，用于后面的 WebHook 触发
```
  
  页面下方还可以配置一些关键字和对应的状态。

- 配置 Git 本地仓库

  在 Redmine 所在的服务器上，Redmine可以访问到的路径中(一定要确定权限)，使用 git 克隆对应Gitlab项目的远程仓库：  `git clone --mirror git@192.168.1.100:java/test.git`
  
  进入项目的仓库设置页面：配置->版本库->新建版本库；
  
  库路径指向刚才克隆的本地仓库的位置，使用绝对路径；
  
  在 项目->版本库 中，现在就可以看到版本库和文件了。

- 安装 redmine_gitlab_hook 插件

  Github地址：https://github.com/phlegx/redmine_gitlab_hook
  
  使用 git clone 下载该插件到Redmine插件目录，比如 redmine-3.4.4-1/apps/redmine/htdocs/plugins；
  
  重启 Redmine 完成安装：在 redmine 安装目录下运行 `./ctlscript.sh restart apache`
  
  在 Redmine 的 管理->插件 中可以看到这一新安装的插件，此时配置 redmine_gitlab_hook，选中 All branches。

- 配置 Gitlab Webhook

Webhook 是 Gitlab 的事件触发系统，这里我们借助这一功能，同 Redmine 的 Gitlab 插件协作，触发 Redmine 的自动更新。

浏览项目的 Webhook 页面：settings->integrations，新建一个Webhook，URL 栏目填写 http://redmine-url/gitlab_hook?project_id=[project-id]&key=[repository-token]，key 部分就是前文中提到的`Repository management WS API key`。比如 http://192.168.1.100:8888/redmine/gitlab_hook?project_id=test&key=ntMQb9TedYR49MXXfN93

- 测试

提交一个新的提交到 Gitlab 项目分支，在提交信息中写入 `fixed #1`，观察Redmine 中的这一 Issue 是否发生更新(需要在Redmine中预先建好这个issue)。

同时也可以观察 Redmine 事件日志：进入 Redmine 安装目录，执行 `tail -f apps/redmine/htdocs/log/production.log`

## 结尾

以上就是 Gitlab 对于 Code Review 和 issue 追踪这两个重要功能的调研。还有一个在开发过程中用到的比较重要的功能没有提到：CI(持续集成)，目前的想法是 Gitlab 与 Jenkins 进行集成，等实际操作之后再来更新吧。


