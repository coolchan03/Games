import 'dart:math';

/// Dots and Boxes on an [rows] × [cols] grid of boxes.
/// Horizontal edges: (rows+1) × cols, vertical edges: rows × (cols+1).
class DotsGame {
  DotsGame({this.rows = 4, this.cols = 4})
      : h = List.filled((rows + 1) * cols, 0),
        v = List.filled(rows * (cols + 1), 0),
        boxes = List.filled(rows * cols, 0);

  final int rows, cols;
  final List<int> h, v, boxes;
  int turn = 1;
  final scores = [0, 0];

  int get edgeCount => h.length + v.length;
  bool get over => boxes.every((b) => b != 0);

  /// Edge ids: 0..h.length-1 horizontal, then vertical.
  bool taken(int e) => e < h.length ? h[e] != 0 : v[e - h.length] != 0;

  List<int> boxesOf(int e) {
    if (e < h.length) {
      final r = e ~/ cols, c = e % cols;
      return [if (r > 0) (r - 1) * cols + c, if (r < rows) r * cols + c];
    }
    final k = e - h.length, r = k ~/ (cols + 1), c = k % (cols + 1);
    return [if (c > 0) r * cols + c - 1, if (c < cols) r * cols + c];
  }

  List<int> edgesOf(int b) {
    final r = b ~/ cols, c = b % cols;
    return [r * cols + c, (r + 1) * cols + c, h.length + r * (cols + 1) + c, h.length + r * (cols + 1) + c + 1];
  }

  int sides(int b) => edgesOf(b).where(taken).length;

  /// Draws edge [e]; returns true if the player completed a box (and moves again).
  bool play(int e) {
    if (taken(e) || over) return false;
    if (e < h.length) {
      h[e] = turn;
    } else {
      v[e - h.length] = turn;
    }
    var scored = false;
    for (final b in boxesOf(e)) {
      if (sides(b) == 4) {
        boxes[b] = turn;
        scores[turn - 1]++;
        scored = true;
      }
    }
    if (!scored) turn = 3 - turn;
    return scored;
  }

  List<int> get free => [for (var e = 0; e < edgeCount; e++) if (!taken(e)) e];

  /// Size of the chain that would be handed over by drawing [e].
  int _giveaway(int e) {
    final copy = DotsGame(rows: rows, cols: cols);
    copy.h.setAll(0, h);
    copy.v.setAll(0, v);
    copy.boxes.setAll(0, boxes);
    copy.turn = 3; // marker owner for boxes handed to the opponent
    copy._mark(e);
    var gained = 0;
    while (true) {
      final grab = copy.free.where((x) => copy.boxesOf(x).any((b) => copy.sides(b) == 3)).toList();
      if (grab.isEmpty) break;
      copy._mark(grab.first);
      gained = copy.boxes.where((b) => b == 3).length;
    }
    return gained;
  }

  void _mark(int e) {
    if (e < h.length) {
      h[e] = turn;
    } else {
      v[e - h.length] = turn;
    }
    for (final b in boxesOf(e)) {
      if (sides(b) == 4 && boxes[b] == 0) boxes[b] = turn;
    }
  }

  int aiMove(int level, Random rng) {
    final options = free;
    // 1. Complete a box when possible.
    final completing = options.where((e) => boxesOf(e).any((b) => sides(b) == 3)).toList();
    if (completing.isNotEmpty && (level > 0 || rng.nextBool())) {
      return completing[rng.nextInt(completing.length)];
    }
    // 2. Safe moves that do not create a third side.
    final safe = options.where((e) => boxesOf(e).every((b) => sides(b) < 2)).toList();
    if (safe.isNotEmpty) return safe[rng.nextInt(safe.length)];
    if (level == 0) return options[rng.nextInt(options.length)];
    // 3. Give away the smallest chain.
    var best = options.first, bestGive = 1 << 30;
    for (final e in options) {
      final g = level == 2 ? _giveaway(e) : boxesOf(e).where((b) => sides(b) == 2).length;
      if (g < bestGive) {
        bestGive = g;
        best = e;
      }
    }
    return best;
  }
}
