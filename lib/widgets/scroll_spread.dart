import 'package:flutter/widgets.dart';

/// A vertical layout that spreads its children over the available height (the
/// job `Spacer`s did) but scrolls when they do not fit. Unlike wrapping a
/// `Column` with spacers in an `IntrinsicHeight`, it works with `GridView`,
/// `LayoutBuilder` and other children that cannot report an intrinsic size.
///
/// A `Column` inside a minimum-height box fills that height when its maximum
/// is unbounded, so `mainAxisAlignment` distributes any spare space.
class ScrollSpread extends StatelessWidget {
  const ScrollSpread({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.spaceEvenly,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      return SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: box.hasBoundedHeight ? box.maxHeight : 0,
          ),
          child: Column(
            mainAxisAlignment: mainAxisAlignment,
            crossAxisAlignment: crossAxisAlignment,
            children: children,
          ),
        ),
      );
    });
  }
}
