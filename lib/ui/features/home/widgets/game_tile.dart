import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:puzzle/l10n/app_localizations.dart';
import 'package:puzzle/utils/l10n_game_helpers.dart';
import 'package:puzzle/data/game_metadata.dart';
import 'package:puzzle/providers/user_providers.dart';
import 'package:puzzle/providers/game_session_provider.dart';
import 'package:puzzle/utils/design_system.dart';
import 'package:puzzle/utils/haptic_feedback.dart';
import 'package:puzzle/utils/navigation_utils.dart';
import 'package:puzzle/data/models/game_streak.dart';
import 'game_guide_screen.dart';

class GameTile extends ConsumerWidget {
  final GameMetadata game;
  final GameStreak? streak;
  final bool isFavorite;
  final String selectedCategory;
  final String searchQuery;

  const GameTile({
    super.key,
    required this.game,
    this.streak,
    required this.isFavorite,
    required this.selectedCategory,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final gameId = game.id;
    final isSolvedToday = streak?.solvedToday ?? false;
    final streakCount = streak?.currentStreak ?? 0;
    final isNew = streak == null;
    final l10n = AppLocalizations.of(context)!;
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    final lid = game.color;
    final lidDark = Color.lerp(lid, Colors.black, .38)!;
    final lidLight = Color.lerp(lid, Colors.white, .18)!;

    // Styled like a board-game box: a coloured lid with a printed label
    // plate, and a darker box side showing underneath.
    return Semantics(
      button: true,
      label: L10nGameHelpers.getGameTitle(context, game.id),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          ScaffoldMessenger.of(context).clearSnackBars();
          ref.read(gameSessionNotifierProvider.notifier).setSession(
                gameId: gameId,
                category: selectedCategory,
                query: searchQuery,
              );
          Navigator.push(
            context,
            CustomPageRoute(page: game.builder(context)),
          );
        },
        onLongPress: () {
          HapticFeedbackUtil.mediumImpact();
          ref.read(userDataNotifierProvider.notifier).toggleFavorite(gameId);
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            // The box side.
            boxShadow: [
              BoxShadow(color: lidDark, offset: const Offset(0, 6)),
              BoxShadow(
                color: Colors.black.withValues(alpha: .25),
                offset: const Offset(0, 9),
                blurRadius: 10,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // Lid with a soft sheen.
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [lidLight, lid, Color.lerp(lid, lidDark, .5)!],
                      ),
                    ),
                  ),
                ),
                // Diagonal box-art stripes.
                Positioned.fill(
                  child: CustomPaint(painter: _LidStripes(Colors.white.withValues(alpha: .07))),
                ),
                // Large box-art icon.
                Positioned(
                  right: isMobile ? -18 : -10,
                  top: isMobile ? -14 : -18,
                  child: Transform.rotate(
                    angle: -0.18,
                    child: Icon(
                      game.icon,
                      size: isMobile ? 120 : 160,
                      color: Colors.white.withValues(alpha: 0.22),
                    ),
                  ),
                ),
                // Inner rim of the lid.
                Positioned.fill(
                  child: Container(
                    margin: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: .35), width: 1.2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: isMobile
                        ? MainAxisAlignment.start
                        : MainAxisAlignment.spaceBetween,
                    children: [
                      _buildHeader(theme, l10n, isSolvedToday, streakCount, isNew),
                      SizedBox(height: isMobile ? 14.0 : 8.0),
                      _buildBody(context, theme, isSolvedToday, isMobile),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    ThemeData theme,
    AppLocalizations l10n,
    bool isSolvedToday,
    int streakCount,
    bool isNew,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Text(
            game.category.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10.0,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isNew)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD54F),
                  borderRadius: BorderRadius.circular(20.0),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, offset: Offset(0, 2)),
                  ],
                ),
                child: Text(
                  l10n.newGameLabel.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 9.0,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF4A2A00),
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            if (streakCount > 0) ...[
              if (isNew) const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_fire_department_rounded,
                        size: 12, color: DesignSystem.accentAmber),
                    const SizedBox(width: 2),
                    Text(
                      '$streakCount',
                      style: const TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 10.0,
                        fontWeight: FontWeight.w900,
                        color: DesignSystem.accentAmber,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (isFavorite) ...[
              const SizedBox(width: 8),
              const Icon(Icons.star_rounded,
                  color: Color(0xFFFFD54F), size: 20,
                  shadows: [Shadow(color: Colors.black38, offset: Offset(0, 1))]),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, ThemeData theme, bool isSolvedToday,
      bool isMobile) {
    const ink = Color(0xFF2B2118);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
      decoration: BoxDecoration(
        // The printed title plate on the lid.
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFBF0), Color(0xFFF3E7CC)],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Color.lerp(game.color, Colors.black, .3)!, width: 1.5),
        boxShadow: const [
          BoxShadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 2),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                L10nGameHelpers.getGameTitle(context, game.id).toUpperCase(),
                maxLines: 1,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontSize: isMobile ? 26.0 : 30.0,
                  letterSpacing: 0.8,
                  height: 1.05,
                  color: ink,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4.0),
          IconButton(
            tooltip: 'How to play',
            icon: Icon(
              Icons.info_outline_rounded,
              color: ink.withValues(alpha: 0.55),
            ),
            iconSize: isMobile ? 20 : 24,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GameGuideScreen(
                    gameId: game.id,
                    gameColor: game.color,
                  ),
                ),
              );
            },
          ),
          // Play button styled as a game token.
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-.3, -.35),
                colors: [Color.lerp(game.color, Colors.white, .35)!, game.color],
              ),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [
                BoxShadow(color: Colors.black38, offset: Offset(0, 2), blurRadius: 2),
              ],
            ),
            child: Icon(
              isSolvedToday ? Icons.check_rounded : Icons.play_arrow_rounded,
              color: Colors.white,
              size: isMobile ? 20 : 24,
            ),
          ),
        ],
      ),
    );
  }
}

class _LidStripes extends CustomPainter {
  _LidStripes(this.colour);
  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = colour
      ..strokeWidth = 14;
    for (var x = -size.height; x < size.width; x += 38) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), paint);
    }
  }

  @override
  bool shouldRepaint(_LidStripes old) => old.colour != colour;
}

Widget buildGameTile(
  BuildContext context,
  WidgetRef ref,
  GameMetadata game,
  String selectedCategory,
  String searchQuery,
) {
  return GameTileWrapper(
    game: game,
    selectedCategory: selectedCategory,
    searchQuery: searchQuery,
  );
}

class GameTileWrapper extends ConsumerWidget {
  final GameMetadata game;
  final String selectedCategory;
  final String searchQuery;

  const GameTileWrapper({
    super.key,
    required this.game,
    required this.selectedCategory,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(
        gameStreakNotifierProvider.select((s) => s[game.id]));
    final isFavorite = ref.watch(
        userDataNotifierProvider.select(
            (d) => (d.favoriteGameIds ?? []).contains(game.id)));

    final l10n = AppLocalizations.of(context)!;

    return Slidable(
      key: ValueKey(game.id),
      startActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.15,
        children: [
          SlidableAction(
            onPressed: (_) {
              HapticFeedbackUtil.mediumImpact();
              ref.read(userDataNotifierProvider.notifier).toggleHideGame(game.id);
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  content: Text(l10n.gameHidden),
                  action: SnackBarAction(
                    label: l10n.undo,
                    onPressed: () {
                      ref.read(userDataNotifierProvider.notifier).toggleHideGame(game.id);
                    },
                  ),
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            backgroundColor: Colors.transparent,
            foregroundColor: DesignSystem.error,
            icon: Icons.visibility_off_rounded,
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.15,
        children: [
          SlidableAction(
            onPressed: (_) {
              HapticFeedbackUtil.mediumImpact();
              ref.read(userDataNotifierProvider.notifier).toggleFavorite(game.id);
            },
            backgroundColor: Colors.transparent,
            foregroundColor: DesignSystem.accentAmber,
            icon: isFavorite ? Icons.star_border_rounded : Icons.star_rounded,
          ),
        ],
      ),
      child: GameTile(
        game: game,
        streak: streak,
        isFavorite: isFavorite,
        selectedCategory: selectedCategory,
        searchQuery: searchQuery,
      ),
    );
  }
}
