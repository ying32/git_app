import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:git_app/utils/build_context_helper.dart';
import 'package:git_app/utils/collection_mgr.dart';
import 'package:git_app/utils/message_box.dart';

import 'package:remixicon/remixicon.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:git_app/app_globals.dart';
import 'package:git_app/widgets/adaptive_widgets.dart';
import 'package:git_app/widgets/platform_page_scaffold.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final TextEditingController _userController;
  late final TextEditingController _passwordController;
  late final TextEditingController _hostController;

  /// token登录，无用户名和密码的
  static const _useToken = true;
  static const _historyKey = "host_history";
  static const _tokenGenerateLocationTip = '“用户设置”->“授权应用”->“生成新的令牌”';

  final _logging = ValueNotifier(false);

  final Map<String, dynamic> _histories = {};

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _userController = TextEditingController();
    _passwordController = TextEditingController();
    _hostController = TextEditingController();
    if (kDebugMode) {
      _userController.text = _useToken ? AppGlobal.cli.token : "ying32";
      _passwordController.text = "123";
      _hostController.text = AppGlobal.cli.host;
    }
  }

  @override
  void dispose() {
    _hostController.dispose();
    _passwordController.dispose();
    _userController.dispose();
    super.dispose();
  }

  Future _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_historyKey);
    if (str != null && str.isNotEmpty) {
      if (mounted) {
        setState(() {
          _histories.clear();
          _histories.addAll(jsonDecode(str));
        });
      }
    }
  }

  Future _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_historyKey, jsonEncode(_histories));
  }

  Widget _buildHistoryButton(String key) {
    final value = _histories[key];
    if (value == null) return const SizedBox();
    final u = Uri.tryParse('$value');
    var title = u?.host ?? value;
    if (u?.port != null && u!.port != 80) {
      title = "$title:${u.port}";
    }
    return SizedBox(
      height: 30,
      child: AdaptiveButton.outlined(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Text(title),
          onPressed: () {
            // token or userName
            _userController.text = key;
            // host
            _hostController.text = value;
          }),
    );
  }

  Widget _buildLoginWidget() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        // mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: SizedBox(
                width: 64,
                height: 64,
                child: Image.asset("assets/images/logo.png")),
          ),
          const SizedBox(height: 20),
          _buildTextField(
            autofocus: true,
            controller: _userController,
            prefixIcon: _useToken
                ? const Icon(Remix.shield_user_line)
                : const Icon(Icons.account_circle),
            hintText: _useToken ? 'token，一个40长度的字符串' : '用户名',
            suffixIcon: IconButton(
                onPressed: () => _userController.clear(),
                icon: const Icon(Icons.clear)),
          ),
          if (!_useToken) ...[
            const SizedBox(height: 20),
            _buildTextField(
              controller: _passwordController,
              prefixIcon: const Icon(Icons.lock),
              hintText: '密码',
              obscureText: true,
            ),
          ] else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 5),
              child: Text(_tokenGenerateLocationTip,
                  style: TextStyle(color: Colors.green)),
            ),
          const SizedBox(height: 20),
          _buildTextField(
            autofocus: true,
            controller: _hostController,
            prefixIcon: const Icon(Remix.server_line),
            hintText: '服务端地址，如：http://192.168.1.22:3000',
            suffixIcon: IconButton(
                onPressed: () => _hostController.clear(),
                icon: const Icon(Icons.add)),
          ),
          const SizedBox(height: 20.0),
          const Text('历史登录'),
          const SizedBox(height: 5.0),
          Wrap(
            runSpacing: 5.0,
            spacing: 5.0,
            children:
                _histories.keys.map((key) => _buildHistoryButton(key)).toList(),
          ),
          const SizedBox(height: 20),
          Center(
            child: ValueListenableBuilder(
              valueListenable: _logging,
              builder: (BuildContext context, bool value, Widget? child) {
                return AdaptiveButton.outlined(
                  onPressed: !value ? _doLogin : null,
                  color: context.primaryColor,
                  width: 200,
                  child: value
                      ? const CircularProgressIndicator.adaptive()
                      : const Text(
                          '登录',
                          style: TextStyle(color: Colors.white),
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future _doLogin() async {
    final host = _hostController.text.trim();
    if (host.isEmpty) {
      showToast('主机地址未设置');
      return;
    }
    if (!host.startsWith(RegExp(r"http://|https://", caseSensitive: false))) {
      showToast('主机地址设置不正确');
      return;
    }
    AppGlobal.cli.setServerHost(host);
    await AppGlobal.cli.unAuthorize();
    AppGlobal.instance.saveServerHost(host);

    final userName = _userController.text.trim();
    if (userName.isEmpty) {
      showToast(_useToken ? '没有输入token' : '没有用户名');
      return;
    }
    if (_useToken && userName.length != 40) {
      showToast('token长度不正确');
      return;
    }

    _logging.value = true;
    try {
      String? token;
      if (!_useToken) {
        final password = _passwordController.text.trim();
        if (password.isEmpty) {
          showToast('没有输入密码');
          return;
        }
        final tokens =
            await AppGlobal.cli.user.tokens(userName, password, force: true);
        token = tokens.data?.firstOrNull?.sha1;
      } else {
        token = userName;
      }

      if (token?.isEmpty ?? true) {
        _showTokenSettingsMessage();
        return;
      }
      AppGlobal.cli.authorize(token!);
      // 获取个人信息
      final res = await AppGlobal.instance.updateMyInfo(true);
      if (!res.succeed) {
        AppGlobal.cli.unAuthorize();
        final err = res.statusMessage == "Unauthorized"
            ? '认证失败，${_useToken ? 'token不正确' : '用户名或密码错误'}'
            : res.statusMessage;

        showMessage("$err", title: '登录失败');
        // SmartDialog.showNotify(
        //     msg: '登录失败: $err', notifyType: NotifyType.failure);
        return;
      }
      _histories[token] = _hostController.text.trim();
      _saveHistory();
      // 重新加载收藏的
      await CollectionMgr.instance.reLoad(token);
      AppGlobal.setLoginState(true);

      SmartDialog.showNotify(msg: '登录成功，欢迎回来', notifyType: NotifyType.success);
    } finally {
      _logging.value = false;
    }
  }

  Future<void> _showTokenSettingsMessage() {
    return showMessage('没有获取到有效的token，请在Web页面：$_tokenGenerateLocationTip中生成。',
        title: 'Token设置方法');
  }

  Widget _buildTextField({
    bool autofocus = false,
    required TextEditingController controller,
    Widget? prefixIcon,
    String? hintText,
    Widget? suffixIcon,
    bool? obscureText,
  }) {
    return AdaptiveTextField(
      autofocus: autofocus,
      controller: controller,
      prefixIcon: prefixIcon,

      suffixIcon: context.platformIsIOS ? null : suffixIcon,
      obscureText: obscureText ?? false,
      placeholder: hintText,
      clearButtonMode: OverlayVisibilityMode.always,
      useUnderlineInputBorder: true,
      // suffix: suffixIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PlatformPageScaffold(
      materialAppBar: () => AppBar(
        title: const Text('登录'),
      ),
      cupertinoNavigationBar: () => CupertinoNavigationBar(
        middle: const Text('登录'),
        previousPageTitle: context.previousPageTitle,
        border: null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 30.0),
      child: Center(child: _buildLoginWidget()),
    );
  }
}
