import 'package:flutter/material.dart';

import '../common/campaign_level_bar.dart';
import '../common/game_kit.dart';
import 'code_breaker_engine.dart';

const _pegColors = [
  Color(0xFFE53935),
  Color(0xFF1E88E5),
  Color(0xFF43A047),
  Color(0xFFFDD835),
  Color(0xFF8E24AA),
  Color(0xFFFB8C00),
  Color(0xFF00ACC1),
  Color(0xFF6D4C41),
];

class CodeBreakerScreen extends StatefulWidget {
  const CodeBreakerScreen({super.key});
  @override
  State<CodeBreakerScreen> createState() => _CodeBreakerScreenState();
}

class _CodeBreakerScreenState extends State<CodeBreakerScreen> {
  int level = CampaignLevelBar.initialLevel('code_breaker');
  CodeBreakerMode get mode => CodeBreakerMode.levels[level - 1];
  late CodeBreakerGame game;
  late List<int?> current;
  int cursor = 0;
  String? message;

  @override
  void initState() {
    super.initState();
    _newGame();
  }

  void _newGame() {
    game = CodeBreakerGame(mode);
    current = List.filled(mode.length, null);
    cursor = 0;
    message = null;
  }

  void _pick(int symbol) {
    if (game.over) return;
    setState(() {
      current[cursor] = symbol;
      final next = current.indexWhere((c) => c == null);
      cursor = next == -1 ? cursor : next;
      message = null;
    });
  }

  void _submit() {
    if (current.contains(null)) return;
    final guess = current.cast<int>();
    if (!game.isValid(guess)) {
      setState(() => message = 'Each colour may be used only once on this level.');
      return;
    }
    setState(() {
      game.submit(guess);
      current = List.filled(mode.length, null);
      cursor = 0;
    });
  }

  void _hint() {
    final h = game.hint();
    if (h == null) return;
    setState(() {
      current = List<int?>.from(h);
      message = 'This code fits every clue so far.';
    });
  }

  Widget _peg(int? s, {double size = 30, bool selected = false, VoidCallback? onTap}) {
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: s == null ? colors.surfaceContainerHighest : _pegColors[s],
          border: Border.all(
              color: selected ? colors.primary : colors.outlineVariant,
              width: selected ? 3 : 1),
        ),
        child: s == null
            ? null
            : Center(
                child: Text('${s + 1}',
                    style: TextStyle(
                        fontSize: size * .4,
                        color: Colors.white,
                        fontWeight: FontWeight.bold))),
      ),
    );
  }

  Widget _clues((int, int) f) {
    return SizedBox(
      width: 64,
      child: Wrap(spacing: 3, runSpacing: 3, children: [
        for (var i = 0; i < f.$1; i++)
          const Icon(Icons.circle, size: 12, color: Colors.black87),
        for (var i = 0; i < f.$2; i++)
          const Icon(Icons.circle_outlined, size: 12),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = game.won
        ? 'Cracked in ${game.guesses.length} guess${game.guesses.length == 1 ? '' : 'es'}!'
        : game.lost
            ? 'Out of guesses — the code is shown below'
            : 'Guess ${game.guesses.length + 1} of ${mode.maxGuesses}';
    return GameScaffold(
      gameId: 'code_breaker',
      completed: game.won,
      title: 'Code Breaker',
      onNewGame: () => setState(_newGame),
      rules: 'Deduce the hidden code of coloured pegs. After each guess you '
          'get clues: ● a peg of the right colour in the right place, ○ a '
          'right colour in the wrong place.\n\nThere are 20 levels, from 3 pegs '
          'and 4 colours to 5 pegs and 8 colours with repeats allowed and '
          'fewer guesses. Crack the code to complete a level; New game draws '
          'a fresh code for the same level. The hint fills in a code that '
          'is consistent with all clues so far.\n\nBased on Hit & Blow from '
          'z7workbench/minigames (MIT).',
      children: [
        CampaignLevelBar(
          gameId: 'code_breaker',
          level: level,
          solved: game.won,
          onLevel: (value) => setState(() {
            level = value;
            _newGame();
          }),
          describe: (l) {
            final m = CodeBreakerMode.levels[l - 1];
            return '${m.length} pegs, ${m.symbols} colours'
                '${m.duplicates ? ', repeats' : ''}, ${m.maxGuesses} tries';
          },
        ),
        StatusBanner(status, highlight: game.over),
        for (var g = 0; g < game.guesses.length; g++)
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            SizedBox(width: 28, child: Text('${g + 1}.')),
            for (final s in game.guesses[g]) _peg(s, size: 26),
            const SizedBox(width: 10),
            _clues(game.feedback[g]),
          ]),
        if (game.over)
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('Code: '),
            for (final s in game.secret) _peg(s),
          ])
        else ...[
          const Divider(),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var i = 0; i < mode.length; i++)
              _peg(current[i],
                  size: 40,
                  selected: i == cursor,
                  onTap: () => setState(() => cursor = i)),
          ]),
          const SizedBox(height: 8),
          Wrap(alignment: WrapAlignment.center, children: [
            for (var s = 0; s < mode.symbols; s++) _peg(s, size: 40, onTap: () => _pick(s)),
          ]),
          if (message != null) Text(message!, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Wrap(alignment: WrapAlignment.center, spacing: 8, children: [
            FilledButton(
                onPressed: current.contains(null) ? null : _submit,
                child: const Text('Check')),
            OutlinedButton.icon(
                onPressed: _hint,
                icon: const Icon(Icons.lightbulb_outline),
                label: const Text('Hint')),
            TextButton(
                onPressed: () => setState(() {
                      current = List.filled(mode.length, null);
                      cursor = 0;
                    }),
                child: const Text('Clear')),
          ]),
        ],
      ],
    );
  }
}
