import 'dart:math';

import 'package:flutter/material.dart';

import '../common/campaign_level_bar.dart';
import '../common/game_kit.dart';
import 'engine/layered_board.dart';
import 'engine/mahjong_tile.dart';
import 'mahjong_tile_art.dart';

/// Layered Mahjong Solitaire with classic KMahjongg layouts. Every deal and
/// every shuffle is generated from a full removal sequence, so it is solvable.
class MahjongSolitaireScreen extends StatefulWidget {
  const MahjongSolitaireScreen({super.key});
  @override
  State<MahjongSolitaireScreen> createState() => _MahjongSolitaireState();
}

class _MahjongSolitaireState extends State<MahjongSolitaireScreen> {
  int level = CampaignLevelBar.initialLevel('mahjong_solitaire');
  late LayeredBoard board = _build(level);
  Layout get layout => board.layout;
  int? selected;
  (int, int)? hint;

  /// Hints used on this level (help lowers the stars).
  int hints = 0;

  /// Builds [level], resuming a saved unfinished attempt when [resume].
  /// The save must be the same deal with only whole pairs removed (or
  /// shuffled), otherwise the fresh deal is used.
  LayeredBoard _build(int level, {bool resume = true}) {
    final b = MahjongLevels.build(level);
    hints = 0;
    final saved = resume
        ? CampaignLevelBar.restoreActive('mahjong_solitaire', level)
        : null;
    if (saved == null || saved.length != b.tiles.length + 2) return b;
    final cells = saved.sublist(2);
    final available = <int, int>{};
    for (final t in b.tiles) {
      available[t!.index] = (available[t.index] ?? 0) + 1;
    }
    for (final c in cells) {
      if (c == -1) continue;
      if (c < 0 || c >= MahjongTile.values.length) return b;
      final left = (available[c] ?? 0) - 1;
      if (left < 0) return b;
      available[c] = left;
    }
    if (cells.where((c) => c == -1).length.isOdd) return b;
    b.tiles = [for (final c in cells) c == -1 ? null : MahjongTile.values[c]];
    b.shuffles = saved[0];
    hints = saved[1];
    return b;
  }

  void _newGame({bool resume = false}) => setState(() {
        board = _build(level, resume: resume);
        selected = null;
        hint = null;
      });

  void _tap(int i) {
    if (!board.isFree(i)) return;
    setState(() {
      hint = null;
      if (selected == null || selected == i) {
        selected = selected == i ? null : i;
      } else if (board.remove(selected!, i)) {
        selected = null;
      } else {
        selected = i;
      }
    });
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
      onNewGame: () => _newGame(),
      rules: 'Remove all tiles in matching pairs. A tile is free when nothing '
          'lies on top of it and its left or right side is open. Any two '
          'flowers match each other, as do any two seasons.\n\nEvery layout '
          'is dealt so that it can be solved. Pinch or scroll to zoom. '
          'Layouts are from KDE KMahjongg.\n\nThere are 20 levels: two deals '
          'of the flat Beginner layout, then the eight layered layouts, each '
          'dealt more than once. Clear every tile to complete a level; New '
          'game restarts the same deal.',
      children: [
        CampaignLevelBar(
          gameId: 'mahjong_solitaire',
          level: level,
          solved: board.won,
          onLevel: (value) {
            level = value;
            _newGame(resume: true);
          },
          describe: (l) => MahjongLevels.layoutFor(l).name,
          activeState: [
            board.shuffles,
            hints,
            for (final t in board.tiles) t?.index ?? -1,
          ],
          result: CampaignResult(
            score: board.shuffles + hints,
            stars: board.shuffles + hints == 0
                ? 3
                : board.shuffles <= 1
                    ? 2
                    : 1,
            label: (n) => n == 0
                ? 'no hints or shuffles'
                : '$n hint${n == 1 ? '' : 's'} or shuffles',
          ),
        ),
        StatusBanner(status, highlight: board.won || moves.isEmpty),
        LayoutBuilder(builder: (context, box) {
          // Fit the width, but on larger screens never taller than about
          // 70% of the screen (short phone-landscape screens may scroll).
          final screenH = MediaQuery.sizeOf(context).height;
          final u = min(
            box.maxWidth / (layout.width + 2),
            screenH * (screenH < 500 ? 1.1 : .7) / ((layout.height + 1) * 1.3 + 2),
          );
          final dx = (box.maxWidth - (layout.width + 2) * u) / 2;
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
          return DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const RadialGradient(
                radius: 1.1,
                colors: [
                  Color(0xFF2E7D4F),
                  Color(0xFF1B5E3A),
                  Color(0xFF0E3B24)
                ],
                stops: [0, .6, 1],
              ),
              border: Border.all(color: const Color(0xFF5D3A1A), width: 4),
            ),
            child: InteractiveViewer(
              maxScale: 4,
              child: SizedBox(
                width: box.maxWidth,
                height: (layout.height + 1) * uy + maxZ * depth + 8,
                child: Stack(children: [
                  for (final i in order)
                    if (board.tiles[i] != null)
                      Positioned(
                        left: dx + u +
                            layout.slots[i].x * u -
                            layout.slots[i].z * depth,
                        top: maxZ * depth +
                            layout.slots[i].y * uy -
                            layout.slots[i].z * depth,
                        width: 2 * u + depth * .6,
                        height: 2 * uy + depth * .6,
                        child: GestureDetector(
                          onTap: () => _tap(i),
                          child: _TileFace(
                            tile: board.tiles[i]!,
                            free: board.isFree(i),
                            selected: selected == i,
                            hinted: hint != null &&
                                (hint!.$1 == i || hint!.$2 == i),
                            depth: depth * .6,
                          ),
                        ),
                      ),
                ]),
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: board.history.isEmpty
                    ? null
                    : () => setState(() {
                          board.undo();
                          selected = null;
                        }),
                icon: const Icon(Icons.undo),
                label: const Text('Undo'),
              ),
              OutlinedButton.icon(
                onPressed: moves.isEmpty
                    ? null
                    : () => setState(() {
                          hint = moves.first;
                          hints++;
                        }),
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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final glow = selected
        ? const Color(0xFFFFC107)
        : hinted
            ? colors.tertiary
            : null;
    return Semantics(
      label: tileToString(tile).replaceAll('_', ' ').toLowerCase(),
      button: free,
      selected: selected,
      child: Stack(children: [
        // Two-layer side: ivory face over a jade-green back, as on real tiles.
        Positioned(
          left: depth,
          top: depth,
          right: 0,
          bottom: 0,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFD9CBA3),
                  Color(0xFF1F7A5A),
                  Color(0xFF0F4D38)
                ],
                stops: [0, .45, 1],
              ),
              borderRadius: BorderRadius.circular(5),
              boxShadow: const [
                BoxShadow(
                    blurRadius: 3, offset: Offset(1, 2), color: Colors.black45),
              ],
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
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: selected
                    ? const [Color(0xFFFFF8E1), Color(0xFFFFE082)]
                    : hinted
                        ? [Colors.white, colors.tertiaryContainer]
                        : free
                            ? const [Color(0xFFFFFDF6), Color(0xFFF1E8D2)]
                            // Blocked: clearly grey so playable tiles stand out.
                            : const [Color(0xFFB4B0A8), Color(0xFF8F8B84)],
              ),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: glow ?? const Color(0xFFB8A77F),
                width: glow != null ? 2.2 : .8,
              ),
              boxShadow: [
                if (glow != null)
                  BoxShadow(color: glow.withValues(alpha: .7), blurRadius: 8),
              ],
            ),
            padding: const EdgeInsets.all(2),
            child: free || selected
                ? CustomPaint(painter: MahjongFacePainter(tile))
                : ColorFiltered(
                    // Blocked tiles: desaturated and dimmed.
                    colorFilter: const ColorFilter.matrix([
                      .35, .45, .1, 0, -10, //
                      .2, .6, .1, 0, -10, //
                      .2, .45, .25, 0, -10, //
                      0, 0, 0, .9, 0,
                    ]),
                    child: CustomPaint(painter: MahjongFacePainter(tile)),
                  ),
          ),
        ),
      ]),
    );
  }
}
