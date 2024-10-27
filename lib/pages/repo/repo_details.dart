import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:remixicon/remixicon.dart';

import 'package:git_app/app_globals.dart';
import 'package:git_app/gogs_client/gogs_client.dart';
import 'package:git_app/models/repo_model.dart';
import 'package:git_app/pages/repo/commits.dart';
import 'package:git_app/pages/content/contents.dart';
import 'package:git_app/pages/issue/create_issue.dart';
import 'package:git_app/pages/issue/issues.dart';
import 'package:git_app/routes.dart';
import 'package:git_app/utils/build_context_helper.dart';
import 'package:git_app/utils/message_box.dart';
import 'package:git_app/utils/page_data.dart';
import 'package:git_app/utils/utils.dart';

import 'package:git_app/widgets/cached_image.dart';
import 'package:git_app/widgets/branches_list.dart';
import 'package:git_app/widgets/divider_plus.dart';
import 'package:git_app/widgets/markdown.dart';

import 'package:git_app/widgets/adaptive_widgets.dart';
import 'package:git_app/widgets/background_icon.dart';
import 'package:git_app/widgets/platform_page_scaffold.dart';
import 'package:git_app/widgets/content_title.dart';
import 'package:git_app/widgets/list_section.dart';

/// 将这些拆出来是因为防止写多了自己眼晕
///
Future<void> _readReadMeFile(RepositoryModel model, [bool? force]) async {
  final readMe = await AppGlobal.cli.repos.content
      .readMeFile(model.repo, model.selectedBranch, force: force);
  if (readMe.succeed && readMe.data != null) {
    model.readMeContent =
        tryDecodeText(Uint8List.fromList(readMe.data!), readMe.contentType);
  }
}

/// 仓库issue按钮
class _RepoCreateIssueButton extends StatelessWidget {
  const _RepoCreateIssueButton();

  @override
  Widget build(BuildContext context) {
    return AdaptiveButton.icon(
      onPressed: () =>
          showCreateIssuePage(context, context.read<RepositoryModel>().repo),
      child: const Icon(Icons.add_circle_outline),
    );
  }
}

/// 仓库操作列表
class _RepoOperateList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Selector<RepositoryModel, Repository>(
        selector: (_, model) => model.repo,
        // shouldRebuild: (previous, next) {
        //   return false;
        // },
        builder: (_, repo, __) {
          final iconColor = context.colorScheme.outline;
          return Column(
            children: [
              ListTileNav(
                leading: const BackgroundIcon(
                  icon: Icons.info_outline,
                  color: Colors.green,
                ),
                title: '问题',
                additionalInfo: Text('${repo.openIssuesCount}',
                    style: TextStyle(color: iconColor)),
                onTap: () {
                  routes.pushPage(
                    context: context,
                    IssuesPage(
                        repo: repo,
                        title: '问题',
                        category: IssuesCategory.repoIssues),
                    data: PageData(previousPageTitle: repo.name),
                  );

                  // routes.pushIssuesPage(context, _repo,
                  //     title: '问题',
                  //     category: IssuesCategory.repoIssues,
                  //     data: PageData(previousPageTitle: _repo.name));
                },
              ),
              const ListTileDivider(),
              ListTileNav(
                leading: const BackgroundIcon(
                  icon: Remix.git_pull_request_line,
                  color: Colors.blue,
                ),
                title: '合并请求',
                additionalInfo: Text('${repo.openPullsCount}',
                    style: TextStyle(color: iconColor)),
                onTap: () {
                  //todo: 没有API可用
                  showToast('没有API可用');
                  // AppGlobal.pushPage(
                  //     IssuesPage(
                  //       category: IssuesCategory.repoPullRequests,
                  //       title: '合并请求',
                  //       repo: _repo,
                  //     ),
                  //     context: context,
                  //     previousPageTitle: _repo.name);
                },
              ),
              const ListTileDivider(),
              ListTileNav(
                leading: const BackgroundIcon(
                  icon: Icons.remove_red_eye_outlined,
                  color: Colors.purple,
                ),
                title: '关注',
                additionalInfo: Text('${repo.watchersCount}',
                    style: TextStyle(color: iconColor)),
                onTap: () {
                  //todo: 没有API可用
                  showToast('没有API可用');
                  // 这里跳转到对应的去哈
                },
              ),

              // _buildLicense(model, iconColor),
            ],
          );
        });
  }
}

/// 仓库信息部分，
class _RepoInfo extends StatelessWidget {
  const _RepoInfo();

  Widget _buildButton(
      String text, VoidCallback? onPressed, IconData icon, Color? iconColor) {
    return AdaptiveButton.outlined(
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 5),
          Text(text)
        ],
      ),
    );
  }

  Widget _buildPrivateWidget() => Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: Text.rich(TextSpan(children: [
          WidgetSpan(child: Builder(builder: (context) {
            return Icon(Icons.lock_outline_rounded,
                size: 18, color: context.colorScheme.outline);
          })),
          const WidgetSpan(child: SizedBox(width: 5)),
          const TextSpan(text: '私有'),
        ])),
      );

  /// fork
  Widget _buildForkWidget(Repository repo) => Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: Builder(builder: (context) {
          return Text.rich(TextSpan(children: [
            WidgetSpan(
                child: Icon(Remix.git_fork_line,
                    size: 20, color: context.colorScheme.outline)),
            const WidgetSpan(child: SizedBox(width: 5)),
            const TextSpan(text: '派生自'),
            const WidgetSpan(child: SizedBox(width: 5)),
            TextSpan(
              text: repo.parent?.name,
              style: const TextStyle(color: Colors.blue),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  if (repo.parent != null) {
                    routes.pushRepositoryDetailsPage(context, repo.parent!,
                        data: PageData(previousPageTitle: repo.name));
                  }
                },
            ),
            //  const WidgetSpan(child: SizedBox(width: 5)),
          ]));
        }),
      );

  @override
  Widget build(BuildContext context) {
    return Selector<RepositoryModel, Repository>(
      selector: (_, model) => model.repo,
      builder: (_, repo, __) {
        final iconColor = context.colorScheme.outline;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 用户头像
            Row(
              children: [
                UserHeadImage(
                  user: repo.owner,
                  size: 40,
                  padding: const EdgeInsets.all(3),
                  radius: 3,
                  previousPageTitle: repo.name,
                  // onTap: _doUserHead,
                ),
                const SizedBox(width: 10),
                Text(repo.owner.username),
              ],
            ),
            const SizedBox(height: 15),

            /// 仓库描述
            if (repo.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: Text(repo.description),
              ),

            /// 是否私有
            if (repo.private) _buildPrivateWidget(),

            /// 网址
            if (repo.website.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: Text.rich(
                    TextSpan(
                      text: repo.website,
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          //
                        },
                    ),
                    style: const TextStyle(color: Colors.blue)),
              ),

            /// star数量和fork数量
            Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: Text.rich(TextSpan(children: [
                TextSpan(
                  children: [
                    WidgetSpan(
                        child:
                            Icon(Remix.star_fill, size: 20, color: iconColor)),
                    const WidgetSpan(child: SizedBox(width: 5)),
                    TextSpan(
                      text: '${repo.starsCount} 点赞',
                      recognizer: repo.starsCount == 0
                          ? null
                          : (TapGestureRecognizer()
                            ..onTap = () {
                              //todo: 没有API可用
                              showToast('没有API可用');
                            }),
                    ),
                  ],
                ),
                const WidgetSpan(child: SizedBox(width: 10)),
                TextSpan(
                  children: [
                    WidgetSpan(
                        child: Icon(Remix.git_fork_line,
                            size: 20, color: iconColor)),
                    const WidgetSpan(child: SizedBox(width: 5)),
                    TextSpan(
                      text: '${repo.forksCount} 派生',
                      recognizer: repo.forksCount == 0
                          ? null
                          : (TapGestureRecognizer()
                            ..onTap = () {
                              showToast('未实现');
                              //if (kDebugMode) {
                              //  AppGlobal.cli.repos.forks(_repo);
                              //}
                            }),
                    ),
                  ],
                ),
              ])),
            ),

            /// 是否fork
            if (repo.fork) _buildForkWidget(repo),

            /// star和watch按钮
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    // width: 160,
                    child: _buildButton(
                      // model.repo.isStaring ? '取消点赞' : '点赞',
                      '点赞',
                      () {
                        //todo: 没有API可用
                        showToast('没有API可用');
                      },
                      //model.repo.isStaring ? Icons.star : Icons.star_border,
                      Icons.star,
                      //model.repo.isStaring ? Colors.yellow : null,
                      Colors.yellow,
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: SizedBox(
                    height: 40,
                    // width: 160,
                    child: _buildButton(
                      // model.repo.isWatching ? '取消关注' : '注关',
                      '注关',
                      () {
                        //todo: 没有API可用
                        showToast('没有API可用');
                      },
                      Icons.remove_red_eye_outlined,
                      //model.repo.isWatching ? Colors.green : null,
                      Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// 分支操作部分
class _RepoBranchOperate extends StatelessWidget {
  const _RepoBranchOperate();

  Future<void> _onSwitchBranches(BuildContext context) async {
    final model = context.read<RepositoryModel>();
    final res = await showCupertinoModalBottomSheet<String>(
        context: context,
        //todo: 这里先设置为false，因为发现拖动下拉刷新，这个也会被检测，其实需要屏蔽外部的，暂没去分析
        enableDrag: false,
        expand: true,
        useRootNavigator: true,
        builder: (_) => BranchesList(
            repo: model.repo, selectedBranch: model.selectedBranch));
    if (res != null) {
      model.selectedBranch = res;
      // 分支切换了，重新拉取README。
      _readReadMeFile(model);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Selector<RepositoryModel, Repository>(
      selector: (_, model) => model.repo,
      builder: (_, repo, __) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: [
                  Icon(Remix.git_branch_line,
                      size: 20, color: context.colorScheme.outline),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(context.watch<RepositoryModel>().selectedBranch,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 20),
                  AdaptiveButton(
                      onPressed: () => _onSwitchBranches(context),
                      child: const Text('切换分支')),
                ],
              ),
            ),
            BottomDivider(
              child: ListTileNav(
                title: '浏览源代码',
                onTap: () => routes.pushPage(
                    ContentsPage(
                      // todo: 这里先用默认的吧，后面再说
                      ref: context.read<RepositoryModel>().selectedBranch,
                      repo: repo,
                      title: repo.name,
                      path: "",
                      prevPath: "",
                    ),
                    context: context,
                    data: PageData(previousPageTitle: repo.name),
                    routeSettings: const RouteSettings(name: routeContentName)),
              ),
            ),
            ListTileNav(
              title: '提交记录',
              // additionalInfo: Text('${model.repo.commitsCount}',
              //     style: TextStyle(color: iconColor)),
              onTap: () => routes.pushPage(
                CommitsPage(
                  repo: repo,
                  branchName: context.read<RepositoryModel>().selectedBranch,
                ),
                context: context,
                data: PageData(previousPageTitle: repo.name),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// README
class _RepoReadMe extends StatelessWidget {
  const _RepoReadMe();

  void _onTap(String value) {
    //todo: 待完善内部跳转
    print(value);
  }

  @override
  Widget build(BuildContext context) {
    return Selector<RepositoryModel, String?>(
      selector: (_, model) => model.readMeContent,
      builder: (_, value, __) {
        if (value == null) return const SizedBox();
        return TopDivider(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.chrome_reader_mode,
                        size: 20, color: context.colorScheme.outline),
                    const SizedBox(width: 10),
                    const Text('README.md') //model.repo.readMe!.fileName),
                  ],
                ),
                //const Divider(height: 1),
                MarkdownBlockPlus(data: value, onTap: _onTap),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 仓库详情页
class RepositoryDetailsPage extends StatelessWidget {
  const RepositoryDetailsPage({super.key});

  Future<void> _init(BuildContext context, bool? force) async {
    final model = context.read<RepositoryModel>();
    model.selectedBranch = null;
    model.readMeContent = null;
    final res = await AppGlobal.cli.repos.repo(model.repo, force: force);
    if (res.succeed && res.data != null) {
      model.repo = res.data!;
      _readReadMeFile(model, force);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PlatformPageScaffold(
      reqRefreshCallback: _init,
      // materialAppBar: () => AppBar(
      //   title: Text(context.watch<RepositoryModel>().repo.name),
      //   actions: const [_RepoCreateIssueButton()],
      // ),
      // cupertinoNavigationBar: () => CupertinoNavigationBar(
      //   middle: Text(context.watch<RepositoryModel>().repo.name),
      //   trailing: const _RepoCreateIssueButton(),
      //   previousPageTitle: context.previousPageTitle,
      // ),
      appBar: PlatformPageAppBar(
        title: Text(context.watch<RepositoryModel>().repo.name),
        actions: const [_RepoCreateIssueButton()],
        previousPageTitle: context.previousPageTitle,
      ),
      children: [
        const SizedBox(height: 15),
        // 信息部分
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 15),
          child: _RepoInfo(),
        ),
        const SizedBox(height: 15),
        // 列表操作的
        _RepoOperateList(),
        // 下面分支和啥的
        const SizedBox(height: 15),
        const _RepoBranchOperate(),
        const SizedBox(height: 15),
        // readme
        const _RepoReadMe(),
      ],
    );
  }
}
