import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puzzle/domain/progress_engine.dart' as engine;
import 'package:puzzle/providers/progress_providers.dart';
import 'package:puzzle/utils/backup_file.dart';
import 'package:puzzle/utils/design_system.dart';
import 'package:puzzle/widgets/tangible.dart';

/// Copy all progress as text and restore it later (or on another device).
/// Works offline and needs no account: the backup is a single JSON string.
class BackupSection extends ConsumerWidget {
  const BackupSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return TangibleContainer(
      padding: const EdgeInsets.all(DesignSystem.spaceMD),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Back up your XP, streaks, favorites and campaign levels, or restore them on another device.',
            style: theme.textTheme.bodySmall),
        const SizedBox(height: DesignSystem.spaceMD),
        Wrap(spacing: DesignSystem.spaceSM, runSpacing: DesignSystem.spaceSM, children: [
          FilledButton.icon(
            key: const ValueKey('backup_save_file'),
            onPressed: () => _saveFile(context, ref),
            icon: const Icon(Icons.save_alt_rounded),
            label: const Text('Save to file'),
          ),
          OutlinedButton.icon(
            key: const ValueKey('backup_load_file'),
            onPressed: () => _loadFile(context, ref),
            icon: const Icon(Icons.folder_open_rounded),
            label: const Text('Load from file'),
          ),
          TextButton.icon(
            key: const ValueKey('backup_export'),
            onPressed: () => _export(context, ref),
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Copy as text'),
          ),
          TextButton.icon(
            key: const ValueKey('backup_import'),
            onPressed: () => _import(context, ref),
            icon: const Icon(Icons.paste_rounded),
            label: const Text('Paste text'),
          ),
        ]),
      ]),
    );
  }

  Future<void> _saveFile(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final saved = await BackupFile.export(ref.read(backupServiceProvider).export());
      if (saved) {
        messenger
          ..clearSnackBars()
          ..showSnackBar(const SnackBar(content: Text('Backup file ready.')));
      }
    } catch (_) {
      messenger.showSnackBar(const SnackBar(
          content: Text('Could not save a file. Try Copy as text instead.')));
    }
  }

  Future<void> _loadFile(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final text = await BackupFile.pick();
      if (text == null) return;
      if (context.mounted) {
        final ok = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Replace progress?'),
            content: const Text('Restoring replaces the XP, streaks and levels on this device.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Restore')),
            ],
          ),
        );
        if (ok != true) return;
      }
      await ref.read(backupServiceProvider).import(text);
      messenger
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('Progress restored.')));
    } on engine.BackupException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } on FormatException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(
          content: Text('Could not read that file. Check it and try again.')));
    }
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await Clipboard.setData(ClipboardData(text: ref.read(backupServiceProvider).export()));
      messenger
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('Backup copied. Paste it somewhere safe.')));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('Could not create the backup.')));
    }
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Restore backup'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Paste a backup below. This replaces the progress on this device.'),
          const SizedBox(height: DesignSystem.spaceSM),
          TextField(
            key: const ValueKey('backup_text'),
            controller: controller,
            maxLines: 5,
            decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Paste backup text'),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () async {
                final data = await Clipboard.getData(Clipboard.kTextPlain);
                if (data?.text != null) controller.text = data!.text!;
              },
              icon: const Icon(Icons.paste_rounded),
              label: const Text('Paste from clipboard'),
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (text == null || text.trim().isEmpty) return;
    try {
      await ref.read(backupServiceProvider).import(text);
      messenger
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('Progress restored.')));
    } on engine.BackupException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('Restore failed. Check the backup and try again.')));
    }
  }
}
