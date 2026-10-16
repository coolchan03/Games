import 'package:puzzle/data/game_guides.dart';
import 'package:puzzle/data/game_guides_added.dart';
import 'package:puzzle/data/game_metadata.dart';

/// Preserve the original detailed guides; prevent newly registered titles
/// from leading to a dead-end information screen.
GameGuide guideForGame(GameMetadata game) {
  final existing = gameGuides[game.id] ?? addedGameGuides[game.id];
  if (existing != null) return existing;
  if (game.id == 'petits_chevaux') {
    return const GameGuide(
      title: 'Petits Chevaux',
      category: 'BOARD',
      objective: 'Bring all four horses home before anyone else.',
      controls: 'Tap Roll, then tap or swipe a highlighted horse. '
          'Large numbered Horse buttons provide an easier touch alternative.',
      walkthrough: [
        'Roll a six to bring a horse onto the board; six grants another roll.',
        'Move exactly the number on the die, capturing rival horses if you land on them.',
        'Land exactly at the base of your finish staircase.',
        'Climb with six specific rolls in order: 1, 2, 3, 4, 5, then 6.',
        'The first player to finish all four horses wins.',
      ],
      strategies: [
        'Balance multiple horses on the track to reduce the risk of a capture.',
        'Plan exact-count entries into the final staircase.',
      ],
    );
  }
  if (game.id == 'nain_jaune') {
    return const GameGuide(
      title: 'Nain Jaune (Yellow Dwarf)',
      category: 'CARD',
      objective: 'Collect the most virtual chips across five deals by '
          'playing premium cards and emptying your hand.',
      controls: 'Tap a highlighted legal card or long-press and drag it '
          'to the drop target; reveal only your own cards in local games.',
      walkthrough: [
        'Each player contributes 1, 2, 3, 4 and 5 chips to premium trays.',
        'Lead any card, then play ascending ranks regardless of suit.',
        'The holder of the next rank plays; a King can restart the run.',
        'Playing the exact 10 diamonds, Jack clubs, Queen spades, '
            'King hearts or 7 diamonds collects its tray.',
        'Empty your hand to win the deal and take chip penalties from '
            'opponents; the most chips after five deals wins.',
      ],
      strategies: [
        'Watch the next rank and save premium cards for their trays.',
        'A card is only legal when highlighted; do not reveal other '
            'players private hands.',
      ],
    );
  }
  final title = game.id
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
  return GameGuide(
    title: title,
    category: game.category,
    objective: 'A ${game.category.toLowerCase()} game in the offline Games library.',
    controls: 'Open the game and tap Rules in the top bar for its actual '
        'controls and scoring. Touch and mouse controls depend on the game.',
    walkthrough: const [
      'Open the game from the library.',
      'Tap the Rules icon in the top-right corner before your first move.',
      'Start a new round and follow the rules shown for that game.',
    ],
    strategies: const [
      'Read the in-game Rules panel before making your first move.',
    ],
  );
}
