import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:git_app/utils/build_context_helper.dart';
import 'package:git_app/widgets/adaptive_widgets.dart';

const routeContentName = 'route_contents';

class _RouteInfo {
  const _RouteInfo(this.name, this.path);
  final String name;
  final String path;
  @override
  String toString() => "$name=$path\n";
}

class ContentTitle extends StatelessWidget {
  const ContentTitle({
    super.key,
    required this.title,
    required this.path,
  });

  final String title;
  final String path;

  List<_RouteInfo> _getRoutes() {
    const spChar = "/";
    final children = path.split(spChar);
    final routes = <_RouteInfo>[];
    for (int i = 0; i < children.length; i++) {
      if (children[i].isNotEmpty) {
        final sub = children.sublist(0, children.length - i);
        routes.add(_RouteInfo(children[children.length - i - 1],
            "$routeContentName$spChar${sub.join(spChar)}"));
      }
    }
    routes.add(const _RouteInfo('根目录', routeContentName));
    return routes;
  }

  void _showActionSheet(BuildContext pageContext) {
    final routes = _getRoutes();
    showCupertinoModalPopup<void>(
      context: pageContext,
      builder: (BuildContext context) => CupertinoActionSheet(
        message: const Text('跳转到...'),
        actions: routes.map((e) {
          return CupertinoActionSheetAction(
            onPressed: () {
              // iOS样式下，要手动pop当前上下文的，然后再用parent的上下文退回
              if (context.platformIsIOS) {
                Navigator.of(context).pop();
              }
              Navigator.of(pageContext).popUntil((route) {
                if (kDebugMode) {
                  print(route.settings.name);
                }
                return route.settings.name == e.path ||
                    route.settings.name == "/";
              });
            },
            child: Text(e.name),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('取消'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (path.isEmpty && title.isEmpty) return const SizedBox();
    final color = context.isDark ? Colors.white : Colors.black;
    Widget child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title,
                maxLines: 1,
                style: TextStyle(
                    overflow: TextOverflow.ellipsis,
                    color: color,
                    fontWeight: FontWeight.w600)),
            if (path.isNotEmpty)
              Text(
                path,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                ),
              ),
          ],
        ),
        Icon(Icons.arrow_drop_down, size: 16, color: color)
      ],
    );

    return AdaptiveButton(
      child: child,
      onPressed: () => _showActionSheet(context),
    );
  }
}
