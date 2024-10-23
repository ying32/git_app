import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:git_app/models/issue_comment_model.dart';
import 'package:git_app/pages/issue/create_issue_comment.dart';
import 'package:git_app/utils/build_context_helper.dart';
import 'package:git_app/utils/message_box.dart';
import 'package:git_app/widgets/adaptive_widgets.dart';
import 'package:git_app/widgets/background_container.dart';
import 'package:git_app/widgets/divider_plus.dart';
import 'package:git_app/widgets/issue/comment_issue_info.dart';
import 'package:git_app/widgets/issue/comment_item.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

import 'package:git_app/app_globals.dart';
import 'package:git_app/widgets/platform_page_scaffold.dart';
import 'package:provider/provider.dart';

import 'issue_comment_more.dart';

class IssuesCommentsViewPage extends StatelessWidget {
  const IssuesCommentsViewPage({super.key});

  Future _init(BuildContext context, bool? force) async {
    final model = context.read<IssueCommentModel>();
    // 这个只一次，
    //model.done = false;
    // if (widget.updateIssues) {
    // 这有一种情况，编辑issue后，因为列表没刷新，所以这里不会刷新，现在让他总是刷新下
    //if (issue.number <= 0) {
    final resIssue = await AppGlobal.cli.issues.getIssue(model.repo,
        model.issue.number <= 0 ? model.issue.id : model.issue.number);
    if (resIssue.succeed &&
        resIssue.data != null &&
        model.issue != resIssue.data) {
      model.issue = resIssue.data!;
    }
    // }
    if (model.firstDone) {
      await _loadComment(model);
    } else {
      _loadComment(model);
    }
  }

  Future<void> _loadComment(IssueCommentModel model) async {
    model.comments.clear();

    //todo: 这个时间线要另处理
    var resComments = await AppGlobal.cli.issues.comment
        .timeline(model.repo, model.issue, nocache: true);
    if (!resComments.succeed) {
      resComments = await AppGlobal.cli.issues.comment
          .getAll(model.repo, model.issue, nocache: true);
    }
    if (!model.firstDone) {
      model.firstDone = true;
    }
    if (resComments.succeed) {
      // 这里加点时间，好让有动画显示
      await Future.delayed(const Duration(milliseconds: 10));
      // 添加默认项目到列表
      model.addAllComment(resComments.data!);
    }
  }

  /// 创建评论
  Future<bool?> _doSendComment(String? value, IssueCommentModel model) async {
    if (value != null) {
      final res = await commitNewComment(model, value);
      if (res == null) {
        model.jumpEnd();
        return true;
      }
      showToast('提交评论失败，错误：$res');
    }

    return null;
  }

  void _doTapCreateComment(BuildContext context, IssueCommentModel model) {
    showCupertinoModalBottomSheet(
        expand: true,
        context: context,
        builder: (context) =>
            CommentInputPage(onSend: (value) => _doSendComment(value, model)));
  }

  Widget _buildBottomBar(BuildContext context, IssueCommentModel model) {
    const radius = Radius.circular(6.0);
    final backColor = context.isLight ? Colors.white : Colors.black12,
        fontColor = context.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      height: 80,
      child: Row(
        children: [
          Expanded(
            child: AdaptiveTextButton(
                color: backColor,
                borderRadius: const BorderRadius.all(radius),
                onPressed: () => _doTapCreateComment(context, model),
                child: Text(
                  '评论',
                  style: TextStyle(color: fontColor),
                )),
          ),
          // todo: 跳转与列表里面有冲突，先不管了
          const SizedBox(width: 10),
          AdaptiveIconButton(
              color: backColor,
              borderRadius:
                  const BorderRadius.only(topLeft: radius, bottomLeft: radius),
              icon: Icon(Icons.keyboard_arrow_down, color: fontColor),
              onPressed: () {
                // 位置不太对
                if (model.controller.hasClients) {
                  model.controller.position
                      .jumpTo(model.controller.position.maxScrollExtent - 1);
                }
              }),
          //VerticalDivider(width: 1, color: Colors.grey.withAlpha(52)),
          const SizedBox(width: 1),
          AdaptiveIconButton(
            color: backColor,
            borderRadius:
                const BorderRadius.only(topRight: radius, bottomRight: radius),
            onPressed: model.jumpStart,
            icon: Icon(Icons.keyboard_arrow_up, color: fontColor),
          ),
          const SizedBox(width: 10),
          AdaptiveIconButton(
            color: backColor,
            borderRadius:
                const BorderRadius.only(topRight: radius, bottomRight: radius),
            icon: Icon(Icons.adaptive.more, color: fontColor),
            onPressed: () => _onTapMore(context, model),
          ),
          // _buildMoreButton(),
        ],
      ),
    );
  }

  void _onTapMore(BuildContext context, IssueCommentModel model) {
    showCupertinoModalBottomSheet(
      expand: false,
      backgroundColor: context.theme.scaffoldBackgroundColor,
      context: context,
      builder: (context) => ChangeNotifierProvider<IssueCommentModel>.value(
        value: model,
        child: const IssueCommentMorePage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<IssueCommentModel>();

    final title =
        Text(model.issue.title, maxLines: 1, overflow: TextOverflow.ellipsis);

    final comments = context.watch<IssueCommentModel>().comments;
    return BackgroundContainer(
      child: PlatformPageScaffold(
        controller: model.controller,
        reqRefreshCallback: _init,
        materialAppBar: () => AppBar(title: title),
        cupertinoNavigationBar: () => CupertinoNavigationBar(
          middle: title,
          previousPageTitle: context.previousPageTitle,
          border: null,
        ),
        emptyItemHint: const Center(child: Text('没有数据哦')),
        itemBuilder: (BuildContext context, int index) {
          // 如果还没有数据，则显示另一种的
          if (comments.isEmpty && !model.firstDone) {
            return switch (index) {
              0 => const BottomDivider(child: CommentIssueInfo(canEdit: false)),
              1 => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: CircularProgressIndicator.adaptive(),
                ),
              _ => const SizedBox()
            };
          }
          // 有数据的时候显示的
          return switch (index) {
            0 => const BottomDivider(child: CommentIssueInfo()),
            1 => BottomDivider(
                child: Container(
                  height: 15,
                  padding: const EdgeInsets.only(left: 40), // 这个后面再调整吧，有点不准哈
                  child: const VerticalDivider(width: 1),
                ),
              ),
            2 => const BottomDivider(child: FirstCommentItem()),
            _ => CommentItem(comment: comments[index - 3])
          };
        },
        bottomBar: !model.firstDone ? null : _buildBottomBar(context, model),
        // useSeparator: true,
        itemCount: comments.length + 3,
      ),
      // ),
    );
  }
}
