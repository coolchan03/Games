import 'dart:math';

import 'package:flutter/material.dart';

import '../common/game_kit.dart';

/// The Game of the Goose (traditional rules, 63 squares, two dice).
class GooseGame {
  GooseGame(this.players, {Random? random}) : rng = random ?? Random() {
    pos = List.filled(players, 0);
    skip = List.filled(players, 0);
  }

  final int players;
  final Random rng;
  late List<int> pos;
  late List<int> skip;
  int turn = 0;
  int? winner;
  List<int> dice = [];
  String log = '';
  bool firstRoll = true;

  static const geese = {5, 9, 14, 18, 23, 27, 32, 36, 41, 45, 50, 54, 59};
  static const specials = {
    6: 'Bridge', 19: 'Inn', 31: 'Well', 42: 'Maze', 52: 'Prison', 58: 'Death', 63: 'Garden',
  };

  String name(int p) => p == 0 ? 'You' : 'Player ${p + 1}';

  /// Players trapped in the well or prison wait until someone else lands there.
  int? _trapped(int square) {
    for (var p = 0; p < players; p++) {
      if (pos[p] == square && skip[p] < 0) return p;
    }
    return null;
  }

  void roll([List<int>? fixed]) {
    if (winner != null) return;
    final p = turn;
    if (skip[p] > 0) {
      skip[p]--;
      log = '${name(p)} ${p == 0 ? 'rest' : 'rests'} at the inn';
      _next();
      return;
    }
    if (skip.every((k) => k < 0)) {
      // Everyone is trapped: release them all so the game can continue.
      skip.fillRange(0, players, 0);
    }
    if (skip[p] < 0) {
      log = '${name(p)} ${p == 0 ? 'are' : 'is'} stuck until rescued';
      _next();
      return;
    }
    dice = fixed ?? [rng.nextInt(6) + 1, rng.nextInt(6) + 1];
    final total = dice[0] + dice[1];
    final notes = <String>[];
    var target = pos[p] + total;
    // Special opening rolls.
    if (pos[p] == 0 && (dice.contains(6) && dice.contains(3))) {
      target = 26;
      notes.add('6+3 at the start: straight to 26');
    } else if (pos[p] == 0 && (dice.contains(5) && dice.contains(4))) {
      target = 53;
      notes.add('5+4 at the start: straight to 53');
    }
    var bounces = 0;
    while (true) {
      if (target > 63) {
        target = 126 - target;
        notes.add('bounced back from 63');
      }
      if (geese.contains(target) && bounces++ < 10) {
        notes.add('goose at $target — fly on $total');
        target += total;
        continue;
      }
      break;
    }
    switch (target) {
      case 6:
        notes.add('bridge to 12');
        target = 12;
      case 42:
        notes.add('lost in the maze, back to 30');
        target = 30;
      case 58:
        notes.add('death — back to the start');
        target = 0;
      case 19:
        notes.add('inn: miss two turns');
        skip[p] = 2;
      case 31:
      case 52:
        final other = _trapped(target);
        if (other != null) {
          skip[other] = 0;
          notes.add('${name(other)} is freed');
        }
        notes.add(target == 31 ? 'fell in the well' : 'thrown in prison');
        skip[p] = -1;
    }
    pos[p] = target;
    log = '${name(p)} rolled ${dice[0]}+${dice[1]}${notes.isEmpty ? '' : ': ${notes.join(', ')}'} → $target';
    if (target == 63) {
      winner = p;
      return;
    }
    _next();
  }

  void _next() {
    turn = (turn + 1) % players;
  }
}

const _tokenColors = [Color(0xFFE53935), Color(0xFF1E88E5), Color(0xFF43A047), Color(0xFFFDD835)];

class GooseGameScreen extends StatefulWidget {
  const GooseGameScreen({super.key});
  @override
  State<GooseGameScreen> createState() => _GooseGameScreenState();
}

class _GooseGameScreenState extends State<GooseGameScreen> {
  int players = 3;
  bool vsComputer = true;
  late GooseGame game = GooseGame(players);
  bool busy = false;
  int generation = 0;

  void _newGame() => setState(() {
        generation++;
        busy = false;
        game = GooseGame(players);
      });

  Future<void> _roll() async {
    if (busy) return;
    final token = generation;
    setState(game.roll);
    busy = true;
    while (mounted && token == generation && vsComputer && game.winner == null && game.turn != 0) {
      await Future<void>.delayed(const Duration(milliseconds: 800));
      if (!mounted || token != generation) return;
      setState(game.roll);
    }
    if (mounted && token == generation) setState(() => busy = false);
  }

  /// Square n (1..63) laid out as a 9×7 serpentine.
  static Offset cell(int n) {
    final i = n - 1, row = i ~/ 9;
    final col = row.isEven ? i % 9 : 8 - i % 9;
    return Offset(col.toDouble(), (6 - row).toDouble());
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    String status;
    if (game.winner != null) {
      status = '${game.name(game.winner!)} reached the garden of the goose!';
    } else {
      status = '${game.log.isEmpty ? '' : '${game.log}\n'}${game.name(game.turn)} to roll';
    }
    return GameScaffold(
      gameId: 'goose_game',
      completed: game.winner == 0 || (!vsComputer && game.winner != null),
      title: 'Game of the Goose',
      onNewGame: _newGame,
      rules: 'Race to square 63 with two dice; you must land on it exactly, '
          'bouncing back by any extra. Landing on a goose moves you on by '
          'the same roll again. Bridge (6) → 12. Inn (19): miss two turns. '
          'Well (31) and Prison (52): stay until another player lands there '
          'to free you. Maze (42) → 30. Death (58) → back to the start. On the '
          'first roll, 6+3 goes to 26 and 5+4 to 53.',
      children: [
        OpponentPicker(
          vsComputer: vsComputer,
          level: AiLevel.easy,
          showLevel: false,
          onChanged: (v, _) {
            vsComputer = v;
            _newGame();
          },
        ),
        const SizedBox(height: 8),
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
        StatusBanner(status, highlight: game.winner != null),
        AspectRatio(
          aspectRatio: 9 / 7,
          child: LayoutBuilder(builder: (context, box) {
            final c = box.maxWidth / 9;
            return Stack(children: [
              for (var n = 1; n <= 63; n++)
                Positioned(
                  left: cell(n).dx * c,
                  top: cell(n).dy * c,
                  width: c,
                  height: c,
                  child: Container(
                    margin: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: GooseGame.geese.contains(n)
                          ? const Color(0xFFFFF59D)
                          : GooseGame.specials.containsKey(n)
                              ? colors.tertiaryContainer
                              : colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('$n', style: const TextStyle(fontSize: 9)),
                      if (GooseGame.geese.contains(n)) const Expanded(child: FittedBox(child: Icon(Icons.flutter_dash, color: Color(0xFFF57F17)))),
                      if (GooseGame.specials.containsKey(n))
                        Expanded(child: FittedBox(child: Text(GooseGame.specials[n]!, style: const TextStyle(fontSize: 8)))),
                    ]),
                  ),
                ),
              for (var p = 0; p < players; p++)
                if (game.pos[p] > 0)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 400),
                    left: (cell(game.pos[p]).dx + .15 + (p % 2) * .4) * c,
                    top: (cell(game.pos[p]).dy + .3 + (p ~/ 2) * .35) * c,
                    width: c * .32,
                    height: c * .32,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _tokenColors[p],
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
            ]);
          }),
        ),
        const SizedBox(height: 8),
        Wrap(alignment: WrapAlignment.center, spacing: 6, children: [
          for (var p = 0; p < players; p++)
            Chip(
              avatar: CircleAvatar(backgroundColor: _tokenColors[p]),
              label: Text('${game.name(p)}: ${game.pos[p]}${game.skip[p] != 0 ? ' (waiting)' : ''}'),
            ),
        ]),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (final d in game.dice) DieFace(d, size: 40),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: busy || game.winner != null ? null : _roll,
            icon: const Icon(Icons.casino_outlined),
            label: const Text('Roll'),
          ),
        ]),
      ],
    );
  }
}
