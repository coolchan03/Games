import 'dart:math';

import 'package:flutter/material.dart';

import '../common/game_kit.dart';

const _symbols = ['🍎', '🍌', '🍇', '🍓', '🍒', '🍍', '🥝', '🍑', '🥕', '🌽', '🍄', '🌵', '🌻', '🐟', '🐢', '🦋', '🐞', '⭐'];

/// Concentration: flip two cards at a time to find pairs. Solo, two players,
/// or against a computer that remembers a share of what it has seen.
class MemoryGame {
  MemoryGame(this.pairs, {Random? random}) : rng = random ?? Random() {
    cards = [for (var i = 0; i < pairs; i++) ...[i, i]]..shuffle(rng);
    owner = List.filled(cards.length, 0);
  }
  final int pairs;
  final Random rng;
  late final List<int> cards;
  late final List<int> owner; // 0 = face down, 1/2 = matched by player
  final List<int> up = [];
  final scores = [0, 0];
  int turn = 1;
  int flips = 0;
  final Map<int, int> seen = {}; // index -> symbol, computer memory

  bool get over => owner.every((o) => o != 0);

  /// Flips [i]; returns true when two cards are up and need resolving.
  bool flip(int i) {
    if (owner[i] != 0 || up.contains(i) || up.length == 2) return false;
    up.add(i);
    seen[i] = cards[i];
    flips++;
    return up.length == 2;
  }

  /// Resolves two face-up cards. Returns true if they matched.
  bool resolve() {
    final a = up[0], b = up[1];
    up.clear();
    if (cards[a] == cards[b]) {
      owner[a] = owner[b] = turn;
      scores[turn - 1]++;
      seen.remove(a);
      seen.remove(b);
      return true;
    }
    turn = 3 - turn;
    return false;
  }

  List<int> get hidden => [for (var i = 0; i < cards.length; i++) if (owner[i] == 0 && !up.contains(i)) i];

  /// Computer pick: remembers each seen card with probability [memory].
  int aiPick(double memory) {
    final known = {for (final e in seen.entries) if (owner[e.key] == 0 && rng.nextDouble() < memory) e.key: e.value};
    if (up.length == 1) {
      final want = cards[up.first];
      for (final e in known.entries) {
        if (e.value == want && e.key != up.first) return e.key;
      }
    } else {
      final bySymbol = <int, List<int>>{};
      for (final e in known.entries) {
        (bySymbol[e.value] ??= []).add(e.key);
      }
      for (final l in bySymbol.values) {
        if (l.length == 2) return l.first;
      }
    }
    final unknown = hidden.where((i) => !known.containsKey(i)).toList();
    final pool = unknown.isNotEmpty ? unknown : hidden;
    return pool[rng.nextInt(pool.length)];
  }
}

class MemoryPairsScreen extends StatefulWidget {
  const MemoryPairsScreen({super.key});
  @override
  State<MemoryPairsScreen> createState() => _MemoryPairsScreenState();
}

class _MemoryPairsScreenState extends State<MemoryPairsScreen> {
  int mode = 1; // 0 solo, 1 vs computer, 2 two players
  AiLevel level = AiLevel.medium;
  int pairs = 8;
  late MemoryGame game = MemoryGame(pairs);
  bool busy = false;
  int generation = 0;

  void _newGame() => setState(() {
        generation++;
        busy = false;
        game = MemoryGame(pairs);
      });

  Future<void> _tap(int i) async {
    if (busy || (mode == 1 && game.turn == 2)) return;
    if (!game.flip(i)) {
      setState(() {});
      return;
    }
    await _resolve();
    if (mode == 1) await _computer();
  }

  Future<void> _resolve() async {
    final token = generation;
    setState(() => busy = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted || token != generation) return;
    setState(() {
      final matched = game.resolve();
      if (mode == 0 && !matched) game.turn = 1;
      busy = false;
    });
  }

  Future<void> _computer() async {
    final token = generation;
    while (mounted && token == generation && game.turn == 2 && !game.over) {
      setState(() => busy = true);
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!mounted || token != generation) return;
      final memory = [.25, .6, .95][level.index];
      setState(() => game.flip(game.aiPick(memory)));
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!mounted || token != generation) return;
      setState(() => game.flip(game.aiPick(memory)));
      await _resolve();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final names = mode == 1 ? ['You', 'Computer'] : ['Player 1', 'Player 2'];
    String status;
    if (game.over) {
      if (mode == 0) {
        status = 'All pairs found in ${game.flips ~/ 2} turns!';
      } else {
        final s = game.scores;
        status = s[0] == s[1] ? 'Tie ${s[0]}–${s[1]}' : '${names[s[0] > s[1] ? 0 : 1]} win${mode == 1 && s[0] > s[1] ? '' : 's'} ${max(s[0], s[1])}–${min(s[0], s[1])}';
      }
    } else if (mode == 0) {
      status = 'Turns ${game.flips ~/ 2} · Pairs ${game.scores[0]}/${game.pairs}';
    } else {
      status = '${names[game.turn - 1]} to flip · ${names[0]} ${game.scores[0]} – ${game.scores[1]} ${names[1]}';
    }
    final cols = pairs <= 8 ? 4 : 6;
    return GameScaffold(
      gameId: 'memory_pairs',
      completed: game.over && (mode != 1 || game.scores[0] > game.scores[1]),
      title: 'Memory',
      onNewGame: _newGame,
      rules: 'Flip two cards per turn. A matching pair is yours and you go '
          'again; otherwise the cards turn back over. Find more pairs than '
          'your opponent, or clear the board in as few turns as possible.',
      children: [
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 0, label: Text('Solo')),
            ButtonSegment(value: 1, label: Text('vs Computer')),
            ButtonSegment(value: 2, label: Text('2 Players')),
          ],
          selected: {mode},
          onSelectionChanged: (s) {
            mode = s.first;
            _newGame();
          },
        ),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 8, label: Text('16 cards')),
                ButtonSegment(value: 12, label: Text('24')),
                ButtonSegment(value: 18, label: Text('36')),
              ],
              selected: {pairs},
              onSelectionChanged: (s) {
                pairs = s.first;
                _newGame();
              },
            ),
          ),
        ]),
        if (mode == 1) ...[
          const SizedBox(height: 8),
          SegmentedButton<AiLevel>(
            segments: [for (final l in AiLevel.values) ButtonSegment(value: l, label: Text(l.label))],
            selected: {level},
            onSelectionChanged: (s) => setState(() => level = s.first),
          ),
        ],
        StatusBanner(status, highlight: game.over),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cols, childAspectRatio: .8),
          itemCount: game.cards.length,
          itemBuilder: (context, i) {
            final faceUp = game.owner[i] != 0 || game.up.contains(i);
            return GestureDetector(
              onTap: () => _tap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: faceUp
                      ? (game.owner[i] == 0
                          ? colors.surfaceContainerHighest
                          : game.owner[i] == 1
                              ? colors.primaryContainer
                              : colors.tertiaryContainer)
                      : colors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: faceUp
                    ? FittedBox(child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Text(_symbols[game.cards[i]], style: const TextStyle(fontSize: 34))))
                    : Icon(Icons.help_outline, color: colors.onPrimary),
              ),
            );
          },
        ),
      ],
    );
  }
}
