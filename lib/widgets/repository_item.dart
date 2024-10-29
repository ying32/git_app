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
    this.rootNavigator = false,
  });

  final Repository repo;
  final String? previousPageTitle;
  final bool rootNavigator;

  @override
  Widget build(BuildContext context) {
    Widget leading = UserHeadImage.lock(
      user: repo.owner,
      radius: 3,
      padding: const EdgeInsets.all(3),
      size: 50,
      showLockIcon: repo.private,
    );
    return ListTileNav(
      onTap: () {
        routes.pushRepositoryDetailsPage(
          repo,
          context: rootNavigator ? null : context,
          data: PageData(previousPageTitle: previousPageTitle),
        );
      },
      leading: leading,
      title: repo.fullName,
      subtitle:
          Text(repo.description, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}
