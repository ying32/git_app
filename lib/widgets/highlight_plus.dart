import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:git_app/utils/build_context_helper.dart';
import 'package:highlight/highlight.dart' show highlight, Node;
import 'package:path/path.dart' as path_lib;

const _lineNumberOffset = 5.0;

enum _DiffState { start, add, sub, normal }

TextPainter _createPainter(BuildContext context, InlineSpan span) =>
    TextPainter(
      text: span,
      textAlign: TextAlign.start,
      textDirection: TextDirection.ltr,
      locale: Localizations.localeOf(context),
    );

class _LineNumberInfo {
  _LineNumberInfo(this.pos, this.number, this.state);
  final int pos;
  final int? number;
  final _DiffState? state;
}

///todo: 这玩意还有待优化，有时候不准，原因还得找找
class _LineNumberPainter extends CustomPainter {
  _LineNumberPainter(
    this.span, {
    required this.context,
    required this.width,
    required this.lineNumbers,
    required this.backgroundColor,
  });

  final BuildContext context;

  final InlineSpan span;
  final double width;
  final List<_LineNumberInfo> lineNumbers;
  final Color backgroundColor;

  final Paint _paint = Paint()..style = PaintingStyle.fill;

  void _drawText(Canvas canvas, int number,
      {required double width, required double offsetY, TextStyle? style}) {
    ui.ParagraphBuilder paragraphBuilder =
        ui.ParagraphBuilder(ui.ParagraphStyle(textAlign: TextAlign.right));
    paragraphBuilder.pushStyle(ui.TextStyle(
        fontSize: style?.fontSize,
        fontFamily: style?.fontFamily,
        color: style?.color));
    paragraphBuilder.addText('$number');
    ui.ParagraphConstraints paragraphConstraints =
        ui.ParagraphConstraints(width: width);
    ui.Paragraph paragraph = paragraphBuilder.build();
    paragraph.layout(paragraphConstraints);
    canvas.drawParagraph(paragraph, Offset(-_lineNumberOffset / 2.0, offsetY));
  }

  @override
  void paint(Canvas canvas, Size size) {
    TextPainter tp = _createPainter(context, span);
    tp.layout(maxWidth: width, minWidth: width);

    // tp.paint(canvas, ui.Offset(size.width, 0));

    final r = ui.Rect.fromLTWH(0, 0, size.width, tp.height);
    _paint.color = backgroundColor;
    canvas.drawRect(r, _paint);
    _paint.color = Colors.grey.withAlpha(158);
    canvas.drawLine(ui.Offset(size.width - 1, 0),
        ui.Offset(size.width - 1, r.height), _paint);

    ui.Offset getLineOffset(int index) {
      if (index >= 0 && index < lineNumbers.length) {
        return tp.getOffsetForCaret(
            TextPosition(
                offset:
                    lineNumbers[index].pos), //, affinity: TextAffinity.upstream
            ui.Rect.fromLTRB(0, 0, width, 0.0));
      }
      return ui.Offset(0.0, tp.height);
    }

    for (int i = 0; i < lineNumbers.length; i++) {
      final e = lineNumbers[i];
      final pp = getLineOffset(i);

      // 画颜色不同的，这个还要修改，位置有点不太对哦
      if (e.state != null) {
        if (e.state != _DiffState.normal) {
          // 下一个位置的
          final npp = getLineOffset(i + 1);
          var r = ui.Rect.fromLTRB(0, pp.dy, size.width, npp.dy);
          if (e.state == _DiffState.add) {
            _paint.color = Colors.green.withAlpha(128);
          } else if (e.state == _DiffState.sub) {
            _paint.color = Colors.red.withAlpha(128);
          } else if (e.state == _DiffState.start) {
            _paint.color = Colors.blue.withAlpha(128);
          }
          canvas.drawRect(r, _paint);
          // 这里直接溢出绘制
          r = ui.Rect.fromLTRB(size.width, pp.dy, size.width + width, npp.dy);
          _paint.color = _paint.color.withAlpha(50);
          canvas.drawRect(r, _paint);
        }
      }

      if (e.number != null) {
        _drawText(canvas, e.number!,
            width: size.width, offsetY: pp.dy, style: tp.text?.style);
      }
    }
    tp.dispose();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate != this;
  }
}

/// 修改自：flutter_highlight-0.7.0\lib\flutter_highlight.dart

class HighlightViewPlus extends StatelessWidget {
  HighlightViewPlus(
    String input, {
    super.key,
    this.theme = const {},
    required this.fileName,
    this.isDiff = false,
    int tabSize = 8, // TODO: https://github.com/flutter/flutter/issues/50087
  }) : source = input.replaceAll('\t', ' ' * tabSize);

  final String source;
  final Map<String, TextStyle> theme;
  final String fileName;
  final bool isDiff;

  // 因为有些不能根据扩展名识别，所以这里维护一个
  static final _otherHighlights = {
    "txt": {"CMakeLists.txt": "cmake"},
    "iml": "xml",
    "manifest": "xml",
    "rc": "c",
    "arb": "json",
    "firebaserc": "json",
    "fmx": "delphi",
    "lfm": "delphi",
    "dfm": "delphi",
    "": {"Podfile": "ruby"}
  };

  static final _xmlStartPattern = RegExp(r'\<\?xml|\<.+?xmlns\=\"');

  List<TextSpan> _convert(List<Node> nodes) {
    List<TextSpan> spans = [];
    var currentSpans = spans;
    List<List<TextSpan>> stack = [];

    void traverse(Node node) {
      if (node.value != null) {
        currentSpans.add(node.className == null
            ? TextSpan(text: node.value)
            : TextSpan(text: node.value, style: theme[node.className!]));
      } else if (node.children != null) {
        List<TextSpan> tmp = [];
        currentSpans
            .add(TextSpan(children: tmp, style: theme[node.className!]));
        stack.add(currentSpans);
        currentSpans = tmp;

        for (var n in node.children!) {
          traverse(n);
          if (n == node.children!.last) {
            currentSpans = stack.isEmpty ? spans : stack.removeLast();
          }
        }
      }
    }

    for (var node in nodes) {
      traverse(node);
    }
    return spans;
  }

  static const _rootKey = 'root';
  static const _defaultFontColor = Color(0xff000000);
  static const _defaultBackgroundColor = Color(0xffffffff);

  /// 提取行信息的
  final _lineInfo = RegExp(r'@@ \-(\d+),(\d+) \+(\d+),(\d+) @@');

  List<_LineNumberInfo> _getLineNumbers(String text) {
    final res = <_LineNumberInfo>[];

    _DiffState? getState(int i) {
      return switch (text.codeUnitAt(i)) {
        0x2B => _DiffState.add, // +
        0x2D => _DiffState.sub, // -
        0x40 => _DiffState.start, // @
        _ => _DiffState.normal,
      };
    }

    int last = 0;
    int? diffStart;
    int normal = 0;
    int sub = 0;
    for (var i = 0; i < text.length; i++) {
      if (text.codeUnitAt(i) == 0xA) {
        if (res.isEmpty) {
          final state = isDiff ? getState(0) : null;

          if (state == _DiffState.start) {
            diffStart =
                int.tryParse(_lineInfo.firstMatch(text)?.group(3) ?? '');
            normal = diffStart ?? 1;
            sub = 0;
          }
          // 如果是diff的，则首行不显示行号
          res.add(_LineNumberInfo(0, isDiff ? null : 1, state));
        } else {
          final pos = last + 1;
          final state = isDiff ? getState(pos) : null;

          if (state == _DiffState.start) {
            diffStart = int.tryParse(_lineInfo
                    .firstMatch(
                        text.substring(pos, text.indexOf("\n", pos + 1)))
                    ?.group(3) ??
                '');
            normal = diffStart ?? 1;
            sub = 0;
          }
          int? number;
          if (state != null) {
            number = switch (state) {
              _DiffState.sub => normal + sub,
              _DiffState.add => normal,
              _DiffState.normal => normal,
              _ => null,
            };
          }
          res.add(
              _LineNumberInfo(pos, isDiff ? number : res.length + 1, state));
          if (isDiff) {
            if (state == _DiffState.normal || state == _DiffState.add) {
              normal++;
            } else if (state == _DiffState.sub) {
              sub++;
            }
          }
        }
        last = i;
      }
    }
    return res;
  }

  double _calcLineMaxWidth(BuildContext context, InlineSpan span) {
    final tp = _createPainter(context, span);
    try {
      tp.layout(maxWidth: 999);
      return tp.width;
    } finally {
      tp.dispose();
    }
  }

  String _getLang(String data) {
    var ext = path_lib.extension(fileName).toLowerCase();
    if (ext.startsWith(".")) ext = ext.substring(1);

    // 这个只是临时的，想要好的，还得做内容识别
    final highlight = _otherHighlights[ext];

    if (highlight != null) {
      // 先查文件名
      final language = (highlight is Map)
          ? highlight[fileName] ?? highlight[ext]
          : highlight;
      if (language != null && language.isNotEmpty) {
        ext = language;
      }
    }
    if (highlight == null) {
      if (data.startsWith(_xmlStartPattern)) {
        ext = "xml";
      }
    }

    return ext;

    ///todo: 选择功能windows没反应，android上倒是可以用
    // return HighlightViewPlus(
    //   data,
    //   language: ext,
    //   theme: AppGlobal.context?.isDark == true ? a11yDarkTheme : githubTheme,
    // );
  }

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: 'Courier New',
      fontSize: 14.0,
      color: theme[_rootKey]?.color ?? _defaultFontColor,
    );
    final span = TextSpan(
        style: style,
        children: _convert(
            highlight.parse(source, language: _getLang(source)).nodes!));
    // 计算代码绘制位置的
    final lineNumbers = _getLineNumbers(source);
    // 计算最大行宽
    final lineNumberWidth = lineNumbers.isEmpty
        ? 0.0
        : _calcLineMaxWidth(
                context,
                TextSpan(
                    text: "${lineNumbers.lastOrNull?.number}", style: style)) +
            _lineNumberOffset;

    final bkColor = theme[_rootKey]?.backgroundColor ?? _defaultBackgroundColor;
    return Container(
      color: bkColor,
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          //todo: 代码显示区域的宽度，如果不用精准的width计算，会造成行号显示位置不正确
          // 其它地方稍微加点就这样，看来这边得另想办法
          const offset = 5.0;
          final width = constraints.minWidth - lineNumberWidth - offset;
          return Row(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomPaint(
                  size: ui.Size(lineNumberWidth, 0),
                  painter: _LineNumberPainter(
                    context: context,
                    lineNumbers: lineNumbers,
                    span,
                    width: width,
                    backgroundColor: context.isDark
                        ? Colors.black.withAlpha(200)
                        : Colors.white.withAlpha(200),
                  )),
              // 经过测试用padding会造成不准，只有用SizedBox才会正常
              const SizedBox(width: offset),
              SelectionArea(
                child: SizedBox(width: width, child: RichText(text: span)),
              ),
            ],
          );
        },
      ),
    );
  }
}
