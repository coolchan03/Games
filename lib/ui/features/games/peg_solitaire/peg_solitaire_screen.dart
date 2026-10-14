import 'package:flutter/material.dart';

import '../common/game_kit.dart';
import 'peg_solitaire_engine.dart';

class PegSolitaireScreen extends StatefulWidget {
  const PegSolitaireScreen({super.key});
  @override
  State<PegSolitaireScreen> createState() => _PegSolitaireScreenState();
}

class _PegSolitaireScreenState extends State<PegSolitaireScreen> {
  bool european = false;
  late PegBoard board = PegBoard(european: european);
  int? selected;

  void _tap(int i) {
    setState(() {
      if (selected != null && board.move(selected!, i)) {
        selected = board.targets(i).isNotEmpty ? i : null;
        return;
      }
      selected = board.pegs[i] && board.targets(i).isNotEmpty ? i : null;
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
      title: 'Peg Solitaire',
      onNewGame: () => setState(() {
        board = PegBoard(european: european);
        selected = null;
      }),
      rules: 'Jump a peg over a neighbouring peg into an empty hole straight '
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
              onSelectionChanged: (s) => setState(() {
                european = s.first;
                board = PegBoard(european: european);
                selected = null;
              }),
            ),
          ),
          IconButton.filledTonal(
            tooltip: 'Undo',
            onPressed: board.history.isEmpty ? null : () => setState(() {
              board.undo();
              selected = null;
            }),
            icon: const Icon(Icons.undo),
          ),
        ]),
        StatusBanner(status, highlight: board.stuck),
        AspectRatio(
          aspectRatio: 1,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
            itemCount: 49,
            itemBuilder: (context, i) {
              if (!board.holes[i]) return const SizedBox();
              return GestureDetector(
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
                    border: Border.all(color: colors.outline),
                    boxShadow: board.pegs[i]
                        ? const [BoxShadow(blurRadius: 3, offset: Offset(0, 2), color: Colors.black38)]
                        : null,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
