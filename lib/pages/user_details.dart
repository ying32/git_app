import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:gogs_app/app_globals.dart';
import 'package:gogs_app/gogs_client/gogs_client.dart';
import 'package:gogs_app/models/user_model.dart';
import 'package:gogs_app/pages/organizations.dart';
import 'package:gogs_app/pages/repo/repositories.dart';
import 'package:gogs_app/pages/settinngs.dart';
import 'package:gogs_app/routes.dart';
import 'package:gogs_app/utils/build_context_helper.dart';
import 'package:gogs_app/utils/message_box.dart';
import 'package:gogs_app/utils/page_data.dart';
import 'package:gogs_app/widgets/adaptive_widgets.dart';

import 'package:gogs_app/widgets/background_icon.dart';
import 'package:gogs_app/widgets/list_section.dart';
import 'package:provider/provider.dart';

import 'package:remixicon/remixicon.dart';

import 'package:gogs_app/widgets/background_container.dart';
import 'package:gogs_app/widgets/cached_image.dart';
import 'package:gogs_app/widgets/platform_page_scaffold.dart';

class UserDetailsPage extends StatelessWidget {
  const UserDetailsPage({super.key});

  Widget _buildUserInfo(User user, Color iconColor) {
    return BackgroundContainer(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: Row(
              children: [
                const UserHeadImage(size: 60, radius: 3),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: const TextStyle(fontSize: 22),
                      ),
                      const SizedBox(height: 5),
                      Text(user.username),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (user.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: Text(
                user.description,
                textAlign: TextAlign.start,
              ),
            ),

          /// 状态信息
          /// 签名信息
          /// 位置 + link
          Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: Text.rich(TextSpan(children: [
              if (user.location.isNotEmpty)
                TextSpan(children: [
                  WidgetSpan(
                      child:
                          Icon(Remix.map_pin_line, size: 20, color: iconColor)),
                  const WidgetSpan(child: SizedBox(width: 5)),
                  TextSpan(text: user.location),
                  const WidgetSpan(child: SizedBox(width: 15)),
                ]),
              if (user.website.isNotEmpty)
                TextSpan(
                  children: [
                    WidgetSpan(
                        child:
                            Icon(Remix.links_line, size: 20, color: iconColor)),
                    const WidgetSpan(child: SizedBox(width: 5)),
                    TextSpan(
                      text: user.website,
                      style: const TextStyle(color: Colors.blue),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          if (kDebugMode) {
                            print("ok");
                          }
                        },
                    ),
                  ],
                  //  mouseCursor: MouseCursor.uncontrolled,
                ),
            ])),
          ),

          /// email
          if (user.email.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: Text.rich(TextSpan(children: [
                WidgetSpan(
                    child:
                        Icon(Icons.email_outlined, size: 20, color: iconColor)),
                const WidgetSpan(child: SizedBox(width: 5)),
                TextSpan(text: user.email),
              ])),
            ),

          Text.rich(TextSpan(children: [
            WidgetSpan(
                child: Icon(Remix.account_circle_line,
                    size: 20, color: iconColor)),
            const WidgetSpan(child: SizedBox(width: 5)),
            TextSpan(text: '${user.followersCount} 关注者 - '),
            TextSpan(text: '${user.followingCount} 关注中'),
          ])),
        ],
      ),
    );
  }

  Future<void> _init(_, bool? force) async {}

  void _doSettingsPressed(BuildContext context, User user) {
    routes.pushPage(
      const SettingsPage(),
      context: context,
      data: PageData(previousPageTitle: user.username),
    );
  }

  void _doSharedPressed() {
    //todo: 待实现
    showToast('没做呢');
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserModel>().user;
    final iconColor = context.colorScheme.outline;
    // 是否为自己
    final isMe = user.id == AppGlobal.instance.userInfo?.id;
    List<Widget>? rights;
    if (isMe) {
      rights = [
        AdaptiveIconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _doSettingsPressed(context, user)),
        AdaptiveIconButton(
            icon: Icon(Icons.adaptive.share), onPressed: _doSharedPressed)
      ];
    }

    return PlatformPageScaffold(
      reqRefreshCallback: _init,
      materialAppBar: () => AppBar(
        title: Text(user.username),
        actions: rights,
      ),
      cupertinoNavigationBar: () => CupertinoNavigationBar(
        middle: Text(user.username),
        previousPageTitle: context.previousPageTitle,
        trailing: rights != null
            ? Row(mainAxisSize: MainAxisSize.min, children: rights)
            : null,
      ),
      children: [
        _buildUserInfo(user, iconColor),
        // const SizedBox(height: 15),
        // _buildPinned(color),
        const SizedBox(height: 15),
        ListSection(
          showTopBottomLine: true,
          children: [
            if (user.reposCount > 0)
              ListTileNav(
                leading: const BackgroundIcon(
                  icon: Remix.git_repository_line,
                  color: Colors.deepPurpleAccent,
                ),
                title: '仓库',
                additionalInfo: Text("${user.reposCount}",
                    style: TextStyle(color: iconColor)),
                onTap: () => routes.pushPage(
                  RepositoriesPage(
                    user: user,
                  ),
                  context: context,
                  data: PageData(previousPageTitle: user.username),
                ),
              ),

            // 这里还不太对哈，
            // if (!user.isOrg) ...[
            //   ListTileNav(
            //     leading: const BackgroundIcon(
            //       icon: Remix.star_line, //Icons.star_border,
            //       color: Colors.yellow,
            //     ),
            //     title: '点赞',
            //     additionalInfo: Text("${user.starCount}",
            //         style: TextStyle(color: iconColor)),
            //     // onTap: () => AppGlobal.pushPage(const OrganizationsPage(),
            //     //    context: context, previousPageTitle: _user.username),
            //   ),
            //   ListTileNav(
            //     leading: const BackgroundIcon(
            //       icon: Remix.organization_chart,
            //       color: Colors.orange,
            //     ),
            //     title: '组织',
            //     additionalInfo: Text('1', style: TextStyle(color: iconColor)),
            //     onTap: () => routes.pushPage(
            //       OrganizationsPage(
            //         user: user,
            //       ),
            //       context: context,
            //       data: PageData(previousPageTitle: user.username),
            //     ),
            //   ),
            // ],
          ],
        ),
      ],
    );
  }
}
