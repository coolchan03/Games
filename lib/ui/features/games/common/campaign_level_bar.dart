import 'dart:async';

import 'package:flutter/material.dart';

import 'campaign_progress.dart';

/// Number of numbered levels every level-based added game provides.
const campaignLevelCount = 20;

/// Level selector shared by the added puzzle campaigns.
///
/// Shows a numbered dropdown (completed levels are ticked), previous/next
/// arrows, and a "Next level" button once [solved]. Completion and the
/// selected level are stored offline through [CampaignProgress] under
/// [gameId]; the owning screen only has to rebuild its puzzle in
/// [onLevel].
class CampaignLevelBar extends StatefulWidget {
  const CampaignLevelBar({
    super.key,
    required this.gameId,
    required this.level,
    required this.solved,
    required this.onLevel,
    this.describe,
    this.count = campaignLevelCount,
  });

  final String gameId;
  final int level;
  final bool solved;
  final ValueChanged<int> onLevel;

  /// Short description of a level, e.g. "5×5".
  final String Function(int level)? describe;
  final int count;

  /// The level to open with: the one last selected, or level 1.
  static int initialLevel(String gameId, {int count = campaignLevelCount}) =>
      CampaignProgress.selectedLevel(gameId, count: count);

  @override
  State<CampaignLevelBar> createState() => _CampaignLevelBarState();
}

class _CampaignLevelBarState extends State<CampaignLevelBar> {
  late Set<int> completed =
      CampaignProgress.load(widget.gameId, maxLevel: widget.count);

  @override
  void initState() {
    super.initState();
    if (widget.solved) _record();
  }

  @override
  void didUpdateWidget(CampaignLevelBar old) {
    super.didUpdateWidget(old);
    if (widget.solved && (!old.solved || old.level != widget.level)) _record();
  }

  void _record() {
    if (completed.contains(widget.level)) return;
    completed = {...completed, widget.level};
    unawaited(CampaignProgress.save(widget.gameId, completed));
  }

  void _select(int level) {
    if (level < 1 || level > widget.count) return;
    unawaited(CampaignProgress.saveSelected(widget.gameId, level));
    widget.onLevel(level);
  }

  String _label(int n) {
    final detail = widget.describe?.call(n);
    return detail == null ? 'Level $n' : 'Level $n · $detail';
  }

  @override
  Widget build(BuildContext context) {
    final level = widget.level;
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
          '${completed.length} of ${widget.count} levels completed',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (widget.solved && level < widget.count)
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
