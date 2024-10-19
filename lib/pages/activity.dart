import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gogs_app/app_globals.dart';
import 'package:gogs_app/gogs_client/gogs_client.dart';
import 'package:gogs_app/utils/build_context_helper.dart';

import 'package:gogs_app/widgets/platform_page_scaffold.dart';
import 'package:gogs_app/widgets/activity_item.dart';

class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  FeedActionList? _feeds;

  int? _afterId;

  Future<void> _init(_, bool? force) async {
    _afterId = null;
    final res = await AppGlobal.cli.user.feeds(force: force);
    _feeds = res.data;
    if ((_feeds?.length ?? 0) > 0) {
      _afterId = _feeds!.last.id;
    }
    if (mounted) setState(() {});
  }

  Future<void> _loadMore() async {
    if (_afterId == null) return;
    if (_feeds != null) {
      final res = await AppGlobal.cli.user.feeds(afterId: _afterId);
      if (mounted && res.data != null && res.data!.isNotEmpty) {
        _afterId = res.data!.last.id;
        setState(() {
          _feeds!.addAll(res.data!);
        });
      } else {
        setState(() {
          _afterId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PlatformPageScaffold(
      reqRefreshCallback: _init,
      reqPullUpLoadCallback: _loadMore,
      materialAppBar: () => AppBar(
        title: const Text('最近活动'),
      ),
      cupertinoSliverNavigationBar: () => const CupertinoSliverNavigationBar(
        // border: null,
        largeTitle: Text('最近活动'),
        // stretch: true,
      ),
      emptyItemHint: Center(
          child:
              Text('没有数据或者没有打补丁', style: context.theme.textTheme.titleLarge)),
      padding: const EdgeInsets.symmetric(vertical: 10),
      separatorPadding: const EdgeInsets.only(left: 45),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          child: ActivityItem(item: _feeds![index]),
        );
      },
      useSeparator: true,
      itemCount: _feeds?.length ?? 0,
    );
  }
}
