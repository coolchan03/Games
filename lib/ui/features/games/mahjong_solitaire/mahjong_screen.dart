import 'dart:async';

import 'package:flutter/material.dart';

import '../common/campaign_progress.dart';
import '../common/game_kit.dart';
import 'engine/layered_board.dart';
import 'engine/mahjong_tile.dart';

/// Layered Mahjong Solitaire with classic KMahjongg layouts. Every deal and
/// every shuffle is generated from a full removal sequence, so it is solvable.
class MahjongSolitaireScreen extends StatefulWidget {
  const MahjongSolitaireScreen({super.key});
  @override
  State<MahjongSolitaireScreen> createState() => _MahjongSolitaireState();
}

class _MahjongSolitaireState extends State<MahjongSolitaireScreen> {
  final layouts = Layout.all();
  late Layout layout = layouts[
    CampaignProgress.selectedLevel('mahjong_solitaire', count: layouts.length) - 1,
  ];
  late LayeredBoard board = _load();
  int? selected;
  (int, int)? hint;

  int get _layoutNumber => layouts.indexOf(layout) + 1;

  LayeredBoard _load() {
    final restored = LayeredBoard(layout);
    final data = CampaignProgress.loadActive('mahjong_solitaire', _layoutNumber,
      maxLength: layout.slots.length + 1);
    if (data != null) restored.restore(data);
    return restored;
  }

  void _save() => unawaited(CampaignProgress.saveActive(
    'mahjong_solitaire', _layoutNumber, board.snapshot(),
  ));

  void _newGame() {
    setState(() {
      board = LayeredBoard(layout);
      selected = null;
      hint = null;
    });
    _save();
  }

  void _tap(int i) {
    if (!board.isFree(i)) return;
    var removed = false;
    setState(() {
      hint = null;
      if (selected == null || selected == i) {
        selected = selected == i ? null : i;
      } else if (board.remove(selected!, i)) {
        selected = null;
        removed = true;
      } else {
        selected = i;
      }
    });
    if (removed) _save();
  }

  @override
  Widget build(BuildContext context) {
    final moves = board.moves;
    final status = board.won
        ? 'Cleared! ${board.shuffles == 0 ? 'No shuffles needed.' : 'Shuffles used: ${board.shuffles}'}'
        : moves.isEmpty
            ? 'No matching free pairs — shuffle to continue'
            : '${board.remaining} tiles · ${moves.length} possible match${moves.length == 1 ? '' : 'es'}';
    return GameScaffold(
      gameId: 'mahjong_solitaire',
      completed: board.won,
      title: 'Mahjong Solitaire',
      maxWidth: 900,
      onNewGame: _newGame,
      rules: 'Remove all tiles in matching pairs. A tile is free when nothing '
          'lies on top of it and its left or right side is open. Any two '
          'flowers match each other, as do any two seasons.\n\nEvery layout '
          'is dealt so that it can be solved. Pinch or scroll to zoom. '
          'Layouts are from KDE KMahjongg. Unfinished layouts resume offline.',
      children: [
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final l in layouts)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(l.name),
                    selected: l == layout,
                    onSelected: (_) {
                      setState(() {
                        layout = l;
                        board = _load();
                        selected = null;
                        hint = null;
                      });
                      unawaited(CampaignProgress.saveSelected(
                        'mahjong_solitaire', _layoutNumber));
                    },
                  ),
                ),
            ],
          ),
        ),
        StatusBanner(status, highlight: board.won || moves.isEmpty),
        LayoutBuilder(builder: (context, box) {
          final u = box.maxWidth / (layout.width + 2);
          final uy = u * 1.3;
          final depth = u * .28;
          final maxZ = layout.slots.fold(0, (m, s) => s.z > m ? s.z : m);
          final order = List.generate(layout.slots.length, (i) => i)
            ..sort((a, b) {
              final sa = layout.slots[a], sb = layout.slots[b];
              if (sa.z != sb.z) return sa.z - sb.z;
              if (sa.y != sb.y) return sa.y - sb.y;
              return sb.x - sa.x;
            });
          return InteractiveViewer(
            maxScale: 4,
            child: SizedBox(
              width: box.maxWidth,
              height: (layout.height + 1) * uy + maxZ * depth + 8,
              child: Stack(children: [
                for (final i in order)
                  if (board.tiles[i] != null)
                    Positioned(
                      left: u + layout.slots[i].x * u - layout.slots[i].z * depth,
                      top: maxZ * depth + layout.slots[i].y * uy - layout.slots[i].z * depth,
                      width: 2 * u + depth * .6,
                      height: 2 * uy + depth * .6,
                      child: GestureDetector(
                        onTap: () => _tap(i),
                        child: _TileFace(
                          tile: board.tiles[i]!,
                          free: board.isFree(i),
                          selected: selected == i,
                          hinted: hint != null && (hint!.$1 == i || hint!.$2 == i),
                          depth: depth * .6,
                        ),
                      ),
                    ),
              ]),
            ),
          );
        }),
        const SizedBox(height: 8),
        Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [
          OutlinedButton.icon(
            onPressed: board.history.isEmpty
                ? null
                : () => setState(() {
                      board.undo();
                      selected = null;
                      _save();
                    }),
            icon: const Icon(Icons.undo),
            label: const Text('Undo'),
          ),
          OutlinedButton.icon(
            onPressed: moves.isEmpty ? null : () => setState(() => hint = moves.first),
            icon: const Icon(Icons.lightbulb_outline),
            label: const Text('Hint'),
          ),
          FilledButton.tonalIcon(
            onPressed: board.won
                ? null
                : () => setState(() {
                      board.shuffle();
                      selected = null;
                      hint = null;
                      _save();
                    }),
            icon: const Icon(Icons.shuffle),
            label: const Text('Shuffle'),
          ),
        ]),
      ],
    );
  }
}

class _TileFace extends StatelessWidget {
  const _TileFace({
    required this.tile,
    required this.free,
    required this.selected,
    required this.hinted,
    required this.depth,
  });

  final MahjongTile tile;
  final bool free, selected, hinted;
  final double depth;

  static const _red = Color(0xFFC62828), _green = Color(0xFF2E7D32), _blue = Color(0xFF1565C0);

  (IconData, Color, String?) get _face {
    final i = tile.index;
    if (i < 9) return (Icons.translate, _red, '${i + 1}');
    if (i < 18) return (Icons.grass, _green, '${i - 8}');
    if (i < 27) return (Icons.radio_button_checked, _blue, '${i - 17}');
    switch (tile) {
      case MahjongTile.SEASON_1:
        return (Icons.spa, _green, null);
      case MahjongTile.SEASON_2:
        return (Icons.wb_sunny, const Color(0xFFF57F17), null);
      case MahjongTile.SEASON_3:
        return (Icons.forest, const Color(0xFF8D6E63), null);
      case MahjongTile.SEASON_4:
        return (Icons.ac_unit, _blue, null);
      case MahjongTile.FLOWER_1:
      case MahjongTile.FLOWER_2:
      case MahjongTile.FLOWER_3:
      case MahjongTile.FLOWER_4:
        return (Icons.local_florist, const Color(0xFFAD1457), '${i - 30}');
      case MahjongTile.WIND_1:
        return (Icons.east, Colors.black87, 'E');
      case MahjongTile.WIND_2:
        return (Icons.south, Colors.black87, 'S');
      case MahjongTile.WIND_3:
        return (Icons.west, Colors.black87, 'W');
      case MahjongTile.WIND_4:
        return (Icons.north, Colors.black87, 'N');
      case MahjongTile.DRAGON_1:
        return (Icons.local_fire_department, _red, null);
      case MahjongTile.DRAGON_2:
        return (Icons.eco, _green, null);
      default:
        return (Icons.crop_square, _blue, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (icon, color, label) = _face;
    return Semantics(
      label: tileToString(tile).replaceAll('_', ' ').toLowerCase(),
      button: free,
      child: Stack(children: [
        // Tile side (3D edge).
        Positioned(
          left: depth,
          top: depth,
          right: 0,
          bottom: 0,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFBFA77A),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        Positioned(
          left: 0,
          top: 0,
          right: depth,
          bottom: depth,
          child: Container(
            decoration: BoxDecoration(
              color: selected
                  ? colors.primaryContainer
                  : hinted
                      ? colors.tertiaryContainer
                      : free
                          ? const Color(0xFFFFFBF0)
                          : const Color(0xFFE8E0CC),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: selected ? colors.primary : Colors.black38,
                width: selected ? 2 : .8,
              ),
            ),
            child: FittedBox(
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  if (label != null)
                    Text(label,
                        style: TextStyle(
                            color: color, fontWeight: FontWeight.w800, fontSize: 18, height: 1)),
                  Icon(icon, color: color, size: 22),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
