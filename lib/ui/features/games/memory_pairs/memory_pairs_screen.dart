import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../common/campaign_progress.dart';
import '../common/game_kit.dart';

const _symbols = <(IconData, Color)>[
  (Icons.pets, Color(0xFF8D6E63)), (Icons.favorite, Color(0xFFE53935)),
  (Icons.star, Color(0xFFFFB300)), (Icons.local_florist, Color(0xFFD81B60)),
  (Icons.wb_sunny, Color(0xFFF57C00)), (Icons.ac_unit, Color(0xFF039BE5)),
  (Icons.eco, Color(0xFF43A047)), (Icons.rocket_launch, Color(0xFF5E35B1)),
  (Icons.music_note, Color(0xFF3949AB)), (Icons.cake, Color(0xFFEC407A)),
  (Icons.bolt, Color(0xFFFDD835)), (Icons.diamond, Color(0xFF00ACC1)),
  (Icons.anchor, Color(0xFF546E7A)), (Icons.sailing, Color(0xFF1E88E5)),
  (Icons.emoji_nature, Color(0xFF7CB342)), (Icons.beach_access, Color(0xFFFF7043)),
  (Icons.directions_bike, Color(0xFF6D4C41)), (Icons.icecream, Color(0xFFAB47BC)),
];

/// Concentration: flip two cards at a time to find pairs. Solo, two players,
/// or against a computer that remembers a share of what it has seen.
class MemoryGame {
  MemoryGame(this.pairs, {Random? random}) : rng = random ?? Random() {
    cards = [for (var i = 0; i < pairs; i++) ...[i, i]]..shuffle(rng);
    owner = List.filled(cards.length, 0);
  }
  MemoryGame._restored(this.pairs, this.rng);

  /// Scores are derived from matched ownership when restoring a session.
  List<int> snapshot() => [
    turn, flips, up.length,
    up.isNotEmpty ? up[0] : -1,
    up.length == 2 ? up[1] : -1,
    ...cards,
    ...owner,
    for (var i = 0; i < cards.length; i++) seen.containsKey(i) ? 1 : 0,
  ];

  static MemoryGame? fromSnapshot(int pairs, List<int> data, {Random? random}) {
    final n = pairs * 2;
    if (pairs < 1 || data.length != 5 + 3 * n ||
        data[0] < 1 || data[0] > 2 || data[1] < 0 ||
        data[2] < 0 || data[2] > 2) return null;
    final upCount = data[2], first = data[3], second = data[4];
    if ((upCount == 0 && (first != -1 || second != -1)) ||
        (upCount == 1 && (first < 0 || first >= n || second != -1)) ||
        (upCount == 2 && (first < 0 || first >= n ||
            second < 0 || second >= n || first == second))) return null;
    final symbols = data.sublist(5, 5 + n);
    final owners = data.sublist(5 + n, 5 + 2 * n);
    final memories = data.sublist(5 + 2 * n);
    if (symbols.any((s) => s < 0 || s >= pairs) ||
        owners.any((o) => o < 0 || o > 2) ||
        memories.any((v) => v < 0 || v > 1)) return null;
    for (var symbol = 0; symbol < pairs; symbol++) {
      final indices = [
        for (var i = 0; i < n; i++) if (symbols[i] == symbol) i,
      ];
      if (indices.length != 2 || owners[indices[0]] != owners[indices[1]]) {
        return null;
      }
    }
    if ((first >= 0 && owners[first] != 0) ||
        (second >= 0 && owners[second] != 0) ||
        data[1] < owners.where((o) => o != 0).length + upCount) {
      return null;
    }
    for (var i = 0; i < n; i++) {
      if (memories[i] == 1 && owners[i] != 0) return null;
    }
    final game = MemoryGame._restored(pairs, random ?? Random());
    game.cards = symbols;
    game.owner = owners;
    game.turn = data[0];
    game.flips = data[1];
    if (first >= 0) game.up.add(first);
    if (second >= 0) game.up.add(second);
    game.scores[0] = owners.where((o) => o == 1).length ~/ 2;
    game.scores[1] = owners.where((o) => o == 2).length ~/ 2;
    for (var i = 0; i < n; i++) {
      if (memories[i] == 1) game.seen[i] = game.cards[i];
    }
    return game;
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
    if (i < 0 || i >= cards.length || over || owner[i] != 0 ||
        up.contains(i) || up.length == 2) return false;
    up.add(i);
    seen[i] = cards[i];
    flips++;
    return up.length == 2;
  }

  /// Resolves two face-up cards. Returns true if they matched.
  bool resolve() {
    if (up.length != 2) return false;
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
  static const pairSizes = [8, 12, 18];
  // Original default remains "vs Computer", eight pairs.
  int mode = switch (CampaignProgress.selectedLevel('memory_pairs', count: 9)) {
    4 || 5 || 6 => 0,
    7 || 8 || 9 => 2,
    _ => 1,
  };
  AiLevel level = switch (
      CampaignProgress.selectedLevel('memory_pairs_ai', count: 3)) {
    2 => AiLevel.easy,
    3 => AiLevel.hard,
    _ => AiLevel.medium,
  };
  int pairs = pairSizes[
      (CampaignProgress.selectedLevel('memory_pairs', count: 9) - 1) % 3];
  late MemoryGame game = _load();
  bool busy = false;
  int generation = 0;

  int get _modeId {
    final group = mode == 1 ? 0 : mode == 0 ? 1 : 2;
    return group * 3 + pairSizes.indexOf(pairs) + 1;
  }

  MemoryGame _load() {
    final data = CampaignProgress.loadActive(
      'memory_pairs', _modeId, maxLength: 5 + pairs * 6,
    );
    if (data != null) {
      final saved = MemoryGame.fromSnapshot(pairs, data);
      if (saved != null) return saved;
    }
    return MemoryGame(pairs);
  }

  void _save() => unawaited(CampaignProgress.saveActive(
      'memory_pairs', _modeId, game.snapshot()));

  void _switchMode() {
    setState(() {
      generation++;
      busy = false;
      game = _load();
    });
    unawaited(CampaignProgress.saveSelected('memory_pairs', _modeId));
    _resumePendingTurn();
  }

  @override
  void initState() {
    super.initState();
    _resumePendingTurn();
  }

  void _resumePendingTurn() {
    final token = generation;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || token != generation) return;
      if (game.up.length == 2) {
        unawaited(_finishAndContinue());
      } else if (mode == 1 && game.turn == 2 && !game.over) {
        unawaited(_computer());
      }
    });
  }

  Future<void> _finishAndContinue() async {
    await _resolve();
    if (mounted && mode == 1 && !game.over && game.turn == 2) {
      await _computer();
    }
  }

  void _newGame() {
    setState(() {
      generation++;
      busy = false;
      game = MemoryGame(pairs);
    });
    _save();
  }

  Future<void> _tap(int i) async {
    if (busy || game.over || (mode == 1 && game.turn == 2)) return;
    final ready = game.flip(i);
    setState(() {});
    if (game.up.isNotEmpty) _save();
    if (!ready) return;
    await _resolve();
    if (mounted && mode == 1 && !game.over) await _computer();
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
    _save();
  }

  Future<void> _computer() async {
    final token = generation;
    while (mounted && token == generation && mode == 1 &&
        game.turn == 2 && !game.over) {
      setState(() => busy = true);
      final memory = [.25, .6, .95][level.index];
      while (game.up.length < 2) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        if (!mounted || token != generation || mode != 1 ||
            game.turn != 2 || game.over) return;
        setState(() => game.flip(game.aiPick(memory)));
        _save();
      }
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
          'your opponent, or clear the board in as few turns as possible. '
          'Your cards, scores, turn and difficulty resume offline.',
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
            _switchMode();
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
                _switchMode();
              },
            ),
          ),
        ]),
        if (mode == 1) ...[
          const SizedBox(height: 8),
          SegmentedButton<AiLevel>(
            segments: [for (final l in AiLevel.values) ButtonSegment(value: l, label: Text(l.label))],
            selected: {level},
            onSelectionChanged: (s) {
              setState(() => level = s.first);
              final value = level == AiLevel.medium ? 1 :
                  level == AiLevel.easy ? 2 : 3;
              unawaited(CampaignProgress.saveSelected('memory_pairs_ai', value));
            },
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
                    ? FittedBox(
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(_symbols[game.cards[i]].$1, color: _symbols[game.cards[i]].$2, size: 34),
                        ),
                      )
                    : Icon(Icons.help_outline, color: colors.onPrimary),
              ),
            );
          },
        ),
      ],
    );
  }
}
