import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'theme_provider.g.dart';

enum AppThemeMode {
  light,
  dark,
  system,
}

@riverpod
class ThemeNotifier extends _$ThemeNotifier {
  static const String _themeBoxName = 'theme_settings';
  static const String _themeKey = 'theme_mode';
  static Box? _cachedBox;

  static Future<Box> _getBox() async {
    if (_cachedBox != null && _cachedBox!.isOpen) return _cachedBox!;
    _cachedBox = await Hive.openBox(_themeBoxName);
    return _cachedBox!;
  }

  static AppThemeMode _initial = AppThemeMode.system;

  /// Reads the saved mode before the first frame so the app never flashes the
  /// system theme and then jumps to the saved one.
  static Future<void> preload() async {
    try {
      final box = await _getBox();
      _initial = _parse(box.get(_themeKey));
    } catch (_) {}
  }

  static AppThemeMode _parse(Object? saved) => switch (saved) {
        'light' => AppThemeMode.light,
        'dark' => AppThemeMode.dark,
        _ => AppThemeMode.system,
      };

  @override
  AppThemeMode build() {
    _loadThemeMode();
    return _initial;
  }

  Future<void> _loadThemeMode() async {
    try {
      final box = await _getBox();
      final savedTheme = box.get(_themeKey, defaultValue: 'system');

      final loaded = _parse(savedTheme);

      if (state != loaded) {
        state = loaded;
      }
    } catch (_) {}
  }

  Future<void> setThemeMode(AppThemeMode themeMode) async {
    try {
      final box = await _getBox();
      await box.put(_themeKey, themeMode.name);
      state = themeMode;
    } catch (_) {}
  }

  void toggleTheme() {
    final next = switch (state) {
      AppThemeMode.light => AppThemeMode.dark,
      AppThemeMode.dark => AppThemeMode.system,
      AppThemeMode.system => AppThemeMode.light,
    };
    setThemeMode(next);
  }

  ThemeMode get themeMode => switch (state) {
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
        AppThemeMode.system => ThemeMode.system,
      };

  String get themeDisplayName => switch (state) {
        AppThemeMode.light => 'Light',
        AppThemeMode.dark => 'Dark',
        AppThemeMode.system => 'System',
      };

  IconData get themeIcon => switch (state) {
        AppThemeMode.light => Icons.light_mode_rounded,
        AppThemeMode.dark => Icons.dark_mode_rounded,
        AppThemeMode.system => Icons.brightness_auto_rounded,
      };
}
