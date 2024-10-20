import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:git_app/widgets/editor_page.dart';

typedef CommentInputSendCallback<T> = Future<bool?> Function(String?);

/// 评论输入框
class CommentInputPage extends StatelessWidget {
  const CommentInputPage({
    super.key,
    this.defaultContent,
    required this.onSend,
  });

  final String? defaultContent;
  final CommentInputSendCallback<String?> onSend;

  @override
  Widget build(BuildContext context) {
    return EditorPage(
        showTitleEdit: false,
        title: const Text('评论'),
        trailingTitle: const Text('发送'),
        contentPlaceholder: '输入评论内容',
        defaultContent: defaultContent,
        onEditCompleted: (String? title, String? content) =>
            onSend.call(content));
  }
}
