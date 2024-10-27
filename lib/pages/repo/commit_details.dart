import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:git_app/utils/build_context_helper.dart';
import 'package:git_app/widgets/platform_page_scaffold.dart';

// class _CommitDetailsItem extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     // TODO: implement build
//     throw UnimplementedError();
//   }
// }

class CommitDetailsPage extends StatelessWidget {
  const CommitDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PlatformPageScaffold(
      // materialAppBar: () => AppBar(),
      // cupertinoNavigationBar: () => CupertinoNavigationBar(
      //   previousPageTitle: context.previousPageTitle,
      // ),
      appBar: PlatformPageAppBar(
        previousPageTitle: context.previousPageTitle,
      ),
      children: const [],
    );
  }
}
