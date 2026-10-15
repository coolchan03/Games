import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/dice_421/dice_421_game.dart';

void main() {
  test('421 outranks triple ones, fiches, triples, runs and nenette', () {
    final combos = [[4, 2, 1], [1, 1, 1], [1, 1, 6],
      [6, 6, 6], [6, 5, 4], [6, 5, 3], [2, 2, 1]];
    for (var i = 0; i < combos.length - 1; i++) {
      expect(Dice421Hand(combos[i]).strength,
          greaterThan(Dice421Hand(combos[i + 1]).strength));
    }
    expect(Dice421Hand([1, 4, 2]).strength, Dice421Hand([4, 2, 1]).strength);
    expect(Dice421Hand([4, 2, 1]).chips, 10);
    expect(Dice421Hand([1, 1, 1]).chips, 7);
    expect(Dice421Hand([6, 6, 6]).chips, 6);
    expect(() => Dice421Hand([0, 2, 7]), throwsArgumentError);
  });

  test('held dice never change and only three throws per turn', () {
    final game = Dice421Game(players: 2, random: Random(4));
    expect(game.stand(), isFalse);
    expect(game.roll(), isTrue);
    final kept = game.dice[0];
    expect(game.toggleHeld(0), isTrue);
    expect(game.roll(), isTrue);
    expect(game.roll(), isTrue);
    expect(game.dice[0], kept);
    expect(game.roll(), isFalse);
    expect(game.stand(), isTrue);
    expect(game.current, 1);
    expect(game.throwsTaken, 0);
    expect(game.held, [false, false, false]);
  });

  test('charge transfers high-roll value from bank to weakest seat', () {
    final game = Dice421Game(players: 2);
    game.resolveRound([[4, 2, 1], [3, 3, 2]]);
    expect(game.bank, 11);
    expect(game.tokens, [0, 10]);
    expect(game.phase, Dice421Phase.charge);
    expect(game.rounds, 1);
  });
  test('bank and chips are conserved across charge rounds', () {
    final game = Dice421Game(players: 3, random: Random(99));
    for (var n = 0; n < 100 && game.phase == Dice421Phase.charge; n++) {
      game.resolveRound([[4, 2, 1], [5, 5, 5], [2, 2, 1]]);
      expect(game.bank + game.tokens.reduce((a, b) => a + b), 21);
    }
    expect(game.phase, Dice421Phase.discharge);
  });

  test('discharge transfers only available chips and declares zero winner', () {
    final state = Dice421Game(players: 2).toJson();
    state['phase'] = 'discharge';
    state['bank'] = 0;
    state['tokens'] = [13, 8];
    final game = Dice421Game.fromJson(state);
    game.resolveRound([[4, 2, 1], [6, 5, 3]]);
    expect(game.tokens, [3, 18]);
    expect(game.phase, Dice421Phase.discharge);
    game.resolveRound([[1, 1, 1], [5, 5, 3]]);
    expect(game.tokens, [0, 21]);
    expect(game.phase, Dice421Phase.finished);
    expect(game.winner, 0);
  });

  test('save round trip and corrupted save validation', () {
    final game = Dice421Game(players: 3, random: Random(4));
    expect(game.roll(), isTrue);
    expect(Dice421Game.fromJson(game.toJson()).toJson(), game.toJson());
    final money = game.toJson();
    money['tokens'] = [3, 4, 5];
    expect(() => Dice421Game.fromJson(money), throwsFormatException);
    final invalidDice = game.toJson();
    invalidDice['dice'] = [8, 2, 3];
    expect(() => Dice421Game.fromJson(invalidDice), throwsFormatException);
  });

  test('computer turn rolls only permitted dice and conserves chips', () {
    final game = Dice421Game(players: 2, computer: true, random: Random(2));
    expect(game.roll(), isTrue);
    expect(game.stand(), isTrue);
    expect(game.current, 1);
    expect(game.playComputerTurn(), isTrue);
    expect(game.current, 0);
    expect(game.bank + game.tokens.reduce((a, b) => a + b), 21);
  });
}
