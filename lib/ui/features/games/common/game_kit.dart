import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers/user_providers.dart';

/// Records a win/completion in the app's streak and XP system. Safe to call
/// where no ProviderScope or storage is available (it then does nothing).
void reportCompletion(BuildContext context, String gameId) {
  try {
    final container = ProviderScope.containerOf(context, listen: false);
    container
        .read(gameStreakNotifierProvider.notifier)
        .completeGame(gameId)
        .catchError((Object _) => false);
  } catch (_) {
    // No provider scope (e.g. widget tests): nothing to record.
  }
}

/// Calls [reportCompletion] once each time [completed] turns true.
class _CompletionReporter extends StatefulWidget {
  const _CompletionReporter(
      {required this.gameId, required this.completed, required this.child});
  final String gameId;
  final bool completed;
  final Widget child;
  @override
  State<_CompletionReporter> createState() => _CompletionReporterState();
}

class _CompletionReporterState extends State<_CompletionReporter> {
  @override
  void initState() {
    super.initState();
    if (widget.completed) _report();
  }

  @override
  void didUpdateWidget(_CompletionReporter old) {
    super.didUpdateWidget(old);
    if (widget.completed && !old.completed) _report();
  }

  void _report() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) reportCompletion(context, widget.gameId);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Shows a "no moves left" dialog once each time [deadEnd] turns true,
/// offering Undo (when available) or a new game.
class _DeadEndWatcher extends StatefulWidget {
  const _DeadEndWatcher({
    required this.deadEnd,
    required this.message,
    required this.onNewGame,
    required this.onUndo,
    required this.child,
  });
  final bool deadEnd;
  final String message;
  final VoidCallback onNewGame;
  final VoidCallback? onUndo;
  final Widget child;
  @override
  State<_DeadEndWatcher> createState() => _DeadEndWatcherState();
}

class _DeadEndWatcherState extends State<_DeadEndWatcher> {
  @override
  void didUpdateWidget(_DeadEndWatcher old) {
    super.didUpdateWidget(old);
    if (widget.deadEnd && !old.deadEnd) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.deadEnd) _show();
      });
    }
  }

  void _show() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        key: const ValueKey('dead_end_dialog'),
        icon: const Icon(Icons.block_rounded),
        title: const Text('No moves left'),
        content: Text(widget.message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Look at the board'),
          ),
          if (widget.onUndo != null)
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onUndo!();
              },
              icon: const Icon(Icons.undo),
              label: const Text('Undo'),
            ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onNewGame();
            },
            icon: const Icon(Icons.restart_alt_rounded),
            label: const Text('New deal'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Shared layout for the board, card and dice games added to Games.
///
/// Every game gets the same app bar (rules + new game), a centred column
/// constrained to a phone-friendly width, and the same status banner.
class GameScaffold extends StatelessWidget {
  const GameScaffold({
    super.key,
    required this.title,
    required this.rules,
    required this.onNewGame,
    required this.children,
    this.maxWidth = 640,
    this.scrollable = true,
    this.gameId,
    this.completed = false,
    this.deadEnd = false,
    this.deadEndMessage =
        'This game can no longer be finished. Undo some moves to try another '
        'line, or start a new deal.',
    this.onUndo,
  });

  final String title;
  final String rules;
  final VoidCallback onNewGame;
  final List<Widget> children;
  final double maxWidth;
  final bool scrollable;

  /// When set, a transition of [completed] to true is recorded as a solve
  /// for streaks and XP.
  final String? gameId;
  final bool completed;

  /// When this turns true the player is told no moves are left and offered
  /// [onUndo] (if given) or a new game.
  final bool deadEnd;
  final String deadEndMessage;
  final VoidCallback? onUndo;

  @override
  Widget build(BuildContext context) {
    final display = MediaQuery.sizeOf(context);
    final compactLandscape =
        display.width > display.height && display.height < 650;
    final content = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compactLandscape ? 8 : 16,
        vertical: compactLandscape ? 6 : 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
    final scaffold = Scaffold(
      appBar: AppBar(
        toolbarHeight: compactLandscape ? 44 : null,
        title: Text(title),
        actions: [
          IconButton(
            tooltip: 'Rules',
            icon: const Icon(Icons.menu_book_rounded),
            onPressed: () => showRules(context, title, rules),
          ),
          IconButton(
            tooltip: 'New game',
            icon: const Icon(Icons.restart_alt_rounded),
            onPressed: onNewGame,
          ),
        ],
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: compactLandscape
                  ? display.width
                  : contentWidthFor(display, maxWidth),
            ),
            child: scrollable ? SingleChildScrollView(child: content) : content,
          ),
        ),
      ),
    );
    final watched = _DeadEndWatcher(
      deadEnd: deadEnd && !completed,
      message: deadEndMessage,
      onNewGame: onNewGame,
      onUndo: onUndo,
      child: scaffold,
    );
    if (gameId == null) return watched;
    return _CompletionReporter(
        gameId: gameId!, completed: completed, child: watched);
  }
}

/// Width for a game's content column. Phones use [preferred]; tablets and
/// desktops use more of the screen: wide card layouts (preferred > 700)
/// grow with the width; in landscape, boards are sized so a square board
/// and its controls fit the screen height.
double contentWidthFor(Size display, double preferred) {
  final roomy = display.shortestSide >= 600 || display.width >= 900;
  if (!roomy) return preferred;
  final portrait = display.height >= display.width;
  if (portrait || preferred > 700) {
    return math.min(1400, math.max(preferred, display.width * .94));
  }
  // Landscape board: leave room for the controls above a square board.
  return math.min(1400, math.max(480, display.height - 220));
}

Future<void> showRules(BuildContext context, String title, String rules) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('How to play $title'),
      content: SingleChildScrollView(child: Text(rules)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Got it'),
        ),
      ],
    ),
  );
}

/// Large, centred status line ("Your move", "Black wins!").
class StatusBanner extends StatelessWidget {
  const StatusBanner(this.text, {super.key, this.highlight = false});

  final String text;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: highlight
            ? colors.primaryContainer
            : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: highlight ? colors.onPrimaryContainer : null,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

enum AiLevel { easy, medium, hard }

extension AiLevelLabel on AiLevel {
  String get label => switch (this) {
        AiLevel.easy => 'Easy',
        AiLevel.medium => 'Medium',
        AiLevel.hard => 'Hard',
      };
}

/// "Play against computer" switch plus Easy/Medium/Hard selector.
class OpponentPicker extends StatelessWidget {
  const OpponentPicker({
    super.key,
    required this.vsComputer,
    required this.level,
    required this.onChanged,
    this.allowTwoPlayer = true,
    this.showLevel = true,
  });

  final bool vsComputer;
  final AiLevel level;
  final void Function(bool vsComputer, AiLevel level) onChanged;
  final bool allowTwoPlayer;
  final bool showLevel;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (allowTwoPlayer)
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                  value: true,
                  icon: Icon(Icons.smart_toy_outlined),
                  label: Text('vs Computer')),
              ButtonSegment(
                  value: false,
                  icon: Icon(Icons.people_alt_outlined),
                  label: Text('2 Players')),
            ],
            selected: {vsComputer},
            onSelectionChanged: (s) => onChanged(s.first, level),
          ),
        if (vsComputer && showLevel) ...[
          const SizedBox(height: 8),
          SegmentedButton<AiLevel>(
            segments: [
              for (final l in AiLevel.values)
                ButtonSegment(value: l, label: Text(l.label)),
            ],
            selected: {level},
            onSelectionChanged: (s) => onChanged(vsComputer, s.first),
          ),
        ],
      ],
    );
  }
}

/// Square, tappable cell used by grid board games.
class BoardCell extends StatelessWidget {
  const BoardCell({
    super.key,
    required this.color,
    this.child,
    this.onTap,
    this.highlight = false,
    this.radius = 6,
  });

  final Color color;
  final Widget? child;
  final VoidCallback? onTap;
  final bool highlight;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(1),
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onTap,
          child: Container(
            decoration: highlight
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(radius),
                    border: Border.all(color: colors.primary, width: 3),
                  )
                : null,
            alignment: Alignment.center,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Round counter used for checkers-like pieces, Go stones, etc.
class Disc extends StatelessWidget {
  const Disc({super.key, required this.color, this.label, this.size = .78});

  final Color color;
  final String? label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final onColor =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
            ? Colors.white
            : Colors.black87;
    return FractionallySizedBox(
      widthFactor: size,
      heightFactor: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: const [
            BoxShadow(
                blurRadius: 2, offset: Offset(0, 1), color: Colors.black26),
          ],
        ),
        child: label == null
            ? null
            : Center(
                child: FittedBox(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Text(label!,
                        style: TextStyle(
                            color: onColor, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
      ),
    );
  }
}

/// Pip face for a six-sided die.
class DieFace extends StatelessWidget {
  const DieFace(this.value,
      {super.key, this.size = 52, this.held = false, this.onTap});

  final int value;
  final double size;
  final bool held;
  final VoidCallback? onTap;

  static const _pips = <int, List<Offset>>{
    1: [Offset(.5, .5)],
    2: [Offset(.25, .25), Offset(.75, .75)],
    3: [Offset(.25, .25), Offset(.5, .5), Offset(.75, .75)],
    4: [Offset(.25, .25), Offset(.75, .25), Offset(.25, .75), Offset(.75, .75)],
    5: [
      Offset(.25, .25),
      Offset(.75, .25),
      Offset(.5, .5),
      Offset(.25, .75),
      Offset(.75, .75)
    ],
    6: [
      Offset(.25, .22),
      Offset(.75, .22),
      Offset(.25, .5),
      Offset(.75, .5),
      Offset(.25, .78),
      Offset(.75, .78)
    ],
  };

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final pip = held ? colors.onPrimary : colors.onSurface;
    return Semantics(
      label: 'Die showing $value${held ? ', held' : ''}',
      button: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: size,
          height: size,
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: held ? colors.primary : colors.surface,
            borderRadius: BorderRadius.circular(size * .18),
            border: Border.all(color: colors.outline, width: 1.5),
          ),
          child: Stack(children: [
            for (final o in _pips[value.clamp(1, 6)]!)
              Positioned(
                left: o.dx * size - size * .08,
                top: o.dy * size - size * .08,
                child: Container(
                  width: size * .16,
                  height: size * .16,
                  decoration: BoxDecoration(color: pip, shape: BoxShape.circle),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}
