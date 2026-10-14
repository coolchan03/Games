import 'package:flutter/material.dart';

/// Shared navigation, readable width, status and rules for the classics library.
class GamePage extends StatelessWidget {
  final String title, rules;
  final String? status, saveStatus;
  final List<Widget> children;
  final List<Widget> actions;
  const GamePage({super.key, required this.title, required this.rules,
    required this.children, this.status, this.saveStatus, this.actions = const []});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: [
        ...actions,
        IconButton(tooltip: 'Rules', icon: const Icon(Icons.help_outline),
          onPressed: () => showDialog<void>(context: context, builder: (ctx) =>
            AlertDialog(title: Text('$title rules'),
              content: SingleChildScrollView(child: Text(rules)),
              actions: [TextButton(onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'))]))),
      ]),
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 850),
        child: ListView(padding: const EdgeInsets.all(16), children: [
          if (status != null) Semantics(liveRegion: true, child: Card(
            color: colors.secondaryContainer,
            child: Padding(padding: const EdgeInsets.all(16),
              child: Text(status!, style: Theme.of(context).textTheme.titleMedium)))),
          if (saveStatus != null) Padding(padding: const EdgeInsets.all(8),
            child: Text(saveStatus!, style: Theme.of(context).textTheme.bodySmall)),
          ...children,
          const SizedBox(height: 24),
        ]),
      ))),
    );
  }
}

class GameSection extends StatelessWidget {
  final String title;
  final Widget child;
  const GameSection({super.key, required this.title, required this.child});
  @override
  Widget build(BuildContext context) => Card(child: Padding(
    padding: const EdgeInsets.all(16), child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12), child,
      ])));
}
