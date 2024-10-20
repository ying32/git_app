import 'package:flutter/material.dart';

class BottomDivider extends StatelessWidget {
  const BottomDivider({
    super.key,
    required this.child,
    this.width = 1.0,
  });

  final Widget child;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        child,
        Divider(height: width),
      ],
    );
  }
}
