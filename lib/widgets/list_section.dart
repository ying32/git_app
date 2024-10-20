import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:git_app/utils/build_context_helper.dart';

import 'background_container.dart';

class ListSection extends StatelessWidget {
  const ListSection({
    super.key,
    required this.children,
    this.backgroundColor,
    this.radius,
    this.showTopBottomLine = false,
    this.dividerMargin = 60,
  });

  final List<Widget> children;
  final Color? backgroundColor;
  final double? radius;
  final bool showTopBottomLine;
  final double dividerMargin;

  List<Widget> _buildItems() {
    final max = math.max(0, children.length * 2 - 1);
    final line = ListTileDivider(left: dividerMargin, right: 0);
    final items = <Widget>[];
    for (var i = 0; i < max; i++) {
      final int index = i ~/ 2;
      if (i.isEven) {
        items.add(children[index]);
      } else {
        items.add(line);
      }
    }
    if (showTopBottomLine) {
      items.insert(0, const ListTileDivider(left: 0, right: 0));
      items.add(const ListTileDivider(left: 0, right: 0));
    }
    return items;
  }

  @override
  Widget build(BuildContext context) => BackgroundContainer(
      color: backgroundColor,
      radius: radius,
      child: Column(children: _buildItems()));
}

class ListTileDivider extends StatelessWidget {
  const ListTileDivider(
      {super.key, this.left = 60.0, this.right = 1.0, this.width = 1.0});

  final double left;
  final double right;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.only(left: left, right: right),
        child: Divider(height: width));
  }
}

class ListTileNav extends StatelessWidget {
  const ListTileNav({
    super.key,
    this.title = "",
    this.titleWidget,
    this.leading,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.additionalInfo,
  });

  /// 最左边的
  final Widget? leading;

  /// 这个部件与[title]其实是一样的，如果这个不为null则使用它，反正之作用[title]属性。
  final Widget? titleWidget;

  /// 标题
  final String title;

  /// 子标题
  final Widget? subtitle;

  /// tap事件
  final VoidCallback? onTap;

  /// 尾部
  final Widget? trailing;

  /// 一个位于trailing之前的附加
  final Widget? additionalInfo;

  @override
  Widget build(BuildContext context) {
    final isIOS = context.platformIsIOS;

    Widget trailing = this.trailing ??
        (isIOS
            ? const CupertinoListTileChevron()
            : const Icon(Icons.navigate_next, color: Colors.grey));

    if (additionalInfo != null && !isIOS) {
      trailing = Row(
          mainAxisSize: MainAxisSize.min,
          children: [additionalInfo!, trailing]);
    }

    return isIOS
        ? CupertinoListTile(
            onTap: onTap,
            leading: leading,
            title: titleWidget ?? Text(title),
            subtitle: subtitle,
            trailing: trailing,
            additionalInfo: additionalInfo,
          )
        : Material(
            type: MaterialType.transparency,
            child: ListTile(
              onTap: onTap,
              leading: leading,
              title: titleWidget ?? Text(title),
              subtitle: subtitle,
              trailing: trailing,
            ),
          );
  }
}
