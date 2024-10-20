import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:gogs_app/app_globals.dart';
import 'package:gogs_app/gogs_client/gogs_client.dart';
import 'package:gogs_app/models/issue_comment_model.dart';
import 'package:gogs_app/pages/issue/create_issue_comment.dart';
import 'package:gogs_app/utils/message_box.dart';
import 'package:gogs_app/utils/utils.dart';
import 'package:gogs_app/widgets/adaptive_widgets.dart';
import 'package:gogs_app/widgets/background_container.dart';
import 'package:gogs_app/widgets/bottom_divider.dart';
import 'package:gogs_app/widgets/cached_image.dart';
import 'package:gogs_app/widgets/markdown.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:remixicon/remixicon.dart';

import 'comment_status.dart';

/// 提交一个新的评论，如果返回null，则表示成功，否则返回错误消息
Future<String?> commitNewComment(IssueCommentModel model, String value) async {
  final res =
      await AppGlobal.cli.issues.comment.create(model.repo, model.issue, value);
  // 创建成功会返回一个IssueComment
  if (res.succeed) {
    // 没有类型返回，所以这里添加个
    model.addComment(res.data!.copyWith(type: 'comment'));
    return null;
  }
  return res.statusMessage;
}

/// 每条评论信息
class CommentItem extends StatelessWidget {
  const CommentItem({
    super.key,
    required this.comment,
  });

  final IssueComment comment;

  Future<bool?> _onEdited(IssueCommentModel model, String? value) async {
    if (value == null) return null;
    final res = await AppGlobal.cli.issues.comment
        .edit(model.repo, model.issue, comment.id, value);
    if (res.succeed) {
      model.updateComment(comment.id, res.data!);
      return true;
    }
    showToast('修改失败:${res.statusMessage}');
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (issueCommentTypeFromString(comment.type) != IssueCommentType.comment) {
      return CommentStatus(comment: comment);
    }
    return Selector<IssueCommentModel, List<IssueComment>>(
      selector: (_, IssueCommentModel model) => model.comments,
      builder: (_, value, __) {
        return BottomDivider(
          child: _CommentItem(
              key: key,
              user: comment.user,
              body: comment.body,
              updatedAt: comment.updatedAt,
              createdAt: comment.createdAt,
              canDelete: comment.user.username ==
                  AppGlobal.instance.userInfo?.username,
              onEdited: (value) =>
                  _onEdited(context.read<IssueCommentModel>(), value)),
        );
      },
    );
  }
}

/// 首条评论，这个首条评论是来自来issue中的，而不是评论列表中的
class FirstCommentItem extends StatelessWidget {
  const FirstCommentItem({super.key});

  Future<bool?> _onEdited(IssueCommentModel model, String? value) async {
    if (value == null) return null;
    final res =
        await AppGlobal.cli.issues.edit(model.repo, model.issue, body: value);
    if (res.succeed && res.data != null) {
      model.issue = model.issue.copyWith(
        body: res.data!.body,
        updatedAt: res.data?.updatedAt,
      );
      return true;
    }
    showToast('修改失败:${res.statusMessage}');
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Selector<IssueCommentModel, Issue>(
      selector: (_, IssueCommentModel model) => model.issue,
      builder: (_, value, __) {
        return _CommentItem(
            key: key,
            user: value.user,
            body: value.body,
            updatedAt: value.updatedAt,
            createdAt: value.createdAt,
            canDelete: false,
            onEdited: (value) =>
                _onEdited(context.read<IssueCommentModel>(), value));
      },
    );
  }
}

class _CommentItem extends StatelessWidget {
  const _CommentItem({
    super.key,
    required this.user,
    required this.body,
    required this.updatedAt,
    required this.createdAt,
    required this.canDelete,
    required this.onEdited,
  });

  final User user;
  final String body;
  final DateTime? updatedAt;
  final DateTime? createdAt;
  final bool canDelete;
  final CommentInputSendCallback<String?> onEdited;

  Widget _buildContentBody(String text) {
    final bodyIsEmpty = text.isEmpty;
    if (bodyIsEmpty) {
      return const Text(
        '这个人很懒，什么都没留下。',
        style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
      );
    }
    if (text.startsWith("<a")) {
      return HtmlWidget(
        baseUrl: Uri.tryParse(AppGlobal.cli.host),
        text,
        onTapUrl: (url) {
          return true;
        },
      );
    }
    return MarkdownBlockPlus(data: text);
  }

  /// 创建新的评论
  Future<bool?> _doSendQuoteReply(
      IssueCommentModel model, String? value) async {
    if (value != null) {
      final res = await commitNewComment(model, value);
      if (res == null) return true;
      showToast('评论失败:$res');
    }
    return null;
  }

  void _doTapBodyEdit(BuildContext context) {
    //final model = context.read<CommentModel>();
    Navigator.of(context).pop();
    showCupertinoModalBottomSheet(
        expand: true,
        context: context,
        builder: (_) =>
            CommentInputPage(defaultContent: body, onSend: onEdited));
  }

  void _doTapDelete(BuildContext context) {}

  void _doTapQuoteReply(BuildContext context) {
    final model = context.read<IssueCommentModel>();
    Navigator.of(context).pop();

    // 这里要使用新建的
    showCupertinoModalBottomSheet(
        expand: true,
        context: context,
        builder: (_) => CommentInputPage(
            defaultContent: '> $body   \n\n',
            onSend: (value) => _doSendQuoteReply(model, value)));
  }

  void _doTapMore(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => CupertinoActionSheet(
        // message: const Text(' '),
        actions: [
          if (AppGlobal.instance.userInfo?.username == user.username) ...[
            // 评论是自己创建的或者这个仓库的所有者是自己才能删除
            if (canDelete)
              CupertinoActionSheetAction(
                onPressed: () => _doTapDelete(context),
                child: const Row(
                  children: [
                    Icon(Remix.delete_bin_line, color: Colors.red),
                    Expanded(child: Text('删除', textAlign: TextAlign.center))
                  ],
                ),
              ),
            // 是自己的才能编辑？或者说仓库所都有者能编辑？
            CupertinoActionSheetAction(
              onPressed: () => _doTapBodyEdit(context),
              child: const Row(
                children: [
                  Icon(Icons.edit),
                  Expanded(child: Text('编辑', textAlign: TextAlign.center))
                ],
              ),
            ),
          ],
          CupertinoActionSheetAction(
            onPressed: () => _doTapQuoteReply(context),
            child: const Row(
              children: [
                Icon(Remix.chat_4_line),
                Expanded(child: Text('引用回复', textAlign: TextAlign.center))
              ],
            ),
          )
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('取消'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundContainer(
      child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  UserHeadImage(
                      size: 22,
                      user: user,
                      // imageURL: comment.user.avatarUrl,
                      radius: 2,
                      padding: const EdgeInsets.all(1)),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.username),
                        const SizedBox(height: 5),
                        Text(timeToLabel(updatedAt),
                            style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                  // 是否已经编辑
                  if (createdAt != null &&
                      updatedAt != null &&
                      createdAt!.compareTo(updatedAt!) < 0)
                    const Text('已编辑',
                        style: TextStyle(color: Colors.grey, fontSize: 13)),
                  // 为issues的这个评论不显示那些东西
                  //todo: 这里待完善，如果是仓库作者则显示所有者？如果是提问者则显示提问者？
                  // if (!isIssue &&
                  //     comment.user.username ==
                  //         AppGlobal.instance.userInfo?.username)
                  //   Padding(
                  //     padding: const EdgeInsets.symmetric(horizontal: 5),
                  //     child: Container(
                  //       padding: const EdgeInsets.all(3),
                  //       decoration: BoxDecoration(
                  //           border:
                  //               Border.all(color: context.colorScheme.outline)),
                  //       child: const Text('所有者',
                  //           style: TextStyle(color: Colors.grey, fontSize: 13)),
                  //     ),
                  //   ),

                  Align(
                      alignment: Alignment.topRight,
                      child: AdaptiveIconButton(
                        icon: Icon(Icons.adaptive.more),
                        onPressed: () => _doTapMore(context),
                      )),
                ],
              ),
              const SizedBox(height: 10),
              _buildContentBody(body),
            ],
          )),
    );
  }
}
