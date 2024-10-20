import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:git_app/gogs_client/gogs_client.dart';
import 'package:git_app/models/repo_model.dart';
import 'package:git_app/models/user_model.dart';
import 'package:git_app/pages/repo/repo_details.dart';
import 'package:git_app/pages/user_details.dart';
import 'package:git_app/utils/build_context_helper.dart';
import 'package:git_app/utils/global_navigator.dart';
import 'package:git_app/utils/page_data.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';

/// 默认的路由
final routes = Routes();

/// 路由
class Routes {
  /// 压入页面，这里可以自定义context，像Cupertino风格时，如果不设置为当前context
  /// 他会以root context来压入
  /// [page]： 要压入的页面
  ///
  /// [context]： 当前上下文
  ///
  /// [title]： ios下可用，如果[CupertinoNavigationBar]的
  ///   [CupertinoNavigationBar.automaticallyImplyMiddle]为true且
  ///   [CupertinoNavigationBar.middle]为空，则自动填充此标题
  ///
  /// [routeSettings]：单独的路由参数设定
  ///
  /// [data]：非必须参数，用于子页通过[PageDataProvider]获取当前上下文中的仓库信息。没有时传入null即可，但这里强制用required表示，防止自己漏掉，也好有个提示。
  ///
  /// [useModal]：使用模态页面
  Future<T?> pushPage<T extends Object?>(
    Widget page, {
    BuildContext? context,
    String? title,
    RouteSettings? routeSettings,
    required PageData? data,
    bool rootNavigator = false,
    bool? useModal,
  }) {
    /// 压入路由回调函数
    ///routePage(BuildContext context) =>
    final provider = PageDataProvider(data: data, child: page);

    /// 上下文
    final ctx = context ?? GlobalNavigator.context!;
    late PageRoute<T> route;
    if (useModal ?? false) {
      route = MaterialWithModalsPageRoute(
          settings: routeSettings, builder: (_) => provider);
    } else {
      route = ctx.platformIsIOS
          ? CupertinoPageRoute(
              settings: routeSettings, builder: (_) => provider, title: title)
          : MaterialPageRoute(
              settings: routeSettings, builder: (_) => provider);
    }
    return Navigator.of(ctx, rootNavigator: rootNavigator).push(route);
  }

  /// 压入仓库详情页
  Future<T?> pushRepositoryDetailsPage<T>(BuildContext context, Repository repo,
      {required PageData? data, bool useModal = true}) {
    return routes.pushPage(
        context: context,
        //RepositoryDetailsPage(repo: repo),
        // Provider<RepositoryModel>(
        ChangeNotifierProvider<RepositoryModel>(
          create: (_) => RepositoryModel(repo),
          child: const RepositoryDetailsPage(),
        ),
        data: data,
        useModal: useModal);
  }

  /// 压入用户详情页
  Future<T?> pushUserDetailsPage<T>(BuildContext context, User user,
      {required PageData? data, bool useModal = true}) {
    return routes.pushPage(
        context: context,
        ChangeNotifierProvider<UserModel>(
          create: (_) => UserModel(user),
          child: const UserDetailsPage(),
        ),
        data: data,
        useModal: useModal);
  }
}
