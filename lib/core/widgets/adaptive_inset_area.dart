import 'dart:math' as math;

import 'package:flutter/material.dart';

class AdaptiveInsetArea extends StatelessWidget {
  const AdaptiveInsetArea({
    super.key,
    required this.child,
    this.left = false,
    this.top = false,
    this.right = false,
    this.bottom = false,
    this.minimum = EdgeInsets.zero,
  });

  final Widget child;
  final bool left;
  final bool top;
  final bool right;
  final bool bottom;
  final EdgeInsets minimum;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final padding = EdgeInsets.only(
      left: left
          ? math.max(mediaQuery.padding.left, minimum.left)
          : minimum.left,
      top: top ? math.max(mediaQuery.padding.top, minimum.top) : minimum.top,
      right: right
          ? math.max(mediaQuery.padding.right, minimum.right)
          : minimum.right,
      bottom: bottom
          ? math.max(mediaQuery.padding.bottom, minimum.bottom)
          : minimum.bottom,
    );

    return Padding(
      padding: padding,
      child: MediaQuery.removePadding(
        context: context,
        removeLeft: left,
        removeTop: top,
        removeRight: right,
        removeBottom: bottom,
        child: child,
      ),
    );
  }
}
