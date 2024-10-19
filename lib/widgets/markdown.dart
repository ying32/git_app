import 'package:flutter/material.dart';
import 'package:gogs_app/utils/build_context_helper.dart';
import 'package:markdown_widget/config/configs.dart';
import 'package:markdown_widget/widget/markdown_block.dart';

class MarkdownBlockPlus extends StatelessWidget {
  const MarkdownBlockPlus(
      {super.key, required this.data, this.selectable = true});

  final String data;
  final bool selectable;

  @override
  Widget build(BuildContext context) => MarkdownBlock(
        data: data,
        selectable: selectable,
        config: context.isDark
            ? MarkdownConfig.darkConfig
            : MarkdownConfig.defaultConfig,
      );
}
