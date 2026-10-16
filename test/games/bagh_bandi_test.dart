import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/bagh_bandi/bagh_bandi_engine.dart';

void main() {
  test('Bagh Bandi has 2 middle tigers and four stacks of five goats', () {
    final game = BaghBandiGame();
    expect(game.tigers, {7, 17});
    expect([game.goats[1], game.goats[3], game.goats[11], game.goats[13]],
        [5, 5, 5, 5]);
    expect(game.goats.reduce((a, b) => a + b), 20);
    expect(game.turn, BandiSide.goats);
    expect(game.goats[0], 0);
  });

  test('goats move one at a time, empty source stacks, and may not restack', () {
    final game = BaghBandiGame();
    expect(game.legalMoves.any((m) => m.from == 1 && m.to == 0), isTrue);
    expect(game.legalMoves.any((m) => m.from == 1 && m.to == 3), isFalse);
    expect(game.move(const BandiMove(from: 1, to: 0)), isTrue);
    expect(game.goats[1], 4);
    expect(game.goats[0], 1);
    expect(game.turn, BandiSide.tigers);
    expect(game.move(const BandiMove(from: 1, to: 2)), isFalse);
    expect(game.goats.reduce((a, b) => a + b) + game.captured, 20);
  });

  test('tiger jumps across one goat, takes one even from a stack', () {
    final game = BaghBandiGame();
    expect(game.move(const BandiMove(from: 1, to: 6)), isTrue);
    // Row 1: empty 5, goat 6, tiger 7. Jump to 5.
    expect(game.legalMoves.any((m) => m.from == 7 &&
      m.to == 5 && m.capture == 6), isTrue);
    expect(game.move(const BandiMove(from: 7, to: 5, capture: 6)), isTrue);
    expect(game.captured, 1);
    expect(game.goats[6], 0);
    expect(game.tigers, {5, 17});
    expect(game.turn, BandiSide.goats);
  });

  test('capture removes top goat from stack, and no chain occurs', () {
    final game = BaghBandiGame();
    game.goats[1] = 3;
    game.goats[6] = 2;
    expect(game.move(const BandiMove(from: 1, to: 0)), isTrue);
    final before = game.goats[6];
    expect(game.move(const BandiMove(from: 7, to: 5, capture: 6)), isTrue);
    expect(game.goats[6], before - 1);
    expect(game.turn, BandiSide.goats);
  });

  test('goats win when neither tiger can step or leap', () {
    final game = BaghBandiGame();
    game.goats.fillRange(0, 25, 0);
    for (final index in [
      0, 1, 2, 3, 4, 5, 6, 8, 9, 10, 11, 12, 13, 14, 15, 16, 18, 19, 21, 22,
    ]) { game.goats[index] = 1; }
    game.turn = BandiSide.tigers;
    expect(game.legalMoves, isEmpty);
    expect(game.outcome, BandiOutcome.goats);
  });

  test('tigers win after all goats taken; invalid moves never mutate', () {
    final game = BaghBandiGame();
    final snap = game.toJson();
    expect(game.move(const BandiMove(from: 7, to: 12)), isFalse);
    expect(game.move(const BandiMove(from: 1, to: -1)), isFalse);
    expect(game.toJson(), snap);
    game.goats.fillRange(0, 25, 0);
    game.captured = 20;
    expect(game.outcome, BandiOutcome.tigers);
  });

  test('save integrity and randomized legal computer choices', () {
    final game = BaghBandiGame();
    final data = game.toJson();
    expect(BaghBandiGame.fromJson(data).toJson(), data);
    final chosen = game.chooseMove(Random(4), level: 2);
    expect(game.legalMoves, contains(chosen));
    expect(game.toJson(), data, reason: 'AI must not mutate during search');
    final corrupt = Map<String, dynamic>.from(data);
    corrupt['captured'] = 2;
    expect(() => BaghBandiGame.fromJson(corrupt), throwsFormatException);
    final dup = Map<String, dynamic>.from(data);
    dup['tigers'] = [7, 7];
    expect(() => BaghBandiGame.fromJson(dup), throwsFormatException);
  });
}
