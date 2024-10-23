import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:git_app/utils/build_context_helper.dart';
import 'package:highlight/highlight.dart' show highlight, Node;

const _lineNumberOffset = 5.0;

TextPainter _createPainter(BuildContext context, InlineSpan span) =>
    TextPainter(
      text: span,
      textAlign: TextAlign.start,
      textDirection: TextDirection.ltr,
      locale: Localizations.localeOf(context),
    );

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
  final List<int> lineNumbers;
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
    var n = 1;
    for (var e in lineNumbers) {
      final pp = tp.getOffsetForCaret(
          TextPosition(offset: e), //, affinity: TextAffinity.upstream
          ui.Rect.fromLTRB(0, 0, width, 0.0));
      _drawText(canvas, n,
          width: size.width, offsetY: pp.dy, style: tp.text?.style);
      // _paint.color = Colors.lightBlue;
      // canvas.drawLine(
      //     ui.Offset(pp.dx, pp.dy), ui.Offset(pp.dx + 5, pp.dy), _paint);

      n++;
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
  final String source;
  final String? language;
  final Map<String, TextStyle> theme;

  HighlightViewPlus(
    String input, {
    super.key,
    this.language,
    this.theme = const {},
    int tabSize = 8, // TODO: https://github.com/flutter/flutter/issues/50087
  }) : source = input.replaceAll('\t', ' ' * tabSize);

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

  List<int> _getLineNumbers(String text) {
    final res = <int>[];
    int last = 0;
    for (var i = 0; i < text.length; i++) {
      if (text.codeUnitAt(i) == 0xA) {
        if (res.isEmpty) {
          res.add(0);
        } else {
          res.add(last + 1);
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

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: 'Courier New',
      fontSize: 14.0,
      color: theme[_rootKey]?.color ?? _defaultFontColor,
    );
    final span = TextSpan(
        style: style,
        children: _convert(highlight.parse(source, language: language).nodes!));
    // 计算代码绘制位置的
    final lineNumbers = _getLineNumbers(source);
    // 计算最大行宽
    final lineNumberWidth = lineNumbers.isEmpty
        ? 0.0
        : _calcLineMaxWidth(context,
                TextSpan(text: "${lineNumbers.length}", style: style)) +
            _lineNumberOffset;

    final bkColor = theme[_rootKey]?.backgroundColor ?? _defaultBackgroundColor;
    return Container(
      color: bkColor,
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          //todo: 代码显示区域的宽度，如果不用精准的width计算，会造成行号显示位置不正确
          // 其它地方稍微加点就这样，看来这边得另想办法
          const offset = 0.0;
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
