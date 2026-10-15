import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/shared/playing_cards.dart';
import 'package:puzzle/ui/features/games/nain_jaune/nain_jaune_engine.dart';

void main() {
  test('four players ante 15 each and receive twelve cards each', () {
    final game = NainJauneGame(players: 4, random: Random(11));
    expect(game.hands.map((h) => h.length).toList(), [12, 12, 12, 12]);
    expect(game.talon.length, 4);
    expect(game.chips, [85, 85, 85, 85]);
    expect(game.trays, [4, 8, 12, 16, 20]);
    expect(game.allCardIds.length, 52);
    expect(game.allCardIds.toSet().length, 52);
  });

  test('supported seat counts deal legal hands with an untouched talon', () {
    for (final (seats, size) in [(3, 15), (4, 12), (5, 9), (6, 8), (7, 7), (8, 6)]) {
      final game = NainJauneGame(players: seats, random: Random(seats));
      expect(game.hands.every((h) => h.length == size), isTrue);
      expect(game.talon.length, 52 - seats * size);
      expect(game.allCardIds.toSet().length, 52);
    }
    expect(() => NainJauneGame(players: 2), throwsArgumentError);
  });

  test('next rank may have any suit, and the holder is next to play', () {
    final game = NainJauneGame(players: 4, random: Random(7));
    final actor = game.current;
    final idx = game.hands[actor].indexWhere((card) => card.rank == 5);
    if (idx == -1) {
      final first = game.legalIndices.first;
      expect(game.play(first), isTrue);
    } else {
      expect(game.play(idx), isTrue);
      final next = game.expectedRank;
      if (next != null) {
        expect(next, 6);
        expect(game.hands[game.current].any((c) => c.rank == 6), isTrue);
        expect(game.legalIndices.every((i) => game.hands[game.current][i].rank == 6), isTrue);
      }
    }
    expect(game.allCardIds.toSet().length, 52);
  });

  test('playing a premium card transfers only its tray to the player', () {
    final game = NainJauneGame(players: 4, random: Random(31));
    final premium = PlayingCard.parse('7d');
    final owner = game.hands.indexWhere((h) => h.contains(premium));
    if (owner == -1) {
      expect(game.talon, contains(premium));
      return;
    }
    game.current = owner;
    final before = game.chips[owner];
    expect(game.play(game.hands[owner].indexOf(premium)), isTrue);
    expect(game.chips[owner], before + 20);
    expect(game.trays[4], 0);
    expect(game.allCardIds.toSet().length, 52);
  });

  test('computer play finishes a deal without losing cards or chips', () {
    final game = NainJauneGame(players: 3, random: Random(13));
    var moves = 0;
    while (!game.roundOver && moves++ < 52) {
      expect(game.legalIndices, isNotEmpty);
      final index = game.chooseBotCard(2, Random(moves));
      expect(game.play(index), isTrue);
      expect(game.allCardIds.toSet().length, 52);
      expect(game.chips.reduce((a, b) => a + b) +
          game.trays.reduce((a, b) => a + b), 300);
    }
    expect(game.roundOver, isTrue);
    expect(game.winner, isNotNull);
    expect(game.play(0), isFalse);
  });

  test('invalid plays leave state unchanged', () {
    final game = NainJauneGame(players: 3, random: Random(12));
    final before = game.toJson();
    expect(game.play(-1), isFalse);
    expect(game.play(1000), isFalse);
    expect(game.toJson(), before);
  });

  test('serialized roundtrip validates uniqueness and chip totals', () {
    final game = NainJauneGame(players: 5, random: Random(8));
    game.play(game.legalIndices.first);
    final saved = game.toJson();
    final restored = NainJauneGame.fromJson(saved);
    expect(restored.toJson(), saved);
    final bad = Map<String, dynamic>.from(saved);
    final hands = (bad['hands'] as List)
        .map((hand) => List<int>.from(hand as List)).toList();
    hands[0][0] = hands[1][0];
    bad['hands'] = hands;
    expect(() => NainJauneGame.fromJson(bad), throwsFormatException);
    expect(() => NainJauneGame.fromJson({...saved, 'chips': [999]}),
        throwsFormatException);
  });
}
