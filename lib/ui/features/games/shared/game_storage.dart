import 'dart:convert';
import 'package:hive/hive.dart';

/// One versioned local-only save area, shared by all classic game screens.
class GameStorage {
  static Future<Box<String>>? _opening;
  static Future<Box<String>> _box() async {
    if (Hive.isBoxOpen('classic_games_v1')) return Hive.box<String>('classic_games_v1');
    final opening = _opening ??= Hive.openBox<String>('classic_games_v1');
    try {
      return await opening;
    } finally {
      if (identical(_opening, opening)) _opening = null;
    }
  }
  static Future<Map<String, dynamic>?> load(String key) async {
    final raw = (await _box()).get(key);
    if (raw == null) return null;
    final value = jsonDecode(raw);
    if (value is! Map<String, dynamic>) throw const FormatException('Invalid saved game');
    return value;
  }
  static Future<void> save(String key, Map<String, dynamic> value) {
    // Snapshot before awaiting disk open, so subsequent moves cannot change it.
    final snapshot = jsonEncode(value);
    return _box().then((box) => box.put(key, snapshot));
  }
}
