import 'package:flutter/widgets.dart';

/// 页面数据
class PageData {
  const PageData({
    this.previousPageTitle,
  });

  /// [previousPageTitle]： ios下可用，用于传递当页面给[CupertinoNavigationBar.previousPageTitle]
  final String? previousPageTitle;

  PageData copyWith({String? previousPageTitle}) => PageData(
        previousPageTitle: previousPageTitle ?? this.previousPageTitle,
      );
}

/// 用于上下文件中获取的
class PageDataProvider extends InheritedWidget {
  const PageDataProvider({
    super.key,
    this.data,
    required super.child,
  });

  /// 提供的数据
  final PageData? data;

  static PageDataProvider? maybeOf(BuildContext context) {
    // return context.getInheritedWidgetOfExactType<PageRouteData>();
    return context.dependOnInheritedWidgetOfExactType<PageDataProvider>();
  }

  static PageDataProvider of(BuildContext context) {
    final PageDataProvider? result = maybeOf(context);
    assert(result != null, 'No PageDataProvider found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(PageDataProvider oldWidget) => data != oldWidget.data;
}
