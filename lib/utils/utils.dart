import 'dart:io';
import 'dart:ui' as ui;

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
