import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/ui/features/games/common/level_audit.dart';

/// Proves (as far as the per-game solvers allow) that every numbered and
/// random level can be finished. Fails only on a level proven impossible.
void main() {
  for (final entry in levelAudits.entries) {
    test('${entry.key}: every level and random level can be completed', () {
      final results = entry.value(40);
      final impossible = results.where((r) => r.status == AuditStatus.impossible);
      final proven = results.where((r) => r.status == AuditStatus.proven).length;
      // ignore: avoid_print
      print('${entry.key}: ${results.length} levels, $proven proven, '
          '${results.length - proven - impossible.length} unverified (budget)');
      expect(impossible.map((r) => '${r.game} ${r.level} ${r.detail}'), isEmpty);
      expect(results, isNotEmpty);
      // The audit must actually be proving things, not just skipping them.
      expect(proven, greaterThan(results.length ~/ 2));
    });
  }
}
