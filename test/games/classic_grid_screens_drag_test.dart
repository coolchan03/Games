import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/alquerque/alquerque_screen.dart';
import 'package:puzzle/ui/features/games/alquerque/alquerque_engine.dart';
import 'package:puzzle/ui/features/games/bagh_chal/bagh_chal_screen.dart';
import 'package:puzzle/ui/features/games/bagh_chal/bagh_chal_engine.dart';
import 'package:puzzle/ui/features/games/neutron/neutron_screen.dart';
import 'package:puzzle/ui/features/games/neutron/neutron_engine.dart';
import 'package:puzzle/ui/features/games/common/grid_board_touch_area.dart';

Offset _center(Rect rect, int cell) => Offset(
  rect.left + ((cell % 5) + .5) * rect.width / 5,
  rect.top + ((cell ~/ 5) + .5) * rect.height / 5,
);

void main() {
  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  testWidgets('Alquerque phone drag executes one legal move', (tester) async {
    phone(tester);
    await tester.pumpWidget(const MaterialApp(home: AlquerqueScreen()));
    final dynamic state = tester.state(find.byType(AlquerqueScreen));
    state.vsComputer = false; // A deterministic pass-and-play gesture test.
    final AlquerqueState engine = state.game as AlquerqueState;
    final move = engine.moves().first;
    final board = tester.getRect(find.byType(GridBoardTouchArea));
    final start = _center(board, move.from);
    final end = _center(board, move.to);
    await tester.timedDragFrom(start, end - start,
        const Duration(milliseconds: 280));
    await tester.pump();
    expect(engine.cells[move.from], 0);
    expect(engine.cells[move.to], 1);
    expect(engine.turn, 2);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Bagh Chal tiger drag works without two-person gestures',
      (tester) async {
    phone(tester);
    await tester.pumpWidget(const MaterialApp(home: BaghChalScreen()));
    final dynamic state = tester.state(find.byType(BaghChalScreen));
    final BaghState engine = state.game as BaghState;
    state.vsComputer = false;
    engine.turn = 2;
    final move = engine.moves().first;
    final board = tester.getRect(find.byType(GridBoardTouchArea));
    final start = _center(board, move.from!);
    final end = _center(board, move.to);
    await tester.timedDragFrom(start, end - start,
        const Duration(milliseconds: 260));
    await tester.pump();
    expect(engine.cells[move.from!], 0);
    expect(engine.cells[move.to], 2);
    expect(engine.turn, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Neutron phone drag makes the opening piece slide',
      (tester) async {
    phone(tester);
    await tester.pumpWidget(const MaterialApp(home: NeutronScreen()));
    final dynamic state = tester.state(find.byType(NeutronScreen));
    final NeutronState engine = state.game as NeutronState;
    state.vsComputer = false;
    final move = engine.moves().first;
    final board = tester.getRect(find.byType(GridBoardTouchArea));
    final start = _center(board, move.from);
    final end = _center(board, move.to);
    await tester.timedDragFrom(start, end - start,
        const Duration(milliseconds: 260));
    await tester.pump();
    expect(engine.cells[move.from], 0);
    expect(engine.cells[move.to], 1);
    expect(engine.turn, 2);
    await tester.pumpWidget(const SizedBox());
  });
}
