import 'dart:math';

/// Card IDs agree with the licensed PHE evaluator: rank * 4 + suit.
class PlayingCard {
  final int id;
  PlayingCard(this.id) {
    if (id < 0 || id >= 52) throw ArgumentError.value(id, 'id');
  }
  int get rank => id ~/ 4 + 2;
  int get suit => id % 4;
  static const ranks = '23456789TJQKA';
  static const suits = 'cdhs';
  static const glyphs = ['\u2663', '\u2666', '\u2665', '\u2660'];
  String get code => '${ranks[rank - 2]}${suits[suit]}';
  String get label => '${rank == 10 ? '10' : ranks[rank - 2]}${glyphs[suit]}';
  String get semanticLabel => '${rank == 14 ? 'Ace' : rank == 13 ? 'King' : rank == 12 ? 'Queen' : rank == 11 ? 'Jack' : rank} of ${const ['clubs', 'diamonds', 'hearts', 'spades'][suit]}';
  factory PlayingCard.parse(String code) {
    if (code.length != 2 || !ranks.contains(code[0]) || !suits.contains(code[1])) {
      throw FormatException('Invalid playing card', code);
    }
    return PlayingCard(ranks.indexOf(code[0]) * 4 + suits.indexOf(code[1]));
  }
  @override
  bool operator ==(Object other) => other is PlayingCard && id == other.id;
  @override
  int get hashCode => id;
}

class CardDeck {
  final List<PlayingCard> _cards;
  CardDeck([Random? random]) : _cards = List.generate(52, PlayingCard.new)
      ..shuffle(random ?? Random());
  CardDeck.restore(List<int> ids) : _cards = ids.map(PlayingCard.new).toList() {
    if (ids.toSet().length != ids.length) throw const FormatException('Duplicate cards');
  }
  int get remaining => _cards.length;
  List<int> get ids => _cards.map((card) => card.id).toList();
  PlayingCard draw() {
    if (_cards.isEmpty) throw StateError('The deck is empty');
    return _cards.removeLast();
  }
}
