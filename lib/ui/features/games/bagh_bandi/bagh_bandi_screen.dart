import 'dart:math';

import 'package:flutter/material.dart';

import '../common/alquerque_board.dart';
import '../common/game_kit.dart';
import '../common/grid_board_touch_area.dart';
import '../shared/game_storage.dart';
import 'bagh_bandi_engine.dart';

class BaghBandiScreen extends StatefulWidget {
  const BaghBandiScreen({super.key});

  @override
  State<BaghBandiScreen> createState() => _BaghBandiScreenState();
}

class _BaghBandiScreenState extends State<BaghBandiScreen> {
  static const _saveKey = 'bagh_bandi_v1';
  static const _instructions =
      'GOAL: Two Bengal tigers try to capture every goat. '
      'The goats win by trapping both tigers so neither can move or jump. '
      'START: Tigers occupy the middle column at rows two and four. '
      'Four stacks of five goats start at the outer columns. '
      'The goats move first. '
      'RULES: Tap a stack or a single goat, then an empty adjacent point '
      'connected by a marked line. Only one goat leaves a stack per turn. '
      'Once moved, goats cannot pile back onto another goat. '
      'Tigers move one step along a line or jump over a goat to an empty '
      'point immediately beyond it. Jumping removes only the top goat from '
      'a stack. This variant permits one optional capture per tiger turn. '
      'Goats cannot jump. If goats have no legal move, tigers win. '
      'A game with 100 consecutive non-capturing moves is a draw. '
      'CONTROLS: Tap source then destination; or drag a piece to its '
      'highlighted destination. Use the Rules button for a refresher. '
      'No internet connection or second device is required.';

  final rng = Random();
  BaghBandiGame game = BaghBandiGame();
  BandiSide humanSide = BandiSide.goats;
  AiLevel difficulty = AiLevel.medium;
  bool vsComputer = true, ready = false, thinking = false;
  int generation = 0;
  int? selected;
  String saveStatus = 'Loading the saved board…';

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    try {
      final data = await GameStorage.load(_saveKey);
      if (!mounted) return;
      if (data != null) {
        game = BaghBandiGame.fromJson(
            Map<String, dynamic>.from(data['game'] as Map));
        vsComputer = data['computer'] == true;
        humanSide = BandiSide.values.byName(
            (data['humanSide'] as String?) ?? BandiSide.goats.name);
        difficulty = AiLevel.values.byName(
            (data['level'] as String?) ?? AiLevel.medium.name);
      }
      saveStatus = data == null ? 'Progress saved locally'
          : 'Previous game restored on this device';
    } catch (_) {
      game = BaghBandiGame();
      saveStatus = 'Saved game invalid; fresh board started';
    }
    if (!mounted) return;
    setState(() => ready = true);
    _runBot();
  }

  Future<void> _save() async {
    if (!ready) return;
    try {
      await GameStorage.save(_saveKey, {
        'game': game.toJson(),
        'computer': vsComputer,
        'humanSide': humanSide.name,
        'level': difficulty.name,
      });
      if (mounted) setState(() => saveStatus = 'Saved on this device');
    } catch (_) {
      if (mounted) setState(() => saveStatus = 'Save unavailable');
    }
  }

  bool get canAct => ready && !thinking &&
      game.outcome == BandiOutcome.ongoing &&
      (!vsComputer || humanSide == game.turn);

  void _newGame() {
    generation++;
    setState(() {
      game = BaghBandiGame();
      thinking = false;
      selected = null;
    });
    _save();
    _runBot();
  }

  bool _play(int source, int dest) {
    if (!canAct) return false;
    final matches = game.legalMoves.where(
        (m) => m.from == source && m.to == dest).toList();
    if (matches.isEmpty) return false;
    setState(() {
      game.move(matches.first);
      selected = null;
    });
    _save();
    _runBot();
    return true;
  }

  void _tap(int i) {
    if (!canAct) return;
    if (selected != null && _play(selected!, i)) return;
    setState(() {
      selected = game.legalMoves.any((m) => m.from == i) ? i : null;
    });
  }

  Future<void> _runBot() async {
    if (!mounted || !ready || thinking || !vsComputer ||
        game.turn == humanSide || game.outcome != BandiOutcome.ongoing) return;
    final token = ++generation;
    setState(() => thinking = true);
    await Future<void>.delayed(const Duration(milliseconds: 280));
    if (!mounted || token != generation) return;
    setState(() {
      game.move(game.chooseMove(rng, level: difficulty.index));
      thinking = false;
    });
    await _save();
  }

  @override
  void dispose() {
    generation++;
    super.dispose();
  }

  static String _side(BandiSide side) =>
      side == BandiSide.goats ? 'Goats' : 'Tigers';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final outcome = game.outcome;
    final status = switch (outcome) {
      BandiOutcome.goats => 'Goats have trapped both tigers — goats win!',
      BandiOutcome.tigers => 'Tigers win!',
      BandiOutcome.draw => 'Draw after 100 moves without a capture',
      BandiOutcome.ongoing => thinking
          ? 'Computer is moving…'
          : '${_side(game.turn)} to move — select a piece',
    };
    final possible = <int>{
      if (selected != null)
        for (final m in game.legalMoves)
          if (m.from == selected) m.to,
    };

    Widget boardCell(int i, double side) {
      final tiger = game.tigers.contains(i);
      final goats = game.goats[i];
      final owned = game.turn == BandiSide.tigers ? tiger : goats > 0;
      final legalOrigin = canAct && owned &&
          game.legalMoves.any((m) => m.from == i);
      final source = selected == i;
      final target = possible.contains(i);
      final symbol = tiger ? Icons.pets_rounded :
          goats > 0 ? Icons.cruelty_free_rounded : null;
      final label = 'Row ${i ~/ 5 + 1} column ${i % 5 + 1}: '
          '${tiger ? 'tiger' : goats > 0 ? '$goats goat${goats == 1 ? '' : 's'}' : 'empty'}'
          '${legalOrigin ? ', selectable' : ''}'
          '${target ? ', destination' : ''}';
      return Positioned(
        left: (i % 5) * side,
        top: (i ~/ 5) * side,
        width: side,
        height: side,
        child: Semantics(
          label: label,
          button: canAct && (legalOrigin || target),
          onTap: canAct ? () => _tap(i) : null,
          child: IgnorePointer(child: Center(child: Container(
            width: side * (tiger || goats > 0 ? .75 : target ? .37 : .19),
            height: side * (tiger || goats > 0 ? .75 : target ? .37 : .19),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tiger ? const Color(0xFFFFAA39) :
                  goats > 0 ? const Color(0xFFF5F5E8) :
                  target ? colors.primary : colors.onSurface.withValues(alpha: .35),
              border: Border.all(
                color: source ? colors.primary :
                    target ? colors.secondary : Colors.black38,
                width: source || target ? 3 : 1.5,
              ),
            ),
            child: symbol == null ? null : Stack(
              clipBehavior: Clip.none,
              children: [
                Center(child: Icon(symbol, color: Colors.black87,
                    size: side * .38)),
                if (goats > 1) Positioned(
                  right: -5, bottom: -5,
                  child: CircleAvatar(radius: side * .145,
                    backgroundColor: colors.tertiaryContainer,
                    child: Text('$goats', style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: side * .21, color: colors.onTertiaryContainer,
                    ))),
                ),
              ],
            ),
          ))),
        ),
      );
    }

    return GameScaffold(
      gameId: 'bagh_bandi',
      completed: outcome != BandiOutcome.ongoing &&
          outcome != BandiOutcome.draw &&
          (!vsComputer || (humanSide == BandiSide.goats
              ? outcome == BandiOutcome.goats
              : outcome == BandiOutcome.tigers)),
      title: 'Bagh Bandi',
      rules: _instructions,
      onNewGame: _newGame,
      children: [
        OpponentPicker(
          vsComputer: vsComputer, level: difficulty,
          onChanged: (bot, level) {
            vsComputer = bot;
            difficulty = level;
            _newGame();
          },
        ),
        if (vsComputer) ...[
          const SizedBox(height: 8),
          Text(
            switch (difficulty) {
              AiLevel.easy => 'Easy: random legal moves',
              AiLevel.medium => 'Medium: tactical positioning',
              AiLevel.hard => 'Hard: anticipates the next opponent move',
            },
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          SegmentedButton<BandiSide>(
            segments: const [
              ButtonSegment(value: BandiSide.goats, label: Text('Play goats')),
              ButtonSegment(value: BandiSide.tigers, label: Text('Play tigers')),
            ],
            selected: {humanSide},
            onSelectionChanged: (s) {
              humanSide = s.first;
              _newGame();
            },
          ),
        ],
        StatusBanner(status, highlight: outcome != BandiOutcome.ongoing),
        Text('Goats remaining: ${game.goatsLeft}/20 · '
            'Tigers: 2 · Captured: ${game.captured}',
            textAlign: TextAlign.center),
        Text(saveStatus, textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => showRules(context, 'Bagh Bandi', _instructions),
          icon: const Icon(Icons.menu_book_outlined),
          label: const Text('How to play & controls'),
        ),
        Text('Tap a piece and then a highlighted point, or drag it there.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        AspectRatio(
          aspectRatio: 1,
          child: LayoutBuilder(builder: (context, box) {
            final size = box.maxWidth;
            final side = size / 5;
            return GridBoardTouchArea(
              columns: 5,
              onTapCell: _tap,
              onDragCell: (from, to) { _play(from, to); },
              onDragStartCell: (origin) {
                if (canAct &&
                    game.legalMoves.any((move) => move.from == origin)) {
                  setState(() => selected = origin);
                }
              },
              child: Stack(children: [
                Positioned.fill(child: CustomPaint(
                  painter: AlquerqueBoardPainter(
                      colors.onSurface.withValues(alpha: .56)),
                )),
                for (var i = 0; i < 25; i++) boardCell(i, side),
              ]),
            );
          }),
        ),
        if (outcome != BandiOutcome.ongoing)
          FilledButton(onPressed: _newGame, child: const Text('Play again')),
      ],
    );
  }
}
