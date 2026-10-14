import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puzzle/providers/library_style_provider.dart';
import 'package:puzzle/ui/features/games/shared/game_storage.dart';
import 'package:puzzle/utils/design_system.dart';
import 'package:puzzle/utils/library_theme.dart';

void main() {
  late Directory directory;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('games-test-');
    Hive.init(directory.path);
  });
  tearDown(() async { await Hive.close(); await directory.delete(recursive: true); });
  test('saves capture snapshots and survive closing and reopening the box', () async {
    final data = <String, dynamic>{'moves': ['e4']};
    final saving = GameStorage.save('test', data);
    (data['moves'] as List).add('e5');
    await saving;
    await Hive.close();
    expect((await GameStorage.load('test'))!['moves'], ['e4']);
    await GameStorage.save('test', {'moves': ['d4']});
    expect((await GameStorage.load('test'))!['moves'], ['d4']);
  });
  test('visual style survives provider recreation', () async {
    final first = ProviderContainer();
    await first.read(libraryStyleProvider.notifier).choose(LibraryStyle.colorful);
    first.dispose();
    final second = ProviderContainer();
    await second.read(libraryStyleProvider.notifier).restore();
    expect(second.read(libraryStyleProvider).style, LibraryStyle.colorful);
    second.dispose();
  });
  test('every visual style keeps full-size controls in light and dark', () {
    for (final style in LibraryStyle.values) {
      for (final base in [DesignSystem.lightTheme, DesignSystem.darkTheme]) {
        final theme = applyLibraryStyle(base, style);
        expect(theme.brightness, base.brightness);
        expect(theme.filledButtonTheme.style!.minimumSize!.resolve({})!.height, greaterThanOrEqualTo(48));
        expect(theme.filledButtonTheme.style!.tapTargetSize, MaterialTapTargetSize.padded);
      }
    }
  });
}
