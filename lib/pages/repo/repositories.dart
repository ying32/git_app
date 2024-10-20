import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gogs_app/gogs_client/gogs_client.dart';

import 'package:gogs_app/app_globals.dart';
import 'package:gogs_app/routes.dart';
import 'package:gogs_app/utils/build_context_helper.dart';
import 'package:gogs_app/utils/page_data.dart';

import 'package:gogs_app/widgets/cached_image.dart';
import 'package:gogs_app/widgets/platform_page_scaffold.dart';
import 'package:gogs_app/widgets/list_section.dart';

class RepositoriesPage extends StatefulWidget {
  const RepositoriesPage({
    super.key,
    this.title = '仓库',
    required this.user,
  });

  /// 标题
  final String title;

  /// 用户信息
  final User user;

  @override
  State<RepositoriesPage> createState() => _RepositoriesPageState();
}

class _RepositoriesPageState extends State<RepositoriesPage>
    with AutomaticKeepAliveClientMixin {
  RepositoryList? _repos;

  Future _init(_, bool? force) async {
    if (widget.user.isOrganization) {
      final res = await AppGlobal.cli.repos.orgRepos(widget.user, force: force);
      _repos = res.data;
    } else {
      final res = await (_isMy
          ? AppGlobal.cli.user.repos(force)
          : AppGlobal.cli.repos.userRepos(widget.user, force: force));
      _repos = res.data;
    }
    if (mounted) setState(() {});
  }

  bool get _isMy => widget.user.id == AppGlobal.instance.userInfo?.id;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return PlatformPageScaffold(
        reqRefreshCallback: _init,
        materialAppBar: () => AppBar(
              title: Text(widget.title),
            ),
        cupertinoSliverNavigationBar: () => CupertinoSliverNavigationBar(
              previousPageTitle: context.previousPageTitle,
              largeTitle: Text(widget.title),
            ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
        itemCount: _repos?.length ?? 0,
        useSeparator: true,
        separatorPadding: const EdgeInsets.only(left: 60),
        emptyItemHint: const Center(child: Text('没有可用的仓库')),
        itemBuilder: (_, index) {
          final item = _repos![index];
          Widget leading = UserHeadImage.lock(
            user: item.owner,
            // imageURL: item.owner.avatarUrl,
            radius: 3,
            padding: const EdgeInsets.all(3),
            size: 50,
            showLockIcon: item.private,
          );

          return ListTileNav(
            onTap: () {
              routes.pushRepositoryDetailsPage(
                context,
                item,
                data: PageData(
                  previousPageTitle: _isMy ? null : widget.title,
                ),
              );
              // AppGlobal.pushModalPage(
              //     RepositoryDetailsPage(
              //       repo: item,
              //     ),
              //     context: context,
              //     previousPageTitle: _isMyRepos ? null : widget.title);
            },
            leading: leading,
            title: item.fullName,
            subtitle: Text(item.description,
                maxLines: 1, overflow: TextOverflow.ellipsis),
          );
        });
  }

  @override
  bool get wantKeepAlive => false;
}
