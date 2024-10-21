import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:git_app/gogs_client/gogs_client.dart';
import 'package:git_app/app_globals.dart';
import 'package:git_app/utils/build_context_helper.dart';
import 'package:git_app/widgets/platform_page_scaffold.dart';
import 'package:git_app/widgets/repository_item.dart';

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

class _RepositoriesPageState
    extends State<RepositoriesPage> /* with AutomaticKeepAliveClientMixin*/ {
  RepositoryList? _repos;

  Future _init(_, bool? force) async {
    if (widget.user.isOrganization) {
      final res = await AppGlobal.cli.repos.orgRepos(widget.user, force: force);
      _repos = res.data;
    } else {
      final res = await (AppGlobal.isMe(widget.user)
          ? AppGlobal.cli.user.repos(force)
          : AppGlobal.cli.repos.userRepos(widget.user, force: force));
      _repos = res.data;
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // super.build(context);

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
      itemBuilder: (_, index) => RepositoryItem(
          repo: _repos![index],
          previousPageTitle: AppGlobal.isMe(widget.user) ? null : widget.title),
    );
  }

  //@override
  // bool get wantKeepAlive => false;
}
