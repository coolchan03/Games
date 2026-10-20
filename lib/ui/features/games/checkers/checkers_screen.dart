import 'package:flutter/material.dart';
import '../common/grid_board_touch_area.dart';
import 'engine/checkers_rules.dart';

class CheckersScreen extends StatefulWidget {
  const CheckersScreen({super.key});
  @override
  State<CheckersScreen> createState() => _CheckersScreenState();
}
class _CheckersScreenState extends State<CheckersScreen> {
  final computer = CheckersComputer();
  CheckersPosition game = CheckersPosition.start();
  bool versusAi = true, thinking = false;
  int difficulty = 1, generation = 0;
  int? selected;
  void reset() => setState(() {
    generation++;
    game = CheckersPosition.start();
    selected = null;
    thinking = false;
  });
  Future<void> computerTurn() async {
    final token = generation;
    setState(() => thinking = true);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (!mounted || token != generation || game.complete ||
        !versusAi || game.turn != 2) return;
    final move = computer.choose(game, difficulty);
    if (!mounted || token != generation) return;
    setState(() {
      game = game.play(move);
      selected = null;
      thinking = false;
    });
  }
  bool _playMove(int from, int to) {
    if (game.complete || thinking || (versusAi && game.turn == 2)) return false;
    final matching = game.legalMoves.where(
      (move) => move.from == from && move.to == to,
    ).toList();
    if (matching.isEmpty) return false;
    setState(() {
      game = game.play(matching.first);
      selected = null;
    });
    if (versusAi && !game.complete && game.turn == 2) computerTurn();
    return true;
  }

  void tap(int index) {
    if (game.complete || thinking || (versusAi && game.turn == 2)) return;
    if (selected != null && _playMove(selected!, index)) return;
    if (game.legalMoves.any((move) => move.from == index)) {
      setState(() => selected = index);
    }
  }

  void drag(int from, int to) => _playMove(from, to);

  void selectDrag(int index) {
    if (game.complete || thinking || (versusAi && game.turn == 2)) return;
    if (game.legalMoves.any((move) => move.from == index) && selected != index) {
      setState(() => selected = index);
    }
  }
  Widget board(ColorScheme colors) {
    final moves = game.legalMoves;
    final targets = selected == null ? <int>{}
      : moves.where((m) => m.from == selected).map((m) => m.to).toSet();
    return AspectRatio(aspectRatio: 1, child: GridBoardTouchArea(
      key: const ValueKey('checkers_touch_board'),
      columns: 8,
      rows: 8,
      onTapCell: tap,
      onDragCell: drag,
      onDragStartCell: selectDrag,
      child: GridView.builder(
      itemCount: 64,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 8),
      itemBuilder: (context, index) {
        final row = index ~/ 8, col = index % 8, piece = game.cells[index];
        final isWhite = piece == 1 || piece == 3;
        final king = piece == 3 || piece == 4;
        return Semantics(
          key: ValueKey('checkers_cell_$index'),
          label: piece == 0
              ? 'Row ${row + 1}, column ${col + 1}, empty'
              : 'Row ${row + 1}, column ${col + 1}, player ${CheckersPosition.owner(piece)} ${king ? 'king' : 'piece'}',
          selected: selected == index,
          hint: targets.contains(index) ? 'Legal destination' : null,
          button: true,
          onTap: () => tap(index),
          child: Container(margin: const EdgeInsets.all(1),
            color: selected == index ? colors.tertiaryContainer
              : (row + col).isOdd ? colors.primaryContainer
              : colors.surfaceContainer,
            alignment: Alignment.center,
            child: piece == 0 ? (targets.contains(index)
              ? Icon(Icons.radio_button_checked, size: 19,
                  color: colors.primary.withValues(alpha: 0.55)) : null)
              : FractionallySizedBox(widthFactor: .79, heightFactor: .79,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isWhite ? colors.surface : colors.onSurface,
                      border: Border.all(color: colors.outline, width: 2)),
                    child: king ? Icon(Icons.star, size: 16,
                      color: isWhite ? colors.onSurface : colors.surface) : null,
                  )),
          ));
      },
    )));
  }
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final label = game.complete ? 'Player ${game.winner} wins!'
      : thinking ? 'Computer thinking…' : 'Player ${game.turn} to move';
    return Scaffold(appBar: AppBar(title: const Text('Checkers')),
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: ListView(padding: const EdgeInsets.all(16), children: [
          SwitchListTile(
            title: const Text('Play against computer'),
            value: versusAi,
            onChanged: (v) { versusAi = v; reset(); },
          ),
          if (versusAi) SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Easy')),
              ButtonSegment(value: 1, label: Text('Medium')),
              ButtonSegment(value: 2, label: Text('Hard')),
            ],
            selected: {difficulty},
            onSelectionChanged: (v) { difficulty = v.first; reset(); },
          ),
          const SizedBox(height: 16),
          Text(label, textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          board(colors),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: reset, icon: const Icon(Icons.restart_alt),
            label: const Text('New game')),
          const SizedBox(height: 12),
          const Text('Tap a piece, then a highlighted square, or drag a piece '
            'directly to a legal destination. Captures are mandatory; '
            'multiple jumps must be completed. Kings move both ways.',
            textAlign: TextAlign.center),
        ]),
      ))),
    );
  }
}
