import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/utils/backup_file.dart';

void main() {
  test('backup file names are dated and filesystem safe', () {
    expect(BackupFile.fileName(DateTime(2026, 3, 7)),
        'puzzle-master-backup-2026-03-07.json');
    expect(BackupFile.fileName(DateTime(2026, 11, 23)),
        'puzzle-master-backup-2026-11-23.json');
  });
}
