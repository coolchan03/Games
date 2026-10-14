import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/shared/playing_cards.dart';

void main() {
  test('a physical deck deals each card exactly once', () {
    final deck = CardDeck(Random(4));
    final cards = List.generate(52, (_) => deck.draw());
    expect(cards.toSet().length, 52);
    expect(deck.remaining, 0);
    expect(deck.draw, throwsStateError);
  });
  test('restoring a deck preserves draw order', () {
    final deck = CardDeck(Random(92));
    deck.draw();
    final restored = CardDeck.restore(deck.ids);
    expect(restored.draw(), deck.draw());
  });
  test('invalid and duplicate cards cannot enter saves', () {
    expect(() => CardDeck.restore([1, 1]), throwsFormatException);
    expect(() => PlayingCard(52), throwsArgumentError);
    expect(() => PlayingCard.parse('1x'), throwsFormatException);
    expect(PlayingCard.parse('As').rank, 14);
  });
}
