import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:gogs_app/gogs_client/gogs_client.dart';
import 'package:gogs_app/utils/global_navigator.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LoginState { none, logged, exited }

class AppGlobal {
  AppGlobal._();

  static const _gogsHostKey = "gogs_host";

  static final _instance = AppGlobal._();
  static AppGlobal get instance => _instance;

  /// gogs REST客户端实例
  static GogsRESTClient get cli => _instance.client;

  /// 登录状态
  final loginState = ValueNotifier<LoginState>(LoginState.none);

  /// rest客户端实例
  final client = GogsRESTClient();

  /// 用户信息
  User? userInfo;

  /// 减少直接引用[GlobalNavigator]，方便维护
  static BuildContext? get context => GlobalNavigator.context;

  /// 初始
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    /// 懒得检查了
    client.setServerHost(prefs.getString(_gogsHostKey) ?? '');
    await client.loadToken();
  }

  Future<void> saveServerHost(String host) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_gogsHostKey, host);
  }

  static void setLoginState(bool value) {
    _instance.loginState.value = switch (value) {
      true => LoginState.logged,
      false => LoginState.exited,
    };
  }

  FutureRESTResult<User?> updateMyInfo([bool? force]) async {
    final res = await client.user.user(force);
    userInfo = res.data;
    return res;
  }

  void dispose() {
    loginState.dispose();
  }
}
