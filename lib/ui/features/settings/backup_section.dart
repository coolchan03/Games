import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puzzle/domain/progress_engine.dart' as engine;
import 'package:puzzle/providers/progress_providers.dart';
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
            key: const ValueKey('backup_export'),
            onPressed: () => _export(context, ref),
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Copy backup'),
          ),
          OutlinedButton.icon(
            key: const ValueKey('backup_import'),
            onPressed: () => _import(context, ref),
            icon: const Icon(Icons.restore_rounded),
            label: const Text('Restore backup'),
          ),
        ]),
      ]),
    );
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
