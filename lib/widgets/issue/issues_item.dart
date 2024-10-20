import 'package:flutter/material.dart';
import 'package:git_app/gogs_client/gogs_client.dart';
import 'package:git_app/models/issue_comment_model.dart';
import 'package:git_app/routes.dart';
import 'package:git_app/utils/build_context_helper.dart';

import 'package:git_app/pages/issue/issue_comments_view.dart';
import 'package:git_app/utils/message_box.dart';
import 'package:git_app/utils/utils.dart';
import 'package:provider/provider.dart';

import 'labels.dart';

class IssuesItem extends StatelessWidget {
  const IssuesItem({
    super.key,
    required this.item,
    required this.repo,
  });

  final Issue item;
  final Repository? repo;

  @override
  Widget build(BuildContext context) {
    Widget child = Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis),
    );
    if (item.labels?.isNotEmpty ?? false) {
      child = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          child,
          IssueLabels(labels: item.labels!),
        ],
      );
    }
    return ListTile(
      leading: item.isOpen
          ? const Icon(Icons.info_outline, color: Colors.green)
          : const Icon(Icons.info_outlined, color: Colors.red),
      titleTextStyle: context.theme.textTheme.bodyMedium
          ?.copyWith(color: context.colorScheme.onSurfaceVariant),
      subtitleTextStyle: context.theme.textTheme.bodyLarge?.copyWith(
          fontSize: context.theme.textTheme.bodyLarge!.fontSize! + 2,
          fontWeight: FontWeight.w500),
      title: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Text("${repo?.fullName} #${item.number}",
            maxLines: 2, overflow: TextOverflow.ellipsis),
      ),
      subtitle: child,
      trailing: SizedBox(
        width: 60,
        child: Column(
          children: [
            Text(timeToLabel(item.updatedAt),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12)),
            if (item.comments > 0) ...[
              const SizedBox(height: 5),
              Container(
                decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(128),
                    borderRadius: BorderRadius.circular(2)),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
                  child: Text('${item.comments}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12)),
                ),
              )
            ],
          ],
        ),
      ),
      onTap: () {
        if (repo == null) {
          showToast('没有仓库信息，无法跳转');
          return;
        }
        routes.pushPage(
            ChangeNotifierProvider<IssueCommentModel>(
                create: (_) {
                  final model = IssueCommentModel();
                  model.issue = item;
                  model.repo = repo!;
                  return model;
                },
                child: const IssuesCommentsViewPage(
                    // repo: repo, item: item
                    )),
            data: null);
        // routes.pushModalPage(IssuesCommentsViewPage(repo: repo, item: item),
        //     previousPageTitle: null);
      },
    );
  }
}
