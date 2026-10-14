import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Bundled notices remain available offline through Settings > Licenses.
void registerGameLicenses() {
  LicenseRegistry.addLicense(() async* {
    const notices = {
      'chess.dart / chess.js': 'chess-dart-LICENSE.txt',
      'PHE poker evaluator and tables': 'phe-MIT.txt',
      'ED-Mahjong tile definitions and layout rules': 'ED-Mahjong-MIT.txt',
    };
    for (final entry in notices.entries) {
      final text = await rootBundle.loadString('THIRD_PARTY_LICENSES/${entry.value}');
      yield LicenseEntryWithLineBreaks([entry.key], text);
    }
  });
}
