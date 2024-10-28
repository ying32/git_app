import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:charset/charset.dart';

bool get isPhone => Platform.isAndroid || Platform.isIOS;
bool get isDesktop => !isPhone;

/// 转换十六进制颜色
ui.Color hexColorTo(String text) {
  if (text.startsWith("#")) text = text.substring(1);
  if (text.length == 3) {
    text = "${text[0] * 2}, ${text[1] * 2}, ${text[2] * 2}";
  }
  return ui.Color(int.tryParse("ff$text", radix: 16) ?? 0);
}

String timeToLabel(DateTime? dateTime) {
  if (dateTime == null) return '';

  const minute = 60;
  const hour = 60 * minute;
  const day = 24 * hour;
  // const week = 7 * day;
  const month = 30 * day;
  const year = 12 * month;

  final seconds = DateTime.now().millisecondsSinceEpoch ~/ 1000 -
      dateTime.millisecondsSinceEpoch ~/ 1000;

  return switch (seconds) {
    0 => '刚刚',
    < minute => '$seconds秒前',
    < hour => '${seconds ~/ minute}分钟前',
    < day => '${seconds ~/ hour}小时前',
    // < week => '${seconds ~/ week}周前',
    < month => '${seconds ~/ day}天前',
    < year => '${seconds ~/ month}个月前',
    >= year => '${seconds ~/ year}年前',
    _ => "",
  };
}

/// 整型转枚举
E enumFromValue<E extends Enum>(Iterable<E> values, int value, E defValue) =>
    values.firstWhere((e) => e.index == value, orElse: () => defValue);

/// 尝试解码文本，采用不同的编码去尝试
String? tryDecodeText(Uint8List data, String? contentType) {
  if (contentType != null) {
    String? charset;
    final idx = contentType.lastIndexOf("charset=");
    if (idx != -1) {
      charset = contentType.substring(idx + 8).trim();
    }
    if (charset != null) {
      Encoding? encoding;
      if (charset.startsWith("utf-8")) {
        encoding = utf8;
      } else if (charset.startsWith("utf-16")) {
        encoding = utf16;
      } else {
        encoding = systemEncoding;
      }
      try {
        return encoding.decode(data);
      } catch (e) {
        //
      }
    }
  }

  //todo: 这个其实不准哈，需要根据内容来探测编码格式，先这样用着吧
  const supports = [utf8, systemEncoding, gbk, utf16, utf32];
  for (final encoding in supports) {
    // 这里当操作系统不为Windows时，且编码为系统编码时跳过，其它平台的编码一般默认都是utf-8，只有windows不同。
    if (!Platform.isWindows && encoding == systemEncoding) continue;
    try {
      return encoding.decode(data);
    } catch (e) {
      //
    }
  }
  return null;
}
