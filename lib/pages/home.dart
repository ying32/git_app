import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:git_app/app_globals.dart';
import 'package:git_app/gogs_client/gogs_client.dart';
import 'package:git_app/pages/issue/issues.dart';
import 'package:git_app/pages/organizations.dart';
import 'package:git_app/pages/repo/repositories.dart';
import 'package:git_app/routes.dart';
import 'package:git_app/utils/collection_mgr.dart';
import 'package:git_app/utils/message_box.dart';
import 'package:git_app/utils/page_data.dart';
import 'package:git_app/widgets/adaptive_widgets.dart';

import 'package:git_app/widgets/background_icon.dart';
import 'package:git_app/widgets/cached_image.dart';
import 'package:git_app/widgets/collection_editor.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:remixicon/remixicon.dart';

import 'package:git_app/widgets/platform_page_scaffold.dart';
import 'package:git_app/widgets/list_section.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _headImageSize = 45.0;
  static const _title = '主页';

  Future<void> _init(_, bool? force) async {
    final res = await AppGlobal.instance.updateMyInfo(force);
    if (mounted && res.succeed) setState(() {});
  }

  void _doPushPageRepos() {
    routes.pushPage(
      RepositoriesPage(
        user: AppGlobal.instance.userInfo!,
        title: '我的仓库',
      ),
      context: context,
      data: const PageData(previousPageTitle: _title),
    );
  }

  void _doPushOrgsPage() {
    routes.pushPage(
      OrganizationsPage(
        title: '我的组织',
        user: AppGlobal.instance.userInfo!,
      ),
      context: context,
      data: const PageData(previousPageTitle: _title),
    );
  }

  Widget _buildHeadImage() => GestureDetector(
        onLongPress: () {
          //todo: 这里打算做个切换多个用户的
        },
        child: UserHeadImage(
          size: _headImageSize,
          user: AppGlobal.instance.userInfo!,
          previousPageTitle: _title,
        ),
      );

  void _doTapEdit() {
    showCupertinoModalBottomSheet<bool>(
            expand: true,
            useRootNavigator: true,
            context: context,
            builder: (BuildContext context) => const CollectionEditor())
        .then((value) {
      // 如果返回true，则更新状态
      if (value == true) setState(() {});
    });
  }

  Widget _buildCollection() {
    return ListSection(
        radius: 6,
        children: CollectionMgr.instance.items.map((e) {
          final repo =
              Repository.fromNameAndOwner(e.repoName, e.ownerName, e.avatarUrl);
          return ListTileNav(
            leading: UserHeadImage(
                user: repo.owner,
                radius: 6,
                padding: const EdgeInsets.all(3),
                size: 50),
            title: repo.fullName,
            onTap: () {
              routes.pushRepositoryDetailsPage(
                context,
                repo,
                data: const PageData(previousPageTitle: _title),
              );
            },
          );
        }).toList());
  }

  @override
  Widget build(BuildContext context) => PlatformPageScaffold(
        reqRefreshCallback: _init,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
        materialAppBar: () => AppBar(
          leading: UnconstrainedBox(
            child: _buildHeadImage(),
          ),
        ),
        cupertinoSliverNavigationBar: () => CupertinoSliverNavigationBar(
          leading: SizedBox(
            height: _headImageSize,
            width: _headImageSize, // 他约束了高了，而且不能用UnconstrainedBox解除限制，否则异常
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: _buildHeadImage(),
            ),
          ),
          border: null,
          largeTitle: const Text(_title),
          // stretch: true,
        ),
        children: [
          const SizedBox(height: 20),
          const Text('我的工作',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          ListSection(
            //backgroundColor: Colors.transparent,
            // header: null,
            //header: Text('fff'),
            // decoration: BoxDecoration(
            //     color: Colors.white, borderRadius: BorderRadius.circular(15)),
            radius: 6,
            children: [
              ListTileNav(
                leading: const BackgroundIcon(
                  icon: Icons.info_outline,
                  color: Colors.green,
                ),
                title: '问题',
                onTap: () {
                  //todo: API不完善可用

                  routes.pushPage(
                      const IssuesPage(
                        category: IssuesCategory.issues,
                        title: '问题',
                      ),
                      context: context,
                      data: const PageData(previousPageTitle: _title));
                },
              ),
              // const ListTileDivider(),
              ListTileNav(
                leading: const BackgroundIcon(
                  icon: Remix.git_pull_request_line,
                  color: Colors.blue,
                ),
                title: '合并请求',
                onTap: () {
                  //todo: 没有API可用
                  showToast('没有API可用');
                  // AppGlobal.pushPage(
                  //     const IssuesPage(
                  //       category: IssuesCategory.pullRequests,
                  //       title: '合并请求',
                  //     ),
                  //     context: context,
                  //     previousPageTitle: widget.title);
                },
              ),
              // const ListTileDivider(),
              ListTileNav(
                leading: const BackgroundIcon(
                  icon: Remix.git_repository_line,
                  color: Colors.deepPurpleAccent,
                ),
                title: '仓库',
                onTap: _doPushPageRepos,
              ),
              // const ListTileDivider(),
              ListTileNav(
                leading: const BackgroundIcon(
                  icon: Remix
                      .organization_chart, //Icons.supervisor_account_outlined,
                  color: Colors.orange,
                ),
                title: '组织',
                onTap: _doPushOrgsPage,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('我的收藏',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
              const Spacer(),
              AdaptiveButton(
                onPressed: _doTapEdit,
                child: const Text('编辑'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildCollection(),
        ],
      );
}
