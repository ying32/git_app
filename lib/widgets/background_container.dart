import 'package:flutter/material.dart';
import 'package:git_app/utils/build_context_helper.dart';

class BackgroundContainer extends StatelessWidget {
  const BackgroundContainer({
    super.key,
    required this.child,
    this.color,
    this.radius,
    this.padding,
  });

  final Color? color;
  final double? radius;
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      clipBehavior: radius != null ? Clip.hardEdge : Clip.none,
      decoration: BoxDecoration(
          color: color ??
              (context.isLight
                  ? Colors.white
                  : const Color.fromARGB(255, 23, 24, 26)),
          borderRadius: radius == null ? null : BorderRadius.circular(radius!)),
      child: child,
    );
  }
}
