import 'dart:math';

import 'package:flutter/material.dart';

import 'peg_solitaire_engine.dart';

const _teeColours = [
  Color(0xFFE53935),
  Color(0xFFFDD835),
  Color(0xFF1E88E5),
  Color(0xFF43A047),
  Color(0xFFFFFFFF),
];

/// Wooden triangle board with coloured tee pegs. Tap a peg then a
/// highlighted hole, or drag the peg there. Before the first move, tapping
/// a peg removes it to choose the starting hole.
class TrianglePegBoardView extends StatelessWidget {
  const TrianglePegBoardView({
    super.key,
    required this.board,
    required this.selected,
    required this.onTap,
    required this.onDrop,
  });

  final TrianglePegBoard board;
  final int? selected;
  final ValueChanged<int> onTap;
  final void Function(int from, int to) onDrop;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final targets =
        selected == null ? const <int>{} : board.targets(selected!).toSet();
    return AspectRatio(
      aspectRatio: 1.08,
      child: LayoutBuilder(builder: (context, box) {
        final width = box.maxWidth;
        final spacing = width / 6;
        final rowStep = spacing * sqrt(3) / 2;
        final hole = spacing * .62;
        Offset centre(int i) {
          final (r, c) = TrianglePegBoard.position(i);
          return Offset(
              width / 2 + (c - r / 2) * spacing, spacing * .9 + r * rowStep);
        }

        Widget peg(int i, {double scale = 1}) => Container(
              width: hole * .78 * scale,
              height: hole * .78 * scale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(-.35, -.4),
                  colors: [
                    Color.lerp(_teeColours[i % _teeColours.length],
                        Colors.white, .55)!,
                    _teeColours[i % _teeColours.length],
                    Color.lerp(_teeColours[i % _teeColours.length],
                        Colors.black, .35)!,
                  ],
                  stops: const [0, .55, 1],
                ),
                border: Border.all(
                    color: selected == i ? colors.primary : Colors.black38,
                    width: selected == i ? 3 : 1),
                boxShadow: const [
                  BoxShadow(
                      blurRadius: 4,
                      offset: Offset(1, 3),
                      color: Colors.black45),
                ],
              ),
            );

        return Stack(children: [
          Positioned.fill(child: CustomPaint(painter: _TrianglePainter())),
          for (var i = 0; i < TrianglePegBoard.holeCount; i++)
            Positioned(
              left: centre(i).dx - hole / 2,
              top: centre(i).dy - hole / 2,
              width: hole,
              height: hole,
              child: DragTarget<int>(
                onWillAcceptWithDetails: (d) =>
                    board.targets(d.data).contains(i),
                onAcceptWithDetails: (d) => onDrop(d.data, i),
                builder: (context, candidate, _) => Semantics(
                  key: ValueKey('triangle_peg_hole_$i'),
                  label: 'Hole ${i + 1}: ${board.pegs[i] ? 'peg' : 'empty'}',
                  hint: targets.contains(i) ? 'Legal destination' : null,
                  button: true,
                  selected: selected == i,
                  child: GestureDetector(
                    onTap: () => onTap(i),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: targets.contains(i) || candidate.isNotEmpty
                            ? colors.primaryContainer
                            : const Color(0xFF3E2414),
                        border: Border.all(
                          color: targets.contains(i)
                              ? colors.primary
                              : const Color(0xFF8D5A35),
                          width: targets.contains(i) ? 3 : 1.5,
                        ),
                        boxShadow: const [
                          BoxShadow(
                              blurRadius: 2,
                              offset: Offset(-1, -1),
                              color: Color(0x55000000)),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: !board.pegs[i]
                          ? null
                          : board.started && board.targets(i).isNotEmpty
                              ? Draggable<int>(
                                  data: i,
                                  feedback: peg(i, scale: 1.2),
                                  childWhenDragging: const SizedBox(),
                                  child: peg(i),
                                )
                              : peg(i),
                    ),
                  ),
                ),
              ),
            ),
        ]);
      }),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final path = Path()
      ..moveTo(w / 2, 0)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    final rect = Offset.zero & size;
    canvas.drawShadow(path, Colors.black, 6, false);
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFD9A066), Color(0xFFB0773F), Color(0xFF8A5A2B)],
        ).createShader(rect),
    );
    // Wood grain.
    final grain = Paint()
      ..color = const Color(0x22000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.save();
    canvas.clipPath(path);
    for (var y = 6.0; y < h; y += 9) {
      final p = Path()..moveTo(0, y);
      for (var x = 0.0; x <= w; x += 24) {
        p.quadraticBezierTo(x + 12, y + sin((x + y) / 37) * 4, x + 24, y);
      }
      canvas.drawPath(p, grain);
    }
    canvas.restore();
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF5D3A1A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
  }

  @override
  bool shouldRepaint(_TrianglePainter old) => false;
}
