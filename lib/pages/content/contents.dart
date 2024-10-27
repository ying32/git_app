import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:git_app/app_globals.dart';
import 'package:git_app/gogs_client/gogs_client.dart';
import 'package:git_app/pages/content/content_view.dart';
import 'package:git_app/routes.dart';
import 'package:git_app/utils/build_context_helper.dart';
import 'package:git_app/utils/page_data.dart';
import 'package:git_app/widgets/list_section.dart';
import 'package:remixicon/remixicon.dart';

import 'package:git_app/widgets/platform_page_scaffold.dart';
import 'package:git_app/widgets/content_title.dart';

class ContentsPage extends StatefulWidget {
  const ContentsPage({
    super.key,
    required this.repo,
    required this.path,
    required this.prevPath,
    required this.title,
    required this.ref,
  });

  /// 当前仓库
  final Repository repo;

  /// 路径
  final String path;

  /// 上一个路径，用于跳转和标题显示的
  final String prevPath;

  /// 标题
  final String title;

  /// 引用分支，如果为null则使用默认的
  final String? ref;

  @override
  State<ContentsPage> createState() => _ContentsPageState();
}

class _ContentsPageState extends State<ContentsPage> {
  ContentList? _contents;

  Future _init(_, bool? force) async {
    final res = await AppGlobal.cli.repos.content
        .getAll(widget.repo, widget.path, ref: widget.ref, force: force);
    _contents = res.data;
    _contents?.sort((left, right) {
      return left.type.compareTo(right.type);
    });
    if (mounted) setState(() {});
  }

  bool get _isRoot => widget.path == "";
  String get _title => _isRoot ? '' : widget.title;

  @override
  Widget build(BuildContext context) {
    return PlatformPageScaffold(
      reqRefreshCallback: _init,
      // materialAppBar: () => AppBar(
      //   title: ContentTitle(title: _title, path: widget.prevPath),
      //   centerTitle: true,
      // ),
      // cupertinoNavigationBar: () => CupertinoNavigationBar(
      //   middle: ContentTitle(title: _title, path: widget.prevPath),
      //   previousPageTitle: context.previousPageTitle,
      // ),
      appBar: PlatformPageAppBar(
        title: ContentTitle(title: _title, path: widget.prevPath),
        centerTitle: true,
        previousPageTitle: context.previousPageTitle,
      ),
      emptyItemHint: const Center(child: Text('没有数据哦')),
      itemBuilder: (BuildContext context, int index) {
        final item = _contents![index];

        return ListTileNav(
            leading: switch (item.type) {
              "file" => const Icon(Remix.file_line, size: 20),
              "symlink" => const Icon(Remix.line_line, size: 20),
              "dir" =>
                Icon(Icons.folder, size: 20, color: context.primaryColor),
              _ => const Icon(Icons.info_outline, size: 20)
            },
            //todo: 这里还要优化，当文本超出时，采用中间省略，而2端显示
            titleWidget:
                Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            onTap: () {
              final routeSettings =
                  RouteSettings(name: '$routeContentName/${item.path}');

              if (item.type == "dir") {
                routes.pushPage(
                  ContentsPage(
                    ref: widget.ref,
                    prevPath: widget.path,
                    repo: widget.repo,
                    path: item.path,
                    title: item.name,
                  ),
                  context: context,
                  data: PageData(previousPageTitle: _title),
                  routeSettings: routeSettings,
                );
              } else if (item.type == "file") {
                routes.pushPage(
                  ContentViewPage(
                    repo: widget.repo,
                    ref: widget.repo.defaultBranch,
                    file: item,
                    title: ContentTitle(
                      title: item.name,
                      path: widget.path,
                    ),
                  ),
                  context: context,
                  data: PageData(previousPageTitle: _title),
                  routeSettings: routeSettings,
                );
              } else if (item.type == "submodule") {
                if (kDebugMode) {
                  print("未实现");
                }
              }
            });
      },
      separatorPadding: const EdgeInsets.only(left: 60),
      useSeparator: true,
      itemCount: _contents?.length ?? 0,
    );
  }
}
