import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/sokoban/sokoban_screen.dart';
import 'package:puzzle/ui/features/games/tower_of_hanoi/tower_of_hanoi_screen.dart';

void main() {
  test('Sokoban swipe chooses one direction and rejects ambiguous drags', () {
    expect(sokobanSwipeDirection(8, 10, 6), 1);
    expect(sokobanSwipeDirection(8, 6, 6), 3);
    expect(sokobanSwipeDirection(8, 14, 6), 2);
    expect(sokobanSwipeDirection(8, 2, 6), 0);
    expect(sokobanSwipeDirection(8, 15, 6), isNull);
    expect(sokobanSwipeDirection(8, 8, 6), isNull);
    expect(sokobanSwipeDirection(8, 14, 0), isNull);
  });

  testWidgets('Tower of Hanoi supports tap and drag without double moves',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: TowerOfHanoiScreen()));
    // Level 2 is the classic four-disc tower.
    await tester.tap(find.byTooltip('Next level'));
    await tester.pump();
    final board = find.byKey(const ValueKey('hanoi_touch_board'));
    expect(board, findsOneWidget);
    await tester.ensureVisible(board);
    final rect = tester.getRect(board);
    Offset peg(int n) => Offset(
          rect.left + rect.width * (n + .5) / 3,
          rect.center.dy,
        );

    await tester.tapAt(peg(0));
    await tester.pump();
    expect(find.text('Moves 0 · minimum 15'), findsOneWidget);
    await tester.tapAt(peg(2));
    await tester.pump();
    expect(find.text('Moves 1 · minimum 15'), findsOneWidget);

    await tester.timedDragFrom(
      peg(0), peg(1) - peg(0), const Duration(milliseconds: 250),
    );
    await tester.pump();
    expect(find.text('Moves 2 · minimum 15'), findsOneWidget);

    // A larger disc cannot be dropped onto the smaller disc on peg 3.
    await tester.timedDragFrom(
      peg(1), peg(2) - peg(1), const Duration(milliseconds: 250),
    );
    await tester.pump();
    expect(find.text('Moves 2 · minimum 15'), findsOneWidget);

    // Moving outside the surface must not clamp to the final peg.
    await tester.timedDragFrom(
      peg(2), Offset(rect.width, 0), const Duration(milliseconds: 250),
    );
    await tester.pump();
    expect(find.text('Moves 2 · minimum 15'), findsOneWidget);
  });

  testWidgets('Sokoban board handles a swipe within a scrolling game page',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: SokobanScreen()));
    final board = find.byKey(const ValueKey('sokoban_touch_board'));
    expect(board, findsOneWidget);
    await tester.ensureVisible(board);
    final rect = tester.getRect(board);
    await tester.timedDragFrom(
      rect.center, Offset(rect.width / 4, 0),
      const Duration(milliseconds: 250),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
