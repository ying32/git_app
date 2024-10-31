import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:git_app/app_globals.dart';
import 'package:git_app/gogs_client/gogs_client.dart';
import 'package:git_app/utils/build_context_helper.dart';
import 'package:git_app/widgets/background_container.dart';
import 'package:git_app/widgets/divider_plus.dart';
import 'package:git_app/widgets/highlight_plus.dart';
import 'package:git_app/widgets/platform_page_scaffold.dart';

class _FileItem {
  _FileItem(
    this.fileName,
    this.content,
    this.isBinFile,
  );
  final String fileName;
  String content;
  bool isBinFile;
}

class CommitDetailsPage extends StatefulWidget {
  const CommitDetailsPage({
    super.key,
    required this.sha,
    required this.message,
    required this.repo,
  });

  final String sha;
  final String message;
  final Repository repo;

  @override
  State<StatefulWidget> createState() => _CommitDetailsPageState();
}

class _CommitDetailsPageState extends State<CommitDetailsPage> {
  final List<_FileItem> _list = [];

  // diff\s--git\sa(.+)\sb(.+)
  final _diffReg = RegExp(r'diff\s--git\sa/(.+)\sb/(.+)', caseSensitive: false);
  //final _lineInfo = RegExp(r'@@ \-(\d+),(\d+) \+(\d+),(\d+) @@');
  // 添加行，删除行
  var additions = 0, deletions = 0;

  Future _init(_, bool? force) async {
    _list.clear();
    final res = await AppGlobal.cli.repos.commit
        .diff(widget.repo, widget.sha, force: force);
    additions = 0;
    deletions = 0;
    if (res.succeed && res.data != null) {
      // 这里分析
      final lines = List<String>.of(LineSplitter.split(res.data!));
      var i = 0;
      _FileItem? item;
      _list.clear();

      final buff = StringBuffer();
      while (i < lines.length) {
        var line = lines[i];
        final re = _diffReg.firstMatch(line);
        if (re != null) {
          //i += 3; // 这里不能固定数，因为他有时候4行，有时候3行的，要根据其它识别下
          i++;

          item?.content = buff.toString();
          buff.clear();
          item = _FileItem(re.group(1) ?? '', '', false);
          _list.add(item);

          var find = false;
          // 跳过不要的一些信息
          while (i < lines.length) {
            line = lines[i];
            item.isBinFile = line.startsWith('Binary files');
            final isDiffStart = line.startsWith("@@");
            // if (isDiffStart) {
            //   // 原本以为这个给出的信息是增加多少行，删除多少行，结果发现不是
            //   final re = _lineInfo.firstMatch(line);
            //   if (re != null) {
            //     // 前面是减
            //     deletions += int.tryParse(re.group(2) ?? '') ?? 0;
            //     // 后面是加
            //     additions += int.tryParse(re.group(4) ?? '') ?? 0;
            //   }
            // }
            find = isDiffStart || item.isBinFile;
            if (find) break;
            i++;
          }
          if (find) continue;
        } else {
          // 开始部分的
          if (line.startsWith("+")) {
            additions++;
          } else if (line.startsWith("-")) {
            deletions++;
          }

          buff.writeln(line);
        }
        i++;
      }
      //print("增加行=$additions, 删除行=$deletions,总计行=${additions + deletions}");
      if (item != null && buff.isNotEmpty) {
        item.content = buff.toString();
      }
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return PlatformPageScaffold(
      reqRefreshCallback: _init,
      canPullDownRefresh: false,
      appBar: PlatformPageAppBar(
        title: Text(widget.sha.substring(0, 10)),
        previousPageTitle: context.previousPageTitle,
      ),
      itemCount: _list.length + 3,
      useSeparator: true,
      itemBuilder: (BuildContext context, int index) {
        if (index == 0) {
          return BackgroundContainer(
            padding:
                const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
            child: Text(widget.message.trimRight()),
          );
        } else if (index == 1) {
          return const SizedBox(height: 15);
        } else if (index == 2) {
          return BackgroundContainer(
            padding:
                const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
            child: Text.rich(TextSpan(
              children: [
                TextSpan(
                    text: '${_list.length}个文件已改变\n',
                    style: const TextStyle(color: Colors.orange)),
                TextSpan(
                    text: '$additions 次插入',
                    style: const TextStyle(color: Colors.green)),
                const TextSpan(text: ' 和 '),
                TextSpan(
                    text: '$deletions 次删除',
                    style: const TextStyle(color: Colors.red)),
              ],
            )),
          );
        }
        final item = _list[index - 3];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 这里的标题还要做一个可以浮动的大概就是到顶部就浮动，得用sliver来做
            BottomDivider(
                child: BackgroundContainer(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    height: 35.0,
                    child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(item.fileName,
                            maxLines: 1, overflow: TextOverflow.ellipsis)))),
            const SizedBox(height: 1),
            SizedBox(
              width: double.infinity,
              child: item.isBinFile
                  ? const Padding(
                      padding: EdgeInsets.all(10.0),
                      child: Text('二进制文件未显示。'),
                    )
                  : HighlightViewPlus(
                      isDiff: true,
                      item.content,
                      fileName: item.fileName,
                    ),
            ),
          ],
        );
      },
    );
  }
}
