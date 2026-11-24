import 'package:flutter/widgets.dart';

/// Lets a screen body that is taller than its slot scroll instead of
/// overflowing, while still filling the slot (so `Spacer`/`Expanded` children
/// and vertical centring behave exactly as before when everything fits).
///
/// Children that cannot report an intrinsic height (a bare `LayoutBuilder`,
/// `GridView`...) are not supported: wrap those individually instead.
class ScrollIfTall extends StatelessWidget {
  const ScrollIfTall({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      if (!box.hasBoundedHeight) return child;
      return SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight),
          child: IntrinsicHeight(child: child),
        ),
      );
    });
  }
}
