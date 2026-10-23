import 'dart:math';

import 'package:flutter/material.dart';

/// Shared look for the sowing games (Mancala, Oware): a carved wooden
/// board, round pits holding glass-bead seeds, and long end stores.

const _beadColours = [
  Color(0xFF42A5F5),
  Color(0xFF66BB6A),
  Color(0xFFEF5350),
  Color(0xFFFFCA28),
  Color(0xFFAB47BC),
  Color(0xFF26C6DA),
  Color(0xFFFF7043),
  Color(0xFFECEFF1),
];

/// Wooden board frame.
class WoodenBoard extends StatelessWidget {
  const WoodenBoard({super.key, required this.child, this.radius = 36});
  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFA86B3C), Color(0xFF8B5530), Color(0xFF6E3F20)],
        ),
        border: Border.all(color: const Color(0xFF4E2A12), width: 2),
        boxShadow: const [
          BoxShadow(
              blurRadius: 12, offset: Offset(0, 6), color: Colors.black38),
        ],
      ),
      child: Stack(children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius - 8),
            child: CustomPaint(painter: _GrainPainter()),
          ),
        ),
        child,
      ]),
    );
  }
}

/// Two rows of pits between two end stores, sized to the available width.
/// [top] is listed left to right as seen on screen.
class SowingBoard extends StatelessWidget {
  const SowingBoard({
    super.key,
    required this.top,
    required this.bottom,
    required this.leftStore,
    required this.rightStore,
  });

  final List<Widget> top, bottom;
  final Widget leftStore, rightStore;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final inner = box.maxWidth - 24; // board padding and border
      final store = inner * .13;
      final pit = min((inner - 2 * store) / top.length, 92.0);
      final gap = pit * .18;
      final height = 2 * pit + gap;
      Widget row(List<Widget> pits) => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final p in pits) SizedBox(width: pit, height: pit, child: p),
            ],
          );
      return WoodenBoard(
        radius: min(48, height / 2 + 10),
        child: SizedBox(
          height: height,
          child: Row(children: [
            SizedBox(width: store, child: leftStore),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [row(top), SizedBox(height: gap), row(bottom)],
              ),
            ),
            SizedBox(width: store, child: rightStore),
          ]),
        ),
      );
    });
  }
}

class _GrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x18000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    for (var y = 3.0; y < size.height; y += 7) {
      final path = Path()..moveTo(0, y);
      for (var x = 0.0; x < size.width; x += 30) {
        path.quadraticBezierTo(
            x + 15, y + sin((x * 3 + y) / 41) * 3, x + 30, y);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_GrainPainter old) => false;
}

/// A carved pit with [seeds] beads. [enabled] pits glow and respond to taps;
/// [lastMove] marks the pit last played.
class SowingPit extends StatelessWidget {
  const SowingPit({
    super.key,
    required this.seeds,
    required this.seedKey,
    this.enabled = false,
    this.lastMove = false,
    this.onTap,
    this.semanticLabel,
  });

  final int seeds;

  /// Stable per-pit value so beads keep their places between frames.
  final int seedKey;
  final bool enabled, lastMove;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: semanticLabel ?? '$seeds seeds',
      button: enabled,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AspectRatio(
          aspectRatio: 1,
          child: Stack(clipBehavior: Clip.none, children: [
            Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    center: Alignment(.2, .35),
                    colors: [Color(0xFF7A4A28), Color(0xFF4A2812)],
                  ),
                  border: Border.all(
                    color: enabled
                        ? colors.primary
                        : lastMove
                            ? const Color(0xFFFFD54F)
                            : const Color(0xFF3B1E0B),
                    width: enabled || lastMove ? 3 : 1.5,
                  ),
                  boxShadow: [
                    if (enabled)
                      BoxShadow(
                          color: colors.primary.withValues(alpha: .55),
                          blurRadius: 10),
                  ],
                ),
                child: ClipOval(
                  child: CustomPaint(painter: _BeadPainter(seeds, seedKey)),
                ),
              ),
            ),
            Positioned(
              right: -2,
              top: -2,
              child: _CountBadge(seeds),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Long end store for captured seeds.
class SeedStore extends StatelessWidget {
  const SeedStore({
    super.key,
    required this.seeds,
    required this.label,
    required this.seedKey,
    this.highlight = false,
  });

  final int seeds;
  final String label;
  final int seedKey;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $seeds seeds',
      child: Column(children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              gradient: const RadialGradient(
                center: Alignment(.2, .3),
                radius: 1.2,
                colors: [Color(0xFF7A4A28), Color(0xFF4A2812)],
              ),
              border: Border.all(
                color: highlight
                    ? const Color(0xFFFFD54F)
                    : const Color(0xFF3B1E0B),
                width: highlight ? 3 : 1.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: CustomPaint(
                painter: _BeadPainter(seeds, seedKey, store: true),
                size: Size.infinite,
              ),
            ),
          ),
        ),
        FittedBox(
          child: Text('$label $seeds',
              style: const TextStyle(
                  color: Color(0xFFFFF3E0), fontWeight: FontWeight.w800)),
        ),
      ]),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge(this.count);
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF4E2A12)),
      ),
      child: Text('$count',
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF3E2414))),
    );
  }
}

class _BeadPainter extends CustomPainter {
  _BeadPainter(this.seeds, this.key, {this.store = false});
  final int seeds, key;
  final bool store;

  @override
  void paint(Canvas canvas, Size size) {
    if (seeds == 0) return;
    final shown = min(seeds, store ? 48 : 22);
    final rng = Random(key * 7919);
    final scale = store
        ? .16
        : shown <= 4
            ? .3
            : shown <= 8
                ? .25
                : shown <= 14
                    ? .21
                    : .18;
    final bead = min(size.width, size.height) * scale;
    final centre = size.center(Offset.zero);
    for (var k = 0; k < shown; k++) {
      // Sunflower spiral keeps beads evenly packed; jitter looks hand-sown.
      final angle = k * 2.39996 + rng.nextDouble() * .4;
      final spread = sqrt(k + .5) / sqrt(shown + .5);
      final rx = (size.width / 2 - bead * .7) * spread;
      final ry = (size.height / 2 - bead * .7) * spread;
      final p = centre + Offset(cos(angle) * rx, sin(angle) * ry);
      final colour = _beadColours[rng.nextInt(_beadColours.length)];
      canvas.drawCircle(
          p + const Offset(1, 1.5), bead / 2, Paint()..color = Colors.black38);
      canvas.drawCircle(
        p,
        bead / 2,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-.4, -.45),
            colors: [
              Colors.white,
              colour,
              Color.lerp(colour, Colors.black, .45)!
            ],
            stops: const [0, .45, 1],
          ).createShader(Rect.fromCircle(center: p, radius: bead / 2)),
      );
    }
  }

  @override
  bool shouldRepaint(_BeadPainter old) =>
      old.seeds != seeds || old.key != key || old.store != store;
}
