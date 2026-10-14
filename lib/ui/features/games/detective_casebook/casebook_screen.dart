import 'package:flutter/material.dart';
import '../shared/game_page.dart';
import '../shared/game_storage.dart';
import 'casebook_engine.dart';
import 'case_progress.dart';

class DetectiveCasebookScreen extends StatefulWidget {
  const DetectiveCasebookScreen({super.key});
  @override
  State<DetectiveCasebookScreen> createState() => _DetectiveCasebookScreenState();
}
class _DetectiveCasebookScreenState extends State<DetectiveCasebookScreen> {
  int caseIndex = 0;
  CaseDifficulty difficulty = CaseDifficulty.standard;
  bool daily = false, ready = false;
  String notebookTab = 'Rooms', saveStatus = 'Loading notebook...', message = '';
  final Map<String, dynamic> sessions = {};
  late DetectiveCase game;
  CaseProgress progress = CaseProgress();
  String get keyName => '${game.id}/${difficulty.name}';
  @override
  void initState() { super.initState(); game = DetectiveCasebook.cases.first; restore(); }
  void selectGame() {
    game = daily ? DetectiveCasebook.daily(DateTime.now(), difficulty) : DetectiveCasebook.caseAt(caseIndex, difficulty);
    final saved = sessions[keyName];
    try {
      progress = saved == null ? CaseProgress() : CaseProgress.fromJson(Map<String, dynamic>.from(saved as Map), game);
      message = '';
    } catch (_) { progress = CaseProgress(); message = 'This notebook was invalid and has been reset.'; }
  }
  Future<void> restore() async {
    try {
      final data = await GameStorage.load('detective_notebooks');
      if (!mounted) return;
      if (data != null) {
        if (data['version'] != 1) throw const FormatException('Unsupported casebook save');
        sessions.addAll(Map<String, dynamic>.from(data['sessions'] as Map));
        caseIndex = (data['caseIndex'] as int).clamp(0, DetectiveCasebook.cases.length - 1);
        difficulty = CaseDifficulty.values.byName(data['difficulty'] as String);
        daily = data['daily'] == true;
      }
      selectGame(); saveStatus = data == null ? 'Notes save on this device' : 'Notebook restored';
    } catch (_) { saveStatus = 'Save unavailable; notes remain in this session'; }
    if (mounted) setState(() => ready = true);
  }
  Future<void> save() async {
    sessions[keyName] = progress.toJson();
    try {
      await GameStorage.save('detective_notebooks', {'version': 1, 'sessions': sessions,
        'caseIndex': caseIndex, 'difficulty': difficulty.name, 'daily': daily});
      if (mounted) setState(() => saveStatus = 'Notebook saved on this device');
    } catch (_) { if (mounted) setState(() => saveStatus = 'Could not save; keep the casebook open'); }
  }
  void switchCase(VoidCallback change) {
    sessions[keyName] = progress.toJson();
    setState(() { change(); selectGame(); }); save();
  }
  void changeProgress(VoidCallback change) { setState(change); save(); }
  Future<void> reveal() async {
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Reveal this case?'), content: const Text('A revealed case will not be counted as solved.'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep investigating')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reveal'))]));
    if (mounted && confirmed == true) changeProgress(() { progress.revealed = true; progress.solved = false; });
  }
  String get hintText => switch (progress.hints) {
    0 => 'Hints are optional. Begin by linking the incident item to a room or time.',
    1 => 'Track the ${game.incidentObject.toLowerCase()} through the item and timing clues.',
    2 => 'The incident-item carrier visited the ${game.rooms[game.incidentRoomIndex]}.',
    _ => 'The incident-item carrier arrived at ${game.times[game.incidentTimeIndex]}.',
  };
  Widget notebook() {
    final values = notebookTab == 'Rooms' ? game.rooms : notebookTab == 'Times' ? game.times : game.objects;
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.5);
    final colors = Theme.of(context).colorScheme;
    return GameSection(title: 'Logic notebook', child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(spacing: 8, runSpacing: 8, children: [for (final tab in ['Rooms', 'Times', 'Objects'])
        ChoiceChip(label: Text(tab), selected: notebookTab == tab,
          onSelected: (_) => setState(() => notebookTab = tab))]),
      const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Tap a cell: unknown, excluded, confirmed. Each row and column has one match.')),
      SingleChildScrollView(scrollDirection: Axis.horizontal, child: Column(children: [
        Row(children: [SizedBox(width: 145 * scale), for (final value in values)
          SizedBox(width: 115 * scale, height: 80 * scale, child: Center(child: Text(value, textAlign: TextAlign.center)))]),
        for (var person = 0; person < 4; person++) Row(children: [
          SizedBox(width: 145 * scale, child: Text(game.suspects[person])),
          for (var value = 0; value < 4; value++) Builder(builder: (context) {
            final key = '$notebookTab/$person/$value', state = progress.notes['$notebookTab/$person/$value'] ?? 0;
            final description = '${game.suspects[person]} and ${values[value]}: ${['unknown', 'excluded', 'confirmed'][state]}';
            return SizedBox(width: 115 * scale, height: 58 * scale, child: Padding(padding: const EdgeInsets.all(3),
              child: Semantics(label: description, button: true, excludeSemantics: true,
                child: OutlinedButton(onPressed: ready ? () => changeProgress(() => progress.cycle(key)) : null,
                  style: OutlinedButton.styleFrom(backgroundColor: state == 2 ? colors.primaryContainer : null),
                  child: Icon(state == 0 ? Icons.remove : state == 1 ? Icons.close : Icons.check)))));
          }),
        ]),
      ])),
    ]));
  }
  Widget answer(String label, List<String> values, String? selected, ValueChanged<String?> change) =>
    DropdownButtonFormField<String>(initialValue: selected, key: ValueKey('$keyName/$label/$selected'),
      isExpanded: true, decoration: InputDecoration(labelText: label),
      items: [for (final value in values) DropdownMenuItem(value: value, child: Text(value, overflow: TextOverflow.ellipsis))],
      onChanged: ready && !progress.revealed && !progress.solved ? (value) => changeProgress(() => change(value)) : null);
  @override
  Widget build(BuildContext context) => GamePage(title: 'Detective Casebook',
    rules: 'Each suspect visited one different room, arrived at one different time and carried one different item. Every displayed clue is true; the complete assignment has exactly one solution. Deduce the carrier of the incident item, their room and their arrival time. Notes and checked clues are saved separately for each case and difficulty. Easy adds direct facts; Standard mixes direct and relational clues; Hard uses only indirect clues with redundant clues removed. Daily cases use the local calendar date. Revealing an answer is recorded separately from solving it.',
    status: progress.solved ? 'Case solved' : progress.revealed ? 'Answer revealed - not counted as solved' : game.title,
    saveStatus: saveStatus, children: [
      SwitchListTile(title: const Text('Daily mystery'), subtitle: const Text('A seeded case for today'),
        value: daily, onChanged: ready ? (value) => switchCase(() => daily = value) : null),
      if (!daily) DropdownButton<int>(isExpanded: true, value: caseIndex,
        items: [for (var i = 0; i < DetectiveCasebook.cases.length; i++)
          DropdownMenuItem(value: i, child: Text('${i + 1}. ${DetectiveCasebook.cases[i].title}', overflow: TextOverflow.ellipsis))],
        onChanged: !ready ? null : (value) { if (value != null) switchCase(() => caseIndex = value); }),
      Wrap(spacing: 8, runSpacing: 8, children: [for (final level in CaseDifficulty.values)
        ChoiceChip(label: Text(level.name[0].toUpperCase() + level.name.substring(1)), selected: difficulty == level,
          onSelected: !ready ? null : (_) => switchCase(() => difficulty = level))]),
      GameSection(title: 'The case', child: Text(game.summary)),
      GameSection(title: 'Evidence - ${game.clues.length} clues', child: Column(children: [
        for (var i = 0; i < game.clues.length; i++) CheckboxListTile(contentPadding: EdgeInsets.zero,
          title: Text(game.clues[i].text), value: progress.checked.contains(i),
          onChanged: !ready ? null : (value) => changeProgress(() {
            if (value == true) progress.checked.add(i); else progress.checked.remove(i);
          })),
      ])),
      notebook(),
      GameSection(title: 'Your conclusion', child: Column(children: [
        answer('Suspect', game.suspects, progress.accusation, (value) => progress.accusation = value),
        answer('Room', game.rooms, progress.room, (value) => progress.room = value),
        answer('Arrival time', game.times, progress.time, (value) => progress.time = value),
        const SizedBox(height: 16),
        FilledButton(onPressed: !ready || progress.solved || progress.revealed || progress.accusation == null || progress.room == null || progress.time == null
          ? null : () => changeProgress(() => message = progress.submit(game) ? 'Your full conclusion matches every clue.' : 'That conclusion conflicts with the evidence. Review the room and time links.'),
          child: const Text('Submit conclusion')),
        if (message.isNotEmpty) Padding(padding: const EdgeInsets.all(8), child: Text(message)),
      ])),
      GameSection(title: 'Hints (${progress.hints}/3)', child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(hintText), const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          OutlinedButton(onPressed: ready && progress.hints < 3 && !progress.solved && !progress.revealed
            ? () => changeProgress(() => progress.hints++) : null, child: const Text('Next hint')),
          TextButton(onPressed: ready && !progress.solved && !progress.revealed ? reveal : null, child: const Text('Reveal answer')),
        ]),
      ])),
      if (progress.solved || progress.revealed) GameSection(title: 'Case resolution', child: Text(
        '${game.culprit} carried the ${game.incidentObject.toLowerCase()} in the ${game.rooms[game.incidentRoomIndex]} at ${game.times[game.incidentTimeIndex]}.')),
    ]);
}
