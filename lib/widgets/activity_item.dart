import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:gogs_app/gogs_client/gogs_client.dart';
import 'package:gogs_app/routes.dart';
import 'package:gogs_app/utils/message_box.dart';
import 'package:gogs_app/widgets/issue/comment_item.dart';
import 'package:provider/provider.dart';
import 'package:remixicon/remixicon.dart';

import 'package:gogs_app/app_globals.dart';
import 'package:gogs_app/pages/issue/issue_comments_view.dart';
import 'package:gogs_app/utils/utils.dart';
import 'cached_image.dart';
import 'markdown.dart';

const _actionCreateRepo = 1;
const _actionRenameRepo = 2;
const _actionStarRepo = 3;
const _actionWatchRepo = 4;
const _actionCommitRepo = 5;
const _actionCreateIssue = 6;
const _actionCreatePullRequest = 7;
const _actionTransferRepo = 8;
const _actionPushTag = 9;
const _actionCommentIssue = 10;
const _actionMergePullRequest = 11;
const _actionCloseIssue = 12;
const _actionReopenIssue = 13;
const _actionClosePullRequest = 14;
const _actionReopenPullRequest = 15;
const _actionCreateBranch = 16;
const _actionDeleteBranch = 17;
const _actionDeleteTag = 18;
const _actionForkRepo = 19;
// const _actionMirrorSyncPush = 20;
// const _actionMirrorSyncCreate = 21;
// const _actionMirrorSyncDelete = 22;

String _opTypeToStr(int opType) => switch (opType) {
      _actionCreateRepo => '创建了仓库',
      _actionRenameRepo => '重命名仓库',
      _actionStarRepo => '点赞了仓库',
      _actionWatchRepo => '关注了仓库',
      _actionCommitRepo => '推送了',
      _actionCreateIssue => '创建了问题',
      _actionCreatePullRequest => '仓库了合并请求',
      _actionTransferRepo => '转移了仓库',
      _actionPushTag => '推送标记',
      _actionCommentIssue => '评论了问题',
      _actionMergePullRequest => '合并了请求',
      _actionCloseIssue => '关闭了问题',
      _actionReopenIssue => '重新打开了问题',
      _actionClosePullRequest => '关闭了合并请求',
      _actionReopenPullRequest => '重新打开了合并请求',
      _actionCreateBranch => '创建了分支',
      _actionDeleteBranch => '删除了分支',
      _actionDeleteTag => '删除了标记',
      _actionForkRepo => '派生了仓库',
// _actionMirrorSyncPush => '',
// _actionMirrorSyncCreate => '',
// _actionMirrorSyncDelete => '',
      _ => '',
    };

class _Icon extends StatelessWidget {
  const _Icon(
    this.icon, {
    this.color = Colors.grey,
  });

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Icon(icon, size: 22, color: color);
}

_Icon? _opTypeToIcon(int opType) => switch (opType) {
      _actionCreateRepo =>
        const _Icon(Remix.git_repository_line, color: Colors.blue),
      _actionRenameRepo => null,
      _actionStarRepo => null,
      _actionWatchRepo => const _Icon(Remix.star_line, color: Colors.grey),
      _actionCommitRepo =>
        const _Icon(Remix.git_commit_line, color: Colors.blueAccent),
      _actionCreateIssue =>
        const _Icon(Remix.information_line, color: Colors.green),
      _actionCreatePullRequest =>
        const _Icon(Remix.git_pull_request_line, color: Colors.purple),
      _actionTransferRepo => null,
      _actionPushTag => const _Icon(Remix.git_commit_line),
      _actionCommentIssue => const _Icon(Remix.question_answer_line),
      _actionMergePullRequest => const _Icon(Remix.git_merge_line),
      _actionCloseIssue =>
        const _Icon(Remix.information_off_line, color: Colors.red),
      _actionReopenIssue =>
        const _Icon(Remix.information_2_line, color: Colors.green),
      _actionClosePullRequest =>
        const _Icon(Remix.git_close_pull_request_line, color: Colors.red),
      _actionReopenPullRequest => null,
      _actionCreateBranch =>
        const _Icon(Remix.git_branch_line, color: Colors.purpleAccent),
      _actionDeleteBranch => null,
      _actionDeleteTag => null,
      _actionForkRepo => const _Icon(Remix.git_fork_line),
      _ => null,
    };

class ActivityItem extends StatelessWidget {
  const ActivityItem({
    super.key,
    required this.item,
  });

  final FeedAction item;

  bool get _contentIsJson => item.jsonContent != null;
  bool get _contentIsEmpty => item.content.isEmpty;

  Widget _buildContentCommit(ContentCommit commit) {
    return Text.rich(
      TextSpan(children: [
        TextSpan(
          text: commit.sha1.substring(0, 10),
          style: const TextStyle(color: Colors.blue, fontSize: 12),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              showToast('没弄呢');
            },
        ),
        const TextSpan(text: ' '),
        TextSpan(
          text: commit.message,
          style: const TextStyle(fontSize: 12),
        ),
      ]),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  void _pushUser(BuildContext context, User user) {
    routes.pushUserDetailsPage(
      context,
      AppGlobal.instance.userInfo?.id == user.id
          ? AppGlobal.instance.userInfo!
          : user,
      data: null,
      // previousPageTitle: widget.title,
    );
  }

  void _pushRepo(BuildContext context) {
    if (item.issueId > 0) {
      //todo: 这里压入的issue最后评论时结果不对哈，待之后找原因
      // routes.pushPage(
      //     IssuesCommentsViewPage(
      //         repo: item.repo,
      //         item: Issue.newEmptyFromId(item.issueId),
      //         updateIssues: true),
      //     data: null);

      routes.pushPage(
          ChangeNotifierProvider<CommentModel>(
              create: (_) {
                final model = CommentModel();
                model.issue = Issue.newEmptyFromId(item.issueId);
                model.repo = item.repo;
                return model;
              },
              child: const IssuesCommentsViewPage(
                  // updateIssues: true,
                  // repo: repo, item: item
                  )),
          data: null);
    } else {
      routes.pushRepositoryDetailsPage(context, item.repo, data: null);
      // AppGlobal.pushPage(
      //   RepositoryDetailsPage(repo: item.repo),
      //   context: context,
      //   previousPageTitle: null,
      // );
    }
  }

  List<Widget>? _buildActionCommitContents(ActionContent? content) =>
      content?.commits.map((e) => _buildContentCommit(e)).toList();

  InlineSpan _buildHead(BuildContext context) => TextSpan(children: [
        WidgetSpan(
            child: UserHeadImage(
                size: 22,
                user: item.committer,
                // imageURL: item.committer.avatarUrl,
                radius: 0,
                padding: const EdgeInsets.all(2))),
        const TextSpan(text: ' '),
        TextSpan(
          text: item.committer.username,
          style: const TextStyle(color: Colors.blue),
          recognizer: TapGestureRecognizer()
            ..onTap = () => _pushUser(context, item.committer),
        ),
        TextSpan(text: ' ${_opTypeToStr(item.opType)} '),
        if (item.opType == _actionCommitRepo) ...[
          TextSpan(
            text: item.refName,
            style: const TextStyle(color: Colors.blue),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                showToast('没弄啊');
              },
          ),
          const TextSpan(text: ' 分支的代码到 '),
        ],
        TextSpan(
          text: '${item.repoOwner.username}/${item.repo.name}',
          style: const TextStyle(color: Colors.blue),
          children: [
            if (item.issueId > 0) TextSpan(text: '#${item.issueId}'),
          ],
          recognizer: TapGestureRecognizer()..onTap = () => _pushRepo(context),
        ),
      ]);

  @override
  Widget build(BuildContext context) {
    final icon = _opTypeToIcon(item.opType);
    return Row(
      children: [
        if (icon != null)
          Padding(padding: const EdgeInsets.only(top: 10), child: icon),
        const SizedBox(width: 10),
        // 中间详细区域
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(_buildHead(context)),
              const SizedBox(height: 10),
              if (item.issueTitle.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(item.issueTitle,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              if (!_contentIsEmpty && !_contentIsJson)
                MarkdownBlockPlus(data: item.content, selectable: false)
              else
                ...?_buildActionCommitContents(item.jsonContent),
            ],
          ),
        ),
        Text(timeToLabel(item.createdAt), style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
