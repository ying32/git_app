import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:git_app/app_globals.dart';
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
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:remixicon/remixicon.dart';

import 'package:git_app/widgets/adaptive_widgets.dart';
import 'package:git_app/widgets/background_icon.dart';
import 'package:git_app/widgets/platform_page_scaffold.dart';
import 'package:git_app/widgets/content_title.dart';
import 'package:git_app/widgets/list_section.dart';

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

  Future<void> _readReadMeFile(RepositoryModel model, bool? force) async {
    final readMe = await AppGlobal.cli.repos.content
        .readMeFile(model.repo, model.selectedBranch, force: force);
    if (readMe.succeed && readMe.data != null) {
      model.readMeContent = tryDecodeText(Uint8List.fromList(readMe.data!));
    }
  }

  Future<void> _onSwitchBranches(
      BuildContext context, RepositoryModel model) async {
    final res = await showCupertinoModalBottomSheet<String>(
        context: context,
        //todo: 这里先设置为false，因为发现拖动下拉刷新，这个也会被检测，其实需要屏蔽外部的，暂没去分析
        enableDrag: false,
        builder: (_) => BranchesList(
            repo: model.repo, selectedBranch: model.selectedBranch));
    if (res != null) {
      model.selectedBranch = res;
    }
  }

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

  /// fork
  Widget _buildForkWidget(RepositoryModel model) => Padding(
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
              text: model.repo.parentName,
              style: const TextStyle(color: Colors.blue),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  final repo = model.repo.parentRepo;
                  if (repo != null) {
                    routes.pushRepositoryDetailsPage(context, repo,
                        data: PageData(previousPageTitle: model.repo.name));
                  }
                },
            ),
            //  const WidgetSpan(child: SizedBox(width: 5)),
          ]));
        }),
      );

  /// private
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

  Widget _buildInfo(RepositoryModel model, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 用户头像
          Row(
            children: [
              UserHeadImage(
                user: model.repo.owner,
                size: 40,
                padding: const EdgeInsets.all(3),
                radius: 3,
                previousPageTitle: model.repo.name,
                // onTap: _doUserHead,
              ),
              const SizedBox(width: 10),
              Text(model.repo.owner.username),
            ],
          ),
          const SizedBox(height: 15),

          /// 仓库描述
          if (model.repo.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: Text(model.repo.description),
            ),

          /// 是否私有
          if (model.repo.private) _buildPrivateWidget(),

          /// 网址
          if (model.repo.website.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: Text.rich(
                  TextSpan(
                    text: model.repo.website,
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
                      child: Icon(Remix.star_fill, size: 20, color: iconColor)),
                  const WidgetSpan(child: SizedBox(width: 5)),
                  TextSpan(
                    text: '${model.repo.starsCount} 点赞',
                    recognizer: model.repo.starsCount == 0
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
                    text: '${model.repo.forksCount} 派生',
                    recognizer: model.repo.forksCount == 0
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
          if (model.repo.fork) _buildForkWidget(model),

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
      ),
    );
  }

  Widget _buildLicense(RepositoryModel model, Color iconColor) {
    return TopDivider(
      child: ListTileNav(
          leading: const BackgroundIcon(
            icon: Icons.balance_outlined,
            color: Colors.pink,
          ),
          title: '许可证',
          onTap: () {
            showToast('没有实现');
          }
          // onTap: model.repo.license!.isEmpty
          //     ? null
          //     : () {
          //         // 这里跳转到对应的去哈
          //       },
          //trailing: model.repo.license!.isEmpty
          //    ? const SizedBox()
          //    : Icon(Icons.open_in_new_sharp, size: 16, color: iconColor),
          // additionalInfo: model.repo.license!.isNotEmpty
          //     ? Row(
          //         mainAxisSize: MainAxisSize.min,
          //         children: [
          //           Text(model.repo.license!, style: TextStyle(color: iconColor)),
          //           const SizedBox(width: 5),
          //         ],
          //       )
          //     : Text('无', style: TextStyle(color: iconColor)),
          ),
    );
  }

  void _doTapCreateIssue(BuildContext context, RepositoryModel model) =>
      showCreateIssuePage(context, model.repo);

  Widget _buildREADME(RepositoryModel model, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.chrome_reader_mode, size: 20, color: iconColor),
              const SizedBox(width: 10),
              const Text('README.md') //model.repo.readMe!.fileName),
            ],
          ),
          //const Divider(height: 1),
          MarkdownBlockPlus(data: model.readMeContent!),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = context.colorScheme.outline;
    final model = context.watch<RepositoryModel>();

    final createIssueButton = AdaptiveButton.icon(
      onPressed: () => _doTapCreateIssue(context, model),
      child: const Icon(Icons.add_circle_outline),
    );

    return PlatformPageScaffold(
      reqRefreshCallback: _init,
      materialAppBar: () => AppBar(
        title: Text(model.repo.name),
        actions: [
          createIssueButton,
        ],
      ),
      cupertinoNavigationBar: () => CupertinoNavigationBar(
        middle: Text(model.repo.name),
        trailing: createIssueButton,
        previousPageTitle: context.previousPageTitle,
      ),
      children: [
        const SizedBox(height: 15),
        // 信息部分
        _buildInfo(model, iconColor),
        const SizedBox(height: 15),
        // 列表操作的
        ListTileNav(
          leading: const BackgroundIcon(
            icon: Icons.info_outline,
            color: Colors.green,
          ),
          title: '问题',
          additionalInfo: Text('${model.repo.openIssuesCount}',
              style: TextStyle(color: iconColor)),
          onTap: () {
            routes.pushPage(
              context: context,
              IssuesPage(
                  repo: model.repo,
                  title: '问题',
                  category: IssuesCategory.repoIssues),
              data: PageData(previousPageTitle: model.repo.name),
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
          additionalInfo: Text('${model.repo.openPullsCount}',
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
          additionalInfo: Text('${model.repo.watchersCount}',
              style: TextStyle(color: iconColor)),
          onTap: () {
            //todo: 没有API可用
            showToast('没有API可用');
            // 这里跳转到对应的去哈
          },
        ),

        //if (model.repo.license != null) ...[
        //  const ListTileDivider(),
        _buildLicense(model, iconColor),
        //],

        // 下面分支和啥的
        const SizedBox(height: 15),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            children: [
              Icon(Remix.git_branch_line, size: 20, color: iconColor),
              const SizedBox(width: 5),
              Expanded(
                child: Text(context.watch<RepositoryModel>().selectedBranch,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 20),
              AdaptiveButton(
                  onPressed: () => _onSwitchBranches(context, model),
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
                  repo: model.repo,
                  title: model.repo.name,
                  path: "",
                  prevPath: "",
                ),
                context: context,
                data: PageData(previousPageTitle: model.repo.name),
                routeSettings: const RouteSettings(name: routeContentName)),
          ),
        ),

        ListTileNav(
          title: '提交记录',
          // additionalInfo: Text('${model.repo.commitsCount}',
          //     style: TextStyle(color: iconColor)),
          onTap: () => routes.pushPage(
            CommitsPage(
              repo: model.repo,
              branchName: context.read<RepositoryModel>().selectedBranch,
            ),
            context: context,
            data: PageData(previousPageTitle: model.repo.name),
          ),
        ),

        const SizedBox(height: 15),
        // Selector<RepositoryModel, String?>(
        //   builder: (_, value, __) {},
        //   selector: (_, RepositoryModel model) => model.readMeContent,
        // ),
        // todo: 这里状态管理要另处理下
        if (model.readMeContent != null && model.readMeContent!.isNotEmpty)
          TopDivider(child: _buildREADME(model, iconColor)),
      ],
    );
  }
}
