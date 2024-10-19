import 'package:flutter/material.dart';

class BackgroundIcon extends StatelessWidget {
  const BackgroundIcon({
    super.key,
    required this.icon,
    required this.color,
    this.iconColor,
    this.size = 28.0,
    this.iconSize = 18.0,
    this.radius = 3,
  });

  /// 背景色
  final Color color;

  /// icon数据
  final IconData icon;

  /// icon颜色
  final Color? iconColor;

  /// Widget尺寸
  final double size;

  /// icon的尺寸
  final double iconSize;

  /// Widget的弧度
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Icon(icon, size: iconSize, color: iconColor ?? Colors.white));
  }
}
