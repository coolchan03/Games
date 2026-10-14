import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/library_style_provider.dart';

class LibraryStyleSelector extends ConsumerWidget {
  const LibraryStyleSelector({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setting = ref.watch(libraryStyleProvider);
    const descriptions = {
      LibraryStyle.classic: 'Classic - familiar neutral surfaces',
      LibraryStyle.compact: 'Compact - tighter spacing, full-size controls',
      LibraryStyle.colorful: 'Colorful - blue-green surfaces and accents',
    };
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SizedBox(height: 20),
      Text('Visual style', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      for (final entry in descriptions.entries) Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: OutlinedButton(
          onPressed: () => ref.read(libraryStyleProvider.notifier).choose(entry.key),
          child: Row(children: [
            Icon(setting.style == entry.key ? Icons.check_circle : Icons.circle_outlined),
            const SizedBox(width: 12), Expanded(child: Text(entry.value)),
          ]))),
      if (setting.error != null) Text(setting.error!),
    ]);
  }
}
