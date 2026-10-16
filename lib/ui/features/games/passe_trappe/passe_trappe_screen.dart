import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../common/game_kit.dart';
import '../shared/game_storage.dart';
import 'passe_trappe_engine.dart';

class PasseTrappeScreen extends StatefulWidget {
  const PasseTrappeScreen({super.key});

  @override
  State<PasseTrappeScreen> createState() => _PasseTrappeScreenState();
}

class _PasseTrappeScreenState extends State<PasseTrappeScreen>
    with SingleTickerProviderStateMixin {
  static const saveKey = 'passe_trappe_v1';
  static const instructions =
      'GOAL: Clear all five pucks from your half of the table first. '
      'Players shoot simultaneously through the single center gate '
      'using elastic bands in the traditional wooden game. '
      'CONTROL: Touch a puck on your half, pull it BACK toward your '
      'elastic, then release it to shoot toward the opponent. '
      'Only pucks passing through the center gate count. '
      'Pucks bounce off walls and one another, and may come back '
      'through the opening. '
      'EASIER PHONE CONTROL: Tap a puck, then use the large '
      '"Shoot selected puck" button to aim automatically at the opening. '
      'Play against a casual computer, or use both ends simultaneously '
      'with a friend on the same touchscreen. '
      'Use Pause to stop play and save your position; no account '
      'or internet connection is required.';

  final rng = Random();
  PasseTrappeGame table = PasseTrappeGame();
  late final Ticker ticker;
  Duration? lastTick;
  bool computer = true, paused = false, ready = false;
  AiLevel difficulty = AiLevel.medium;
  int? selectedPuck;
  double botTime = 0, saveTime = 0;
  Size boardSize = Size.zero;
  final Map<int, Offset> pointerStart = {};
  final Map<int, int> pointerPuck = {};
  String saveStatus = 'Loading game…';

  @override
  void initState() {
    super.initState();
    ticker = createTicker(_tick)..start();
    _restore();
  }

  Future<void> _restore() async {
    try {
      final data = await GameStorage.load(saveKey);
      if (!mounted) return;
      if (data != null) {
        table = PasseTrappeGame.fromJson(
            Map<String, dynamic>.from(data['game'] as Map));
        computer = data['computer'] == true;
        paused = data['paused'] == true;
        difficulty = AiLevel.values.byName(
            (data['level'] as String?) ?? AiLevel.medium.name);
      }
      saveStatus = data == null ? 'Offline local match' :
          'Previous match restored on this device';
    } catch (_) {
      table = PasseTrappeGame();
      saveStatus = 'Save invalid; a new match is ready';
    }
    if (mounted) setState(() => ready = true);
  }

  Future<void> _save() async {
    if (!ready) return;
    try {
      await GameStorage.save(saveKey, {
        'game': table.toJson(), 'computer': computer,
        'paused': paused, 'level': difficulty.name,
      });
      if (mounted) setState(() => saveStatus = 'Saved on this device');
    } catch (_) {
      if (mounted) setState(() => saveStatus = 'Save unavailable');
    }
  }

  void _reset() {
    setState(() {
      table = PasseTrappeGame();
      paused = false;
      selectedPuck = null;
      botTime = saveTime = 0;
      pointerPuck.clear();
      pointerStart.clear();
    });
    _save();
  }

  void _tick(Duration now) {
    final dt = lastTick == null ? 0.0
        : ((now - lastTick!).inMicroseconds / 1e6).clamp(0.0, .06);
    lastTick = now;
    if (!ready || paused || table.winner != null || dt <= 0) return;
    setState(() {
      table.step(dt);
      botTime += dt;
      saveTime += dt;
      if (computer && botTime >= [.9, .65, .4][difficulty.index]) {
        botTime = 0;
        table.autoLaunch(rng, side: 1, level: difficulty.index);
      }
    });
    if (saveTime > 3) {
      saveTime = 0;
      _save();
    }
  }

  Offset _boardPoint(Offset local) {
    if (boardSize.width == 0 || boardSize.height == 0) return Offset.zero;
    return Offset((local.dx / boardSize.width).clamp(0.0, 1.0),
        (local.dy / boardSize.height).clamp(0.0, 1.0));
  }

  void _pointerDown(PointerDownEvent event) {
    if (paused || !ready || table.winner != null) return;
    final point = _boardPoint(event.localPosition);
    final puck = table.puckAt(point, side: computer ? 0 : null);
    if (puck == null) return;
    pointerStart[event.pointer] = point;
    pointerPuck[event.pointer] = puck.id;
    setState(() => selectedPuck = puck.id);
  }

  void _pointerUp(PointerUpEvent event) {
    final start = pointerStart.remove(event.pointer);
    final id = pointerPuck.remove(event.pointer);
    if (start == null || id == null || paused || !ready) return;
    final pull = _boardPoint(event.localPosition) - start;
    if (pull.distance > .045 && table.launch(id, pull)) {
      setState(() => selectedPuck = null);
      _save();
    }
  }

  void _pointerCancel(PointerCancelEvent event) {
    pointerStart.remove(event.pointer);
    pointerPuck.remove(event.pointer);
  }

  void _shootSelected() {
    if (!ready || paused || selectedPuck == null) return;
    if (table.aimShoot(selectedPuck!)) {
      setState(() => selectedPuck = null);
      _save();
    }
  }

  @override
  void dispose() {
    ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final win = table.winner;
    final bottom = table.countOnSide(0);
    final top = table.countOnSide(1);
    final status = win == null
        ? '${computer ? 'You' : 'Bottom'}: $bottom pucks · '
            '${computer ? 'Computer' : 'Top'}: $top pucks'
        : '${win == 0 ? (computer ? 'You win' : 'Bottom wins') : (computer ? 'Computer wins' : 'Top wins')}!';
    return GameScaffold(
      title: 'Passe-Trappe',
      gameId: 'passe_trappe',
      completed: win != null && (!computer || win == 0),
      onNewGame: _reset,
      scrollable: false,
      rules: instructions,
      children: [
        OpponentPicker(
          vsComputer: computer,
          level: difficulty,
          onChanged: (vsBot, newLevel) {
            computer = vsBot;
            difficulty = newLevel;
            _reset();
          },
        ),
        if (computer)
          Text(
            switch (difficulty) {
              AiLevel.easy => 'Easy: relaxed, gentle and less accurate shots',
              AiLevel.medium => 'Medium: steady and reasonably aimed shots',
              AiLevel.hard => 'Hard: quick, strong and accurate shots',
            },
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        StatusBanner(status, highlight: win != null),
        Text('Pull a puck back and release, or tap one and shoot.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall),
        Text(saveStatus, textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall),
        Expanded(child: LayoutBuilder(builder: (context, constraints) {
          const boardRatio = 1.48;
          final width = min(constraints.maxWidth,
              constraints.maxHeight / boardRatio);
          boardSize = Size(width, width * boardRatio);
          return Center(child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: _pointerDown,
            onPointerUp: _pointerUp,
            onPointerCancel: _pointerCancel,
            child: SizedBox(
              width: boardSize.width,
              height: boardSize.height,
              child: Semantics(
                label: 'Sling puck table. Top has $top pucks; '
                    'bottom has $bottom. Drag back to shoot.',
                child: CustomPaint(
                  painter: _PasseBoard(table, selectedPuck),
                ),
              ),
            ),
          ));
        })),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10, runSpacing: 6,
          children: [
            FilledButton.icon(
              onPressed: ready && !paused && win == null &&
                  selectedPuck != null ? _shootSelected : null,
              icon: const Icon(Icons.gps_fixed_rounded),
              label: const Text('Shoot selected puck'),
            ),
            OutlinedButton.icon(
              onPressed: ready && win == null ? () {
                setState(() => paused = !paused);
                _save();
              } : null,
              icon: Icon(paused ? Icons.play_arrow_rounded :
                  Icons.pause_rounded),
              label: Text(paused ? 'Resume' : 'Pause'),
            ),
            TextButton.icon(
              onPressed: () => showRules(context, 'Passe-Trappe', instructions),
              icon: const Icon(Icons.menu_book_outlined),
              label: const Text('How to play'),
            ),
          ],
        ),
        if (win != null)
          FilledButton(onPressed: _reset, child: const Text('Play again')),
      ],
    );
  }
}

class _PasseBoard extends CustomPainter {
  const _PasseBoard(this.game, this.selected);
  final PasseTrappeGame game;
  final int? selected;

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width, y = size.height;
    Offset p(Offset point) => Offset(point.dx * x, point.dy * y);
    final wood = Paint()..color = const Color(0xFFCEB88F);
    final outline = Paint()
      ..color = const Color(0xFF4C382D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    final center = Paint()
      ..color = const Color(0xFF4C382D)
      ..strokeWidth = 6;
    final board = RRect.fromRectAndRadius(Offset.zero & size,
        const Radius.circular(14));
    canvas.drawRRect(board, wood);
    canvas.drawRRect(board, outline);

    // Rubber band rails across the two back ends.
    final bands = Paint()..color = const Color(0xFF604C36)
      ..strokeWidth = 5;
    canvas.drawLine(p(const Offset(.08, .058)),
        p(const Offset(.92, .058)), bands);
    canvas.drawLine(p(const Offset(.08, .942)),
        p(const Offset(.92, .942)), bands);

    // A single real opening in the central divider.
    final leftEdge = .5 - PasseTrappeGame.gateWidth / 2;
    final rightEdge = .5 + PasseTrappeGame.gateWidth / 2;
    canvas.drawLine(p(Offset(0, PasseTrappeGame.mid)),
        p(Offset(leftEdge, PasseTrappeGame.mid)), center);
    canvas.drawLine(p(Offset(rightEdge, PasseTrappeGame.mid)),
        p(const Offset(1, PasseTrappeGame.mid)), center);
    final mouth = Paint()
      ..color = const Color(0xFF90CAF9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRect(Rect.fromLTRB(leftEdge * x,
        y * PasseTrappeGame.mid - 8, rightEdge * x,
        y * PasseTrappeGame.mid + 8), mouth);

    final stroke = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final puck in game.pucks) {
      final pos = p(puck.position);
      final radius = PasseTrappeGame.radius * x;
      canvas.drawCircle(pos, radius,
          Paint()..color = puck.position.dy < .5
              ? const Color(0xFF4576A7) : const Color(0xFFB85C44));
      canvas.drawCircle(pos, radius, stroke);
      if (puck.id == selected) {
        canvas.drawCircle(pos, radius + 5,
            Paint()..color = const Color(0xFFFFD257)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3);
      }
    }
  }

  @override
  bool shouldRepaint(_PasseBoard old) => true;
}
