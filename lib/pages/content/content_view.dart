import 'dart:async';

import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_highlight/themes/a11y-dark.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:git_app/gogs_client/gogs_client.dart';
import 'package:git_app/widgets/highlight_plus.dart';
import 'package:git_app/utils/build_context_helper.dart';
import 'package:git_app/utils/utils.dart';
import 'package:git_app/widgets/markdown.dart';
import 'package:path/path.dart' as path_lib;
import 'package:git_app/app_globals.dart';
import 'package:git_app/widgets/platform_page_scaffold.dart';

// const _jpegHeader = [0xFF, 0xD8, 0xFF];
// const tiffHeader1 = [0x49, 0x49, 0x2A];
// const tiffHeader2 = [0x4D, 0x4D, 0x2A];
// const tiffHeader3 = [0x4D, 0x4D, 0x00];
// const pngHeader = [0x89, 0x50, 0x4E, 0x47];
// const bmpHeader = [0x42, 0x4D];
// const gifHeader = [0x47, 0x49, 0x46];
//
// bool _compareBytes(List<int> data1, List<int> data2) {
//   final count = math.min(data1.length, data2.length);
//   for (int i = 0; i < count; i++) {
//     if (data1[i] != data2[i]) return false;
//   }
//   return true;
// }

/// 判断file类型
// bool _isImage(List<int> data) {
//   return _compareBytes(data, _jpegHeader) ||
//       _compareBytes(data, tiffHeader1) ||
//       _compareBytes(data, tiffHeader2) ||
//       _compareBytes(data, tiffHeader3) ||
//       _compareBytes(data, pngHeader) ||
//       _compareBytes(data, bmpHeader) ||
//       _compareBytes(data, gifHeader);
// }

class ContentViewPage extends StatefulWidget {
  const ContentViewPage({
    super.key,
    this.title,
    required this.file,
    required this.repo,
    required this.ref,
  });

  /// 文件内容信息
  final Content file;

  /// 外部传过来的标题widget
  final Widget? title;

  /// 当前仓库
  final Repository repo;

  /// 引用分支或者某个hash
  final String ref;

  @override
  State<StatefulWidget> createState() => _ContentViewPageState();
}

class _ContentViewPageState extends State<ContentViewPage> {
  Widget? child;

  bool get _canPreview => widget.file.size <= 1024 * 1024 * 1;

  @override
  void initState() {
    super.initState();
    // 不使用下拉刷新，且不再兼容原来gogs的content字段，那个太扯淡了
    //_init(null, null);
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _init(_, __) async {
    if (_canPreview) {
      // 不缓存内容
      final res = await AppGlobal.cli.repos.content
          .raw(widget.repo, widget.ref, widget.file.path, nocache: true);
      final data = res.data;
      if (data != null) {
        child = _buildContent(Uint8List.fromList(data), res.contentType ?? '');
      }
    } else {
      child = const Center(child: Text('<...文件太大...>'));
    }
    if (mounted) setState(() {});
  }

  Widget? _buildContent(Uint8List data, String contentType) {
    /// 是图片类型
    if (contentType.startsWith("image/")) {
      return Image.memory(data);
    } else if (contentType.startsWith("text/plain")) {
      final text = tryDecodeText(data, contentType);
      if (text != null) {
        var ext = path_lib.extension(widget.file.name).toLowerCase();
        if (ext.startsWith(".")) ext = ext.substring(1);
        final isMarkdown =
            switch (ext) { "md" || "markdown" => true, _ => false };
        if (isMarkdown) return MarkdownBlockPlus(data: text);
        return HighlightViewPlus(
          text,
          fileName: widget.file.name,
          theme:
              AppGlobal.context?.isDark == true ? a11yDarkTheme : githubTheme,
        );
      }
    }
    //
    // if (_isImage(data)) {
    //   return Image.memory(data);
    // }
    return Text('不支持预览的数据类型=$contentType');
  }

  @override
  Widget build(BuildContext context) {
    return PlatformPageScaffold(
      // materialAppBar: () => AppBar(
      //   title: widget.title,
      //   centerTitle: true,
      // ),
      // cupertinoNavigationBar: () => CupertinoNavigationBar(
      //   middle: widget.title,
      //   previousPageTitle: context.previousPageTitle,
      // ),
      appBar: PlatformPageAppBar(
        title: widget.title,
        centerTitle: true,
        previousPageTitle: context.previousPageTitle,
      ),
      padding: const EdgeInsets.all(5),
      reqRefreshCallback: _init,
      canPullDownRefresh: false,
      //emptyItemHint: const Center(child: Text('<...文件太大...>')),

      children: child == null ? [] : [child!],
    );
  }
}
