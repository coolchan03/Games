import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/common/grid_board_touch_area.dart';
import 'package:puzzle/ui/features/games/nonogram/nonogram_touch.dart';

Offset centerOf(Rect board, int index, int side) {
  return Offset(
    board.left + (index % side + .5) * board.width / side,
    board.top + (index ~/ side + .5) * board.height / side,
  );
}

void main() {
  test('nonogram drag covers each horizontal and vertical intermediate square', () {
    expect(nonogramStrokeCells(8, 12, 8), [8, 9, 10, 11, 12]);
    expect(nonogramStrokeCells(1, 25, 8), [1, 9, 17, 25]);
    expect(nonogramStrokeCells(12, 8, 8), [12, 11, 10, 9, 8]);
    expect(nonogramStrokeCells(0, 18, 8), [0, 9, 18]);
    expect(nonogramStrokeCells(7, 56, 8),
        [7, 14, 21, 28, 35, 42, 49, 56]);
  });

  test('nonogram drag validates endpoints and tiny boards', () {
    expect(nonogramStrokeCells(-1, 2, 8), isEmpty);
    expect(nonogramStrokeCells(1, 64, 8), isEmpty);
    expect(nonogramStrokeCells(1, 2, 0), isEmpty);
    expect(nonogramStrokeCells(15, 15, 8), [15]);
  });

  test('paint helper is atomic and never toggles repeated squares', () {
    final original = List.generate(8, (_) => List.filled(8, 0));
    final marked = paintNonogramCells(
        original, [8, 9, 10, 10, 10], value: 1);
    expect(original[1][0], 0, reason: 'Original state stays immutable');
    expect(marked[1].take(4), [1, 1, 1, 0]);
    expect(identical(marked, original), isFalse);
    expect(identical(
      paintNonogramCells(marked, [9, 8, 10, 9], value: 1), marked), isTrue);
    final crossed = paintNonogramCells(marked, [18, 19], value: 2);
    expect(crossed[2].sublist(2, 4), [2, 2]);
    expect(crossed[1][0], 1);
    expect(paintNonogramCells(crossed, [900, -3], value: 1),
        same(crossed));
    expect(paintNonogramCells(crossed, [3], value: 0), same(crossed));
  });

  testWidgets('phone-sized board supports fill and mark drags, no double taps',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    var grid = List.generate(8, (_) => List.filled(8, 0));
    var markMode = false;
    final taps = <int>[];
    final strokes = <(int, int)>[];

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ListView(children: [
          Center(
            child: SizedBox(
              width: 256,
              height: 256,
              child: GridBoardTouchArea(
                key: const ValueKey('nonogram_test_board'),
                columns: 8,
                rows: 8,
                onTapCell: taps.add,
                onDragCell: (from, to) {
                  strokes.add((from, to));
                  grid = paintNonogramCells(
                    grid,
                    nonogramStrokeCells(from, to, 8),
                    value: markMode ? 2 : 1,
                  );
                },
                child: const ColoredBox(color: Colors.white),
              ),
            ),
          ),
        ]),
      ),
    ));
    final board = tester.getRect(
        find.byKey(const ValueKey('nonogram_test_board')));

    final first = centerOf(board, 8, 8);
    final last = centerOf(board, 12, 8);
    await tester.timedDragFrom(
        first, last - first, const Duration(milliseconds: 280));
    await tester.pump();
    expect(strokes, [(8, 12)]);
    expect(taps, isEmpty);
    expect(grid[1].take(5), [1, 1, 1, 1, 1]);

    markMode = true;
    final m0 = centerOf(board, 24, 8);
    final m4 = centerOf(board, 28, 8);
    await tester.timedDragFrom(
        m0, m4 - m0, const Duration(milliseconds: 280));
    await tester.pump();
    expect(strokes.length, 2);
    expect(grid[3].take(5), [2, 2, 2, 2, 2]);

    // Outside-board drops and cancelled gestures must leave the grid as is.
    final before = grid.map((row) => List<int>.from(row)).toList();
    await tester.timedDragFrom(
      centerOf(board, 18, 8),
      const Offset(450, 0),
      const Duration(milliseconds: 280),
    );
    await tester.pump();
    expect(grid, before);
    final touch = await tester.startGesture(centerOf(board, 33, 8));
    await touch.moveTo(centerOf(board, 37, 8));
    await touch.cancel();
    await tester.pump();
    expect(grid, before);

    await tester.tapAt(centerOf(board, 55, 8));
    await tester.pump();
    expect(taps, [55]);
  });
}
