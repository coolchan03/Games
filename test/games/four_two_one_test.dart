import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/four_two_one/four_two_one_engine.dart';

void main() {
  test('421 combinations are ordered, not merely summed', () {
    expect(FourTwoOneHand([4, 2, 1]).strength,
        greaterThan(FourTwoOneHand([1, 1, 6]).strength));
    expect(FourTwoOneHand([1, 1, 6]).strength,
        greaterThan(FourTwoOneHand([1, 1, 1]).strength));
    expect(FourTwoOneHand([6, 6, 6]).strength,
        greaterThan(FourTwoOneHand([6, 5, 4]).strength));
    expect(FourTwoOneHand([6, 5, 4]).strength,
        greaterThan(FourTwoOneHand([6, 6, 5]).strength));
    expect(FourTwoOneHand([2, 2, 1]).strength,
        lessThan(FourTwoOneHand([1, 2, 3]).strength));
    expect(FourTwoOneHand([4, 2, 1]).chips, 10);
    expect(FourTwoOneHand([1, 1, 1]).chips, 7);
    expect(FourTwoOneHand([6, 5, 4]).chips, 2);
    expect(() => FourTwoOneHand([7, 1, 2]), throwsArgumentError);
  });

  test('charge gives the worst player chips and conserves 21', () {
    final game = FourTwoOneGame(players: 2, random: Random(1));
    expect(game.phase, FourTwoOnePhase.charge);
    expect(game.bank, 21);
    expect(game.roll(fixed: [4, 2, 1]), isTrue);
    expect(game.stop(), isTrue);
    expect(game.rollLimit, 1);
    expect(game.roll(fixed: [3, 3, 2]), isTrue);
    expect(game.roll(fixed: [4, 2, 1]), isFalse,
        reason: 'the leader set a one-roll limit');
    expect(game.stop(), isTrue);
    expect(game.bank, 11);
    expect(game.chips, [0, 10]);
    expect(game.chips.reduce((a, b) => a + b) + game.bank, 21);
  });

  test('held dice stay unchanged across rerolls and cap at three throws', () {
    final game = FourTwoOneGame(players: 2, random: Random(2));
    expect(game.roll(fixed: [4, 5, 6]), isTrue);
    expect(game.hold(0), isTrue);
    expect(game.roll(fixed: [1, 2, 3]), isTrue);
    expect(game.dice, [4, 2, 3]);
    expect(game.roll(fixed: [1, 2, 1]), isTrue);
    expect(game.roll(), isFalse);
    expect(game.stop(), isTrue);
    expect(game.rollLimit, 3);
  });

  test('tied low dice trigger a replay without forfeiting chips', () {
    final game = FourTwoOneGame(players: 2, random: Random(8));
    for (var i = 0; i < 2; i++) {
      expect(game.roll(fixed: [6, 5, 3]), isTrue);
      expect(game.stop(), isTrue);
    }
    expect(game.bank, 21);
    expect(game.roundNumber, 2);
    expect(game.chips, [0, 0]);
  });

  test('save, restore, invalid data and seeded computer play', () {
    final game = FourTwoOneGame(players: 3, random: Random(9));
    game.roll(fixed: [4, 2, 1]);
    game.hold(0);
    final saved = game.toJson();
    expect(FourTwoOneGame.fromJson(saved).toJson(), saved);
    final broken = Map<String, dynamic>.from(saved);
    broken['bank'] = 999;
    expect(() => FourTwoOneGame.fromJson(broken), throwsFormatException);
    final before = game.current;
    expect(game.autoTurn(), isTrue);
    expect(game.current, isNot(before));
    expect(game.chips.fold<int>(game.bank, (sum, n) => sum + n), 21);
  });
}
