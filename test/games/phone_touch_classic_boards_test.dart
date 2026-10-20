import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/checkers/checkers_screen.dart';
import 'package:puzzle/ui/features/games/checkers/engine/checkers_rules.dart';
import 'package:puzzle/ui/features/games/peg_solitaire/peg_solitaire_screen.dart';
import 'package:puzzle/ui/features/games/peg_solitaire/peg_solitaire_engine.dart';
import 'package:puzzle/ui/features/games/chess/chess_screen.dart';
import 'package:puzzle/ui/features/games/chess/engine/models/chess_state.dart';
import 'package:puzzle/ui/features/games/chess/engine/models/enums.dart';
import 'package:puzzle/ui/features/games/common/grid_board_touch_area.dart';

Offset cellCenter(Rect rect, int index, int columns) => Offset(
      rect.left + (index % columns + .5) * rect.width / columns,
      rect.top + (index ~/ columns + .5) * rect.height / columns,
    );

void phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('drag origin remains original cell near a grid boundary',
      (tester) async {
    phone(tester);
    final taps = <int>[];
    final drags = <(int, int)>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 250,
            height: 250,
            child: GridBoardTouchArea(
              key: const ValueKey('edge_board'),
              columns: 5,
              onTapCell: taps.add,
              onDragCell: (from, to) => drags.add((from, to)),
              child: const ColoredBox(color: Colors.blue),
            ),
          ),
        ),
      ),
    ));
    final top = tester.getTopLeft(find.byKey(const ValueKey('edge_board')));
    await tester.timedDragFrom(
      top + const Offset(49, 25),
      const Offset(70, 0),
      const Duration(milliseconds: 270),
    );
    await tester.pump();
    expect(drags, [(0, 2)]);
    expect(taps, isEmpty);
  });

  testWidgets('Checkers drag plays a legal move in a scrolling phone page',
      (tester) async {
    phone(tester);
    await tester.pumpWidget(const MaterialApp(home: CheckersScreen()));
    await tester.tap(find.text('Play against computer'));
    await tester.pump();
    final dynamic checkersState = tester.state(find.byType(CheckersScreen));
    expect(checkersState.versusAi, isFalse,
        reason: 'Checkers must be in deterministic pass-and-play mode');
    final board = find.byKey(const ValueKey('checkers_touch_board'));
    await tester.ensureVisible(board);
    final rect = tester.getRect(board);
    final move = CheckersPosition.start().legalMoves.first;
    final from = cellCenter(rect, move.from, 8);
    final to = cellCenter(rect, move.to, 8);
    await tester.timedDragFrom(
      from, to - from, const Duration(milliseconds: 280),
    );
    await tester.pump();
    expect(find.text('Player 2 to move'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Checkers retains tap selection and rejects outside drops',
      (tester) async {
    phone(tester);
    await tester.pumpWidget(const MaterialApp(home: CheckersScreen()));
    await tester.tap(find.text('Play against computer'));
    await tester.pump();
    final dynamic checkersState = tester.state(find.byType(CheckersScreen));
    expect(checkersState.versusAi, isFalse,
        reason: 'Checkers must be in deterministic pass-and-play mode');
    final board = find.byKey(const ValueKey('checkers_touch_board'));
    await tester.ensureVisible(board);
    final rect = tester.getRect(board);
    final move = CheckersPosition.start().legalMoves.first;
    final from = cellCenter(rect, move.from, 8);
    final to = cellCenter(rect, move.to, 8);
    await tester.timedDragFrom(
      from, const Offset(-500, 0), const Duration(milliseconds: 280),
    );
    await tester.pump();
    expect(find.text('Player 1 to move'), findsOneWidget);
    await tester.tapAt(from);
    await tester.pump();
    await tester.tapAt(to);
    await tester.pump();
    expect(find.text('Player 2 to move'), findsOneWidget);
  });

  testWidgets('Peg Solitaire drags a legal jump with no duplicate tap',
      (tester) async {
    phone(tester);
    await tester.pumpWidget(const MaterialApp(home: PegSolitaireScreen()));
    final board = find.byKey(const ValueKey('peg_solitaire_touch_board'));
    await tester.ensureVisible(board);
    final rect = tester.getRect(board);
    final initial = PegBoard();
    final from = List.generate(49, (i) => i)
        .firstWhere((i) => initial.targets(i).isNotEmpty);
    final to = initial.targets(from).first;
    final start = cellCenter(rect, from, 7);
    final end = cellCenter(rect, to, 7);
    await tester.timedDragFrom(
      start, end - start, const Duration(milliseconds: 280),
    );
    await tester.pump();
    expect(find.text('31 pegs left'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Peg Solitaire ignores invalid drops and keeps tap fallback',
      (tester) async {
    phone(tester);
    await tester.pumpWidget(const MaterialApp(home: PegSolitaireScreen()));
    final board = find.byKey(const ValueKey('peg_solitaire_touch_board'));
    await tester.ensureVisible(board);
    final rect = tester.getRect(board);
    final initial = PegBoard();
    final from = List.generate(49, (i) => i)
        .firstWhere((i) => initial.targets(i).isNotEmpty);
    final to = initial.targets(from).first;
    final start = cellCenter(rect, from, 7);
    await tester.timedDragFrom(
      start, const Offset(-500, 0), const Duration(milliseconds: 280),
    );
    await tester.pump();
    expect(find.text('32 pegs left'), findsOneWidget);
    await tester.tapAt(start);
    await tester.pump();
    await tester.tapAt(cellCenter(rect, to, 7));
    await tester.pump();
    expect(find.text('31 pegs left'), findsOneWidget);
  });

  test('Chess flipped display maps precisely to board coordinates', () {
    expect(chessCellForDisplay(0, false), 0);
    expect(chessCellForDisplay(0, true), 63);
    expect(chessCellForDisplay(63, true), 0);
    expect(chessCellForDisplay(16, true), 47);
  });

  testWidgets('Chess drag completes a legal move on a portrait phone',
      (tester) async {
    phone(tester);
    await tester.pumpWidget(const MaterialApp(home: ChessScreen()));
    final dynamic state = tester.state(find.byType(ChessScreen));
    state.vsComputer = false;
    final board = find.byKey(const ValueKey('chess_touch_board'));
    await tester.ensureVisible(board);
    final rect = tester.getRect(board);
    final game = state.game as ChessState;
    final move = game.getLegalMovesForSquare(6, 0).first;
    final from = cellCenter(rect, move.fromRow * 8 + move.fromCol, 8);
    final to = cellCenter(rect, move.toRow * 8 + move.toCol, 8);
    await tester.timedDragFrom(
      from, to - from, const Duration(milliseconds: 280),
    );
    await tester.pump();
    expect((state.game as ChessState).currentTurn, PieceColor.black);
    expect((state.game as ChessState).pieceAt(6, 0), isNull);
  });

  testWidgets('Flipped Chess drag uses screen coordinates, not raw squares',
      (tester) async {
    phone(tester);
    await tester.pumpWidget(const MaterialApp(home: ChessScreen()));
    final dynamic state = tester.state(find.byType(ChessScreen));
    state.vsComputer = false;
    final flip = find.text('Flip board');
    await tester.ensureVisible(flip);
    await tester.tap(flip);
    await tester.pump();
    final board = find.byKey(const ValueKey('chess_touch_board'));
    await tester.ensureVisible(board);
    final rect = tester.getRect(board);
    final move = (state.game as ChessState)
        .getLegalMovesForSquare(7, 1)
        .first;
    final fromIndex = 63 - (move.fromRow * 8 + move.fromCol);
    final toIndex = 63 - (move.toRow * 8 + move.toCol);
    final from = cellCenter(rect, fromIndex, 8);
    final to = cellCenter(rect, toIndex, 8);
    await tester.timedDragFrom(
      from, to - from, const Duration(milliseconds: 280),
    );
    await tester.pump();
    expect((state.game as ChessState).currentTurn, PieceColor.black);
    expect((state.game as ChessState).pieceAt(7, 1), isNull);
  });
}
