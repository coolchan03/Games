import 'package:puzzle/data/game_guides.dart';
import 'package:puzzle/data/game_metadata.dart';

/// Preserve the original detailed guides; prevent newly registered titles
/// from leading to a dead-end information screen.
GameGuide guideForGame(GameMetadata game) {
  final existing = gameGuides[game.id];
  if (existing != null) return existing;
  if (game.id == 'four_two_one') {
    return const GameGuide(
      title: '421',
      category: 'BOARD',
      objective: 'Get rid of your chips. The player left holding them loses.',
      controls: 'Tap Roll, then tap individual dice to Hold or release them; '
          'tap Reroll and finally Keep result to pass the device.',
      walkthrough: [
        'Roll three dice, then choose which to Hold or reroll.',
        'The first player decides how many rolls everyone can take.',
        'In Charge, the weakest hand takes chips from the central bank.',
        'In Discharge, the strongest passes chips to the weakest.',
        'The last player with chips loses the round.',
      ],
      strategies: [
        '421 is strongest, followed by triple aces, two aces/triples, runs, and points.',
        'Try to avoid being the weakest rather than chasing a risky top hand.',
      ],
    );
  }
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
