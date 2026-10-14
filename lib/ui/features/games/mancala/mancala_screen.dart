import 'dart:math';
import 'package:flutter/material.dart';
import 'engine/mancala_state.dart';

/// Kalah Mancala using MiniGames' MIT-licensed rules engine.
class MancalaScreen extends StatefulWidget {
  const MancalaScreen({super.key});
  @override
  State<MancalaScreen> createState() => _MancalaState();
}
class _MancalaState extends State<MancalaScreen> {
  final Random rng = Random();
  MancalaState game = MancalaState.newGame();
  bool vsAi = true, thinking = false;
  int difficulty = 1, generation = 0;
  bool get complete => game.status == MancalaStatus.gameOver;
  void reset() => setState(() {
    generation++;
    game = MancalaState.newGame();
    thinking = false;
  });
  int evaluate(MancalaState s) {
    if (s.status == MancalaStatus.gameOver) {
      return s.winner == 1 ? 100000 : s.winner == 0 ? -100000 : 0;
    }
    return (s.board[13] - s.board[6]) * 20
      + (s.board.sublist(7, 13).fold<int>(0, (a,b) => a+b)
       - s.board.sublist(0, 6).fold<int>(0, (a,b) => a+b));
  }
  int search(MancalaState s, int depth, int alpha, int beta) {
    if (depth == 0 || s.status == MancalaStatus.gameOver) return evaluate(s);
    final moves = s.validPits;
    if (moves.isEmpty) return evaluate(s);
    if (s.currentPlayer == 1) {
      var best = -1000000;
      for (final pit in moves) {
        best = max(best, search(s.sowSeeds(pit).newState, depth-1, alpha, beta));
        alpha = max(alpha, best);
        if (alpha >= beta) break;
      }
      return best;
    }
    var best = 1000000;
    for (final pit in moves) {
      best = min(best, search(s.sowSeeds(pit).newState, depth-1, alpha, beta));
      beta = min(beta, best);
      if (alpha >= beta) break;
    }
    return best;
  }
  int aiPit() {
    final valid = game.validPits;
    if (difficulty == 0 || valid.length == 1) {
      return valid[rng.nextInt(valid.length)];
    }
    var highest = -1000000;
    final best = <int>[];
    for (final pit in valid) {
      final next = game.sowSeeds(pit).newState;
      final score = difficulty == 1 ? evaluate(next)
          : search(next, 4, -1000000, 1000000);
      if (score > highest) {
        highest = score;
        best..clear()..add(pit);
      } else if (score == highest) {
        best.add(pit);
      }
    }
    return best[rng.nextInt(best.length)];
  }
  Future<void> computerTurns() async {
    final token = generation;
    setState(() => thinking = true);
    while (mounted && vsAi && !complete &&
           game.currentPlayer == 1 && token == generation) {
      await Future<void>.delayed(const Duration(milliseconds: 120));
      if (!mounted || token != generation || complete || !vsAi) break;
      final pit = aiPit();
      setState(() => game = game.sowSeeds(pit).newState);
    }
    if (mounted && token == generation) setState(() => thinking = false);
  }
  void play(int pit) {
    if (complete || thinking || !game.validPits.contains(pit)) return;
    setState(() => game = game.sowSeeds(pit).newState);
    if (vsAi && !complete && game.currentPlayer == 1) computerTurns();
  }
  Widget pit(int index, ColorScheme colors) {
    final enabled = !complete && !thinking &&
        (!vsAi || game.currentPlayer == 0) && game.validPits.contains(index);
    return Expanded(child: Padding(
      padding: const EdgeInsets.all(2),
      child: AspectRatio(aspectRatio: 0.9,
        child: InkWell(
          onTap: enabled ? () => play(index) : null,
          borderRadius: BorderRadius.circular(22),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: enabled ? colors.primaryContainer : colors.surfaceContainer,
              border: Border.all(color: enabled ? colors.primary : colors.outlineVariant),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Center(child: Text('${game.board[index]}',
              style: Theme.of(context).textTheme.titleLarge)),
          ),
        ),
      ),
    ));
  }
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final status = complete
        ? game.winner == null ? 'Draw!'
          : game.winner == 0 ? 'Player 1 wins!' : 'Player 2 wins!'
        : thinking ? 'Computer thinking…'
        : 'Player ${game.currentPlayer + 1} to move';
    return Scaffold(
      appBar: AppBar(title: const Text('Mancala')),
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: ListView(padding: const EdgeInsets.all(16), children: [
          SwitchListTile(
            title: const Text('Play against computer'),
            value: vsAi,
            onChanged: (v) { vsAi = v; reset(); },
          ),
          if (vsAi) SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Easy')),
              ButtonSegment(value: 1, label: Text('Medium')),
              ButtonSegment(value: 2, label: Text('Hard')),
            ],
            selected: {difficulty},
            onSelectionChanged: (v) { difficulty = v.first; reset(); },
          ),
          const SizedBox(height: 20),
          Text(status, textAlign: TextAlign.center,
               style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 20),
          const Text('Player 2', textAlign: TextAlign.center),
          Row(children: [for (var i = 12; i >= 7; i--) pit(i, colors)]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: Text('P2 store: ${game.board[13]}',
              textAlign: TextAlign.center)),
            Expanded(child: Text('P1 store: ${game.board[6]}',
              textAlign: TextAlign.center)),
          ]),
          const SizedBox(height: 14),
          Row(children: [for (var i = 0; i < 6; i++) pit(i, colors)]),
          const Text('Player 1', textAlign: TextAlign.center),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: reset,
            icon: const Icon(Icons.restart_alt),
            label: const Text('New game'),
          ),
          const SizedBox(height: 12),
          const Text('Tap one of your pits to sow seeds. Reach your own store '
                     'for another turn, or land in an empty pit to capture.',
                     textAlign: TextAlign.center),
        ]),
      ))),
    );
  }
}
