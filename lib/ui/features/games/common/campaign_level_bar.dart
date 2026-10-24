import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'campaign_progress.dart';

/// Number of numbered levels every level-based added game provides.
const campaignLevelCount = 20;

/// How well a level was solved: a score (moves, guesses, points…) and
/// 1–3 stars.
class CampaignResult {
  const CampaignResult({
    required this.score,
    required this.stars,
    required this.label,
    this.lowerIsBetter = true,
  });

  final int score;
  final int stars;

  /// Describes a score, e.g. `(s) => '$s moves'`.
  final String Function(int score) label;
  final bool lowerIsBetter;
}

/// Stars for a score against a par: within [par] → 3, within twice → 2.
int starsForPar(int score, int par) =>
    score <= par ? 3 : score <= par * 2 ? 2 : 1;

/// Level selector shared by the added puzzle campaigns.
///
/// Shows a numbered dropdown (completed levels show their stars),
/// previous/next arrows and, once [solved], a "Level complete" card with
/// the result and a "Next level" button. Completion, the selected level,
/// best results and the unfinished [activeState] are stored offline through
/// [CampaignProgress] under [gameId]; the owning screen only has to rebuild
/// its puzzle in [onLevel] and restore with [restoreActive].
class CampaignLevelBar extends StatefulWidget {
  const CampaignLevelBar({
    super.key,
    required this.gameId,
    required this.level,
    required this.solved,
    required this.onLevel,
    this.describe,
    this.count = campaignLevelCount,
    this.activeState,
    this.result,
  });

  final String gameId;
  final int level;
  final bool solved;
  final ValueChanged<int> onLevel;

  /// Short description of a level, e.g. "5×5".
  final String Function(int level)? describe;
  final int count;

  /// Snapshot of the unfinished puzzle, saved whenever it changes so the
  /// level can be resumed later. Cleared when the level is solved.
  final List<int>? activeState;

  /// The result to record once [solved].
  final CampaignResult? result;

  /// The level to open with: the one last selected, or level 1.
  static int initialLevel(String gameId, {int count = campaignLevelCount}) =>
      CampaignProgress.selectedLevel(gameId, count: count);

  /// The saved unfinished state for [level], if any. Screens must validate
  /// it against the regenerated level before using it.
  static List<int>? restoreActive(String gameId, int level,
          {int maxLength = 4096}) =>
      CampaignProgress.loadActive(gameId, level, maxLength: maxLength);

  @override
  State<CampaignLevelBar> createState() => _CampaignLevelBarState();
}

class _CampaignLevelBarState extends State<CampaignLevelBar> {
  late Set<int> completed =
      CampaignProgress.load(widget.gameId, maxLevel: widget.count);
  late Map<int, (int, int)> results =
      CampaignProgress.loadResults(widget.gameId);
  List<int>? _savedState;

  /// The result just achieved, shown in the "Level complete" card.
  CampaignResult? _justWon;

  @override
  void initState() {
    super.initState();
    if (widget.solved) _record(celebrate: false);
    _autosave();
  }

  @override
  void didUpdateWidget(CampaignLevelBar old) {
    super.didUpdateWidget(old);
    if (old.level != widget.level) {
      _justWon = null;
      _savedState = null;
    }
    if (widget.solved && (!old.solved || old.level != widget.level)) {
      _record(celebrate: old.level == widget.level);
    }
    _autosave();
  }

  void _autosave() {
    if (widget.solved) {
      if (_savedState != null || widget.activeState != null) {
        _savedState = null;
        unawaited(CampaignProgress.clearActive(widget.gameId, widget.level));
      }
      return;
    }
    final state = widget.activeState;
    if (state == null || listEquals(state, _savedState)) return;
    _savedState = List.of(state);
    unawaited(CampaignProgress.saveActive(widget.gameId, widget.level, state));
  }

  void _record({required bool celebrate}) {
    if (!completed.contains(widget.level)) {
      completed = {...completed, widget.level};
      unawaited(CampaignProgress.save(widget.gameId, completed));
    }
    final r = widget.result;
    if (r != null) {
      results = CampaignProgress.recordResult(widget.gameId, widget.level,
          stars: r.stars, score: r.score, lowerIsBetter: r.lowerIsBetter);
    }
    if (celebrate) _justWon = r ?? const CampaignResult(score: 0, stars: 3, label: _noLabel);
  }

  static String _noLabel(int _) => '';

  void _select(int level) {
    if (level < 1 || level > widget.count) return;
    unawaited(CampaignProgress.saveSelected(widget.gameId, level));
    widget.onLevel(level);
  }

  String _label(int n) {
    final detail = widget.describe?.call(n);
    return detail == null ? 'Level $n' : 'Level $n · $detail';
  }

  Widget _stars(int count, {double size = 16}) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            Icon(
              i < count ? Icons.star_rounded : Icons.star_outline_rounded,
              size: size,
              color: i < count ? const Color(0xFFFFB300) : Colors.grey,
            ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final level = widget.level;
    final theme = Theme.of(context);
    final best = results[level];
    final won = widget.solved ? _justWon : null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          IconButton(
            tooltip: 'Previous level',
            onPressed: level > 1 ? () => _select(level - 1) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: DropdownButton<int>(
              key: ValueKey('${widget.gameId}_level_selector'),
              isExpanded: true,
              value: level,
              items: [
                for (var n = 1; n <= widget.count; n++)
                  DropdownMenuItem(
                    value: n,
                    child: Row(children: [
                      if (results[n] != null)
                        Semantics(
                          label: '${results[n]!.$1} stars',
                          child: _stars(results[n]!.$1, size: 14),
                        )
                      else
                        Icon(
                          completed.contains(n)
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          size: 18,
                          semanticLabel:
                              completed.contains(n) ? 'Completed' : null,
                        ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(_label(n), overflow: TextOverflow.ellipsis),
                      ),
                    ]),
                  ),
              ],
              onChanged: (n) {
                if (n != null) _select(n);
              },
            ),
          ),
          IconButton(
            tooltip: 'Next level',
            onPressed: level < widget.count ? () => _select(level + 1) : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ]),
        Text(
          '${completed.length} of ${widget.count} levels completed'
          '${best != null && widget.result != null ? ' · best ${widget.result!.label(best.$2)}' : ''}',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall,
        ),
        if (won != null)
          Card(
            key: ValueKey('${widget.gameId}_level_complete'),
            margin: const EdgeInsets.only(top: 8),
            color: theme.colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('Level $level complete!',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                if (widget.result != null) ...[
                  _stars(won.stars, size: 30),
                  Text(widget.result!.label(won.score),
                      style: theme.textTheme.bodyMedium),
                ],
                if (level < widget.count) ...[
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    key: ValueKey('${widget.gameId}_next_level'),
                    onPressed: () => _select(level + 1),
                    icon: const Icon(Icons.skip_next),
                    label: Text('Next level (${level + 1})'),
                  ),
                ] else
                  const Text('You finished every level!'),
              ]),
            ),
          )
        else if (widget.solved && level < widget.count)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: FilledButton.icon(
              key: ValueKey('${widget.gameId}_next_level'),
              onPressed: () => _select(level + 1),
              icon: const Icon(Icons.skip_next),
              label: Text('Next level (${level + 1})'),
            ),
          ),
      ],
    );
  }
}
