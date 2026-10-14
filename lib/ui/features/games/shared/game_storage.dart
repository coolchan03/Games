import 'dart:convert';
import 'package:hive/hive.dart';

/// One versioned, local-only save area. No account or network is involved.
class GameStorage {
  static Future<Box<String>>? _opening;
  static Future<Box<String>> _box() {
    if (Hive.isBoxOpen('classic_games_v1')) {
      return Future.value(Hive.box<String>('classic_games_v1'));
    }
    return _opening ??= Hive.openBox<String>('classic_games_v1')
        .catchError((Object error) { _opening = null; throw error; });
  }

  static Future<Map<String, dynamic>?> load(String key) async {
    final raw = (await _box()).get(key);
    if (raw == null) return null;
    final value = jsonDecode(raw);
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Invalid saved game');
    }
    return value;
  }

  static Future<void> save(String key, Map<String, dynamic> value) {
    // Capture before an asynchronous open so a later move cannot alter this save.
    final snapshot = jsonEncode(value);
    return _box().then((box) => box.put(key, snapshot));
  }
}
