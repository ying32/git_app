import 'package:flutter/material.dart';
import 'package:git_app/app_globals.dart';
import 'package:git_app/gogs_client/gogs_client.dart';
import 'package:git_app/models/issue_comment_model.dart';
import 'package:git_app/utils/message_box.dart';
import 'package:git_app/widgets/adaptive_widgets.dart';
import 'package:git_app/widgets/list_section.dart';
import 'package:provider/provider.dart';
import 'package:remixicon/remixicon.dart';

class IssueCommentMorePage extends StatelessWidget {
  const IssueCommentMorePage({super.key});

  void _doCloseIssue(BuildContext context) {
    final model = context.read<IssueCommentModel>();

    AppGlobal.cli.issues
        .edit(model.repo, model.issue, isOpen: !model.issue.isOpen)
        .then((value) {
      if (value.succeed && value.data != null) {
        model.issue = model.issue.copyWith(state: value.data!.state);
        // closed
        // reopen
        // 最后一个的
        model.addComment(IssueComment(
            id: 0,
            user: value.data!.user, // 这个user对不对？
            body: '',
            createdAt: DateTime.now(),
            updatedAt: value.data!.updatedAt,
            type: value.data!.isOpen ? 'reopen' : 'closed'));
      }
    });
  }

  void _doLock() {
    //todo: 没有API可用
    showToast('没有API可用');
  }

  void _doUnsubscribe() {
    //todo: 没有API可用
    showToast('没有API可用');
  }

  void _doEditLabels(BuildContext context) {
    //todo: 未实现
    showToast('没实现');
    // showCupertinoModalBottomSheet(
    //   expand: true,
    //   context: context,
    //   builder: (context) => IssueLabelsPage(repo: widget.repo),
    // );
  }

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      ListSection(
          backgroundColor: Colors.transparent,
          dividerMargin: 20,
          children: [
            const ListTileNav(
              title: 'Assignees',
              trailing: AdaptiveButton(
                onPressed: null,
                child: Text('编辑'),
              ),
            ),
            ListTileNav(
              title: '标签',
              trailing: AdaptiveButton(
                onPressed: () => _doEditLabels(context),
                child: const Text('编辑'),
              ),
            ),
            const ListTileNav(
              title: 'Projects',
              trailing: AdaptiveButton(
                onPressed: null,
                child: Text('编辑'),
              ),
            ),
            const ListTileNav(
              title: 'Milestone',
              trailing: AdaptiveButton(
                onPressed: null,
                child: Text('编辑'),
              ),
            )
          ]),
      const ListTileDivider(left: 20),
      // Consumer<CommentModel>(
      Selector<IssueCommentModel, Issue>(
        builder: (_, Issue value, __) {
          return ListTileNav(
            leading: value.isOpen
                ? const Icon(Remix.forbid_2_line, color: Colors.red)
                : const Icon(Remix.information_line, color: Colors.green),
            titleWidget: value.isOpen
                ? const Text('关闭问题', style: TextStyle(color: Colors.red))
                : const Text('重新开启问题', style: TextStyle(color: Colors.green)),
            onTap: () => _doCloseIssue(context),
          );
        },
        selector: (_, model) => model.issue,
      ),
      ListTileNav(
        leading: const Icon(Remix.lock_line),
        title: '锁定',
        onTap: _doLock,
      ),
      ListTileNav(
        leading: const Icon(Remix.volume_mute_line),
        title: '取消订阅',
        onTap: _doUnsubscribe,
      ),
    ]);
  }
}
