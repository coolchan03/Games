import 'dart:async';

import 'package:flutter/material.dart';

import '../common/campaign_progress.dart';
import '../common/game_kit.dart';
import 'black_box_engine.dart';

class BlackBoxScreen extends StatefulWidget {
  const BlackBoxScreen({super.key});
  @override
  State<BlackBoxScreen> createState() => _BlackBoxScreenState();
}

class _BlackBoxScreenState extends State<BlackBoxScreen> {
  static const modes = [4, 3, 5, 6];
  int balls = modes[CampaignProgress.selectedLevel('black_box', count: 4) - 1];
  late BlackBoxGame game = _load();

  int get modeIndex => modes.indexOf(balls) + 1;

  BlackBoxGame _load() {
    const n = 8;
    final raw = CampaignProgress.loadActive('black_box', modeIndex,
        maxLength: 1 + 2 * n * n + 4 * n);
    return raw == null
        ? BlackBoxGame(n: n, balls: balls)
        : BlackBoxGame.fromSnapshot(n: n, balls: balls, data: raw) ??
            BlackBoxGame(n: n, balls: balls);
  }

  void _save() => unawaited(CampaignProgress.saveActive(
    'black_box', modeIndex, game.snapshot(),
  ));

  void _newGame() {
    setState(() => game = BlackBoxGame(balls: balls));
    _save();
  }

  /// Labels for exit pairs (1, 2, 3, …) in the order they were found.
  Map<int, String> get _labels {
    final labels = <int, String>{};
    var next = 1;
    for (final e in game.fired.entries) {
      if (labels.containsKey(e.key)) continue;
      final r = e.value;
      if (r.kind == 'X') {
        labels[e.key] = '$next';
        labels[r.exit!] = '$next';
        next++;
      } else {
        labels[e.key] = r.kind;
      }
    }
    return labels;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final n = game.n;
    final labels = _labels;
    final status = game.revealed
        ? (game.correct
            ? 'Correct! Score ${game.score} (lower is better)'
            : '${game.wrong} ball${game.wrong == 1 ? '' : 's'} misplaced — score ${game.score}')
        : 'Lasers fired: ${game.lasersUsed} · balls marked ${game.guesses.length}/${game.balls}';
    Widget port(int p) {
      final l = labels[p];
      return GestureDetector(
        onTap: () {
          setState(() => game.fire(p));
          _save();
        },
        child: Container(
          margin: const EdgeInsets.all(1.5),
          decoration: BoxDecoration(
            color: l == null
                ? colors.primaryContainer
                : l == 'H'
                    ? const Color(0xFFE57373)
                    : l == 'R'
                        ? const Color(0xFFFFD54F)
                        : const Color(0xFF81C784),
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: FittedBox(child: Padding(padding: const EdgeInsets.all(2), child: Text(l ?? '•', style: const TextStyle(fontWeight: FontWeight.bold)))),
        ),
      );
    }

    return GameScaffold(
      gameId: 'black_box',
      completed: game.revealed && game.correct,
      title: 'Black Box',
      onNewGame: _newGame,
      rules: 'Balls are hidden in the 8×8 box. Tap an edge port to fire a '
          'laser in. H means it hit a ball head-on; R means it was reflected '
          'back out; a number shows the matching pair of ports where it went '
          'in and came out. A ball diagonally ahead of the laser turns it 90° '
          'away; two such balls reflect it; a ball diagonally beside the '
          'entry square reflects it immediately.\n\nTap squares to mark '
          'where you think the balls are, then check. Each laser costs 1 '
          'point and each wrong ball 5 — lower is better. Rules from Simon '
          'Tatham\'s Portable Puzzle Collection. Progress resumes offline.',
      children: [
        SegmentedButton<int>(
          segments: [for (final b in const [3, 4, 5, 6]) ButtonSegment(value: b, label: Text('$b balls'))],
          selected: {balls},
          onSelectionChanged: (s) {
            setState(() {
              balls = s.first;
              game = _load();
            });
            unawaited(CampaignProgress.saveSelected('black_box', modeIndex));
          },
        ),
        StatusBanner(status, highlight: game.revealed),
        AspectRatio(
          aspectRatio: 1,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: n + 2),
            itemCount: (n + 2) * (n + 2),
            itemBuilder: (context, i) {
              final r = i ~/ (n + 2), c = i % (n + 2);
              final corner = (r == 0 || r == n + 1) && (c == 0 || c == n + 1);
              if (corner) return const SizedBox();
              if (r == 0) return port(c - 1);
              if (c == n + 1) return port(n + r - 1);
              if (r == n + 1) return port(2 * n + (n - c));
              if (c == 0) return port(3 * n + (n - r));
              final cell = (r - 1) * n + (c - 1);
              final guessed = game.guesses.contains(cell);
              final real = game.hidden.contains(cell);
              return GestureDetector(
                onTap: () {
                  setState(() => game.toggleGuess(cell));
                  _save();
                },
                child: Container(
                  margin: const EdgeInsets.all(1),
                  color: const Color(0xFF263238),
                  alignment: Alignment.center,
                  child: guessed || (game.revealed && real)
                      ? Icon(Icons.circle,
                          color: !game.revealed
                              ? Colors.white
                              : real && guessed
                                  ? Colors.greenAccent
                                  : real
                                      ? Colors.orangeAccent
                                      : Colors.redAccent)
                      : null,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: game.revealed || game.guesses.length != game.balls
              ? null
              : () {
                  setState(() => game.revealed = true);
                  _save();
                },
          child: const Text('Check my answer'),
        ),
      ],
    );
  }
}
