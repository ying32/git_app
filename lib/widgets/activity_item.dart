import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:gogs_app/gogs_client/gogs_client.dart';
import 'package:gogs_app/models/issue_comment_model.dart';
import 'package:gogs_app/routes.dart';
import 'package:gogs_app/utils/message_box.dart';
import 'package:provider/provider.dart';
import 'package:remixicon/remixicon.dart';

import 'package:gogs_app/app_globals.dart';
import 'package:gogs_app/pages/issue/issue_comments_view.dart';
import 'package:gogs_app/utils/utils.dart';
import 'cached_image.dart';
import 'markdown.dart';

///note: 本为偷下懒用int的，现在为了与gitea统一，所以改为string类型了
const _actionCreateRepo = 'create_repo';
const _actionRenameRepo = 'rename_repo';
const _actionStarRepo = 'star_repo';
const _actionWatchRepo = 'watch_repo';
const _actionCommitRepo = 'commit_repo';
const _actionCreateIssue = 'create_issue';
const _actionCreatePullRequest = 'create_pull_request';
const _actionTransferRepo = 'transfer_repo';
const _actionPushTag = 'push_tag';
const _actionCommentIssue = 'comment_issue';
const _actionMergePullRequest = 'merge_pull_request';
const _actionCloseIssue = 'close_issue';
const _actionReopenIssue = 'reopen_issue';
const _actionClosePullRequest = 'close_pull_request';
const _actionReopenPullRequest = 'reopen_pull_request';
const _actionCreateBranch = 'create_branch';
const _actionDeleteBranch = 'delete_branch';
const _actionDeleteTag = 'delete_tag';
const _actionForkRepo = 'fork_repo';
// const _actionMirrorSyncPush = 'mirror_sync_push';
// const _actionMirrorSyncCreate = 'mirror_sync_create';
// const _actionMirrorSyncDelete = 'mirror_sync_delete';

String _opTypeToStr(String opType) => switch (opType) {
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

_Icon? _opTypeToIcon(String opType) => switch (opType) {
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
        WidgetSpan(
          child: Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 2, left: 15),
            child: GestureDetector(
              onTap: () {
                showToast('没弄呢');
              },
              child: Container(
                constraints: const BoxConstraints(minWidth: 80),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
                // todo: 这里还要优化，要对齐
                child: Text(
                  commit.sha1.substring(0, 10),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ),
        ),
        // TextSpan(
        //   text: commit.sha1.substring(0, 10),
        //   style: const TextStyle(color: Colors.blue, fontSize: 12),
        //   recognizer: TapGestureRecognizer()
        //     ..onTap = () {
        //       showToast('没弄呢');
        //     },
        // ),
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
          ChangeNotifierProvider<IssueCommentModel>(
              create: (_) {
                final model = IssueCommentModel();
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
                user: item.actUser,
                // imageURL: item.committer.avatarUrl,
                radius: 0,
                padding: const EdgeInsets.all(2))),
        const TextSpan(text: ' '),
        TextSpan(
          text: item.actUser.username,
          style: const TextStyle(color: Colors.blue),
          recognizer: TapGestureRecognizer()
            ..onTap = () => _pushUser(context, item.actUser),
        ),
        TextSpan(text: ' ${_opTypeToStr(item.opType)} '),
        if (item.opType == _actionCommitRepo) ...[
          TextSpan(
            text: item.refName.split("/").last,
            style: const TextStyle(color: Colors.blue),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                showToast('没弄啊');
              },
          ),
          const TextSpan(text: ' 分支的代码到 '),
        ],
        TextSpan(
          text: '${item.repo.owner.username}/${item.repo.name}',
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
