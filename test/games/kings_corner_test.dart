import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/shared/playing_cards.dart';
import 'package:puzzle/ui/features/games/kings_corner/kings_corner_game.dart';

void main() {
  test('initial deal conserves a deck and starts with one drawn card', () {
    final game = KingsCornerGame(players: 2, random: Random(12));
    expect(game.hands.map((hand) => hand.length).toList(), [8, 7]);
    expect(game.piles.length, 8);
    expect(game.piles.take(4).every((pile) => pile.length == 1), isTrue);
    expect(game.piles.skip(4).every((pile) => pile.isEmpty), isTrue);
    expect(game.stock.remaining, 33);
    expect(game.allCardIds.length, 52);
    expect(game.allCardIds.toSet().length, 52);
  });

  test('building always requires one rank down and opposite color', () {
    expect(KingsCornerGame.canBuild(PlayingCard.parse('Qh'), PlayingCard.parse('Ks')), isTrue);
    expect(KingsCornerGame.canBuild(PlayingCard.parse('Qs'), PlayingCard.parse('Ks')), isFalse);
    expect(KingsCornerGame.canBuild(PlayingCard.parse('Jh'), PlayingCard.parse('Ks')), isFalse);
    expect(KingsCornerGame.canBuild(PlayingCard.parse('As'), PlayingCard.parse('2h')), isTrue);
    expect(KingsCornerGame.canBuild(PlayingCard.parse('Ah'), PlayingCard.parse('2s')), isTrue);
    expect(KingsCornerGame.canBuild(PlayingCard.parse('Ah'), PlayingCard.parse('2h')), isFalse);
  });

  test('only kings can start corners; freed sides accept any card', () {
    final game = KingsCornerGame(random: Random(11));
    final nonKing = game.hands[game.current].indexWhere((c) => c.rank != 13);
    expect(nonKing, isNonNegative);
    expect(game.playCard(nonKing, 4), isFalse);
    expect(game.hands[game.current].length, 8);
    expect(game.movePile(0, 0), isFalse);
    expect(game.movePile(4, 0), isFalse);
  });
  test('invalid moves cannot mutate a turn or a saved deck', () {
    final game = KingsCornerGame(random: Random(17));
    final before = game.toJson();
    expect(game.playCard(-1, 2), isFalse);
    expect(game.playCard(0, 9), isFalse);
    expect(game.movePile(-1, 2), isFalse);
    expect(game.movePile(1, 9), isFalse);
    expect(game.toJson(), before);
    final saved = game.toJson();
    final restored = KingsCornerGame.fromJson(saved);
    expect(restored.toJson(), saved);
    expect(restored.allCardIds.toSet().length, 52);
    final tampered = Map<String, dynamic>.from(saved);
    final hands = (saved['hands'] as List).map((h) => List<int>.from(h as List)).toList();
    hands[1][0] = hands[0][0];
    tampered['hands'] = hands;
    expect(() => KingsCornerGame.fromJson(tampered), throwsFormatException);
  });

  test('turn rotation draws once and round cannot create cards', () {
    final game = KingsCornerGame(players: 3, random: Random(37));
    final startStock = game.stock.remaining;
    final first = game.current;
    expect(game.endTurn(), isTrue);
    expect(game.current, (first + 1) % 3);
    expect(game.hands[game.current].length, 8);
    expect(game.stock.remaining, startStock - 1);
    expect(game.allCardIds.toSet().length, 52);
  });

  test('greedy computer turn is legal and preserves all cards', () {
    final game = KingsCornerGame(random: Random(13));
    expect(game.endTurn(), isTrue);
    game.playGreedyTurn();
    expect(game.current, 0);
    expect(game.allCardIds.toSet().length, 52);
    expect(game.allCardIds.length, 52);
  });
}
