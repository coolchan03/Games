import 'dart:async';

import 'package:flutter/material.dart';

import '../common/campaign_progress.dart';
import '../common/game_kit.dart';
import '../common/grid_board_touch_area.dart';
import 'peg_solitaire_engine.dart';

class PegSolitaireScreen extends StatefulWidget {
  const PegSolitaireScreen({super.key});
  @override
  State<PegSolitaireScreen> createState() => _PegSolitaireScreenState();
}

class _PegSolitaireScreenState extends State<PegSolitaireScreen> {
  bool european = CampaignProgress.selectedLevel(
    'peg_solitaire', count: 2) == 2;
  late PegBoard board = _load();
  int? selected;

  int get _layoutIndex => european ? 2 : 1;

  PegBoard _load() {
    final fresh = PegBoard(european: european);
    final saved = CampaignProgress.loadActive(
      'peg_solitaire', _layoutIndex, maxLength: 49,
    );
    if (saved != null) fresh.restore(saved);
    return fresh;
  }

  void _save() => unawaited(CampaignProgress.saveActive(
    'peg_solitaire', _layoutIndex, board.snapshot(),
  ));

  void _restart() {
    setState(() { board = PegBoard(european: european); selected = null; });
    _save();
  }

  void _tap(int i) {
    setState(() {
      if (selected != null && board.move(selected!, i)) {
        selected = board.targets(i).isNotEmpty ? i : null;
        _save();
        return;
      }
      selected = board.pegs[i] && board.targets(i).isNotEmpty ? i : null;
    });
  }

  void _selectDrag(int from) {
    if (board.holes[from] && board.pegs[from] &&
        board.targets(from).isNotEmpty && selected != from) {
      setState(() => selected = from);
    }
  }

  void _drag(int from, int to) {
    if (!board.holes[from] || !board.holes[to] ||
        !board.targets(from).contains(to)) return;
    setState(() {
      board.move(from, to);
      selected = board.targets(to).isNotEmpty ? to : null;
      _save();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final status = board.stuck
        ? board.perfect
            ? 'Perfect — one peg in the centre!'
            : board.remaining == 1
                ? 'Solved with one peg left!'
                : 'No more jumps · ${board.remaining} pegs left'
        : '${board.remaining} pegs left';
    final targets = selected == null ? <int>{} : board.targets(selected!).toSet();
    return GameScaffold(
      gameId: 'peg_solitaire',
      completed: board.remaining == 1,
      title: 'Peg Solitaire',
      onNewGame: _restart,
      rules: 'Tap a peg and a highlighted destination, or drag the peg directly '
          'there. Jump over a neighbouring peg into an empty hole straight '
          'behind it (no diagonals); the jumped peg is removed. Try to finish '
          'with a single peg — ideally in the centre hole.',
      children: [
        Row(children: [
          Expanded(
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('English 33')),
                ButtonSegment(value: true, label: Text('European 37')),
              ],
              selected: {european},
              onSelectionChanged: (s) {
                setState(() {
                  european = s.first;
                  board = _load();
                  selected = null;
                });
                unawaited(CampaignProgress.saveSelected(
                  'peg_solitaire', _layoutIndex,
                ));
              },
            ),
          ),
          IconButton.filledTonal(
            tooltip: 'Undo',
            onPressed: board.history.isEmpty ? null : () => setState(() {
              board.undo();
              selected = null;
              _save();
            }),
            icon: const Icon(Icons.undo),
          ),
        ]),
        StatusBanner(status, highlight: board.stuck),
        AspectRatio(
          aspectRatio: 1,
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
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
            itemCount: 49,
            itemBuilder: (context, i) {
              if (!board.holes[i]) return const SizedBox();
              return Semantics(
                key: ValueKey('peg_solitaire_cell_$i'),
                label: 'Hole ${i + 1}: ${board.pegs[i] ? 'peg' : 'empty'}',
                hint: targets.contains(i) ? 'Legal destination' : null,
                button: true,
                selected: selected == i,
                onTap: () => _tap(i),
                child: Container(
                  margin: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: board.pegs[i]
                        ? (selected == i ? colors.primary : const Color(0xFF8D4E2A))
                        : targets.contains(i)
                            ? colors.primaryContainer
                            : colors.surfaceContainerHighest,
                    border: Border.all(
                      color: selected == i || targets.contains(i)
                          ? colors.primary : colors.outline,
                      width: selected == i || targets.contains(i) ? 3 : 1,
                    ),
                    boxShadow: board.pegs[i]
                        ? const [BoxShadow(blurRadius: 3, offset: Offset(0, 2), color: Colors.black38)]
                        : null,
                  ),
                ),
              );
            },
          ),
          ),
        ),
      ],
    );
  }
}
