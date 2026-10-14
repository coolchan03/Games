import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/shared/playing_cards.dart';
import 'package:puzzle/ui/features/games/poker/poker_evaluator.dart';
import 'package:puzzle/ui/features/games/poker/poker_table.dart';

PokerRank rank(String codes) => evaluatePoker(codes.split(' ').map(PlayingCard.parse).toList());
void main() {
  test('all nine categories and royal flush have correct ordering', () {
    final examples = ['As Ks Qs Js Ts', '9c 9d 9h 9s 2d', 'Ac Ad Ah 2s 2d',
      'As Js 8s 5s 2s', '9c 8h 7d 6s 5c', 'Qc Qh Qs 9d 2c',
      'Jc Jh 8s 8d 2c', 'Ac Ah 9s 4d 2c', 'Ac Jh 9s 4d 2c'];
    final values = examples.map(rank).map((r) => r.value).toList();
    expect(values.first, 1);
    expect(values, orderedEquals([...values]..sort()));
    expect(values.toSet().length, 9);
  });
  test('wheel is a five-high straight, not ace-high', () {
    expect(rank('As 2d 3h 4c 5s').name, 'Straight');
    expect(rank('As 2d 3h 4c 5s').value, greaterThan(rank('2s 3d 4h 5c 6s').value));
  });
  test('kickers matter and suits never break a tie', () {
    expect(rank('Ac Ad Ks 8h 4c').value, lessThan(rank('Ah As Qd 8c 4s').value));
    expect(rank('Ac Ad Ks 8h 4c').value, rank('Ah As Kd 8c 4s').value);
  });
  test('best of seven can use the board alone', () {
    expect(rank('As Ks Qs Js Ts 2c 3d').value, 1);
    expect(rank('Ac Ad Ah Kc Kd Kh 2s').name, 'Full house');
  });
  test('duplicate cards are rejected', () {
    expect(() => rank('As As 2c 3d 4h'), throwsArgumentError);
  });
  test('main and side pots conserve chips and exclude folded players', () {
    expect(distributePokerPots([50, 100, 100], [false, false, false], [1, 2, 3], 0), [150, 100, 0]);
    expect(distributePokerPots([50, 100, 100], [true, false, false], [1, 2, 3], 0), [0, 250, 0]);
    expect(distributePokerPots([100, 50], [false, false], [2, 1], 0), [50, 100]);
  });
  test('odd chips go clockwise after dealer', () {
    expect(distributePokerPots([5, 5, 5], [false, false, true], [1, 1, 3], 0), [7, 8, 0]);
  });
  test('heads-up blinds and fold finish one hand', () {
    final game = PokerTable(random: Random(1));
    expect(game.current, 0); expect(game.toCall, 5); expect(game.pot, 15);
    expect(game.act(PokerAction.fold), true); expect(game.ended, true);
    expect(game.stacks, [195, 205]);
  });
  test('big blind receives its option after a call', () {
    final game = PokerTable(random: Random(2));
    game.act(PokerAction.checkCall);
    expect(game.current, 1); expect(game.toCall, 0); expect(game.phase, PokerPhase.preflop);
    game.act(PokerAction.checkCall);
    expect(game.community.length, 3); expect(game.current, 1);
  });
  test('draw validates replacements without destroying cards', () {
    final game = PokerTable(variant: PokerVariant.draw, seats: 6, random: Random(4));
    while (game.phase != PokerPhase.draw) { game.act(PokerAction.checkCall); }
    expect(game.replaceCards({0, 1, 2, 3}), false);
    while (game.phase == PokerPhase.draw) { expect(game.replaceCards({0, 1, 2}), true); }
    expect(game.deck.remaining, 4);
    expect(PokerTable.fromJson(game.toJson()).deck.ids, game.deck.ids);
  });
  test('random legal hands across variants conserve cards, chips and saves', () {
    final random = Random(493);
    for (final variant in PokerVariant.values) {
      for (var seed = 0; seed < 80; seed++) {
        var game = PokerTable(variant: variant, seats: 2 + seed % 5,
          startingStacks: List.generate(2 + seed % 5, (i) => 10 + (i + 1) * 13), random: Random(seed));
        var actions = 0;
        while (!game.ended && actions++ < 160) {
          if (game.phase == PokerPhase.draw) { game.replaceCards({0, 1, 2}); }
          else {
            final action = game.canRaise && random.nextBool() ? PokerAction.raise
              : random.nextInt(8) == 0 ? PokerAction.fold : PokerAction.checkCall;
            expect(game.act(action), true);
          }
          game = PokerTable.fromJson(game.toJson());
        }
        expect(game.ended, true, reason: '$variant/$seed');
        expect(game.stacks.reduce((a, b) => a + b), game.initialChips);
      }
    }
  });
  test('corrupt duplicate-card save is refused', () {
    final game = PokerTable(random: Random(22));
    final data = game.toJson();
    (data['deck'] as List)[0] = game.hands[0][0].id;
    expect(() => PokerTable.fromJson(data), throwsFormatException);
  });
}
