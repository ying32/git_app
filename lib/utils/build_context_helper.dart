import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gogs_app/utils/page_data.dart';

extension BuildContextHelper on BuildContext {
  /// 主题
  ThemeData get theme => Theme.of(this);

  ColorScheme get colorScheme => theme.colorScheme;

  /// cupertino
  CupertinoThemeData get cupertinoTheme => CupertinoTheme.of(this);

  /// 是否为暗黑模式
  bool get isDark => colorScheme.brightness == Brightness.dark;

  /// 是否为明亮模式
  bool get isLight => colorScheme.brightness == Brightness.light;

  /// 主题主色
  Color? get primaryColor => colorScheme.primary;

  /// 当前主题平台定义
  TargetPlatform get platform => theme.platform;

  /// 是否为iOS平台
  bool get platformIsIOS => platform == TargetPlatform.iOS;

  /// 上下文件中的数据
  PageData? get pageData => PageDataProvider.maybeOf(this)?.data;

  /// 上一页标题
  String? get previousPageTitle {
    final title = pageData?.previousPageTitle ?? '返回';
    // 最大只支持12个字段
    if (title.length > 12) {
      return "${title.substring(0, 5)}...${title.substring(title.length - 4)}";
    }
    return title;
  }
}
