import 'package:flutter/material.dart';
import 'package:git_app/gogs_client/gogs_client.dart';
import 'package:git_app/pages/repo/commit_details.dart';
import 'package:git_app/routes.dart';
import 'package:git_app/utils/page_data.dart';

import 'package:git_app/utils/utils.dart';
import 'package:git_app/widgets/list_section.dart';
import 'cached_image.dart';

class CommitsItem extends StatelessWidget {
  const CommitsItem({
    super.key,
    required this.repo,
    required this.item,
  });

  final Repository repo;
  final Commit item;

  void _doTap() {
    routes.pushPage(
        CommitDetailsPage(
          repo: repo,
          commit: item,
        ),
        data: PageData(previousPageTitle: repo.name));
  }

  @override
  Widget build(BuildContext context) {
    return ListTileNav(
      titleWidget: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Text(item.commit.message.trimRight(),
            maxLines: 2, overflow: TextOverflow.ellipsis),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(bottom: 8.0, top: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            UserHeadImage(
              size: 22,
              user: item.author,
              padding: const EdgeInsets.all(1),
            ),
            const SizedBox(width: 10),
            Text(item.commit.author.name),
          ],
        ),
      ),
      trailing: Text(timeToLabel(item.commit.committer.date),
          style: const TextStyle(fontSize: 12)),
      onTap: _doTap,
    );
  }
}
