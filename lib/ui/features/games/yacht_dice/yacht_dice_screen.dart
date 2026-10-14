import 'package:flutter/material.dart';

import '../common/game_kit.dart';
import 'engine/scoring.dart';
import 'engine/scoring_category.dart';
import 'engine/yacht_dice_state.dart';
import 'engine/yacht_game.dart';

String categoryLabel(ScoringCategory c) =>
    c == ScoringCategory.allSelect ? 'Chance' : c.displayName;

/// Yacht dice (a Yahtzee-style game) using the MIT-licensed scoring and AI
/// from z7workbench/minigames.
class YachtDiceScreen extends StatefulWidget {
  const YachtDiceScreen({super.key});
  @override
  State<YachtDiceScreen> createState() => _YachtDiceScreenState();
}

class _YachtDiceScreenState extends State<YachtDiceScreen> {
  bool vsComputer = true;
  AiLevel level = AiLevel.medium;
  int humans = 1;
  late YachtGame game;
  bool aiRunning = false;
  int generation = 0;

  @override
  void initState() {
    super.initState();
    _newGame();
  }

  void _newGame() {
    generation++;
    aiRunning = false;
    game = YachtGame(
      humans: vsComputer ? 1 : humans,
      ai: vsComputer ? AiDifficulty.values[level.index] : null,
    );
  }

  Future<void> _runAi() async {
    if (aiRunning) return;
    final token = generation;
    setState(() => aiRunning = true);
    while (mounted && token == generation) {
      await Future<void>.delayed(const Duration(milliseconds: 550));
      if (!mounted || token != generation) return;
      final more = await game.aiStep();
      if (!mounted || token != generation) return;
      setState(() {});
      if (!more) break;
    }
    if (mounted && token == generation) setState(() => aiRunning = false);
  }

  void _score(ScoringCategory c) {
    if (aiRunning || game.current.type == PlayerType.ai) return;
    setState(() => game.select(c));
    if (!game.isOver && game.current.type == PlayerType.ai) _runAi();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = game.current;
    final humanTurn = p.type == PlayerType.human && !aiRunning && !game.isOver;
    String status;
    if (game.isOver) {
      final w = game.winners;
      status = w.length > 1
          ? 'Tie game at ${w.first.totalScore}!'
          : '${w.first.name} ${w.first.name == 'You' ? 'win' : 'wins'} with ${w.first.totalScore}!';
    } else if (!humanTurn) {
      status = 'Computer is rolling…';
    } else if (!game.hasRolled) {
      status = '${p.name}${p.name == 'You' ? '' : ':'} roll the dice';
    } else {
      status = '${p.name}: tap dice to hold · ${p.rollsRemaining} roll'
          '${p.rollsRemaining == 1 ? '' : 's'} left · or pick a score';
    }
    return GameScaffold(
      title: 'Yacht Dice',
      onNewGame: () => setState(_newGame),
      rules: 'Roll five dice up to three times per turn, holding any dice '
          'between rolls. Then score the dice in one empty category. Each '
          'category is used once; after 12 turns the highest total wins.\n\n'
          'Ones–Sixes: sum of that number (35 bonus if they total 63+). '
          'Chance: sum of all dice. Full House: 25. Four of a Kind: sum of '
          'all dice. Small Straight (4 in a row): 15. Large Straight (5 in a '
          'row): 30. Yacht (5 of a kind): 50.',
      children: [
        OpponentPicker(
          vsComputer: vsComputer,
          level: level,
          onChanged: (v, l) => setState(() {
            vsComputer = v;
            level = l;
            _newGame();
          }),
        ),
        if (!vsComputer)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: SegmentedButton<int>(
              segments: [
                for (var n = 2; n <= 4; n++)
                  ButtonSegment(value: n, label: Text('$n players')),
              ],
              selected: {humans},
              onSelectionChanged: (s) => setState(() {
                humans = s.first;
                _newGame();
              }),
            ),
          ),
        StatusBanner(status, highlight: game.isOver),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var i = 0; i < 5; i++)
            p.dice[i] == 0
                ? Container(
                    width: 52,
                    height: 52,
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: theme.colorScheme.outlineVariant),
                    ),
                    child: const Center(child: Text('?')),
                  )
                : DieFace(p.dice[i],
                    held: p.kept[i] && p.rollsRemaining > 0,
                    onTap: humanTurn ? () => setState(() => game.toggleKeep(i)) : null),
        ]),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: humanTurn && game.canRoll ? () => setState(game.roll) : null,
          icon: const Icon(Icons.casino_outlined),
          label: Text(game.hasRolled ? 'Roll again (${p.rollsRemaining})' : 'Roll'),
        ),
        const SizedBox(height: 12),
        _scoreTable(theme, humanTurn),
      ],
    );
  }

  Widget _scoreTable(ThemeData theme, bool humanTurn) {
    final players = game.state.players;
    final cur = game.current;
    int upper(PlayerState p) =>
        upperCategories.map((c) => p.scores[c] ?? 0).reduce((a, b) => a + b);
    TableRow row(String label, List<Widget> cells, {bool bold = false}) => TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Text(label,
                  style: bold ? const TextStyle(fontWeight: FontWeight.bold) : null),
            ),
            ...cells,
          ],
        );
    Widget cell(PlayerState p, ScoringCategory c) {
      final v = p.scores[c];
      final isCur = identical(p, cur) || p.name == cur.name;
      if (v != null) return Center(child: Text('$v'));
      if (isCur && humanTurn && game.hasRolled) {
        final preview = calculateScore(cur.dice, c);
        return Padding(
          padding: const EdgeInsets.all(2),
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero, minimumSize: const Size(40, 34)),
            onPressed: () => _score(c),
            child: Text('$preview'),
          ),
        );
      }
      return const Center(child: Text('–'));
    }

    return Table(
      border: TableBorder.symmetric(
          inside: BorderSide(color: theme.colorScheme.outlineVariant, width: .5)),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      columnWidths: const {0: FlexColumnWidth(1.6)},
      children: [
        row('', [
          for (final p in players)
            Center(
              child: Text(p.name,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: p.name == cur.name && !game.isOver
                          ? theme.colorScheme.primary
                          : null)),
            ),
        ]),
        for (final c in upperCategories)
          row(categoryLabel(c), [for (final p in players) cell(p, c)]),
        row('Bonus (63+)', [
          for (final p in players)
            Center(child: Text(p.bonusEarned > 0 ? '35' : '${upper(p)}/63')),
        ]),
        for (final c in ScoringCategory.values.where((c) => !upperCategories.contains(c)))
          row(categoryLabel(c), [for (final p in players) cell(p, c)]),
        row('Total', [for (final p in players) Center(child: Text('${p.totalScore}'))],
            bold: true),
      ],
    );
  }
}
