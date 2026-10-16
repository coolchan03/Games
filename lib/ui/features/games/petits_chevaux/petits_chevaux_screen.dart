import 'package:flutter/material.dart';
import '../common/game_kit.dart';
import '../ludo/ludo_engine.dart' show cellFor;
import '../ludo/ludo_screen.dart' show LudoBoard;
import '../shared/game_storage.dart';
import 'petits_chevaux_engine.dart';

const _colors = [
  Color(0xFF1AAA30), Color(0xFFFFCD1D),
  Color(0xFF4A5FD1), Color(0xFFF84700),
];
const _names = ['Green', 'Yellow', 'Blue', 'Red'];

Offset _stable(int seat, int piece) {
  var c = piece.isEven ? 1.5 : 3.5, r = piece < 2 ? 1.5 : 3.5;
  for (var k = 0; k < seat; k++) {
    final temp = 14 - r;
    r = c;
    c = temp;
  }
  return Offset(c, r);
}

class PetitsChevauxScreen extends StatefulWidget {
  const PetitsChevauxScreen({super.key});
  @override
  State<PetitsChevauxScreen> createState() => _PetitsChevauxScreenState();
}

class _PetitsChevauxScreenState extends State<PetitsChevauxScreen> {
  int players = 2, epoch = 0;
  bool computer = true, ready = false, thinking = false;
  late PetitsChevauxGame game;
  String saveStatus = 'Loading...';

  List<int> get seats => switch (players) {
    2 => [1, 3], 3 => [0, 1, 3], _ => [0, 1, 2, 3],
  };

  @override
  void initState() {
    super.initState();
    game = PetitsChevauxGame(seats: seats, computer: {1})..current = 3;
    restore();
  }

  Future<void> restore() async {
    try {
      final saved = await GameStorage.load('petits_chevaux_v1');
      if (!mounted) return;
      if (saved != null) {
        game = PetitsChevauxGame.fromJson(
            Map<String, dynamic>.from(saved['game'] as Map));
        players = game.seats.length;
        computer = game.computer.isNotEmpty;
      }
      saveStatus = saved == null ? 'Local play only' : 'Saved board restored';
    } catch (_) {
      saveStatus = 'Save invalid; new game started';
    }
    if (!mounted) return;
    setState(() => ready = true);
    runComputer();
  }

  Future<void> save() async {
    try {
      await GameStorage.save('petits_chevaux_v1', {'game': game.toJson()});
      if (mounted) setState(() => saveStatus = 'Saved on this device');
    } catch (_) {
      if (mounted) setState(() => saveStatus = 'Save unavailable');
    }
  }

  bool get canMove => ready && !thinking && !game.over &&
      !game.computer.contains(game.current);

  void newGame() {
    epoch++;
    setState(() {
      game = PetitsChevauxGame(
          seats: seats, computer: computer ? seats.where((s) => s != 3).toSet() : {})
        ..current = 3;
      thinking = false;
    });
    save();
  }

  void roll() {
    if (!canMove || game.dice != null) return;
    setState(() => game.roll());
    save();
    runComputer();
  }

  void selectHorse(int index) {
    if (!canMove || !game.legalMoves.any((m) => m.piece == index)) return;
    setState(() => game.play(index));
    save();
    runComputer();
  }

  Future<void> runComputer() async {
    if (!mounted || !ready || thinking || game.over ||
        !game.computer.contains(game.current)) return;
    final token = ++epoch;
    setState(() => thinking = true);
    for (var turns = 0; turns < 60; turns++) {
      if (!mounted || token != epoch || game.over ||
          !game.computer.contains(game.current)) break;
      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (!mounted || token != epoch) return;
      setState(() {
        if (game.roll()) game.play(game.choose(2).piece);
      });
    }
    if (!mounted || token != epoch) return;
    setState(() => thinking = false);
    await save();
  }

  @override
  void dispose() {
    epoch++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cur = game.current;
    final canSelect = canMove && game.dice != null;
    final movable = game.legalMoves.map((m) => m.piece).toSet();
    final status = game.over
        ? '${_names[game.finishOrder.first]} wins!'
        : '${_names[cur]} — ${thinking ? "computer moving" : game.dice == null ? "roll" : "choose a horse"}';
    return GameScaffold(
      gameId: 'petits_chevaux',
      completed: game.over && game.finishOrder.first == 3,
      title: 'Petits Chevaux',
      onNewGame: newGame,
      rules: 'OBJECTIVE: Be first to bring all four horses home. '
          'CONTROLS: Roll, then tap or swipe a highlighted horse on the board. '
          'You can always use the large numbered horse buttons below. '
          'Roll a 6 to leave the stable and get another turn. '
          'Move the rolled number along the track. '
          'Land on an opponent horse to send it back to its stable; '
          'captures do not give an extra roll. '
          'Reach the foot of your staircase exactly, then roll 1, 2, 3, '
          '4, 5 and 6 successively to take the horse home. '
          'This variant allows overtaking; three consecutive sixes '
          'do not cancel earlier moves. Play with friends on this '
          'device or against computer players.',
      children: [
        Row(children: [
          Expanded(child: DropdownButton<int>(
            isExpanded: true,
            value: players,
            items: [for (final n in [2, 3, 4])
              DropdownMenuItem(value: n, child: Text('$n players'))],
            onChanged: thinking ? null : (n) {
              if (n == null) return;
              players = n;
              newGame();
            },
          )),
          Expanded(child: SwitchListTile(
            title: const Text('Computer'),
            dense: true,
            value: computer,
            onChanged: thinking ? null : (v) {
              computer = v;
              newGame();
            },
          )),
        ]),
        StatusBanner(status, highlight: game.over),
        Text(game.message, textAlign: TextAlign.center),
        Text(saveStatus, textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall),
        AspectRatio(aspectRatio: 1, child: LayoutBuilder(
          builder: (context, constraints) {
            final cell = constraints.maxWidth / 15;
            return Stack(children: [
              Positioned.fill(child: CustomPaint(painter: LudoBoard())),
              for (final seat in game.seats)
                for (var i = 0; i < 4; i++)
                  Builder(builder: (context) {
                    final step = game.steps[seat]![i];
                    final point = step == -1 ? _stable(seat, i)
                        : step >= 57 ? const Offset(7, 7) :
                        Offset(cellFor(seat, step)[0].toDouble(),
                            cellFor(seat, step)[1].toDouble());
                    final active = seat == cur && movable.contains(i) && canSelect;
                    return Positioned(
                      left: point.dx * cell, top: point.dy * cell,
                      width: cell, height: cell,
                      child: Semantics(
                        label: '${_names[seat]} horse ${i + 1}'
                            '${active ? ", move available" : ""}',
                        button: active,
                        child: GestureDetector(
                          onTap: active ? () => selectHorse(i) : null,
                          onPanEnd: active ? (_) => selectHorse(i) : null,
                          child: Container(
                            margin: EdgeInsets.all(cell * .06),
                            decoration: BoxDecoration(
                              color: _colors[seat], shape: BoxShape.circle,
                              border: Border.all(
                                color: active ? Colors.white : Colors.black54,
                                width: active ? 3 : 1,
                              ),
                              boxShadow: active ? const [
                                BoxShadow(color: Colors.black38, blurRadius: 7)
                              ] : null,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
            ]);
          },
        )),

        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (game.dice != null) DieFace(game.dice!, size: 48),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: canMove && game.dice == null ? roll : null,
            icon: const Icon(Icons.casino),
            label: const Text('Roll'),
          ),
        ]),
        if (canSelect) ...[
          const SizedBox(height: 10),
          const Text('Tap, swipe, or select a numbered horse:',
              textAlign: TextAlign.center),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12, runSpacing: 12,
            children: [
              for (var i = 0; i < 4; i++)
                SizedBox(
                  height: 50,
                  child: FilledButton.tonal(
                    onPressed: movable.contains(i) ? () => selectHorse(i) : null,
                    child: Text('Horse ${i + 1}'),
                  ),
                ),
            ],
          ),
        ],
        if (game.over)
          FilledButton(onPressed: newGame, child: const Text('Play again')),
      ],
    );
  }
}
