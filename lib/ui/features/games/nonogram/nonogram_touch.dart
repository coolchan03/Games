/// Helpers for drag painting on a nonogram grid.
///
/// Cell indices use row-major order, from 0 through size * size - 1.
/// A drag paints once on release, so cancelling a gesture leaves the puzzle
/// unchanged and visiting the same cell twice does not toggle it away.
List<int> nonogramStrokeCells(int from, int to, int size) {
  if (size <= 0 || from < 0 || to < 0 ||
      from >= size * size || to >= size * size) {
    return const <int>[];
  }

  var x0 = from % size;
  var y0 = from ~/ size;
  final x1 = to % size;
  final y1 = to ~/ size;
  final dx = (x1 - x0).abs();
  final dy = (y1 - y0).abs();
  final sx = x0 < x1 ? 1 : -1;
  final sy = y0 < y1 ? 1 : -1;
  var error = dx - dy;

  final cells = <int>[];
  while (true) {
    cells.add(y0 * size + x0);
    if (x0 == x1 && y0 == y1) break;
    final twiceError = error * 2;
    if (twiceError > -dy) {
      error -= dy;
      x0 += sx;
    }
    if (twiceError < dx) {
      error += dx;
      y0 += sy;
    }
  }
  return cells;
}

/// Copy-on-write painting: mark/fill never toggles already painted cells.
/// Returns the original grid if no valid cell needs an update.
List<List<int>> paintNonogramCells(
  List<List<int>> grid,
  Iterable<int> cells, {
  required int value,
}) {
  if (grid.isEmpty || (value != 1 && value != 2)) return grid;
  final size = grid.length;
  if (grid.any((row) => row.length != size)) return grid;
  List<List<int>>? changed;
  for (final index in cells.toSet()) {
    if (index < 0 || index >= size * size) continue;
    final row = index ~/ size;
    final col = index % size;
    if ((changed ?? grid)[row][col] == value) continue;
    changed ??= grid.map((line) => List<int>.from(line)).toList();
    changed[row][col] = value;
  }
  return changed ?? grid;
}
