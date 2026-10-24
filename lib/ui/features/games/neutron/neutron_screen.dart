import 'dart:math';

import 'package:flutter/material.dart';

import '../common/game_kit.dart';
import '../common/grid_board_touch_area.dart';
import 'neutron_engine.dart';

class NeutronScreen extends StatefulWidget {
  const NeutronScreen({super.key});
  @override
  State<NeutronScreen> createState() => _NeutronScreenState();
}

class _NeutronScreenState extends State<NeutronScreen> {
  final rng = Random();
  bool vsComputer = true;
  AiLevel level = AiLevel.medium;
  NeutronState game = NeutronState();
  int? neutronTo; // chosen neutron destination this turn
  int? from;
  bool thinking = false;
  int generation = 0;

  void _newGame() => setState(() {
        generation++;
        thinking = false;
        from = null;
        neutronTo = null;
        game = NeutronState();
      });

  bool get _neutronPhase => !game.firstMove && neutronTo == null;

  Future<void> _computer() async {
    if (!vsComputer || game.turn != 2 || game.result != 0) return;
    final token = generation;
    setState(() => thinking = true);
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted || token != generation) return;
    setState(() {
      game.apply(neutronAi(game, level.index, rng));
      thinking = false;
    });
  }

  void _tap(int i) {
    if (thinking || game.result != 0 || (vsComputer && game.turn == 2)) return;
    final moves = game.moves();
    setState(() {
      if (_neutronPhase) {
        if (game.cells[i] == 3) {
          from = game.neutron;
          return;
        }
        if (from == game.neutron && moves.any((m) => m.neutronTo == i)) {
          final finishing = moves.firstWhere((m) => m.neutronTo == i);
          if (finishing.from < 0) {
            game.apply(finishing);
            from = null;
            return;
          }
          neutronTo = i;
          from = null;
        }
        return;
      }
      final mine = moves.where((m) => m.neutronTo == neutronTo).toList();
      if (from != null && mine.any((m) => m.from == from && m.to == i)) {
        game.apply(mine.firstWhere((m) => m.from == from && m.to == i));
        from = null;
        neutronTo = null;
        return;
      }
      from = mine.any((m) => m.from == i) ? i : null;
    });
    _computer();
  }

  void _drag(int source, int destination) {
    if (thinking || game.result != 0 || (vsComputer && game.turn == 2)) return;
    final options = game.moves();
    final legal = _neutronPhase
        ? source == game.neutron &&
          options.any((move) => move.neutronTo == destination)
        : options.any((move) => move.neutronTo == neutronTo &&
            move.from == source && move.to == destination);
    if (!legal) return;
    _tap(source);
    _tap(destination);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final r = game.result;
    String name(int p) => p == 1 ? (vsComputer ? 'You (blue)' : 'Blue') : (vsComputer ? 'Computer' : 'Red');
    // Board shown with the pending neutron move applied.
    final shown = List.of(game.cells);
    if (neutronTo != null) {
      shown[game.neutron] = 0;
      shown[neutronTo!] = 3;
    }
    final moves = r == 0 ? game.moves() : <NeutronMove>[];
    Set<int> targets = {};
    if (_neutronPhase && from == game.neutron) {
      targets = {for (final m in moves) if (m.neutronTo != null) m.neutronTo!};
    } else if (from != null) {
      targets = {for (final m in moves) if (m.neutronTo == neutronTo && m.from == from) m.to};
    }
    final status = r != 0
        ? '${name(r)} ${vsComputer && r == 1 ? 'win' : 'wins'}!'
        : thinking
            ? 'Computer is thinking…'
            : _neutronPhase
                ? '${name(game.turn)}: first slide the Neutron (tap it)'
                : '${name(game.turn)}: now slide one of your pieces';
    return GameScaffold(
      gameId: 'neutron',
      completed: r == 1 || (!vsComputer && r == 2),
      title: 'Neutron',
      onNewGame: _newGame,
      rules: 'Each turn has two parts: first slide the grey Neutron, then '
          'slide one of your own pieces. Everything slides in a straight '
          'line (8 directions) as far as it can go, stopping at the edge or '
          'next to another piece. If the Neutron ends on your home row '
          '(blue: bottom, red: top) you win — even if the opponent moved it '
          'there. A player who cannot move the Neutron loses. Blue skips the '
          'Neutron on the very first turn. '
          'CONTROLS: Tap a piece and its legal target, or drag it there.',
      children: [
        OpponentPicker(
          vsComputer: vsComputer,
          level: level,
          onChanged: (v, l) {
            vsComputer = v;
            level = l;
            _newGame();
          },
        ),
        StatusBanner(status, highlight: r != 0),
        LandscapeBoard(child: AspectRatio(
          aspectRatio: 1,
          child: GridBoardTouchArea(
            columns: 5,
            onTapCell: _tap,
            onDragCell: _drag,
            onDragStartCell: _tap,
            child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5),
            itemCount: 25,
            itemBuilder: (context, i) {
              final v = shown[i];
              final home = i ~/ 5 == 4 ? const Color(0x221E88E5) : i ~/ 5 == 0 ? const Color(0x22E53935) : null;
              return Semantics(
                button: true,
                label: 'Row ${i ~/ 5 + 1}, column ${i % 5 + 1}',
                onTap: () => _tap(i),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: targets.contains(i) ? colors.primaryContainer : home ?? colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: v == 0
                      ? null
                      : Padding(
                          padding: const EdgeInsets.all(8),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: v == 1 ? const Color(0xFF1E88E5) : v == 2 ? const Color(0xFFE53935) : const Color(0xFF9E9E9E),
                              border: Border.all(color: from == i ? colors.onSurface : Colors.black26, width: from == i ? 4 : 1.5),
                            ),
                            child: v == 3 ? const Icon(Icons.blur_circular, color: Colors.white) : null,
                          ),
                        ),
                ),
              );
            },
          )),
        )),
        if (neutronTo != null)
          TextButton(onPressed: () => setState(() => neutronTo = null), child: const Text('Undo Neutron move')),
      ],
    );
  }
}
