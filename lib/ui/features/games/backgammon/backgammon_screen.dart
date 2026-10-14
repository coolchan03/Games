import 'package:flutter/material.dart';

import '../common/game_kit.dart';
import 'engine/backgammon_match.dart';
import 'engine/constants.dart';
import 'engine/game_entities.dart';

/// Backgammon on the GPL-3.0 bbackgammon rules engine. You play White
/// (moving from point 24 down to 1); the computer or a friend plays Black.
class BackgammonScreen extends StatefulWidget {
  const BackgammonScreen({super.key});
  @override
  State<BackgammonScreen> createState() => _BackgammonScreenState();
}

class _BackgammonScreenState extends State<BackgammonScreen> {
  bool vsComputer = true;
  AiLevel level = AiLevel.medium;
  late BackgammonMatch match;
  int? selected;
  bool busy = false;
  int generation = 0;

  static const _white = Color(0xFFF5F0E6), _black = Color(0xFF2B2B2B);

  @override
  void initState() {
    super.initState();
    _newGame();
  }

  void _newGame() {
    generation++;
    busy = false;
    selected = null;
    match = BackgammonMatch();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runComputer());
  }

  bool get _computerToMove =>
      vsComputer && match.winner == null && match.state.currentPlayer == Player.black;

  Future<void> _runComputer() async {
    if (busy || !_computerToMove) return;
    final token = generation;
    busy = true;
    while (mounted && token == generation && _computerToMove) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!mounted || token != generation) return;
      if (match.needsRoll) {
        setState(match.roll);
        continue;
      }
      final turn = match.computerTurn(level.index);
      for (final m in turn) {
        await Future<void>.delayed(const Duration(milliseconds: 450));
        if (!mounted || token != generation) return;
        setState(() => match.play(m));
      }
      if (turn.isEmpty) break;
    }
    if (mounted && token == generation) setState(() => busy = false);
  }

  Set<int> get _targets {
    if (selected == null) return {};
    return {for (final m in match.legalMoves()) if (m.from == selected) m.to};
  }

  Set<int> get _sources => {for (final m in match.legalMoves()) m.from};

  void _tapPoint(int index) {
    if (busy || _computerToMove || match.winner != null || match.needsRoll) return;
    setState(() {
      if (selected != null && _targets.contains(index)) {
        match.play(Move(from: selected!, to: index, die: 0));
        selected = null;
        if (match.state.dice.isNotEmpty && _sources.length == 1 && _sources.first == whiteBarIndex) {
          selected = whiteBarIndex;
        }
      } else if (_sources.contains(index)) {
        selected = selected == index ? null : index;
      } else {
        selected = null;
      }
    });
    _runComputer();
  }

  void _roll() {
    setState(() {
      match.roll();
      selected = null;
    });
    _runComputer();
  }

  Widget _checkers(int count, Color color, {bool top = true, double size = 22}) {
    final shown = count > 5 ? 5 : count;
    final children = [
      for (var i = 0; i < shown; i++)
        Container(
          width: size,
          height: size,
          margin: const EdgeInsets.symmetric(vertical: .5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(color: Colors.black45),
          ),
          alignment: Alignment.center,
          child: i == shown - 1 && count > 5
              ? Text('$count',
                  style: TextStyle(
                      fontSize: size * .5,
                      fontWeight: FontWeight.bold,
                      color: color == _white ? Colors.black : Colors.white))
              : null,
        ),
    ];
    return Column(
      mainAxisAlignment: top ? MainAxisAlignment.start : MainAxisAlignment.end,
      children: top ? children : children.reversed.toList(),
    );
  }

  Widget _point(int index, bool top, double w, double h) {
    final p = match.state.points[index];
    final isTarget = _targets.contains(index);
    final isSource = _sources.contains(index) && !_computerToMove && !busy;
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => _tapPoint(index),
      child: SizedBox(
        width: w,
        height: h,
        child: CustomPaint(
          painter: _Triangle(
            color: index.isEven ? const Color(0xFFB5523B) : const Color(0xFFE8C07D),
            top: top,
            highlight: isTarget ? colors.primary : selected == index ? colors.tertiary : null,
          ),
          child: Column(
            mainAxisAlignment: top ? MainAxisAlignment.start : MainAxisAlignment.end,
            children: [
              if (!top) Text('${index + 1}', style: const TextStyle(fontSize: 9, color: Colors.white70)),
              Expanded(
                child: Container(
                  decoration: isSource && selected == null
                      ? BoxDecoration(border: Border.all(color: Colors.white38))
                      : null,
                  child: p.pieceCount == 0
                      ? null
                      : _checkers(p.pieceCount, p.player == Player.white ? _white : _black,
                          top: top, size: w * .9),
                ),
              ),
              if (top) Text('${index + 1}', style: const TextStyle(fontSize: 9, color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = match.state;
    final colors = Theme.of(context).colorScheme;
    final w = match.winner;
    String status;
    if (w != null) {
      final pts = match.resultPoints;
      final kind = pts == 3 ? 'backgammon' : pts == 2 ? 'gammon' : 'game';
      status = vsComputer
          ? (w == Player.white ? 'You win a $kind!' : 'Computer wins a $kind')
          : '${w.displayName} wins a $kind!';
    } else if (_computerToMove || busy) {
      status = 'Computer is playing…';
    } else if (match.needsRoll) {
      status = '${vsComputer ? 'Your' : '${s.currentPlayer.displayName}\'s'} turn — roll the dice';
    } else {
      status = '${s.currentPlayer.displayName} to move · dice ${s.dice.join(' ')}';
    }
    if (match.message != null && w == null) status = '${match.message}\n$status';
    final whiteOffTarget = _targets.contains(whiteHomeIndex);
    final blackOffTarget = _targets.contains(blackHomeIndex);
    return GameScaffold(
      gameId: 'backgammon',
      completed: match.winner != null && (!vsComputer || match.winner == Player.white),
      title: 'Backgammon',
      maxWidth: 760,
      onNewGame: () => setState(_newGame),
      rules: 'Move all 15 of your checkers around the board into your home '
          'board and then bear them off. White moves from point 24 toward 1 '
          '(home is 1–6); Black moves the other way. Each die is a separate '
          'move; doubles are played four times. You may land on any point '
          'not held by two or more enemy checkers. Landing on a single enemy '
          'checker ("blot") sends it to the bar; it must re-enter before its '
          'owner can move anything else. You must use as many dice as '
          'possible. Win a gammon (2) if the loser has borne off nothing, a '
          'backgammon (3) if they still have a checker on the bar or in your '
          'home board.\n\nTap a highlighted checker, then a highlighted '
          'point. Tap the tray on the right to bear off.',
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
        StatusBanner(status, highlight: w != null),
        LayoutBuilder(builder: (context, box) {
          final pw = (box.maxWidth - 16 - 30 - 34) / 12;
          final ph = pw * 5.6;
          Widget half(List<int> idx, bool top) => Row(children: [
                for (final i in idx.take(6)) _point(i, top, pw, ph),
                GestureDetector(
                  onTap: () => _tapPoint(top ? blackBarIndex : whiteBarIndex),
                  child: Container(
                    width: 30,
                    height: ph,
                    color: const Color(0xFF4E342E),
                    child: top
                        ? _checkers(s.blackBar.length, _black, size: 24)
                        : Container(
                            decoration: selected == whiteBarIndex
                                ? BoxDecoration(border: Border.all(color: colors.tertiary, width: 2))
                                : null,
                            child: _checkers(s.whiteBar.length, _white, top: false, size: 24)),
                  ),
                ),
                for (final i in idx.skip(6)) _point(i, top, pw, ph),
              ]);
          return Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: const Color(0xFF6D4C41), borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Column(children: [
                half([for (var i = 12; i < 24; i++) i], true),
                SizedBox(
                  height: 34,
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    for (final d in match.rolled)
                      Opacity(
                        opacity: s.dice.isEmpty ? .4 : 1,
                        child: DieFace(d, size: 28),
                      ),
                  ]),
                ),
                half([for (var i = 11; i >= 0; i--) i], false),
              ]),
              const SizedBox(width: 4),
              Column(children: [
                GestureDetector(
                  onTap: () => _tapPoint(blackHomeIndex),
                  child: _tray(s.blackHome.length, _black, ph, blackOffTarget),
                ),
                const SizedBox(height: 34),
                GestureDetector(
                  onTap: () => _tapPoint(whiteHomeIndex),
                  child: _tray(s.whiteHome.length, _white, ph, whiteOffTarget),
                ),
              ]),
            ]),
          );
        }),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: match.needsRoll && !_computerToMove && !busy ? _roll : null,
              icon: const Icon(Icons.casino_outlined),
              label: const Text('Roll'),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: match.canUndo && !_computerToMove && !busy
                ? () => setState(() {
                      match.undo();
                      selected = null;
                    })
                : null,
            icon: const Icon(Icons.undo),
            label: const Text('Undo'),
          ),
        ]),
        const SizedBox(height: 6),
        Text('Pips — White ${s.pipCount(Player.white)} · Black ${s.pipCount(Player.black)}',
            textAlign: TextAlign.center),
      ],
    );
  }

  Widget _tray(int count, Color color, double h, bool target) => Container(
        width: 30,
        height: h,
        decoration: BoxDecoration(
          color: const Color(0xFF4E342E),
          border: Border.all(
              color: target ? Theme.of(context).colorScheme.primary : Colors.black26,
              width: target ? 3 : 1),
        ),
        alignment: Alignment.center,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
              width: 22, height: 8, color: color, margin: const EdgeInsets.only(bottom: 4)),
          Text('$count', style: const TextStyle(color: Colors.white, fontSize: 12)),
        ]),
      );
}

class _Triangle extends CustomPainter {
  _Triangle({required this.color, required this.top, this.highlight});
  final Color color;
  final bool top;
  final Color? highlight;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    if (top) {
      path
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width / 2, size.height * .85);
    } else {
      path
        ..moveTo(0, size.height)
        ..lineTo(size.width, size.height)
        ..lineTo(size.width / 2, size.height * .15);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
    if (highlight != null) {
      canvas.drawPath(
          path,
          Paint()
            ..color = highlight!
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3);
    }
  }

  @override
  bool shouldRepaint(_Triangle old) =>
      old.color != color || old.top != top || old.highlight != highlight;
}
