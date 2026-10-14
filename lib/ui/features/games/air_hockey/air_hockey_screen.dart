import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../common/game_kit.dart';
import 'air_hockey_engine.dart';

class AirHockeyScreen extends StatefulWidget {
  const AirHockeyScreen({super.key});
  @override
  State<AirHockeyScreen> createState() => _AirHockeyScreenState();
}

class _AirHockeyScreenState extends State<AirHockeyScreen> with SingleTickerProviderStateMixin {
  bool vsComputer = true;
  AiLevel level = AiLevel.medium;
  int target = 7;
  AirHockeyPhysics table = AirHockeyPhysics();
  late final Ticker ticker;
  Duration? lastTick;
  final Map<int, Offset> pointers = {};
  Offset? bottomTarget, topTarget;
  Size boardSize = Size.zero;

  bool get over => table.scores.any((s) => s >= target);

  @override
  void initState() {
    super.initState();
    ticker = createTicker(_tick)..start();
  }

  @override
  void dispose() {
    ticker.dispose();
    super.dispose();
  }

  void _tick(Duration now) {
    final dt = lastTick == null ? 0.0 : ((now - lastTick!).inMicroseconds / 1e6).clamp(0.0, 1 / 20);
    lastTick = now;
    if (over || dt == 0) return;
    setState(() {
      if (bottomTarget != null) table.setBottom(bottomTarget!, dt);
      if (vsComputer) {
        table.aiStep(dt, level.index);
      } else if (topTarget != null) {
        table.setTop(topTarget!, dt);
      }
      table.step(dt);
    });
  }

  Offset _toTable(Offset local) => Offset(
        local.dx / boardSize.width * AirHockeyPhysics.width,
        local.dy / boardSize.height * AirHockeyPhysics.height,
      );

  void _pointer(PointerEvent e) {
    final p = _toTable(e.localPosition);
    pointers[e.pointer] = p;
    if (p.dy > AirHockeyPhysics.height / 2 || vsComputer) {
      bottomTarget = Offset(p.dx, p.dy.clamp(AirHockeyPhysics.height / 2, AirHockeyPhysics.height));
    } else {
      topTarget = p;
    }
  }

  void _newGame() => setState(() {
        table = AirHockeyPhysics();
        bottomTarget = topTarget = null;
      });

  @override
  Widget build(BuildContext context) {
    final s = table.scores;
    final names = vsComputer ? ['You', 'Computer'] : ['Bottom', 'Top'];
    final status = over
        ? '${s[0] >= target ? names[0] : names[1]} win${s[0] >= target && vsComputer ? '' : 's'} ${s[0]}–${s[1]}!'
        : '${names[0]} ${s[0]} – ${s[1]} ${names[1]} · first to $target';
    return GameScaffold(
      gameId: 'air_hockey',
      completed: s[0] >= target && vsComputer || (!vsComputer && over),
      title: 'Air Hockey',
      scrollable: false,
      onNewGame: _newGame,
      rules: 'Drag your paddle in your half of the table to strike the puck '
          'into the goal at the far end. In two-player mode each player uses '
          'their own half of the screen (multi-touch). First to the target '
          'score wins.',
      children: [
        OpponentPicker(
          vsComputer: vsComputer,
          level: level,
          onChanged: (v, l) {
            vsComputer = v;
            level = l;
            _newGame();
          },
        ),
        StatusBanner(status, highlight: over),
        Expanded(
          child: LayoutBuilder(builder: (context, box) {
            final h = box.maxHeight;
            final w = (h / AirHockeyPhysics.height).clamp(0.0, box.maxWidth);
            boardSize = Size(w, w * AirHockeyPhysics.height);
            return Center(
              child: Listener(
                onPointerDown: _pointer,
                onPointerMove: _pointer,
                onPointerUp: (e) => pointers.remove(e.pointer),
                child: SizedBox(
                  width: boardSize.width,
                  height: boardSize.height,
                  child: CustomPaint(painter: _RinkPainter(table)),
                ),
              ),
            );
          }),
        ),
        if (over) FilledButton(onPressed: _newGame, child: const Text('Play again')),
      ],
    );
  }
}

class _RinkPainter extends CustomPainter {
  _RinkPainter(this.t);
  final AirHockeyPhysics t;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / AirHockeyPhysics.width;
    Offset p(Offset o) => o * k;
    final rink = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(size.width * .08));
    canvas.drawRRect(rink, Paint()..color = const Color(0xFFE3F2FD));
    final line = Paint()
      ..color = const Color(0xFF90CAF9)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), line);
    canvas.drawCircle(size.center(Offset.zero), size.width * .15, line);
    final goal = Paint()..color = const Color(0xFF263238);
    final gw = AirHockeyPhysics.goalWidth * k;
    canvas.drawRect(Rect.fromLTWH((size.width - gw) / 2, 0, gw, 6), goal);
    canvas.drawRect(Rect.fromLTWH((size.width - gw) / 2, size.height - 6, gw, 6), goal);
    canvas.drawRRect(rink, Paint()
      ..color = const Color(0xFF1565C0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4);
    canvas.drawCircle(p(t.puck), AirHockeyPhysics.puckR * k, Paint()..color = Colors.black87);
    for (final (pos, color) in [(t.bottom, const Color(0xFFE53935)), (t.top, const Color(0xFF1E88E5))]) {
      canvas.drawCircle(p(pos), AirHockeyPhysics.paddleR * k, Paint()..color = color);
      canvas.drawCircle(p(pos), AirHockeyPhysics.paddleR * k * .45, Paint()..color = Colors.white.withValues(alpha: .6));
    }
  }

  @override
  bool shouldRepaint(_RinkPainter old) => true;
}
