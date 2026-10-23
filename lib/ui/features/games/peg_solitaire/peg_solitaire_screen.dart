import 'package:flutter/material.dart';

import '../common/campaign_level_bar.dart';
import '../common/game_kit.dart';
import '../common/grid_board_touch_area.dart';
import 'peg_solitaire_engine.dart';
import 'triangle_peg_board_view.dart';

class PegSolitaireScreen extends StatefulWidget {
  const PegSolitaireScreen({super.key});
  @override
  State<PegSolitaireScreen> createState() => _PegSolitaireScreenState();
}

class _PegSolitaireScreenState extends State<PegSolitaireScreen> {
  int level = CampaignLevelBar.initialLevel('peg_solitaire');
  late PegBoard board = PegLevels.build(level);
  int? selected;

  /// Playing the 15-hole triangle game instead of the cross-board levels.
  bool triangle = false;
  TrianglePegBoard tri = TrianglePegBoard();

  void _tapTriangle(int i) {
    setState(() {
      if (!tri.started) {
        tri.begin(i);
        return;
      }
      if (selected != null && tri.move(selected!, i)) {
        selected = tri.targets(i).isNotEmpty ? i : null;
        return;
      }
      selected = tri.pegs[i] && tri.targets(i).isNotEmpty ? i : null;
    });
  }

  void _dropTriangle(int from, int to) => setState(() {
        if (tri.move(from, to)) {
          selected = tri.targets(to).isNotEmpty ? to : null;
        }
      });

  Widget _modeToggle() => SegmentedButton<bool>(
        key: const ValueKey('peg_solitaire_mode'),
        segments: const [
          ButtonSegment(
              value: false,
              icon: Icon(Icons.add_box_outlined),
              label: Text('Cross · 20 levels')),
          ButtonSegment(
              value: true,
              icon: Icon(Icons.change_history),
              label: Text('Triangle')),
        ],
        selected: {triangle},
        onSelectionChanged: (s) => setState(() {
          triangle = s.first;
          selected = null;
        }),
      );

  Widget _buildTriangle(BuildContext context) {
    final left = tri.remaining;
    final status = !tri.started
        ? 'Tap any peg to remove it and start'
        : tri.stuck
            ? '$left peg${left == 1 ? '' : 's'} left — '
                '${TrianglePegBoard.rating(left)}'
            : '$left pegs left';
    return GameScaffold(
      gameId: 'peg_solitaire',
      completed: tri.started && tri.remaining == 1,
      title: 'Peg Solitaire',
      onNewGame: () => setState(() {
        tri = TrianglePegBoard();
        selected = null;
      }),
      rules: 'The classic 15-hole triangle peg game. Start by tapping any '
          'peg to take it out. Then jump a peg over a neighbour into an empty '
          'hole directly beyond it — along a row or either diagonal — and '
          'remove the peg you jumped. Tap a peg and then a highlighted hole, '
          'or drag the peg there.\n\nThe game ends when no jumps are left. '
          'Leave one peg: genius! Two: pretty smart. Three: just average. '
          'Four or more: keep practising. Every starting hole can be '
          'finished with one peg.',
      children: [
        _modeToggle(),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
              child: StatusBanner(status,
                  highlight: tri.stuck && tri.remaining <= 2)),
          IconButton.filledTonal(
            tooltip: 'Undo',
            onPressed: tri.history.isEmpty
                ? null
                : () => setState(() {
                      tri.undo();
                      selected = null;
                    }),
            icon: const Icon(Icons.undo),
          ),
        ]),
        const SizedBox(height: 8),
        TrianglePegBoardView(
          board: tri,
          selected: selected,
          onTap: _tapTriangle,
          onDrop: _dropTriangle,
        ),
      ],
    );
  }

  void _tap(int i) {
    setState(() {
      if (selected != null && board.move(selected!, i)) {
        selected = board.targets(i).isNotEmpty ? i : null;
        return;
      }
      selected = board.pegs[i] && board.targets(i).isNotEmpty ? i : null;
    });
  }

  void _selectDrag(int from) {
    if (board.holes[from] &&
        board.pegs[from] &&
        board.targets(from).isNotEmpty &&
        selected != from) {
      setState(() => selected = from);
    }
  }

  void _drag(int from, int to) {
    if (!board.holes[from] ||
        !board.holes[to] ||
        !board.targets(from).contains(to)) return;
    setState(() {
      board.move(from, to);
      selected = board.targets(to).isNotEmpty ? to : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (triangle) return _buildTriangle(context);
    final colors = Theme.of(context).colorScheme;
    final status = board.stuck
        ? board.perfect
            ? 'Perfect — one peg in the centre!'
            : board.remaining == 1
                ? 'Solved with one peg left!'
                : 'No more jumps · ${board.remaining} pegs left'
        : '${board.remaining} pegs left';
    final targets =
        selected == null ? <int>{} : board.targets(selected!).toSet();
    return GameScaffold(
      gameId: 'peg_solitaire',
      completed: board.remaining == 1,
      title: 'Peg Solitaire',
      onNewGame: () => setState(() {
        board = PegLevels.build(level);
        selected = null;
      }),
      rules:
          'Tap a peg and a highlighted destination, or drag the peg directly '
          'there. Jump over a neighbouring peg into an empty hole straight '
          'behind it (no diagonals); the jumped peg is removed. Try to finish '
          'with a single peg.\n\nThere are 20 levels: classic patterns from 6 '
          'to 28 pegs, then the full board started from each of its seven '
          'different empty holes, ending with the classic centre start. '
          'Every level can be solved; leave one peg to complete it. New game '
          'restarts the current level.\n\nSwitch to Triangle for the classic '
          '15-hole triangle game.',
      children: [
        _modeToggle(),
        CampaignLevelBar(
          gameId: 'peg_solitaire',
          level: level,
          solved: board.remaining == 1,
          onLevel: (value) => setState(() {
            level = value;
            board = PegLevels.build(level);
            selected = null;
          }),
          describe: PegLevels.nameFor,
        ),
        Row(children: [
          Expanded(child: StatusBanner(status, highlight: board.stuck)),
          IconButton.filledTonal(
            tooltip: 'Undo',
            onPressed: board.history.isEmpty
                ? null
                : () => setState(() {
                      board.undo();
                      selected = null;
                    }),
            icon: const Icon(Icons.undo),
          ),
        ]),
        const SizedBox(height: 8),
        AspectRatio(
          aspectRatio: 1,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: Alignment(-.3, -.35),
                radius: 1,
                colors: [
                  Color(0xFFC88A50),
                  Color(0xFF9A6233),
                  Color(0xFF6E3F20)
                ],
              ),
              boxShadow: [
                BoxShadow(
                    blurRadius: 12,
                    offset: Offset(0, 6),
                    color: Colors.black38),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: GridBoardTouchArea(
                key: const ValueKey('peg_solitaire_touch_board'),
                columns: 7,
                rows: 7,
                onTapCell: (i) {
                  if (board.holes[i]) _tap(i);
                },
                onDragStartCell: _selectDrag,
                onDragCell: _drag,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7),
                  itemCount: 49,
                  itemBuilder: (context, i) {
                    if (!board.holes[i]) return const SizedBox();
                    final target = targets.contains(i);
                    return Semantics(
                      key: ValueKey('peg_solitaire_cell_$i'),
                      label:
                          'Hole ${i + 1}: ${board.pegs[i] ? 'peg' : 'empty'}',
                      hint: target ? 'Legal destination' : null,
                      button: true,
                      selected: selected == i,
                      onTap: () => _tap(i),
                      child: Container(
                        margin: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: target
                              ? null
                              : const RadialGradient(
                                  center: Alignment(.3, .35),
                                  colors: [
                                    Color(0xFF6B3E1E),
                                    Color(0xFF3A1D0A)
                                  ],
                                ),
                          color: target ? colors.primaryContainer : null,
                          border: Border.all(
                            color: target
                                ? colors.primary
                                : const Color(0xFF3A1D0A),
                            width: target ? 3 : 1,
                          ),
                        ),
                        padding: const EdgeInsets.all(2),
                        child: board.pegs[i]
                            ? _Marble(selected: selected == i)
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A glass marble for the cross board.
class _Marble extends StatelessWidget {
  const _Marble({required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-.35, -.4),
          colors: selected
              ? [
                  Colors.white,
                  colors.primary,
                  Color.lerp(colors.primary, Colors.black, .4)!
                ]
              : const [Color(0xFFFFF8E1), Color(0xFFFFB300), Color(0xFF8D5A00)],
          stops: const [0, .5, 1],
        ),
        border: selected ? Border.all(color: colors.primary, width: 2) : null,
        boxShadow: const [
          BoxShadow(blurRadius: 3, offset: Offset(1, 2), color: Colors.black54),
        ],
      ),
    );
  }
}
