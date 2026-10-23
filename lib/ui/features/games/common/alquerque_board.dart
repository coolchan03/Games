import 'package:flutter/material.dart';

/// 5×5 Alquerque-style board: orthogonal lines everywhere, diagonals
/// through points whose coordinates sum to an even number.
class AlquerqueGeometry {
  static const n = 5;

  static bool hasDiagonals(int i) => (i % n + i ~/ n).isEven;

  /// Directions available from point [i] (dx, dy).
  static List<(int, int)> dirs(int i) => [
        (1, 0),
        (-1, 0),
        (0, 1),
        (0, -1),
        if (hasDiagonals(i)) ...[(1, 1), (1, -1), (-1, 1), (-1, -1)],
      ];

  static int? step(int i, int dx, int dy, [int k = 1]) {
    final x = i % n + dx * k, y = i ~/ n + dy * k;
    if (x < 0 || y < 0 || x >= n || y >= n) return null;
    return y * n + x;
  }
}

class AlquerqueBoardPainter extends CustomPainter {
  AlquerqueBoardPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.width / 5;
    final p = Paint()
      ..color = color
      ..strokeWidth = 2.5;
    Offset at(int x, int y) => Offset((x + .5) * c, (y + .5) * c);
    for (var k = 0; k < 5; k++) {
      canvas.drawLine(at(0, k), at(4, k), p);
      canvas.drawLine(at(k, 0), at(k, 4), p);
    }
    // Diagonals.
    canvas.drawLine(at(0, 0), at(4, 4), p);
    canvas.drawLine(at(4, 0), at(0, 4), p);
    canvas.drawLine(at(2, 0), at(4, 2), p);
    canvas.drawLine(at(4, 2), at(2, 4), p);
    canvas.drawLine(at(2, 4), at(0, 2), p);
    canvas.drawLine(at(0, 2), at(2, 0), p);
  }

  @override
  bool shouldRepaint(AlquerqueBoardPainter old) => old.color != color;
}
