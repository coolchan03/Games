import 'package:flutter/material.dart';

import '../common/campaign_level_bar.dart';
import '../common/game_kit.dart';
import 'black_box_engine.dart';

class BlackBoxScreen extends StatefulWidget {
  const BlackBoxScreen({super.key});
  @override
  State<BlackBoxScreen> createState() => _BlackBoxScreenState();
}

class _BlackBoxScreenState extends State<BlackBoxScreen> {
  int level = CampaignLevelBar.initialLevel('black_box');
  late BlackBoxGame game = _build(level);

  /// Builds [level], resuming a saved unfinished attempt when [resume].
  BlackBoxGame _build(int level, {bool resume = true}) {
    final (n, balls) = BlackBoxLevels.specs[level - 1];
    final saved =
        resume ? CampaignLevelBar.restoreActive('black_box', level) : null;
    return (saved == null ? null : BlackBoxGame.fromSnapshot(n, balls, saved)) ??
        BlackBoxLevels.build(level);
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
                '${game.wrong > 0 ? ' — your layout gives identical results' : ''}'
            : '${game.wrong} ball${game.wrong == 1 ? '' : 's'} misplaced — score ${game.score}')
        : 'Lasers fired: ${game.lasersUsed} · balls marked ${game.guesses.length}/${game.balls}';
    Widget port(int p) {
      final l = labels[p];
      return GestureDetector(
        onTap: () => setState(() => game.fire(p)),
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
      onNewGame: () => setState(() => game = _build(level, resume: false)),
      rules: 'Balls are hidden in the box. Tap an edge port to fire a '
          'laser in. H means it hit a ball head-on; R means it was reflected '
          'back out; a number shows the matching pair of ports where it went '
          'in and came out. A ball diagonally ahead of the laser turns it 90° '
          'away; two such balls reflect it; a ball diagonally beside the '
          'entry square reflects it immediately.\n\nTap squares to mark '
          'where you think the balls are, then check. Each laser costs 1 '
          'point and each wrong ball 5 — lower is better. A layout that gives '
          'exactly the same laser results as the real one also counts as '
          'correct.\n\nThere are 20 levels, from 2 balls in a 5×5 box to 8 '
          'balls in a 10×10 box. Get a level right to complete it; New game '
          'hides the balls again. Rules from Simon Tatham\'s Portable Puzzle '
          'Collection.',
      children: [
        CampaignLevelBar(
          gameId: 'black_box',
          level: level,
          solved: game.revealed && game.correct,
          onLevel: (value) => setState(() {
            level = value;
            game = _build(level);
          }),
          describe: (l) {
            final (n, b) = BlackBoxLevels.specs[l - 1];
            return '$n×$n, $b balls';
          },
          activeState: game.snapshot,
          result: CampaignResult(
            score: game.score,
            stars: starsForPar(game.score, game.balls * 2),
            label: (s) => 'score $s',
          ),
        ),
        StatusBanner(status, highlight: game.revealed),
        LandscapeBoard(child: AspectRatio(
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
                onTap: () => setState(() => game.toggleGuess(cell)),
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
        )),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: game.revealed || game.guesses.length != game.balls
              ? null
              : () => setState(() => game.revealed = true),
          child: const Text('Check my answer'),
        ),
      ],
    );
  }
}
