# gogs_app

一个Gogs的客户端，UI是仿照首个iOS版本github app做的。

----

#### flutter版本

* flutter 3.22.1
* dart 3.4.1

#### 说明

* 有好些功能都没做全，有些是因为缺少API，但懒得打补丁，有的是懒得去弄。

* 嗯！里面的状态管理器有的用了有的没用，主要一开始没用那东西，后面慢慢替换吧。

* http缓存问题只弄了个最简单的。

* 啊。。。 

#### 截图

[查看截图](screenshots/README.md)

----

gogs API文档： https://github.com/gogs/docs-api

**注：因为gogs client API已经几年没有更新了，无法满足基本需求，所以我做了个补丁，尽可能少的修改gogs源码来达到自己的要求，相关[补丁](gogs_patch)，**`这只是一个简单的补丁，因为懒得弄`


 