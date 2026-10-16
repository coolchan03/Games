import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/common/grid_board_touch_area.dart';

void main() {
  test('cell hit test rejects outside or unmeasured board positions', () {
    const size = Size(250, 250);
    expect(boardCellForPoint(const Offset(74, 24), size, columns: 5), 1);
    expect(boardCellForPoint(const Offset(249, 249), size, columns: 5), 24);
    expect(boardCellForPoint(const Offset(-1, 30), size, columns: 5), isNull);
    expect(boardCellForPoint(const Offset(250, 10), size, columns: 5), isNull);
    expect(boardCellForPoint(const Offset(20, 250), size, columns: 5), isNull);
    expect(boardCellForPoint(const Offset(1, 1), Size.zero, columns: 5), isNull);
  });

  testWidgets('tap invokes exactly one cell action, even in a scroll view',
      (tester) async {
    final taps = <int>[];
    final drops = <(int, int)>[];
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: ListView(
      children: [Center(child: SizedBox(width: 250, height: 250,
        child: GridBoardTouchArea(
          key: const ValueKey('board'),
          columns: 5,
          onTapCell: taps.add,
          onDragCell: (from, to) => drops.add((from, to)),
          child: const ColoredBox(color: Colors.amber),
        ),
      ))],
    ))));
    final top = tester.getTopLeft(find.byKey(const ValueKey('board')));
    await tester.tapAt(top + const Offset(75, 25));
    await tester.pump();
    expect(taps, [1]);
    expect(drops, isEmpty);
  });

  testWidgets('long drag chooses source and actual destination without tap',
      (tester) async {
    final taps = <int>[];
    final drops = <(int, int)>[];
    final sources = <int>[];
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: Center(child: SizedBox(
        width: 250, height: 250,
        child: GridBoardTouchArea(
          key: const ValueKey('board'),
          columns: 5,
          onTapCell: taps.add,
          onDragCell: (from, to) => drops.add((from, to)),
          onDragStartCell: sources.add,
          child: const ColoredBox(color: Colors.blue),
        ),
      )),
    )));
    final origin = tester.getTopLeft(find.byKey(const ValueKey('board')));
    await tester.timedDragFrom(origin + const Offset(25, 25),
        const Offset(110, 50), const Duration(milliseconds: 250));
    await tester.pump();
    expect(drops, [(0, 7)]);
    expect(sources, [0]);
    expect(taps, isEmpty, reason: 'Dragging must not activate the tap handler');
  });

  testWidgets('off-board and cancelled drops never move a piece', (tester) async {
    final drops = <(int, int)>[];
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: Center(child: SizedBox(width: 250, height: 250,
        child: GridBoardTouchArea(
          key: const ValueKey('board'),
          columns: 5,
          onTapCell: (_) {},
          onDragCell: (from, to) => drops.add((from, to)),
          child: const ColoredBox(color: Colors.blue),
        ),
      )),
    )));
    final pos = tester.getTopLeft(find.byKey(const ValueKey('board')));
    await tester.timedDragFrom(pos + const Offset(25, 25),
        const Offset(-90, 10), const Duration(milliseconds: 250));
    expect(drops, isEmpty);
    final touch = await tester.startGesture(pos + const Offset(25, 25));
    await touch.moveBy(const Offset(75, 75));
    await touch.cancel();
    await tester.pump();
    expect(drops, isEmpty);
  });
}
