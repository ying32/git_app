import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:git_app/gogs_client/gogs_client.dart';

import 'package:git_app/app_globals.dart';
import 'package:git_app/routes.dart';
import 'package:git_app/utils/build_context_helper.dart';
import 'package:git_app/utils/page_data.dart';
import 'package:git_app/widgets/cached_image.dart';
import 'package:git_app/widgets/platform_page_scaffold.dart';
import 'package:git_app/widgets/list_section.dart';

class OrganizationsPage extends StatefulWidget {
  const OrganizationsPage({
    super.key,
    this.title = '组织',
    required this.user,
  });

  /// 标题
  final String title;

  /// 用户信息
  final User user;

  @override
  State<OrganizationsPage> createState() => _OrganizationsPageState();
}

class _OrganizationsPageState
    extends State<OrganizationsPage> /*with AutomaticKeepAliveClientMixin*/ {
  OrganizationList? _orgs;

  Future<void> _init(_, bool? force) async {
    final res = AppGlobal.isMe(widget.user)
        ? await AppGlobal.cli.user.orgs(force)
        : await AppGlobal.cli.user.usersOrgs(widget.user, force);
    _orgs = res.data;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    //super.build(context);

    return PlatformPageScaffold(
      reqRefreshCallback: _init,
      materialAppBar: () => AppBar(
        title: Text(widget.title),
      ),
      // cupertinoNavigationBar: () => CupertinoNavigationBar(
      //   middle: Text(widget.title),
      //   previousPageTitle: PageRouteData.maybeOf(context)?.previousPageTitle,
      // ),

      cupertinoSliverNavigationBar: () => CupertinoSliverNavigationBar(
        previousPageTitle: context.previousPageTitle,
        largeTitle: Text(widget.title),
      ),

      itemCount: _orgs?.length ?? 0,
      separatorPadding: const EdgeInsets.only(left: 60),

      itemBuilder: (_, index) {
        final item = _orgs![index];
        return ListTileNav(
          onTap: () {
            routes.pushUserDetailsPage(
              context,
              item,
              data: PageData(
                  previousPageTitle:
                      AppGlobal.isMe(widget.user) ? null : widget.title),
            );
          },
          leading: UserHeadImage(
            user: item,
            radius: 3,
            padding: const EdgeInsets.all(3),
            size: 50,
          ),
          title: item.username,
          subtitle: Text(item.description,
              maxLines: 1, overflow: TextOverflow.ellipsis),
        );
      },
      useSeparator: true,
      emptyItemHint: const Center(child: Text('没有加入任何组织')),
      // children:
      //     ? []
      //     : null,
    );
  }

  // @override
  // bool get wantKeepAlive => false;
}
