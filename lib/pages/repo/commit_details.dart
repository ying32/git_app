import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_highlight/themes/a11y-dark.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:git_app/app_globals.dart';
import 'package:git_app/gogs_client/gogs_client.dart';
import 'package:git_app/utils/build_context_helper.dart';
import 'package:git_app/widgets/divider_plus.dart';
import 'package:git_app/widgets/highlight_plus.dart';
import 'package:git_app/widgets/platform_page_scaffold.dart';

class _FileItem {
  _FileItem(this.fileName, this.content);
  final String fileName;
  String content;
}

class CommitDetailsPage extends StatefulWidget {
  const CommitDetailsPage({
    super.key,
    required this.commit,
    required this.repo,
  });

  final Commit commit;
  final Repository repo;

  @override
  State<StatefulWidget> createState() => _CommitDetailsPageState();
}

class _CommitDetailsPageState extends State<CommitDetailsPage> {
  final List<_FileItem> _list = [];

  // diff\s--git\sa(.+)\sb(.+)
  final _diffReg = RegExp(r'diff\s--git\sa/(.+)\sb/(.+)', caseSensitive: false);

  Future _init(_, bool? force) async {
    _list.clear();
    final res = await AppGlobal.cli.repos.commit
        .diff(widget.repo, widget.commit, force: force);

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
          item = _FileItem(re.group(1) ?? '', '');
          _list.add(item);

          var find = false;
          while (i < lines.length) {
            line = lines[i];
            find = line.startsWith("@@");
            if (find) break;
            i++;
          }
          if (find) continue;
        } else {
          buff.writeln(line);
        }
        i++;
      }
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
      // canPullDownRefresh: false,
      appBar: PlatformPageAppBar(
        previousPageTitle: context.previousPageTitle,
      ),
      itemCount: _list.length,
      itemBuilder: (BuildContext context, int index) {
        final item = _list[index];
        return BottomDivider(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BottomDivider(
                  child: SizedBox(height: 30.0, child: Text(item.fileName))),
              const SizedBox(height: 1),
              SizedBox(
                width: double.infinity,
                child: HighlightViewPlus(
                  isDiff: true,
                  item.content,
                  fileName: item.fileName,
                  theme: AppGlobal.context?.isDark == true
                      ? a11yDarkTheme
                      : githubTheme,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
