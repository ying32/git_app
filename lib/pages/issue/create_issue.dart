import 'package:flutter/material.dart';
import 'package:gogs_app/app_globals.dart';
import 'package:gogs_app/gogs_client/gogs_client.dart';
import 'package:gogs_app/utils/build_context_helper.dart';
import 'package:gogs_app/utils/message_box.dart';

import 'package:gogs_app/widgets/editor_page.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

/// 显示创建issue的
Future<Issue?> showCreateIssuePage(
    BuildContext context, Repository repo) async {
  return showCupertinoModalBottomSheet<Issue>(
    expand: true,
    context: context,
    builder: (context) => _CreateIssuePage(repo: repo),
  );
}

/// 创建issue的body布局
class _CreateIssuePage extends StatelessWidget {
  const _CreateIssuePage({
    required this.repo,
  });

  final Repository repo;

  Future<Issue?> _onSend(String? title, String? content) async {
    final issue = CreateIssue(
        title: title!,
        body: content ?? '',
        assignee: AppGlobal.instance.userInfo!.username);
    // 创建成功会返回一个issue
    final res = await AppGlobal.cli.issues.create(repo, issue);
    if (res.succeed) {
      return res.data;
    } else {
      showToast(res.statusMessage ?? '未知错误');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return EditorPage(
      title: Column(
        children: [
          Text(
            repo.fullName,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          Text(
            '创建新的issue',
            textAlign: TextAlign.center,
            style: context.theme.textTheme.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      trailingTitle: const Text('提交'),
      contentPlaceholder: '内容（可选）',
      onEditCompleted: _onSend,
    );
  }
}
