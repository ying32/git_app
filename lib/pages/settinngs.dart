import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gogs_app/app_globals.dart';
import 'package:gogs_app/models/app_model.dart';
import 'package:gogs_app/utils/app_config.dart';
import 'package:gogs_app/utils/build_context_helper.dart';
import 'package:gogs_app/utils/message_box.dart';
import 'package:gogs_app/widgets/list_section.dart';

import 'package:gogs_app/widgets/platform_page_scaffold.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _dartMode = false;

  @override
  void initState() {
    super.initState();
    _dartMode = AppConfig.instance.themeMode == ThemeMode.dark;
  }

  void _doSetDartMode(bool value) {
    setState(() {
      _dartMode = value;
      final mode = _dartMode ? ThemeMode.dark : ThemeMode.light;
      context.read<AppModel>().themeMode = mode;
      AppConfig.instance.themeMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PlatformPageScaffold(
      materialAppBar: () => AppBar(
        title: const Text('设置'),
      ),
      cupertinoNavigationBar: () => CupertinoNavigationBar(
        middle: const Text('设置'),
        previousPageTitle: context.previousPageTitle,
      ),
      children: [
        CupertinoFormSection(
          children: [
            ListTileNav(
              title: '暗黑模式',
              trailing:
                  Switch.adaptive(value: _dartMode, onChanged: _doSetDartMode),
            ),
          ],
        ),
        Center(
          child: TextButton.icon(
              onPressed: () {
                AppGlobal.cli.unAuthorize().then((value) {
                  AppGlobal.setLoginState(false);
                  showToast('已退出登录');
                });
              },
              icon: const Icon(Icons.exit_to_app),
              label: const Text('退出登录')),
        ),
      ],
    );
  }
}
