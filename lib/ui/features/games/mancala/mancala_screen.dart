import 'dart:math';
import 'package:flutter/material.dart';

import '../common/game_kit.dart';
import '../common/sowing_board.dart';
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
  int? lastPit;
  bool get complete => game.status == MancalaStatus.gameOver;
  void reset() => setState(() {
        generation++;
        game = MancalaState.newGame();
        thinking = false;
        lastPit = null;
      });
  int evaluate(MancalaState s) {
    if (s.status == MancalaStatus.gameOver) {
      return s.winner == 1
          ? 100000
          : s.winner == 0
              ? -100000
              : 0;
    }
    return (s.board[13] - s.board[6]) * 20 +
        (s.board.sublist(7, 13).fold<int>(0, (a, b) => a + b) -
            s.board.sublist(0, 6).fold<int>(0, (a, b) => a + b));
  }

  int search(MancalaState s, int depth, int alpha, int beta) {
    if (depth == 0 || s.status == MancalaStatus.gameOver) return evaluate(s);
    final moves = s.validPits;
    if (moves.isEmpty) return evaluate(s);
    if (s.currentPlayer == 1) {
      var best = -1000000;
      for (final pit in moves) {
        best =
            max(best, search(s.sowSeeds(pit).newState, depth - 1, alpha, beta));
        alpha = max(alpha, best);
        if (alpha >= beta) break;
      }
      return best;
    }
    var best = 1000000;
    for (final pit in moves) {
      best =
          min(best, search(s.sowSeeds(pit).newState, depth - 1, alpha, beta));
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
      final score =
          difficulty == 1 ? evaluate(next) : search(next, 4, -1000000, 1000000);
      if (score > highest) {
        highest = score;
        best
          ..clear()
          ..add(pit);
      } else if (score == highest) {
        best.add(pit);
      }
    }
    return best[rng.nextInt(best.length)];
  }

  Future<void> computerTurns() async {
    final token = generation;
    setState(() => thinking = true);
    while (mounted &&
        vsAi &&
        !complete &&
        game.currentPlayer == 1 &&
        token == generation) {
      await Future<void>.delayed(const Duration(milliseconds: 120));
      if (!mounted || token != generation || complete || !vsAi) break;
      final pit = aiPit();
      setState(() {
        game = game.sowSeeds(pit).newState;
        lastPit = pit;
      });
    }
    if (mounted && token == generation) setState(() => thinking = false);
  }

  void play(int pit) {
    if (complete || thinking || !game.validPits.contains(pit)) return;
    setState(() {
      game = game.sowSeeds(pit).newState;
      lastPit = pit;
    });
    if (vsAi && !complete && game.currentPlayer == 1) computerTurns();
  }

  Widget pit(int index) {
    final enabled = !complete &&
        !thinking &&
        (!vsAi || game.currentPlayer == 0) &&
        game.validPits.contains(index);
    return Padding(
      padding: const EdgeInsets.all(2),
      child: SowingPit(
        key: ValueKey('mancala_pit_$index'),
        seeds: game.board[index],
        seedKey: index,
        enabled: enabled,
        lastMove: lastPit == index,
        onTap: () => play(index),
        semanticLabel: 'Pit ${index < 6 ? index + 1 : index - 6} of '
            '${index < 6 ? 'player 1' : 'player 2'}: '
            '${game.board[index]} seeds',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final names = vsAi ? ['You', 'Computer'] : ['Player 1', 'Player 2'];
    final status = complete
        ? game.winner == null
            ? 'Draw ${game.board[6]}–${game.board[13]}!'
            : '${names[game.winner!]} win${game.winner == 0 && vsAi ? '' : 's'}'
                ' ${game.board[6]}–${game.board[13]}!'
        : thinking
            ? 'Computer is sowing…'
            : '${names[game.currentPlayer]} to move';
    return GameScaffold(
      gameId: 'mancala',
      completed: complete && (vsAi ? game.winner == 0 : game.winner != null),
      title: 'Mancala',
      onNewGame: reset,
      rules: 'Kalah rules. On your turn pick one of your six pits and sow its '
          'seeds one at a time counter-clockwise, including your own store '
          '(on your right) but skipping your opponent\'s. If the last seed '
          'lands in your store, take another turn. If it lands in an empty '
          'pit on your side, capture it together with the seeds in the pit '
          'opposite. When one side runs out of seeds the other player stores '
          'the rest; the bigger store wins.\n\nPlayer 1 plays the bottom row; '
          'glowing pits are the ones you can play.',
      children: [
        OpponentPicker(
          vsComputer: vsAi,
          level: AiLevel.values[difficulty],
          onChanged: (v, l) {
            vsAi = v;
            difficulty = l.index;
            reset();
          },
        ),
        StatusBanner(status, highlight: complete),
        const SizedBox(height: 8),
        Text(names[1],
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        SowingBoard(
          top: [for (var i = 12; i >= 7; i--) pit(i)],
          bottom: [for (var i = 0; i < 6; i++) pit(i)],
          leftStore: SeedStore(
            key: const ValueKey('mancala_store_13'),
            seeds: game.board[13],
            label: vsAi ? 'CPU' : 'P2',
            seedKey: 13,
            highlight: complete && game.winner == 1,
          ),
          rightStore: SeedStore(
            key: const ValueKey('mancala_store_6'),
            seeds: game.board[6],
            label: vsAi ? 'You' : 'P1',
            seedKey: 6,
            highlight: complete && game.winner == 0,
          ),
        ),
        const SizedBox(height: 4),
        Text(names[0],
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall),
      ],
    );
  }
}
