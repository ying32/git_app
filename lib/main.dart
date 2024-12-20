import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:git_app/utils/app_config.dart';
import 'package:git_app/utils/collection_mgr.dart';

import 'app.dart';
import 'app_globals.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 读配置
  await AppConfig.instance.readConfig();
  // 加载token
  await AppGlobal.instance.init();
  try {
    await CollectionMgr.instance.load(AppGlobal.cli.token);
    AppGlobal.instance.updateMyInfo(true);
    // 这里不再强制了，只要设置了token就能直接进入
    // if (!(await AppGlobal.instance.updateMyInfo(true)).succeed) {
    //   await AppGlobal.cli.unAuthorize();
    // }
    AppGlobal.setLoginState(AppGlobal.cli.isAuthorized);
  } catch (e) {
    await AppGlobal.cli.unAuthorize();
  }
  runApp(const GogsApp());
}
