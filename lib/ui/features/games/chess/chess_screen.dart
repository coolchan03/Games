import 'package:flutter/material.dart';
import '../shared/game_page.dart';
import '../shared/game_storage.dart';
import 'chess_session.dart';
import 'chess_board.dart';

class ChessScreen extends StatefulWidget {
  const ChessScreen({super.key});
  @override
  State<ChessScreen> createState() => _ChessScreenState();
}
class _ChessScreenState extends State<ChessScreen> {
  ChessSession game = ChessSession();
  String mode = 'Local two players';
  String? selected;
  String saveStatus = 'Loading local game...';
  bool ready = false, thinking = false, flipped = false;
  int epoch = 0;
  static const modes = ['Local two players', 'Easy AI', 'Medium AI', 'Hard AI'];
  @override
  void initState() { super.initState(); restore(); }
  Future<void> restore() async {
    try {
      final data = await GameStorage.load('chess');
      if (!mounted) return;
      if (data != null) {
        game = ChessSession.fromJson(Map<String, dynamic>.from(data['game'] as Map));
        mode = modes.contains(data['mode']) ? data['mode'] as String : modes.first;
        flipped = data['flipped'] == true;
      }
      saveStatus = data == null ? 'Moves save on this device' : 'Resumed saved game';
    } catch (_) { saveStatus = 'Save unavailable or invalid; playing a new game'; }
    if (!mounted) return;
    setState(() => ready = true);
    await computerTurn();
  }
  Future<void> save() async {
    try {
      await GameStorage.save('chess', {'game': game.toJson(), 'mode': mode, 'flipped': flipped});
      if (mounted) setState(() => saveStatus = 'Saved on this device');
    } catch (_) {
      if (mounted) setState(() => saveStatus = 'Could not save; keep this game open');
    }
  }
  Future<void> computerTurn() async {
    if (!mounted || !ready || mode == modes.first || game.whiteToMove || game.ended || thinking) return;
    final token = ++epoch;
    setState(() => thinking = true);
    try {
      final move = await chooseChessMove(game, modes.indexOf(mode) - 1,
        cancelled: () => !mounted || token != epoch);
      if (!mounted || token != epoch) return;
      setState(() {
        thinking = false;
        if (move != null) game.play(move['from']!, move['to']!, promotion: move['promotion'] ?? 'q');
      });
      await save();
    } catch (_) {
      if (mounted && token == epoch) setState(() {
        thinking = false; saveStatus = 'Computer move failed. Switch to local play or undo.';
      });
    }
  }
  Future<void> choose(String square) async {
    if (!ready || thinking || game.ended) return;
    final targets = selected == null ? <Map>[] : game.legalMoves
      .where((move) => move['from'] == selected && move['to'] == square).toList();
    if (targets.isNotEmpty) {
      var promotion = 'q';
      if (targets.any((move) => move['promotion'] != null)) {
        final result = await showDialog<String>(context: context, builder: (ctx) =>
          SimpleDialog(title: const Text('Promote pawn'), children: [
            for (final entry in const {'q': 'Queen', 'r': 'Rook', 'b': 'Bishop', 'n': 'Knight'}.entries)
              SimpleDialogOption(onPressed: () => Navigator.pop(ctx, entry.key), child: Text(entry.value)),
          ]));
        if (!mounted || result == null) return;
        promotion = result;
      }
      setState(() { game.play(selected!, square, promotion: promotion); selected = null; });
      await save(); await computerTurn(); return;
    }
    final piece = game.position.get(square);
    setState(() => selected = piece?.color == game.position.turn ? square : null);
  }
  void newGame() {
    epoch++;
    setState(() { game = ChessSession(); selected = null; thinking = false; });
    save();
  }
  void undo() {
    epoch++;
    setState(() {
      thinking = false; selected = null; game.undo();
      if (mode != modes.first && !game.whiteToMove) game.undo();
    });
    save();
  }
  @override
  void dispose() { epoch++; super.dispose(); }
  @override
  Widget build(BuildContext context) => GamePage(title: 'Chess',
    rules: 'Checkmate the opposing king. Legal moves, check, castling, en passant and all four promotions are enforced by chess.dart. Draws include stalemate, insufficient material, threefold repetition and fifty moves without a pawn move or capture. Tap a piece, then a highlighted square. Local mode is pass-and-play; AI plays Black. Easy chooses legal moves; Medium and Hard use bounded searches. Undo takes back your turn. No network engine is needed.',
    status: thinking ? 'Computer thinking...' : game.status, saveStatus: saveStatus,
    children: [
      DropdownButton<String>(isExpanded: true, value: mode,
        items: [for (final value in modes) DropdownMenuItem(value: value, child: Text(value))],
        onChanged: !ready || thinking ? null : (value) {
          if (value != null) { setState(() => mode = value); save(); computerTurn(); }
        }),
      const SizedBox(height: 12),
      ChessBoard(game: game, flipped: flipped, enabled: ready && !thinking && !game.ended,
        selected: selected, onChoose: choose),
      const SizedBox(height: 16),
      Wrap(spacing: 8, runSpacing: 8, children: [
        FilledButton.icon(onPressed: ready ? newGame : null, icon: const Icon(Icons.restart_alt), label: const Text('New game')),
        OutlinedButton.icon(onPressed: ready && game.history.isNotEmpty ? undo : null, icon: const Icon(Icons.undo), label: const Text('Undo')),
        OutlinedButton.icon(onPressed: !ready ? null : () { setState(() => flipped = !flipped); save(); }, icon: const Icon(Icons.flip), label: const Text('Flip board')),
      ]),
      const SizedBox(height: 12),
      GameSection(title: 'Move history', child: SelectableText(game.history.isEmpty ? 'No moves yet' :
        [for (var i = 0; i < game.history.length; i += 2)
          '${i ~/ 2 + 1}. ${game.history[i]} ${i + 1 < game.history.length ? game.history[i + 1] : ''}'].join('   '))),
    ]);
}
