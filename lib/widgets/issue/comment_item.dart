import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:gogs_app/app_globals.dart';
import 'package:gogs_app/gogs_client/gogs_client.dart';
import 'package:gogs_app/pages/issue/create_issue_comment.dart';
import 'package:gogs_app/utils/message_box.dart';
import 'package:gogs_app/utils/utils.dart';
import 'package:gogs_app/widgets/adaptive_widgets.dart';
import 'package:gogs_app/widgets/background_container.dart';
import 'package:gogs_app/widgets/cached_image.dart';
import 'package:gogs_app/widgets/markdown.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:remixicon/remixicon.dart';

class CommentItemData {
  CommentItemData(this.comment, [this.isIssue = false]);
  final IssueComment comment;
  final IssueCommentList subStatus = [];
  final bool isIssue;

  CommentItemData copyWith(
      {IssueComment? comment, IssueCommentList? subStatus, bool? isIssue}) {
    final res = CommentItemData(
      comment ?? this.comment,
      isIssue ?? this.isIssue,
    );
    if (subStatus != null) res.subStatus.addAll(subStatus);
    return res;
  }
}

/// 评论数据模型
class CommentModel extends ChangeNotifier {
  /// 当前issue
  late Issue _issue;
  Issue get issue => _issue;
  set issue(Issue value) {
    _issue = value;
    notifyListeners();
  }

  /// 评论列表
  final List<CommentItemData> _comments = [];
  List<CommentItemData> get comments => _comments;
  void addComment(CommentItemData data) {
    _comments.add(data);
    notifyListeners();
  }

  void updateComment(int id, IssueComment newComment) {
    final idx = _comments.indexWhere((e) => e.comment.id == id);
    if (idx != -1) {
      _comments[idx] = _comments[idx].copyWith(comment: newComment);
      notifyListeners();
    }
  }

  /// 当前仓库
  late Repository repo;
}

/// 每条评论信息
class CommentItem extends StatelessWidget {
  const CommentItem({
    super.key,
    required this.comment,
    required this.isIssue,
  });

  final IssueComment comment;
  final bool isIssue;

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
    return Builder(
      builder: (BuildContext context) {
        return MarkdownBlockPlus(data: text);
      },
    );
  }

  /// 编辑评论
  Future<bool?> _doSendEditComment(CommentModel model, String? value) async {
    if (value == null) return null;
    if (!isIssue) {
      final res = await AppGlobal.cli.issues.comment
          .edit(model.repo, model.issue, comment.id, value);
      if (res.succeed) {
        model.updateComment(comment.id, res.data!);
        return true;
      }
      showToast('回复失败:${res.statusMessage}');
    } else {
      //todo: 这里的状态还要处理啊
      final res =
          await AppGlobal.cli.issues.edit(model.repo, model.issue, body: value);
      if (res.succeed) {
        model.issue = model.issue.copyWith(
          body: res.data?.body,
          updatedAt: res.data?.updatedAt,
        );

        // setState(() {
        //   _issue = issue.copyWith(

        //   );
        //   _comment =
        //       comment.copyWith(body: issue.body, updatedAt: issue.updatedAt);
        // });
        return true;
      }
      showToast('编辑失败:${res.statusMessage}');
    }

    return null;
  }

  /// 创建新的评论
  Future<bool?> _doSendNewComment(CommentModel model, String? value) async {
    if (value == null) return null;

    final res = await AppGlobal.cli.issues.comment
        .create(model.repo, model.issue, value);
    if (res.succeed) {
      model.addComment(CommentItemData(res.data!));
      return true;
    }
    showToast('编辑失败:${res.statusMessage}');

    return null;
  }

  void _doTapBodyEdit(BuildContext context) {
    final model = context.read<CommentModel>();
    Navigator.of(context).pop();
    showCupertinoModalBottomSheet(
        expand: true,
        context: context,
        builder: (context) => CommentInputPage(
            defaultContent: comment.body,
            onSend: (value) => _doSendEditComment(model, value)));
  }

  void _doTapDelete(BuildContext context) {}

  void _doTapQuoteReply(BuildContext context) {
    final model = context.read<CommentModel>();
    Navigator.of(context).pop();

    // 这里要使用新建的
    showCupertinoModalBottomSheet(
        expand: true,
        context: context,
        builder: (context) => CommentInputPage(
            defaultContent: '> ${comment.body}   \n\n',
            onSend: (value) => _doSendNewComment(model, value)));
  }

  void _doTapMore(BuildContext context) {
    final modal = context.read<CommentModel>();
    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => CupertinoActionSheet(
        // message: const Text(' '),
        actions: [
          if (AppGlobal.instance.userInfo?.username ==
              comment.user.username) ...[
            // 评论是自己创建的或者这个仓库的所有者是自己才能删除
            if (!isIssue && comment.user.username == modal.repo.owner.username)
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
                      user: comment.user,
                      // imageURL: comment.user.avatarUrl,
                      radius: 2,
                      padding: const EdgeInsets.all(1)),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(comment.user.username),
                        const SizedBox(height: 5),
                        Text(timeToLabel(comment.updatedAt),
                            style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                  // 是否已经编辑
                  if (comment.createdAt != null &&
                      comment.updatedAt != null &&
                      comment.createdAt!.compareTo(comment.updatedAt!) < 0)
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
              _buildContentBody(comment.body),
            ],
          )),
    );
  }
}
