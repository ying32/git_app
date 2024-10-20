import 'package:flutter/material.dart';

class DividerPlus extends StatelessWidget {
  const DividerPlus({
    super.key,
    required this.child,
    this.top = true,
    this.bottom = true,
    this.width = 1.0,
  });

  final Widget child;
  final bool top;
  final bool bottom;
  final double width;

  @override
  Widget build(BuildContext context) {
    // 者没有就不显示呗
    if (!top && !bottom) return Divider(height: width);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (top) Divider(height: width),
        child,
        if (bottom) Divider(height: width),
      ],
    );
  }
}

class BottomDivider extends StatelessWidget {
  const BottomDivider({
    super.key,
    required this.child,
    this.width = 1.0,
  });

  final Widget child;
  final double width;

  @override
  Widget build(BuildContext context) =>
      DividerPlus(width: width, top: false, bottom: true, child: child);
}

class TopDivider extends StatelessWidget {
  const TopDivider({
    super.key,
    required this.child,
    this.width = 1.0,
  });

  final Widget child;
  final double width;

  @override
  Widget build(BuildContext context) =>
      DividerPlus(width: width, top: true, bottom: false, child: child);
}
