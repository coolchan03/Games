import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/ui_scale_provider.dart';
import '../utils/design_system.dart';
import 'tangible.dart';

/// Picks the interface size; the sample line updates live.
class UiSizeSelector extends ConsumerWidget {
  const UiSizeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(uiSizeProvider);
    final theme = Theme.of(context);
    return TangibleContainer(
      padding: const EdgeInsets.all(DesignSystem.spaceMD),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Interface size', style: theme.textTheme.titleMedium),
        const SizedBox(height: DesignSystem.spaceXS),
        Text('Makes text and labels larger across the whole app, games included.',
            style: theme.textTheme.bodySmall),
        const SizedBox(height: DesignSystem.spaceSM),
        Wrap(spacing: DesignSystem.spaceSM, runSpacing: DesignSystem.spaceSM, children: [
          for (final size in UiSize.values)
            ChoiceChip(
              key: ValueKey('ui_size_${size.name}'),
              label: Text(size.label),
              selected: size == selected,
              onSelected: (_) => ref.read(uiSizeProvider.notifier).choose(size),
            ),
        ]),
      ]),
    );
  }
}
