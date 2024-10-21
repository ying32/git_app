import 'package:flutter/material.dart';
import 'package:git_app/gogs_client/gogs_client.dart';
import 'package:git_app/routes.dart';
import 'package:git_app/utils/page_data.dart';

import 'cached_image.dart';
import 'list_section.dart';

class RepositoryItem extends StatelessWidget {
  const RepositoryItem({
    super.key,
    required this.repo,
    required this.previousPageTitle,
  });

  final Repository repo;
  final String? previousPageTitle;

  @override
  Widget build(BuildContext context) {
    Widget leading = UserHeadImage.lock(
      user: repo.owner,
      // imageURL: item.owner.avatarUrl,
      radius: 3,
      padding: const EdgeInsets.all(3),
      size: 50,
      showLockIcon: repo.private,
    );
    return ListTileNav(
      onTap: () {
        routes.pushRepositoryDetailsPage(
          context,
          repo,
          data: PageData(previousPageTitle: previousPageTitle),
        );
        // AppGlobal.pushModalPage(
        //     RepositoryDetailsPage(
        //       repo: item,
        //     ),
        //     context: context,
        //     previousPageTitle: _isMyRepos ? null : widget.title);
      },
      leading: leading,
      title: repo.fullName,
      subtitle:
          Text(repo.description, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}
