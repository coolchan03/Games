import 'package:flutter/material.dart';

import '../common/game_kit.dart';
import 'dominoes_engine.dart';

class DominoTile extends StatelessWidget {
  const DominoTile(this.a, this.b, {super.key, this.size = 30, this.vertical = false, this.selected = false, this.dim = false, this.onTap});
  final int a, b;
  final double size;
  final bool vertical, selected, dim;
  final VoidCallback? onTap;

  static const _pips = <int, List<Offset>>{
    0: [],
    1: [Offset(.5, .5)],
    2: [Offset(.25, .25), Offset(.75, .75)],
    3: [Offset(.25, .25), Offset(.5, .5), Offset(.75, .75)],
    4: [Offset(.25, .25), Offset(.75, .25), Offset(.25, .75), Offset(.75, .75)],
    5: [Offset(.25, .25), Offset(.75, .25), Offset(.5, .5), Offset(.25, .75), Offset(.75, .75)],
    6: [Offset(.25, .2), Offset(.75, .2), Offset(.25, .5), Offset(.75, .5), Offset(.25, .8), Offset(.75, .8)],
  };

  Widget _half(int v) => SizedBox(
        width: size,
        height: size,
        child: Stack(children: [
          for (final o in _pips[v]!)
            Positioned(
              left: o.dx * size - size * .08,
              top: o.dy * size - size * .08,
              child: Container(
                width: size * .16,
                height: size * .16,
                decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle),
              ),
            ),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final divider = Container(
      width: vertical ? size * .8 : 1.5,
      height: vertical ? 1.5 : size * .8,
      color: Colors.black38,
    );
    final children = [_half(a), divider, _half(b)];
    return Semantics(
      label: 'Domino $a $b',
      button: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        child: Opacity(
          opacity: dim ? .45 : 1,
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBF0),
              borderRadius: BorderRadius.circular(size * .15),
              border: Border.all(color: selected ? colors.primary : Colors.black45, width: selected ? 3 : 1),
            ),
            child: vertical
                ? Column(mainAxisSize: MainAxisSize.min, children: children)
                : Row(mainAxisSize: MainAxisSize.min, children: children),
          ),
        ),
      ),
    );
  }
}

class DominoesScreen extends StatefulWidget {
  const DominoesScreen({super.key});
  @override
  State<DominoesScreen> createState() => _DominoesScreenState();
}

class _DominoesScreenState extends State<DominoesScreen> {
  int players = 2;
  AiLevel level = AiLevel.medium;
  late DominoesGame game = DominoesGame(players: players);
  Domino? selected;
  bool busy = false;
  int generation = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bots());
  }

  void _newMatch() {
    setState(() {
      generation++;
      busy = false;
      selected = null;
      game = DominoesGame(players: players);
    });
    _bots();
  }

  Future<void> _bots() async {
    if (busy) return;
    final token = generation;
    busy = true;
    while (mounted && token == generation && game.roundWinner == null && game.turn != 0) {
      setState(() {});
      await Future<void>.delayed(const Duration(milliseconds: 800));
      if (!mounted || token != generation) return;
      setState(() => game.aiTurn(level.index));
    }
    if (mounted && token == generation) setState(() => busy = false);
  }

  void _tapTile(Domino d) {
    if (busy || game.turn != 0 || game.roundWinner != null) return;
    final ends = game.ends(d);
    if (ends.isEmpty) return;
    if (ends.length == 1) {
      setState(() {
        game.play(d, ends.first);
        selected = null;
      });
      _bots();
    } else {
      setState(() => selected = d);
    }
  }

  void _playEnd(String end) {
    final d = selected;
    if (d == null) return;
    setState(() {
      game.play(d, end);
      selected = null;
    });
    _bots();
  }

  @override
  Widget build(BuildContext context) {
    final myTurn = game.turn == 0 && !busy && game.roundWinner == null;
    final canPlay = game.playable(0).isNotEmpty;
    String status;
    if (game.roundWinner != null) {
      status = game.log;
      if (game.matchOver) status += '\n${game.scores[0] >= game.target ? 'You win the match!' : 'Match lost.'}';
    } else if (myTurn) {
      status = canPlay ? (selected == null ? 'Your turn: tap a tile' : 'Play it on which end?') : (game.boneyard.isEmpty ? 'No move — pass' : 'No move — draw a tile');
    } else {
      status = '${game.name(game.turn)} is playing…';
    }
    return GameScaffold(
      title: 'Dominoes',
      onNewGame: _newMatch,
      rules: 'Double-six draw dominoes. Play a tile that matches the number '
          'at either open end of the line. If you cannot, draw from the '
          'boneyard until you can; when it is empty, pass. The first player '
          'to empty their hand scores the pips left in everyone else\'s hand. '
          'If nobody can move, the lowest hand wins the difference. First to '
          '100 wins.',
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
            _newMatch();
          },
        ),
        const SizedBox(height: 8),
        SegmentedButton<AiLevel>(
          segments: [for (final l in AiLevel.values) ButtonSegment(value: l, label: Text(l.label))],
          selected: {level},
          onSelectionChanged: (s) => setState(() => level = s.first),
        ),
        StatusBanner('$status\nScores: ${[for (var p = 0; p < players; p++) '${game.name(p)} ${game.scores[p]}'].join(' · ')}',
            highlight: myTurn || game.roundWinner != null),
        Wrap(alignment: WrapAlignment.center, spacing: 8, children: [
          for (var p = 1; p < players; p++) Chip(label: Text('${game.name(p)}: ${game.hands[p].length} tiles')),
          Chip(label: Text('Boneyard ${game.boneyard.length}')),
        ]),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: const Color(0xFF1E6B45), borderRadius: BorderRadius.circular(14)),
          constraints: const BoxConstraints(minHeight: 80),
          child: game.line.isEmpty
              ? const Center(child: Text('Lead any tile', style: TextStyle(color: Colors.white70)))
              : Wrap(
                  alignment: WrapAlignment.center,
                  runSpacing: 4,
                  children: [
                    for (final t in game.line) DominoTile(t.left, t.right, size: 18, vertical: t.left == t.right),
                  ],
                ),
        ),
        if (selected != null)
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () => _playEnd('L'), child: Text('◀ Left end (${game.leftEnd})'))),
            const SizedBox(width: 8),
            Expanded(child: OutlinedButton(onPressed: () => _playEnd('R'), child: Text('Right end (${game.rightEnd}) ▶'))),
          ]),
        const SizedBox(height: 8),
        Wrap(alignment: WrapAlignment.center, children: [
          for (final d in game.hands[0])
            DominoTile(d.a, d.b,
                size: 26,
                vertical: true,
                selected: selected == d,
                dim: myTurn && game.ends(d).isEmpty,
                onTap: () => _tapTile(d)),
        ]),
        const SizedBox(height: 8),
        if (game.roundWinner != null)
          FilledButton(
            onPressed: game.matchOver
                ? _newMatch
                : () {
                    setState(game.deal);
                    _bots();
                  },
            child: Text(game.matchOver ? 'New match' : 'Next round'),
          )
        else if (myTurn && !canPlay)
          FilledButton.tonal(
            onPressed: () {
              setState(() {
                if (!game.draw()) game.pass();
              });
              if (game.turn != 0) _bots();
            },
            child: Text(game.boneyard.isEmpty ? 'Pass' : 'Draw'),
          ),
      ],
    );
  }
}
