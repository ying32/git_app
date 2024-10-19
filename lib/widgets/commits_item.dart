import 'package:flutter/material.dart';
import 'package:gogs_app/gogs_client/gogs_client.dart';

import 'package:gogs_app/utils/utils.dart';
import 'cached_image.dart';

class CommitsItem extends StatelessWidget {
  const CommitsItem({
    super.key,
    required this.repo,
    required this.item,
  });

  final Repository repo;
  final Commit item;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(item.commit.message,
          maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            UserHeadImage(
              size: 22,
              user: item.author,
              // imageURL: item.author.avatarUrl,
              padding: const EdgeInsets.all(1),
            ),
            const SizedBox(width: 10),
            Text(item.commit.author.name),
          ],
        ),
      ),
      trailing: Text(timeToLabel(item.commit.committer.date),
          style: const TextStyle(fontSize: 12)),
    );
  }
}
