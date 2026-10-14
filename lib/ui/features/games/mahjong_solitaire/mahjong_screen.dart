import 'dart:math';
import 'package:flutter/material.dart';
import '../shared/game_page.dart';
import '../shared/game_storage.dart';
import 'engine/mahjong_board.dart';

class MahjongSolitaireScreen extends StatefulWidget {
  const MahjongSolitaireScreen({super.key});
  @override
  State<MahjongSolitaireScreen> createState() => _MahjongSolitaireScreenState();
}
class _MahjongSolitaireScreenState extends State<MahjongSolitaireScreen> {
  MahjongBoard board = MahjongBoard.generate(null, 'pagoda');
  int? selected;
  MahjongPair? hint;
  bool ready = false;
  String saveStatus = 'Loading saved deal...';
  @override
  void initState() { super.initState(); restore(); }
  Future<void> restore() async {
    try {
      final data = await GameStorage.load('mahjong_layered');
      if (!mounted) return;
      if (data != null) board = MahjongBoard.fromJson(data);
      saveStatus = data == null ? 'Deal saves on this device' : 'Resumed your saved deal';
    } catch (_) { saveStatus = 'Save unavailable or invalid; starting a new deal'; }
    if (mounted) setState(() => ready = true);
  }
  Future<void> save() async {
    try {
      await GameStorage.save('mahjong_layered', board.toJson());
      if (mounted) setState(() => saveStatus = 'Saved on this device');
    } catch (_) { if (mounted) setState(() => saveStatus = 'Could not save; keep this deal open'); }
  }
  void choose(int i) {
    if (!ready || !board.isFree(i)) return;
    setState(() {
      hint = null;
      if (selected == i) selected = null;
      else if (selected != null && board.remove(selected!, i)) selected = null;
      else selected = i;
    });
    save();
  }
  void reset({bool sameDeal = false, String? layout}) {
    setState(() {
      board = sameDeal ? board.restart() : MahjongBoard.generate(null, layout ?? board.layoutId);
      selected = null; hint = null;
    });
    save();
  }
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final matches = board.matches;
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.5);
    final w = 56.0 * scale, h = 76.0 * scale;
    final width = (board.positions.map((p) => p.x).reduce(max) + 2) * w / 2 + 24;
    final height = (board.positions.map((p) => p.y).reduce(max) + 2) * h / 2 + 24;
    return GamePage(title: 'Mahjong Solitaire',
      rules: 'Remove matching pairs. A tile must have no overlapping tile above it and at least one open left or right side. Flowers match any flower; seasons match any season. Garden has one layer, Terraces and Pagoda have four. Every generated starting deal has a verified removal sequence, but choosing other matches can still lead to a dead end. Use Undo or Restart deal. Hint highlights a legal pair, not a guaranteed winning route. Scroll the board sideways on small screens.',
      status: board.complete ? 'Deal complete!' : '${board.remaining} tiles - ${matches.length} legal pairs${matches.isEmpty ? ' - undo or restart' : ''}',
      saveStatus: saveStatus, children: [
        DropdownButton<String>(isExpanded: true, value: board.layoutId,
          items: [for (final entry in MahjongBoard.layoutNames.entries)
            DropdownMenuItem(value: entry.key, child: Text(entry.value))],
          onChanged: !ready ? null : (value) { if (value != null) reset(layout: value); }),
        const SizedBox(height: 12),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: SizedBox(width: width, height: height,
          child: Stack(children: [for (var i = 0; i < board.tiles.length; i++) if (board.tiles[i] != null)
            Positioned(left: 18 + board.positions[i].x * w / 2 - board.positions[i].z * 4,
              top: 18 + board.positions[i].y * h / 2 - board.positions[i].z * 4,
              width: w - 2, height: h - 2,
              child: Semantics(label: '${MahjongBoard.tileLabel(board.tiles[i]!)}; layer ${board.positions[i].z + 1}; ${board.isFree(i) ? 'free' : 'blocked'}',
                button: true, selected: selected == i, excludeSemantics: true,
                child: Tooltip(message: MahjongBoard.tileLabel(board.tiles[i]!), child: Material(
                  elevation: 2 + board.positions[i].z.toDouble(), borderRadius: BorderRadius.circular(7),
                  color: selected == i || hint?.first == i || hint?.second == i ? colors.primaryContainer
                    : board.isFree(i) ? colors.surfaceContainerLowest : colors.surfaceContainerHighest,
                  child: InkWell(onTap: ready && board.isFree(i) ? () => choose(i) : null,
                    borderRadius: BorderRadius.circular(7), child: Container(
                      decoration: BoxDecoration(border: Border.all(color: selected == i || hint?.first == i || hint?.second == i
                        ? colors.primary : colors.outlineVariant, width: selected == i ? 3 : 1), borderRadius: BorderRadius.circular(7)),
                      padding: const EdgeInsets.all(4), child: Column(children: [
                        Expanded(child: Center(child: FittedBox(fit: BoxFit.scaleDown,
                          child: Text(MahjongBoard.tileLabel(board.tiles[i]!).replaceFirst(' ', '\n'),
                            textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))))),
                        Icon(board.isFree(i) ? Icons.lock_open : Icons.lock_outline, size: 13),
                      ])),
                  ),
                )))),
          ]))),
        const SizedBox(height: 16),
        Wrap(spacing: 8, runSpacing: 8, children: [
          FilledButton(onPressed: ready ? () => reset() : null, child: const Text('New deal')),
          OutlinedButton(onPressed: ready ? () => reset(sameDeal: true) : null, child: const Text('Restart deal')),
          OutlinedButton.icon(onPressed: !ready || board.history.isEmpty ? null : () {
            setState(() { board.undo(); selected = null; hint = null; }); save();
          }, icon: const Icon(Icons.undo), label: const Text('Undo')),
          OutlinedButton.icon(onPressed: ready && matches.isNotEmpty ? () => setState(() {
            hint = matches.first; selected = null;
          }) : null, icon: const Icon(Icons.lightbulb_outline), label: const Text('Hint')),
        ]),
      ]);
  }
}
