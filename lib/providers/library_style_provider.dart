import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../ui/features/games/shared/game_storage.dart';

enum LibraryStyle { classic, compact, colorful }

class StylePreference {
  final LibraryStyle style;
  final String? error;
  const StylePreference(this.style, {this.error});
}

class LibraryStyleNotifier extends StateNotifier<StylePreference> {
  LibraryStyleNotifier() : super(const StylePreference(LibraryStyle.classic)) { restore(); }
  int _revision = 0;
  Future<void> restore() async {
    final revision = _revision;
    try {
      final data = await GameStorage.load('appearance');
      if (!mounted || revision != _revision || data == null) return;
      state = StylePreference(LibraryStyle.values.byName(data['style'] as String));
    } catch (_) {
      if (mounted && revision == _revision) {
        state = StylePreference(state.style, error: 'Appearance could not be restored.');
      }
    }
  }
  Future<void> choose(LibraryStyle style) async {
    final revision = ++_revision;
    state = StylePreference(style);
    try {
      await GameStorage.save('appearance', {'version': 1, 'style': style.name});
    } catch (_) {
      if (mounted && revision == _revision) {
        state = StylePreference(style, error: 'Style changed, but could not be saved.');
      }
    }
  }
}
final libraryStyleProvider = StateNotifierProvider<LibraryStyleNotifier, StylePreference>(
  (ref) => LibraryStyleNotifier());
