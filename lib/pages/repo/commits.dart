import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gogs_app/app_globals.dart';
import 'package:gogs_app/gogs_client/gogs_client.dart';
import 'package:gogs_app/utils/build_context_helper.dart';

import 'package:gogs_app/widgets/commits_item.dart';
import 'package:gogs_app/widgets/platform_page_scaffold.dart';

class CommitsPage extends StatefulWidget {
  const CommitsPage({
    super.key,
    required this.repo,
    required this.branchName,
  });

  /// 仓库
  final Repository repo;

  /// 分支名
  final String branchName;

  @override
  State<CommitsPage> createState() => _CommitsPageState();
}

class _CommitsPageState extends State<CommitsPage> {
  CommitList? _commits;

  Future _init(_, bool? force) async {
    final res =
        await AppGlobal.cli.repos.commit.getAll(widget.repo, force: force);
    _commits = res.data;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return PlatformPageScaffold(
      reqRefreshCallback: _init,
      materialAppBar: () => AppBar(
        title: const Text('提交记录'),
      ),
      cupertinoNavigationBar: () => CupertinoNavigationBar(
        middle: const Text('提交记录'),
        previousPageTitle: context.previousPageTitle,
      ),
      emptyItemHint: const Center(child: Text('没有数据哦')),
      itemBuilder: (BuildContext context, int index) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: CommitsItem(repo: widget.repo, item: _commits![index]),
      ),
      useSeparator: true,
      itemCount: _commits?.length ?? 0,
    );
  }
}
