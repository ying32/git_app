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
  bool _isGitea = false;

  Future<void> _init(_, bool? force) async {
    _afterId = null;
    _isGitea = false;
    var res = await AppGlobal.cli.user.feeds(force: force);
    if (res.succeed) {
      _feeds = res.data;
      if ((_feeds?.length ?? 0) > 0) {
        _afterId = _feeds!.last.id;
      }
    } else {
      res = await AppGlobal.cli.user
          .activitiesFeeds(AppGlobal.instance.userInfo!, force: force);
      if (res.succeed) {
        _isGitea = true;
        _feeds = res.data;
        _afterId = 2; // 这里本应该用page的
      }
    }
    if (mounted && (_feeds?.isNotEmpty ?? false)) setState(() {});
  }

  Future<void> _loadMore() async {
    if (_afterId == null) return;
    if (_feeds != null) {
      // todo: 这里待处理gitea的
      FeedActionList? feeds;
      if (_isGitea) {
        final res = await AppGlobal.cli.user
            .activitiesFeeds(AppGlobal.instance.userInfo!, page: _afterId);
        if (res.data != null && res.data!.isNotEmpty) {
          _afterId = _afterId! + 1;
          feeds = res.data;
        }
      } else {
        final res = await AppGlobal.cli.user.feeds(afterId: _afterId);
        if (res.data != null && res.data!.isNotEmpty) {
          _afterId = res.data!.last.id;
          feeds = res.data;
        }
      }
      if (mounted && feeds != null && feeds.isNotEmpty) {
        setState(() {
          _feeds!.addAll(feeds!);
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
