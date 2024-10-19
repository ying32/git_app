import "package:flutter/material.dart";

/// 建立一个GlobalNavigator类，好封装
class GlobalNavigator {
  /// 设置相关的key，必须要调用的，用法：
  /// ```dart
  /// MaterialApp(
  ///   ...
  ///   navigatorKey: GlobalNavigator.navigatorKey,
  ///   ...
  /// );
  ///
  /// ```
  static final navigatorKey = GlobalKey<NavigatorState>();

  /// 获取全局上下文 //.currentState?.context;
  static BuildContext? get context => navigatorKey.currentContext;

  /// 当前widget
  static Widget? get widget => navigatorKey.currentWidget;

  static Future<T?> push<T extends Object?>(Route<T> route) =>
      Navigator.of(context!).push(route);

  /// 压入页面，包装好的，有时候记忆力不太好，太长了
  ///
  /// [page] 需要压入的页面
  static Future<T?> pushPage<T extends Object?>(Widget page) {
    return Navigator.of(context!).push(MaterialPageRoute(builder: (_) => page));
  }

  /// 压入页面，通过app中定义的路由路径来确定
  ///
  /// [routeName] 需要压入的路由名
  ///
  /// [arguments]要传入的参数
  static Future<T?> pushPageName<T extends Object?>(String routeName,
      {Object? arguments}) {
    return Navigator.of(context!).pushNamed(routeName, arguments: arguments);
  }

  /// 路由出栈
  ///
  /// [result] 返回结果
  static void pop<T extends Object?>([T? result]) =>
      Navigator.of(context!).pop(result);

  /// 点击任意位置关闭键盘
  static void hideKeyboard() {
    final c = context;
    if (c == null) return;
    FocusScopeNode currentFocus = FocusScope.of(c);
    if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
      FocusManager.instance.primaryFocus!.unfocus();
    }
  }
}
