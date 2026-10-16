import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/ludo/ludo_engine.dart' show cellFor;
import 'package:puzzle/ui/features/games/petits_chevaux/petits_chevaux_engine.dart';

void main() {
  test('horses need a six to leave the stable and keep the extra turn', () {
    final game = PetitsChevauxGame(seats: [0, 1], random: Random(4));
    expect(game.roll(fixed: 3), isFalse);
    expect(game.current, 1);
    game.current = 0;
    expect(game.roll(fixed: 6), isTrue);
    expect(game.legalMoves.map((m) => m.piece).toSet(), {0, 1, 2, 3});
    expect(game.play(0), isTrue);
    expect(game.steps[0]![0], 0);
    expect(game.current, 0, reason: 'six awards another turn');
    expect(game.roll(fixed: 1), isTrue);
    expect(game.play(0), isTrue);
    expect(game.current, 1);
  });

  test('exact arrival and the 1-2-3-4-5-6 finishing staircase', () {
    final game = PetitsChevauxGame(seats: [0, 1], random: Random(7));
    game.steps[0]![0] = 50;
    expect(game.movesFor(2), isEmpty);
    expect(game.movesFor(1).single.to, 51);
    game.steps[0]![0] = 51;
    expect(game.movesFor(2), isEmpty);
    expect(game.movesFor(1).single.to, 52);
    game.steps[0]![0] = 53;
    expect(game.movesFor(3).single.to, 54);
    expect(game.movesFor(2), isEmpty);
    game.steps[0]![0] = 56;
    expect(game.movesFor(6).firstWhere((m) => m.piece == 0).to, 57);
    expect(game.movesFor(5), isEmpty);
  });

  test('landing on an enemy sends it home, including on starting squares', () {
    final game = PetitsChevauxGame(seats: [0, 1], random: Random(2));
    final target = cellFor(0, 6).join(',');
    final opposite = List.generate(51, (i) => i)
        .firstWhere((i) => cellFor(1, i).join(',') == target);
    game.steps[0]![0] = 5;
    game.steps[1]![0] = opposite;
    expect(game.roll(fixed: 1), isTrue);
    expect(game.play(0), isTrue);
    expect(game.steps[0]![0], 6);
    expect(game.steps[1]![0], -1);
    expect(game.current, 1, reason: 'captures do not grant extra turns');
  });

  test('blocked or invalid moves never alter the board', () {
    final game = PetitsChevauxGame(seats: [0, 1], random: Random(2));
    final before = game.toJson();
    expect(game.play(0), isFalse);
    expect(game.toJson(), before);
    expect(() => game.roll(fixed: 7), throwsArgumentError);
    expect(game.toJson(), before);
  });


  test('two friendly horses cannot end on the same track or stair cell', () {
    final game = PetitsChevauxGame(seats: [0, 1], random: Random(2));
    game.steps[0]![0] = 5;
    game.steps[0]![1] = 6;
    expect(game.movesFor(1).any((move) => move.piece == 0), isFalse);
    game.steps[0]![0] = 52;
    game.steps[0]![1] = 53;
    expect(game.movesFor(2).any((move) => move.piece == 0), isFalse);
    // The shared finishing center must accept all four completed horses.
    game.steps[0]![0] = 56;
    game.steps[0]![1] = 57;
    expect(game.movesFor(6).any((move) => move.piece == 0 && move.to == 57), isTrue);
  });

  test('round-trip save, corrupt save rejection, and AI legal moves', () {
    final game = PetitsChevauxGame(seats: [0, 1, 3],
        computer: {1, 3}, random: Random(8));
    game.roll(fixed: 6);
    game.play(0);
    game.roll(fixed: 1);
    final data = game.toJson();
    final restored = PetitsChevauxGame.fromJson(data);
    expect(restored.toJson(), data);
    expect(restored.choose(2).piece, isIn([0, 1, 2, 3]));
    final corrupt = Map<String, dynamic>.from(data);
    corrupt['current'] = 9;
    expect(() => PetitsChevauxGame.fromJson(corrupt), throwsFormatException);
  });
}
