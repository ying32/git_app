import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:git_app/app_globals.dart';
import 'package:git_app/gogs_client/gogs_client.dart';
import 'package:git_app/pages/repo/commit_details.dart';
import 'package:git_app/routes.dart';
import 'package:git_app/utils/page_data.dart';
import 'package:git_app/utils/utils.dart';
import 'package:git_app/widgets/cached_image.dart';
import 'package:git_app/widgets/issue/labels.dart';
// import 'package:html/dom.dart' as dom;
import 'package:remixicon/remixicon.dart';

/// 评论的类型

enum IssueCommentType {
  unknown,
  comment,
  reopen,
  closed,
  issueRef,
  commitRef,
  commentRef,
  pullRef,
  // gitea，不知道还有些啥状态，没去看他的源码
  assignees,
  changeIssueRef,
  label,
  changeTitle
}

IssueCommentType issueCommentTypeFromString(String text) {
  return switch (text) {
    "comment" => IssueCommentType.comment,
    "reopen" => IssueCommentType.reopen,
    //gitea | close
    "closed" || "close" => IssueCommentType.closed,
    "issue_ref" => IssueCommentType.issueRef,
    "commit_ref" => IssueCommentType.commitRef,
    "comment_ref" => IssueCommentType.commentRef,
    "pull_ref" => IssueCommentType.pullRef,
    // gitea
    "assignees" => IssueCommentType.assignees,
    "change_issue_ref" => IssueCommentType.changeIssueRef,
    "label" => IssueCommentType.label,
    "change_title" => IssueCommentType.changeTitle,
    _ => IssueCommentType.unknown,
  };
}

/// 评论状态
class CommentStatus extends StatelessWidget {
  CommentStatus({super.key, required this.comment}) {
    /// 判断下内容
    _bodyIsHtml = comment.bodyIsHtml;
  }

  final IssueComment comment;
  late final bool _bodyIsHtml;

  static const _defaultTextStyle = TextStyle(fontSize: 13);

  static final _regEx =
      RegExp(r'<a\s+href="([^"]+)"[^>]*>(.*?)<\/a>', caseSensitive: false);
  //
  // Widget _buildALabel() {
  //   final match = _regEx.firstMatch(comment.body);
  //   return Padding(
  //     padding: const EdgeInsets.only(left: 25, right: 15),
  //     child: Text(
  //       match?.group(2) ?? '',
  //       maxLines: 1,
  //       overflow: TextOverflow.ellipsis,
  //       style: _defaultTextStyle.copyWith(
  //         color: Colors.blue,
  //         decoration: TextDecoration.underline,
  //       ),
  //     ),
  //   );
  // }

  void _doTap(String url) {
    final arr = url.split("/");
    if (arr.length != 5) return;
    final repo = Repository.fromNameAndOwner(arr[2], arr[1], '');
    routes.pushPage(
        CommitDetailsPage(
          repo: repo,
          sha: arr.last,
          // 这个提交内容不完整，还得压入后刷新才能得到完整的。。。
          message: _regEx.firstMatch(comment.body)?.group(2) ?? '',
        ),
        data: PageData(previousPageTitle: repo.name));
  }

  Widget _buildTextBody(InlineSpan afterText) {
    Widget child = Text.rich(
      TextSpan(
        children: [
          const WidgetSpan(child: SizedBox(width: 10)),
          WidgetSpan(
            child: Padding(
              padding: const EdgeInsets.only(right: 5.0),
              child: UserHeadImage(
                  size: 16, user: comment.user, padding: EdgeInsets.zero),
            ),
          ),
          TextSpan(text: comment.user.username),
          const TextSpan(text: ' 于 ', style: TextStyle(color: Colors.grey)),
          TextSpan(text: timeToLabel(comment.updatedAt)),
          const TextSpan(text: ' '),
          afterText,
          if (_bodyIsHtml) ...[
            const TextSpan(text: " 并引用了该问题\n"),
            WidgetSpan(
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 30, right: 15, bottom: 3, top: 3),
                // child: _buildALabel(),
                child: HtmlWidget(
                  // buildAsync: true,
                  comment.body,
                  //customStylesBuilder: (dom.Element element) {
                  //  // 要怎么才能生效？
                  //  return {"text-overflow": "ellipsis", "white-space": "pre"};
                  //},
                  onTapUrl: (u) {
                    _doTap(u);
                    return true;
                  },
                  textStyle: _defaultTextStyle.copyWith(
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
          ],
        ],
        style: _defaultTextStyle,
      ),
      // maxLines: 1,
      // overflow: TextOverflow.ellipsis,
      style: _defaultTextStyle,
      textAlign: TextAlign.start,
    );

    return child;
  }

  static const _startPadding = 15.0;

  Widget _buildIcon({required IconData icon, required Color iconColor}) {
    return Column(
      children: [
        const SizedBox(
          height: _startPadding,
          child: VerticalDivider(width: 1),
        ),
        Icon(icon, color: iconColor, size: 16),
        const Expanded(child: VerticalDivider(width: 1)),
      ],
    );
  }

  Widget _buildBody({
    required IconData icon,
    required Color iconColor,
    required InlineSpan afterText,
  }) {
    return IntrinsicHeight(
      child: Padding(
        padding: const EdgeInsets.only(left: 30),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 状态图标
            _buildIcon(icon: icon, iconColor: iconColor),
            // 内容
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: _startPadding),
                child: _buildTextBody(afterText),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var type = issueCommentTypeFromString(comment.type);
    // 因为没打补丁，所以这里当为未知的时候做个简单判断，虽然不能知道是啥，但好歹能显示些
    if (type == IssueCommentType.unknown) {
      if (comment.body.isNotEmpty) {
        if (_bodyIsHtml) {
          type = IssueCommentType.commitRef;
        } else {
          type = IssueCommentType.comment;
        }
      }
    }
    late Widget child;
    switch (type) {
      case IssueCommentType.closed:
        child = _buildBody(
          icon: Remix.forbid_2_line,
          iconColor: Colors.red,
          afterText: const TextSpan(text: '关闭了此问题'),
        );
      case IssueCommentType.reopen:
        child = _buildBody(
          icon: Remix.circle_fill,
          iconColor: Colors.green,
          afterText: const TextSpan(text: '重新开启了此问题'),
        );
      case IssueCommentType.commitRef:
        child = _buildBody(
          icon: Remix.git_branch_line,
          iconColor: Colors.green,
          afterText: const TextSpan(text: '提交'),
        );
      case IssueCommentType.assignees:
        child = _buildBody(
          icon: Remix.account_circle_line,
          iconColor: Colors.grey,
          afterText: TextSpan(text: '指派给', children: [
            if (comment.assignee != null)
              TextSpan(
                  text: AppGlobal.instance.userInfo?.id == comment.assignee!.id
                      ? '自己'
                      : comment.assignee!.username),
          ]),
        );
      case IssueCommentType.changeIssueRef:
        child = _buildBody(
          icon: Remix.git_merge_line,
          iconColor: Colors.grey,
          afterText: TextSpan(text: '添加了引用 ', children: [
            TextSpan(
                text: comment.timeline?.newRef,
                style: const TextStyle(fontWeight: FontWeight.bold))
          ]),
        );
      case IssueCommentType.changeTitle:
        child = _buildBody(
          icon: Remix.edit_line,
          iconColor: Colors.grey,
          afterText: TextSpan(text: '修改标题 ', children: [
            TextSpan(
                text: comment.timeline?.oldTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.lineThrough,
                )),
            const TextSpan(text: ' 为 '),
            TextSpan(
                text: comment.timeline?.newTitle,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ]),
        );
      // 这个要优化，要合并起来为一条？不过看github的app是每个一条哈。
      case IssueCommentType.label:
        final isDelete = comment.body != '1';
        child = _buildBody(
          icon: Remix.price_tag_3_line,
          iconColor: Colors.grey,
          afterText: TextSpan(text: '${isDelete ? '删除' : '添加'}了标签 ', children: [
            if (comment.timeline?.label != null)
              WidgetSpan(
                  child: IssueLabelWidget(label: comment.timeline!.label!))
          ]),
        );

      default:
        child = SizedBox(
          child: Text(
            '没有打补丁，不支持状态=$type',
            style: const TextStyle(color: Colors.red),
          ),
        );
    }
    return child;
  }
}
