# git_app

嗯！本来是为Gogs写的，但是API啥的也不全，虽然自己打了些补丁，但远不够，后面发现竟然还有个gitea，所以干脆兼容
gitea下，顺便改名为git_app。

UI是仿照首个iOS版本github app做的。

----

#### flutter版本

* flutter 3.22.1
* dart 3.4.1

#### 说明

* 有好些功能都没做全，有些是因为缺少API。

* 嗯！里面的状态管理器有的用了有的没用，主要一开始没用那东西，后面慢慢替换吧。

* http缓存只弄了个最简单的。

* 啊。。。 

#### 截图

[查看截图](screenshots/README.md)

----

#### Gogs补丁

gogs API文档： https://github.com/gogs/docs-api

**注：因为gogs client API已经几年没有更新了，无法满足基本需求，所以我做了个补丁，尽可能少的修改gogs源码来达到自己的要求，相关[补丁](gogs_patch)，**`这只是一个简单的补丁，因为懒得弄（甚至还删除了不少补丁）`


 