import 'package:flutter/material.dart';
import 'package:git_app/app_globals.dart';
import 'package:git_app/gogs_client/gogs_client.dart';
import 'package:git_app/models/issue_comment_model.dart';
import 'package:git_app/utils/build_context_helper.dart';
import 'package:git_app/utils/message_box.dart';
import 'package:git_app/widgets/adaptive_widgets.dart';
import 'package:git_app/widgets/background_container.dart';
import 'package:git_app/widgets/cached_image.dart';
import 'package:provider/provider.dart';
import 'package:remixicon/remixicon.dart';

class CommentIssueInfo extends StatelessWidget {
  const CommentIssueInfo({super.key});

  Future<void> _doTapMore(BuildContext context) async {
    final model = context.read<IssueCommentModel>();
    final controller = TextEditingController(text: model.issue.title);
    try {
      final res = await showAdaptiveDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog.adaptive(
              title: const Text('修改标题'),
              content: AdaptiveTextField(
                controller: controller,
                autofocus: true,
                maxLines: null,
                // useUnderlineInputBorder: false,
              ),
              actions: [
                AdaptiveButton(
                  child: Text(context.platformIsIOS ? '好' : '确定'),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
                AdaptiveButton(
                  child: const Text('取消'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            );
          });
      // 确定修改，如果未改变则不提交
      final text = controller.text.trim();
      if (res == true && text != model.issue.title) {
        final result = await AppGlobal.cli.issues
            .edit(model.repo, model.issue, title: text);
        if (result.succeed) {
          model.issue = model.issue
              .copyWith(title: text, updatedAt: result.data?.updatedAt);
        } else {
          showToast(result.statusMessage ?? '未知错误');
        }
      }
    } finally {
      controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundContainer(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Selector<IssueCommentModel, Issue>(
          selector: (_, model) => model.issue,
          builder: (_, issue, __) {
            final color = issue.isOpen ? Colors.green : Colors.red;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    UserHeadImage(
                        size: 22,
                        user: issue.user,
                        radius: 2,
                        padding: const EdgeInsets.all(1)),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text.rich(TextSpan(
                        text: context.read<IssueCommentModel>().repo.fullName,
                        children: [
                          TextSpan(
                              text: " #${issue.number}",
                              style: const TextStyle(color: Colors.grey)),
                        ],
                      )),
                    ),

                    /// 显示编辑
                    if (issue.user.username ==
                        AppGlobal.instance.userInfo?.username)
                      AdaptiveIconButton(
                          //icon: Icon(Icons.adaptive.more),
                          icon: const Icon(Remix.edit_2_line, size: 20),
                          onPressed: () => _doTapMore(context)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(issue.title,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: color.withAlpha(100),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 2, horizontal: 5),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.info_outlined, size: 16, color: color),
                      const SizedBox(width: 5),
                      Text(issue.isOpen ? '开启中' : '已关闭',
                          style: TextStyle(color: color))
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
