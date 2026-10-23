import 'dart:math';
import 'package:flutter/material.dart';

import '../common/game_kit.dart';

class ConnectFourScreen extends StatefulWidget {
  const ConnectFourScreen({super.key});
  @override
  State<ConnectFourScreen> createState() => _ConnectFourState();
}

class _ConnectFourState extends State<ConnectFourScreen> {
  final rng = Random();
  late List<List<int>> cells;
  int turn = 1, difficulty = 1, winner = 0;
  bool versusAi = true, done = false;
  _ConnectFourState() {
    reset();
  }
  (int, int)? last;
  void reset() {
    cells = List.generate(6, (_) => List.filled(7, 0));
    turn = 1;
    winner = 0;
    done = false;
    last = null;
  }

  /// Cells of the winning line(s), for highlighting.
  Set<(int, int)> get winningCells {
    final out = <(int, int)>{};
    if (winner == 0) return out;
    for (var r = 0; r < 6; r++) {
      for (var c = 0; c < 7; c++) {
        for (final (dr, dc) in const [(1, 0), (0, 1), (1, 1), (1, -1)]) {
          final line = [for (var k = 0; k < 4; k++) (r + dr * k, c + dc * k)];
          if (line.every((p) =>
              p.$1 >= 0 &&
              p.$1 < 6 &&
              p.$2 >= 0 &&
              p.$2 < 7 &&
              cells[p.$1][p.$2] == winner)) {
            out.addAll(line);
          }
        }
      }
    }
    return out;
  }

  List<int> get legal => [
        for (var c = 0; c < 7; c++)
          if (cells[0][c] == 0) c
      ];
  bool four(List<List<int>> b, int p) {
    for (var r = 0; r < 6; r++)
      for (var c = 0; c < 7; c++)
        for (final d in const [
          [1, 0],
          [0, 1],
          [1, 1],
          [1, -1]
        ]) {
          bool ok = true;
          for (var k = 0; k < 4; k++) {
            final y = r + d[0] * k, x = c + d[1] * k;
            if (y < 0 || y >= 6 || x < 0 || x >= 7 || b[y][x] != p) {
              ok = false;
              break;
            }
          }
          if (ok) return true;
        }
    return false;
  }

  int drop(List<List<int>> b, int col, int p) {
    for (var r = 5; r >= 0; r--)
      if (b[r][col] == 0) {
        b[r][col] = p;
        return r;
      }
    return -1;
  }

  int search(List<List<int>> b, int depth, int p) {
    if (four(b, 2)) return 10000 + depth;
    if (four(b, 1)) return -10000 - depth;
    final choices = [
      for (var c = 0; c < 7; c++)
        if (b[0][c] == 0) c
    ];
    if (depth == 0 || choices.isEmpty)
      return List.generate(
          6,
          (r) => b[r][3] == 2
              ? 3
              : b[r][3] == 1
                  ? -3
                  : 0).reduce((a, b) => a + b);
    var best = p == 2 ? -99999 : 99999;
    for (final c in choices) {
      final next = b.map((x) => List<int>.from(x)).toList();
      drop(next, c, p);
      final v = search(next, depth - 1, 3 - p);
      best = p == 2 ? max(best, v) : min(best, v);
    }
    return best;
  }

  int ai() {
    if (difficulty == 0) return legal[rng.nextInt(legal.length)];
    var best = -99999;
    final options = <int>[];
    for (final c in legal) {
      final b = cells.map((x) => List<int>.from(x)).toList();
      drop(b, c, 2);
      final v = search(b, difficulty == 1 ? 2 : 4, 1);
      if (v > best) {
        best = v;
        options
          ..clear()
          ..add(c);
      } else if (v == best) options.add(c);
    }
    return options[rng.nextInt(options.length)];
  }

  void advance() {
    if (four(cells, turn)) {
      winner = turn;
      done = true;
    } else if (legal.isEmpty) {
      done = true;
    } else {
      turn = 3 - turn;
    }
  }

  void play(int col) {
    if (done || !legal.contains(col)) return;
    setState(() {
      last = (drop(cells, col, turn), col);
      advance();
      if (versusAi && !done) {
        final c = ai();
        last = (drop(cells, c, 2), c);
        advance();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final names = versusAi ? ['You', 'Computer'] : ['Red', 'Yellow'];
    final status = done
        ? winner == 0
            ? 'Draw!'
            : '${names[winner - 1]} win${versusAi && winner == 1 ? '' : 's'}!'
        : '${names[turn - 1]} to move';
    final wins = winningCells;
    return GameScaffold(
      gameId: 'connect_four',
      completed: done && (versusAi ? winner == 1 : winner != 0),
      title: 'Connect Four',
      onNewGame: () => setState(reset),
      rules: 'Take turns dropping discs into the columns; a disc falls to the '
          'lowest free space. Line up four of your colour across, up and '
          'down, or diagonally to win. Tap anywhere in a column to drop a '
          'disc. Red always starts.',
      children: [
        OpponentPicker(
          vsComputer: versusAi,
          level: AiLevel.values[difficulty],
          onChanged: (v, l) => setState(() {
            versusAi = v;
            difficulty = l.index;
            reset();
          }),
        ),
        StatusBanner(status, highlight: done),
        const SizedBox(height: 8),
        AspectRatio(
          aspectRatio: 7 / 6.4,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF2B5FD9), Color(0xFF1A3FA8)],
              ),
              boxShadow: const [
                BoxShadow(
                    blurRadius: 10,
                    offset: Offset(0, 5),
                    color: Colors.black38),
              ],
            ),
            child: Row(children: [
              for (var c = 0; c < 7; c++)
                Expanded(
                  child: Semantics(
                    label: 'Column ${c + 1}',
                    button: !done && legal.contains(c),
                    child: GestureDetector(
                      key: ValueKey('connect_four_column_$c'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () => play(c),
                      child: Column(children: [
                        for (var r = 0; r < 6; r++)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(3),
                              child: _Disc(
                                player: cells[r][c],
                                winning: wins.contains((r, c)),
                                last: last == (r, c),
                              ),
                            ),
                          ),
                      ]),
                    ),
                  ),
                ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _Disc extends StatelessWidget {
  const _Disc(
      {required this.player, required this.winning, required this.last});
  final int player;
  final bool winning, last;

  @override
  Widget build(BuildContext context) {
    final base = player == 1
        ? const Color(0xFFE53935)
        : player == 2
            ? const Color(0xFFFDD835)
            : null;
    return AspectRatio(
      aspectRatio: 1,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: base == null ? const Color(0xFFE8EEF9) : null,
          gradient: base == null
              ? null
              : RadialGradient(
                  center: const Alignment(-.3, -.35),
                  colors: [
                    Color.lerp(base, Colors.white, .45)!,
                    base,
                    Color.lerp(base, Colors.black, .3)!,
                  ],
                  stops: const [0, .55, 1],
                ),
          border: Border.all(
            color: winning
                ? Colors.white
                : last
                    ? Colors.white70
                    : const Color(0xFF12307F),
            width: winning
                ? 4
                : last
                    ? 2.5
                    : 2,
          ),
          boxShadow: [
            if (winning) const BoxShadow(color: Colors.white70, blurRadius: 10),
          ],
        ),
      ),
    );
  }
}
