import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:gogs_app/gogs_client/gogs_client.dart';
import 'package:gogs_app/utils/utils.dart';
import 'package:html/dom.dart' as dom;
import 'package:remixicon/remixicon.dart';

/// 评论的类型
enum _CommentType {
  unknown,
  comment,
  reopen,
  closed,
  issueRef,
  commitRef,
  commentRef,
  pullRef,
}

_CommentType _commentTypeFromString(String text) {
  return switch (text) {
    "comment" => _CommentType.comment,
    "reopen" => _CommentType.reopen,
    "closed" => _CommentType.closed,
    "issue_ref" => _CommentType.issueRef,
    "commit_ref" => _CommentType.commitRef,
    "comment_ref" => _CommentType.commentRef,
    "pull_ref" => _CommentType.pullRef,
    _ => _CommentType.unknown,
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

  Widget _buildALabel() {
    final match = _regEx.firstMatch(comment.body);
    return Padding(
      padding: const EdgeInsets.only(right: 15),
      child: Text(
        match?.group(2) ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: _defaultTextStyle.copyWith(
          color: Colors.blue,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  Widget _buildTextBody(String afterText) {
    Widget child = Text.rich(
      TextSpan(
        children: [
          const WidgetSpan(child: SizedBox(width: 10)),
          TextSpan(text: comment.user.username),
          const TextSpan(text: ' 于 ', style: TextStyle(color: Colors.grey)),
          TextSpan(text: timeToLabel(comment.updatedAt)),
          TextSpan(
              text: ' $afterText', style: const TextStyle(color: Colors.grey)),
          if (_bodyIsHtml) const TextSpan(text: " 并引用了该问题"),
        ],
        style: _defaultTextStyle,
      ),
      // maxLines: 1,
      // overflow: TextOverflow.ellipsis,
      style: _defaultTextStyle,
      textAlign: TextAlign.start,
    );
    if (_bodyIsHtml) {
      child = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          child,
          const SizedBox(height: 5),
          // _buildALabel(),
          // 这里用个htmlWidget其实是比较方便的，但没找着不让他换行的问题
          HtmlWidget(
            // buildAsync: true,
            comment.body,
            customStylesBuilder: (dom.Element element) {
              // 要怎么才能生效？
              return {"text-overflow": "ellipsis", "white-space": "pre"};
            },
            onTapUrl: (u) => true,
            textStyle: _defaultTextStyle.copyWith(
                color: Colors.grey, overflow: TextOverflow.ellipsis),
          ),
        ],
      );
    }

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
    required String afterText,
  }) {
    return IntrinsicHeight(
      child: Padding(
        padding: const EdgeInsets.only(left: 30),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIcon(icon: icon, iconColor: iconColor),
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
    var type = _commentTypeFromString(comment.type);
    // 因为没打补丁，所以这里当为未知的时候做个简单判断，虽然不能知道是啥，但好歹能显示些
    if (type == _CommentType.unknown) {
      if (comment.body.isNotEmpty) {
        if (_bodyIsHtml) {
          type = _CommentType.commitRef;
        } else {
          type = _CommentType.comment;
        }
      }
    }
    late Widget child;
    switch (type) {
      case _CommentType.closed:
        child = _buildBody(
          icon: Remix.forbid_2_line,
          iconColor: Colors.red,
          afterText: '关闭',
        );
      case _CommentType.reopen:
        child = _buildBody(
          icon: Remix.circle_fill,
          iconColor: Colors.green,
          afterText: '重新开启',
        );
      case _CommentType.commitRef:
        child = _buildBody(
          icon: Remix.git_commit_line,
          iconColor: Colors.green,
          afterText: '提交',
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
