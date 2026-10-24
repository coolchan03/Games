import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puzzle/data/game_registry.dart';
import 'package:puzzle/providers/game_session_provider.dart';
import 'package:puzzle/utils/l10n_game_helpers.dart';
import 'package:puzzle/utils/navigation_utils.dart';

/// "Continue" shortcut to the most recently played game, styled like a
/// wooden tray holding that game's box.
class ContinueCard extends ConsumerWidget {
  const ContinueCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastId = ref.watch(gameSessionNotifierProvider
        .select((s) => s.recentGameIds.isEmpty ? null : s.recentGameIds.first));
    if (lastId == null) return const SizedBox.shrink();
    final matches = allGamesMetadata.where((g) => g.id == lastId);
    if (matches.isEmpty) return const SizedBox.shrink();
    final game = matches.first;
    final title = L10nGameHelpers.getGameTitle(context, game.id);

    void open() {
      ref.read(gameSessionNotifierProvider.notifier).setSession(
          gameId: game.id, category: 'ALL', query: '');
      Navigator.push(context, CustomPageRoute(page: game.builder(context)));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Semantics(
        button: true,
        label: 'Continue $title',
        child: GestureDetector(
          key: const ValueKey('continue_card'),
          onTap: open,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Color(0xFF9A5E33), Color(0xFF6E3F20)],
              ),
              boxShadow: const [
                BoxShadow(color: Color(0xFF4A2812), offset: Offset(0, 4)),
              ],
            ),
            child: Row(children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: game.color,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(game.icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'CONTINUE PLAYING',
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                        color: Color(0xFFFFD54F),
                      ),
                    ),
                    Text(
                      title.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: const Color(0xFFFFF3E0),
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFFD54F),
                ),
                child: const Icon(Icons.play_arrow_rounded,
                    color: Color(0xFF4A2812)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
