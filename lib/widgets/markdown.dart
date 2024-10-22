import 'package:flutter/material.dart';
import 'package:git_app/utils/build_context_helper.dart';
import 'package:markdown_widget/config/configs.dart';
import 'package:markdown_widget/widget/blocks/leaf/link.dart';
import 'package:markdown_widget/widget/markdown_block.dart';

class MarkdownBlockPlus extends StatelessWidget {
  const MarkdownBlockPlus({
    super.key,
    required this.data,
    this.selectable = true,
    this.onTap,
  });

  final String data;
  final bool selectable;
  final ValueCallback<String>? onTap;

  @override
  Widget build(BuildContext context) {
    final config = (context.isDark
        ? MarkdownConfig.darkConfig
        : MarkdownConfig.defaultConfig);
    return MarkdownBlock(
      data: data,
      selectable: selectable,
      config: onTap != null
          ? config.copy(configs: [LinkConfig(onTap: onTap)])
          : config,
    );
  }
}
