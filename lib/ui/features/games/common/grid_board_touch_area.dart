import 'package:flutter/material.dart';

/// A precise, bounds-checked pointer-to-grid mapping shared by board games.
/// Rejects accidental outside-board drops instead of clamping to an edge cell.
int? boardCellForPoint(Offset point, Size size,
    {required int columns, int rows = 5}) {
  if (columns <= 0 ||
      rows <= 0 ||
      !size.width.isFinite ||
      !size.height.isFinite ||
      size.width <= 0 ||
      size.height <= 0 ||
      !point.dx.isFinite ||
      !point.dy.isFinite ||
      point.dx < 0 ||
      point.dy < 0 ||
      point.dx >= size.width ||
      point.dy >= size.height) {
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
  int? _activePointer;
  int? _dragFrom;
  Offset? _pointerDownPoint;

  void _resetDrag() {
    _activePointer = null;
    _dragFrom = null;
    _pointerDownPoint = null;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);

      int? hit(Offset point) => boardCellForPoint(point, size,
          columns: widget.columns, rows: widget.rows);

      void beginDrag(DragStartDetails details) {
        // Use the original finger-down square, not the post-slop location.
        _dragFrom = hit(_pointerDownPoint ?? details.localPosition);
        if (_dragFrom != null) widget.onDragStartCell?.call(_dragFrom!);
      }

      // Only a real PointerUp may commit a move; PointerCancel must not.
      return Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (event) {
          if (_activePointer != null) return;
          _activePointer = event.pointer;
          _pointerDownPoint = event.localPosition;
        },
        onPointerUp: (event) {
          if (event.pointer != _activePointer) return;
          final from = _dragFrom;
          final to = hit(event.localPosition);
          _resetDrag();
          if (from != null && to != null && from != to) {
            widget.onDragCell(from, to);
          }
        },
        onPointerCancel: (event) {
          if (event.pointer == _activePointer) _resetDrag();
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) {
            final cell = hit(details.localPosition);
            _resetDrag();
            if (cell != null) widget.onTapCell(cell);
          },
          // A diagonal one-cell move must beat the outer ListView's
          // vertical scroll recognizer instead of being swallowed by it.
          onHorizontalDragStart: beginDrag,
          onVerticalDragStart: beginDrag,
          child: widget.child,
        ),
      );
    });
  }
}
