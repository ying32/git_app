import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:git_app/app_globals.dart';
import 'package:git_app/gogs_client/gogs_client.dart';
import 'package:git_app/widgets/platform_page_scaffold.dart';
import 'package:git_app/widgets/repository_item.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  RepositoryList? _repos;

  Future<void> _onSubmitted(String? value) async {
    if (value != null && value.isNotEmpty) {
      final res = await AppGlobal.cli.repos.search(value);
      if (res.succeed && res.data != null && res.data!.ok) {
        _repos = res.data!.data;
        if (mounted) setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PlatformPageScaffold(
      materialAppBar: () => AppBar(
        title: const Text('发现'),
      ),
      cupertinoSliverNavigationBar: () => const CupertinoSliverNavigationBar(
        largeTitle: Text('发现'),
        border: null,
        stretch: true,
      ),
      topBar: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        child: CupertinoSearchTextField(
          //controller: _controller,
          onSubmitted: _onSubmitted,
          onChanged: (String value) {
            if (value.isEmpty) {
              setState(() {
                _repos?.clear();
              });
            }
          },
        ),
      ),
      emptyItemHint: const Center(child: Text('没有数据')),
      //todo: 还没做呢，他这结果搜索回来是空的
      itemBuilder: (_, index) =>
          RepositoryItem(repo: _repos![index], previousPageTitle: '发现'),
      itemCount: _repos?.length ?? 0,
    );
  }
}
