import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../ui/features/games/shared/game_storage.dart';

/// App-wide interface size. Multiplies the system text scale so every label,
/// including the many fixed-size ones inside games, can be made larger.
enum UiSize {
  compact('Compact', 1.0),
  comfortable('Comfortable', 1.15),
  large('Large', 1.3),
  extraLarge('Extra large', 1.5);

  const UiSize(this.label, this.factor);
  final String label;
  final double factor;
}

class UiSizeNotifier extends StateNotifier<UiSize> {
  UiSizeNotifier() : super(_initial);

  static UiSize _initial = UiSize.comfortable;
  static const _key = 'ui_size';

  /// Loads the saved size before the first frame to avoid a visible jump.
  static Future<void> preload() async {
    try {
      final data = await GameStorage.load(_key);
      final name = data?['size'];
      _initial = UiSize.values.firstWhere((s) => s.name == name,
          orElse: () => UiSize.comfortable);
    } catch (_) {}
  }

  Future<void> choose(UiSize size) async {
    state = size;
    try {
      await GameStorage.save(_key, {'version': 1, 'size': size.name});
    } catch (_) {
      // The choice still applies for this session.
    }
  }
}

final uiSizeProvider =
    StateNotifierProvider<UiSizeNotifier, UiSize>((ref) => UiSizeNotifier());
