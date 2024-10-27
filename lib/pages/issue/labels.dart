import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:git_app/gogs_client/gogs_client.dart';
import 'package:git_app/widgets/platform_page_scaffold.dart';

class IssueLabelsPage extends StatelessWidget {
  const IssueLabelsPage({super.key, required this.repo});

  final Repository repo;

  Future<void> _init(_, bool? force) async {
    //  final res = AppGlobal.cli.repos.labels(widget.repo);
    // ??? 为异常？
    // if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return PlatformPageScaffold(
        reqRefreshCallback: _init,
        // materialAppBar: () => AppBar(
        //       title: const Text('标签'),
        //     ),
        // cupertinoNavigationBar: () => const CupertinoNavigationBar(
        //       middle: Text('标签'),
        //     ),
        appBar: const PlatformPageAppBar(
          title: Text('标签'),
        ),
        child: const Center(
          child: Text('111'),
        ));
  }
}
