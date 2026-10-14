import 'package:flutter/material.dart';

import '../common/card_view.dart';
import '../common/cards/card.dart';
import '../common/game_kit.dart';
import 'go_fish_engine.dart';

class GoFishScreen extends StatefulWidget {
  const GoFishScreen({super.key});
  @override
  State<GoFishScreen> createState() => _GoFishScreenState();
}

class _GoFishScreenState extends State<GoFishScreen> {
  int players = 3;
  AiLevel level = AiLevel.medium;
  late GoFishGame game = GoFishGame(players);
  Rank? rank;
  bool busy = false;
  int generation = 0;

  void _newGame() => setState(() {
        generation++;
        busy = false;
        rank = null;
        game = GoFishGame(players);
      });

  Future<void> _bots() async {
    if (busy) return;
    final token = generation;
    busy = true;
    while (mounted && token == generation && !game.over && game.turn != 0) {
      setState(() {});
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (!mounted || token != generation) return;
      final (target, r) = game.aiAsk(level.index);
      setState(() => game.ask(target, r));
    }
    if (mounted && token == generation) setState(() => busy = false);
  }

  void _ask(int target) {
    if (rank == null || busy || game.turn != 0 || game.over) return;
    setState(() {
      game.ask(target, rank!);
      rank = null;
    });
    _bots();
  }

  @override
  Widget build(BuildContext context) {
    final myTurn = game.turn == 0 && !busy && !game.over;
    String status;
    if (game.over) {
      final w = game.winners;
      status = w.length > 1
          ? 'Tie between ${w.map(game.name).join(' & ')}'
          : w.first == 0
              ? 'You win with ${game.books[0].length} books!'
              : '${game.name(w.first)} wins with ${game.books[w.first].length} books';
    } else if (myTurn) {
      status = rank == null ? 'Tap a card to choose a rank to ask for' : 'Who do you ask?';
    } else {
      status = '${game.name(game.turn)} is asking…';
    }
    String books(int p) => game.books[p].map((r) => r == Rank.ten ? '10' : r.asciiChar).join(' ');
    return GameScaffold(
      gameId: 'go_fish',
      completed: game.over && game.winners.contains(0),
      title: 'Go Fish',
      onNewGame: _newGame,
      rules: 'On your turn, pick a rank you hold and ask another player for '
          'it. If they have any, they hand them all over and you go again. '
          'If not, "Go fish!" — draw from the pond; drawing the rank you '
          'asked for also gives another turn. Collect all four of a rank to '
          'make a book. When all 13 books are made, the most books wins.',
      children: [
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 2, label: Text('2 players')),
            ButtonSegment(value: 3, label: Text('3')),
            ButtonSegment(value: 4, label: Text('4')),
          ],
          selected: {players},
          onSelectionChanged: (s) {
            players = s.first;
            _newGame();
          },
        ),
        const SizedBox(height: 8),
        SegmentedButton<AiLevel>(
          segments: [for (final l in AiLevel.values) ButtonSegment(value: l, label: Text(l.label))],
          selected: {level},
          onSelectionChanged: (s) => setState(() => level = s.first),
        ),
        StatusBanner('$status\n${game.log}', highlight: myTurn || game.over),
        for (var p = 1; p < players; p++)
          Card(
            child: ListTile(
              leading: Icon(game.turn == p ? Icons.record_voice_over : Icons.person_outline),
              title: Text('${game.name(p)} · ${game.hands[p].length} cards'),
              subtitle: Text('Books: ${books(p).isEmpty ? '—' : books(p)}'),
              trailing: FilledButton.tonal(
                onPressed: myTurn && rank != null && game.hands[p].isNotEmpty ? () => _ask(p) : null,
                child: const Text('Ask'),
              ),
            ),
          ),
        Text('Pond: ${game.pond.length} cards · Your books: ${books(0).isEmpty ? '—' : books(0)}',
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        HandView(
          cards: sortedForDisplay(game.hands[0])..sort((a, b) => b.rank.index - a.rank.index),
          selected: rank == null ? {} : game.hands[0].where((c) => c.rank == rank).toSet(),
          onTap: myTurn ? (c) => setState(() => rank = c.rank) : null,
        ),
      ],
    );
  }
}
