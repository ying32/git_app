import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gogs_app/gogs_client/gogs_client.dart';
import 'package:gogs_app/routes.dart';
import 'package:gogs_app/utils/build_context_helper.dart';
import 'package:gogs_app/utils/page_data.dart';
import 'package:gogs_app/widgets/adaptive_widgets.dart';

import 'package:gogs_app/app_globals.dart';

class CachedImage extends StatelessWidget {
  const CachedImage({
    super.key,
    required this.url,
  });

  final String url;

  @override
  Widget build(BuildContext context) {
    // 也不知道为啥他头像返回的url与其它都不一样
    final bi = AppGlobal.cli.baseUri;
    final newURL = Uri.tryParse(url)
        ?.replace(scheme: bi.scheme, host: bi.host, port: bi.port)
        .toString();

    return CachedNetworkImage(
      fit: BoxFit.cover,
      imageUrl: newURL ?? url,
      errorWidget: (context, url, error) => LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return Icon(
            Icons.error_outline,
            color: context.primaryColor,
            size: constraints.maxHeight,
          );
        },
      ),
    );
  }
}

enum _UserHeadStyle { none, lock }

class UserHeadImage extends StatelessWidget {
  const UserHeadImage({
    super.key,
    required this.size,
    this.user,
    this.padding,
    this.radius,
    this.splashRadius,
    this.previousPageTitle,
  })  : _style = _UserHeadStyle.none,
        iconColor = null,
        showLockIcon = false;

  /// widget的尺寸
  final double size;

  /// 要显示的user信息，如果为null则使用登录用户的
  final User? user;

  /// 弧度
  final double? radius;

  /// material控件按下时的弧度
  final double? splashRadius;

  /// 内容padding
  final EdgeInsetsGeometry? padding;

  /// 下一页标题，如果不为null则响应tap事件，并压入到user详情页
  final String? previousPageTitle;

  final _UserHeadStyle _style;

  /// 如果为lock的时icon的颜色
  final Color? iconColor;

  /// 是否显示lock标识
  final bool showLockIcon;

  const UserHeadImage.lock({
    super.key,
    required this.size,
    this.user,
    this.padding,
    this.radius,
    this.splashRadius,
    this.iconColor,
    this.showLockIcon = true,
    this.previousPageTitle,
  }) : _style = _UserHeadStyle.lock;

  void _doTap(BuildContext context) {
    var u = user ?? AppGlobal.instance.userInfo;
    if (u == null) return;
    // 因为没有将所有的user信息打补丁，所以这里判断下
    if (u.id == AppGlobal.instance.userInfo?.id) {
      u = AppGlobal.instance.userInfo!;
    }
    routes.pushUserDetailsPage(
      context,
      u,
      data: PageData(previousPageTitle: previousPageTitle),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget child = Padding(
      padding: padding ?? const EdgeInsets.all(6.0),
      child: CachedImage(
        url: (user ?? AppGlobal.instance.userInfo)?.avatarUrl ?? '',
      ),
    );
    final borderRadius = BorderRadius.circular(radius ?? size / 2);
    if (previousPageTitle != null) {
      child =
          AdaptiveButton.icon(onPressed: () => _doTap(context), child: child);
    }

    if (_style == _UserHeadStyle.lock && showLockIcon) {
      child = Stack(
        //  fit: StackFit.loose,
        children: [
          child,
          Align(
            alignment: Alignment.bottomRight,
            child: Icon(Icons.lock_rounded,
                size: 14, color: iconColor ?? context.colorScheme.outline),
          )
        ],
      );
    }

    return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
            color: const Color.fromARGB(200, 227, 228, 232),
            borderRadius: borderRadius),
        child: Center(child: child));
  }
}
