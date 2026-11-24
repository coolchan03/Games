import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Gives [child] (typically a `Column` with `Expanded` children) at least
/// [minHeight] to lay out in, and scrolls when the slot is shorter. On tall
/// screens it behaves exactly like the child alone; on short ones the content
/// keeps a usable size instead of overflowing.
class MinHeightScroll extends StatelessWidget {
  const MinHeightScroll({super.key, required this.minHeight, required this.child});

  final double minHeight;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final height = math.max(box.hasBoundedHeight ? box.maxHeight : 0.0, minHeight);
      if (box.hasBoundedHeight && box.maxHeight >= minHeight) return child;
      return SingleChildScrollView(child: SizedBox(height: height, child: child));
    });
  }
}
