import 'package:flutter/material.dart';

/// A precise, bounds-checked pointer-to-grid mapping shared by board games.
/// Rejects accidental outside-board drops instead of clamping to an edge cell.
int? boardCellForPoint(Offset point, Size size,
    {required int columns, int rows = 5}) {
  if (columns <= 0 || rows <= 0 ||
      !size.width.isFinite || !size.height.isFinite ||
      size.width <= 0 || size.height <= 0 ||
      !point.dx.isFinite || !point.dy.isFinite ||
      point.dx < 0 || point.dy < 0 ||
      point.dx >= size.width || point.dy >= size.height) {
    return null;
  }
  final x = (point.dx * columns / size.width).floor();
  final y = (point.dy * rows / size.height).floor();
  return y * columns + x;
}

/// Shared phone-first touch surface for grid games.
///
/// - A tap selects the origin or the target, which can remain highlighted.
/// - A drag moves from its actual origin to its actual destination.
/// - Gestures outside the board, cancelled gestures, and same-cell drags
///   never activate a game move.
/// - The pan recognizer claims board drags from the parent scrolling page.
///   No cell-level tap detectors should be placed underneath this surface.
class GridBoardTouchArea extends StatefulWidget {
  const GridBoardTouchArea({
    super.key,
    required this.columns,
    this.rows = 5,
    required this.onTapCell,
    required this.onDragCell,
    this.onDragStartCell,
    required this.child,
  });

  final int columns, rows;
  final ValueChanged<int> onTapCell;
  final void Function(int from, int to) onDragCell;
  final ValueChanged<int>? onDragStartCell;
  final Widget child;

  @override
  State<GridBoardTouchArea> createState() => _GridBoardTouchAreaState();
}

class _GridBoardTouchAreaState extends State<GridBoardTouchArea> {
  int? _dragFrom;
  Offset? _lastPoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);

      int? hit(Offset point) => boardCellForPoint(
            point, size, columns: widget.columns, rows: widget.rows);

      void resetDrag() {
        _dragFrom = null;
        _lastPoint = null;
      }

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (details) {
          final cell = hit(details.localPosition);
          if (cell != null) widget.onTapCell(cell);
        },
        onPanStart: (details) {
          _dragFrom = hit(details.localPosition);
          _lastPoint = details.localPosition;
          if (_dragFrom != null) widget.onDragStartCell?.call(_dragFrom!);
        },
        onPanUpdate: (details) {
          _lastPoint = details.localPosition;
        },
        onPanEnd: (_) {
          final from = _dragFrom;
          final to = _lastPoint == null ? null : hit(_lastPoint!);
          resetDrag();
          if (from != null && to != null && from != to) {
            widget.onDragCell(from, to);
          }
        },
        onPanCancel: resetDrag,
        child: widget.child,
      );
    });
  }
}
