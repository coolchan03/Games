import 'dart:math';
import 'package:flutter/material.dart';
import '../shared/game_page.dart';
import '../shared/game_storage.dart';
import '../shared/card_face.dart';
import 'poker_evaluator.dart';
import 'poker_table.dart';

class PokerScreen extends StatefulWidget {
  final PokerVariant variant;
  const PokerScreen({super.key, this.variant = PokerVariant.holdem});
  @override
  State<PokerScreen> createState() => _PokerScreenState();
}
class _PokerScreenState extends State<PokerScreen> {
  late PokerTable game;
  final random = Random();
  final Set<int> discards = {};
  bool ready = false, revealed = false, vsComputer = true, thinking = false;
  int epoch = 0;
  String saveStatus = 'Loading local table...';
  String get saveKey => 'poker_${widget.variant.name}';
  @override
  void initState() {
    super.initState();
    game = PokerTable(variant: widget.variant);
    restore();
  }
  Future<void> restore() async {
    try {
      final data = await GameStorage.load(saveKey);
      if (!mounted) return;
      if (data != null) {
        final restored = PokerTable.fromJson(Map<String, dynamic>.from(data['table'] as Map));
        if (restored.variant != widget.variant) throw const FormatException('Wrong table variant');
        game = restored;
        vsComputer = data['vsComputer'] == true && game.seats == 2;
      }
      saveStatus = data == null ? 'Virtual chips only; saved locally' : 'Table restored; cards remain hidden';
    } catch (_) { saveStatus = 'Save unavailable or invalid; starting a new table'; }
    if (!mounted) return;
    setState(() => ready = true);
    await runComputer();
  }
  Future<void> save() async {
    try {
      await GameStorage.save(saveKey, {'table': game.toJson(), 'vsComputer': vsComputer});
      if (mounted) setState(() => saveStatus = 'Saved on this device - virtual chips only');
    } catch (_) {
      if (mounted) setState(() => saveStatus = 'Could not save; keep this table open');
    }
  }
  void apply(PokerAction action) {
    if (!ready || thinking || (!revealed && !game.ended)) return;
    setState(() { game.act(action); revealed = false; discards.clear(); });
    save(); runComputer();
  }
  void draw() {
    if (!ready || thinking || !revealed) return;
    setState(() { game.replaceCards(discards); revealed = false; discards.clear(); });
    save(); runComputer();
  }
  Future<void> runComputer() async {
    if (!mounted || !ready || !vsComputer || game.current != 1 || game.ended || thinking) return;
    final token = ++epoch;
    setState(() => thinking = true);
    try {
      for (var steps = 0; steps < 20 && game.current == 1 && !game.ended; steps++) {
        await Future<void>.delayed(const Duration(milliseconds: 220));
        if (!mounted || token != epoch) return;
        setState(() {
          if (game.phase == PokerPhase.draw) { game.replaceCards(pokerBotDiscards(game.hands[1])); }
          else { game.act(pokerBotAction(game, random)); }
        });
      }
      if (!mounted || token != epoch) return;
      setState(() => thinking = false);
      await save();
    } catch (_) {
      if (mounted && token == epoch) setState(() {
        thinking = false; saveStatus = 'Computer turn failed; start a new table to recover';
      });
    }
  }
  void newTable(int seats, bool computer) {
    epoch++;
    setState(() {
      game = PokerTable(variant: widget.variant, seats: seats, random: random);
      vsComputer = computer; thinking = false; revealed = false; discards.clear();
    });
    save(); runComputer();
  }
  void nextHand() {
    epoch++;
    setState(() { game = game.nextHand(random); thinking = false; revealed = false; discards.clear(); });
    save(); runComputer();
  }
  @override
  void dispose() { epoch++; super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final drawing = game.phase == PokerPhase.draw;
    final canAct = ready && !thinking && !game.ended && revealed;
    final title = widget.variant == PokerVariant.holdem ? "Texas Hold'em" : 'Five Card Draw';
    return GamePage(title: title,
      rules: "Offline fixed-limit practice with virtual chips, not real money. Hold'em uses blinds 5/10 and bets of 10 before/on the flop, 20 on the turn/river. Draw uses a 10-chip ante, five private cards, one draw of up to three cards, and bets of 10 then 20. Up to three raises per betting round. A raise must be fully affordable; short stacks can call all-in. Main and side pots are awarded independently, ties split, and odd chips go clockwise after the dealer. Local play supports 2-6 people; computer mode is heads-up with a casual opponent that sees only its own cards and the board. Hand rankings: straight flush, four of a kind, full house, flush, straight, three of a kind, two pair, pair, high card. Best five cards count. Cards are hidden between local turns and after resume.",
      status: game.ended ? game.result : '${game.phaseLabel} - ${thinking ? 'Computer thinking' : 'Player ${game.current + 1} to act'} - pot ${game.pot}',
      saveStatus: saveStatus,
      actions: [IconButton(tooltip: 'New game', icon: const Icon(Icons.restart_alt),
        onPressed: ready ? () => newTable(game.seats, vsComputer) : null)],
      children: [
        DropdownButton<String>(isExpanded: true,
          value: vsComputer ? 'computer' : '${game.seats}',
          items: [const DropdownMenuItem(value: 'computer', child: Text('You vs casual computer')),
            for (final n in [2, 3, 4, 5, 6]) DropdownMenuItem(value: '$n', child: Text('$n local players'))],
          onChanged: !ready || thinking ? null : (value) {
            if (value != null) newTable(value == 'computer' ? 2 : int.parse(value), value == 'computer');
          }),
        const Text('Changing player mode starts a new 200-chip table.'),
        if (widget.variant == PokerVariant.holdem) GameSection(title: 'Community cards', child:
          Wrap(spacing: 8, runSpacing: 8, children: [for (var i = 0; i < 5; i++)
            CardFace(card: i < game.community.length ? game.community[i] : null)])),
        for (var seat = 0; seat < game.seats; seat++) GameSection(
          title: 'Player ${seat + 1}${vsComputer && seat == 1 ? ' (computer)' : ''}${seat == game.dealer ? ' - dealer' : ''}: ${game.stacks[seat]} chips${game.folded[seat] ? ' - folded/out' : ''}',
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(spacing: 8, runSpacing: 8, children: [for (var i = 0; i < game.hands[seat].length; i++)
              CardFace(card: game.hands[seat][i],
                hidden: !(game.showCards && !game.folded[seat]) &&
                  !(ready && revealed && !thinking && !game.ended && seat == game.current),
                selected: drawing && seat == game.current && discards.contains(i),
                onTap: canAct && drawing && seat == game.current ? () => setState(() {
                  if (!discards.remove(i) && discards.length < 3) discards.add(i);
                }) : null),
            ]),
            if (game.showCards && !game.folded[seat]) Padding(padding: const EdgeInsets.only(top: 8),
              child: Text(evaluatePoker([...game.hands[seat], ...game.community]).name)),
          ])),
        if (!game.ended && !thinking && ready && !revealed) FilledButton.icon(
          onPressed: () => setState(() => revealed = true), icon: const Icon(Icons.visibility),
          label: Text('View Player ${game.current + 1} cards')),
        if (canAct && drawing) ...[
          Text('Tap up to three cards to replace. Selected: ${discards.length}/3.'),
          FilledButton(onPressed: draw, child: Text(discards.isEmpty ? 'Stand pat' : 'Replace ${discards.length} cards')),
        ],
        if (canAct && !drawing) Wrap(spacing: 8, runSpacing: 8, children: [
          FilledButton(onPressed: () => apply(PokerAction.checkCall),
            child: Text(game.toCall == 0 ? 'Check' : 'Call ${min(game.toCall, game.stacks[game.current])}${game.toCall >= game.stacks[game.current] ? ' (all-in)' : ''}')),
          OutlinedButton(onPressed: game.canRaise ? () => apply(PokerAction.raise) : null,
            child: Text('Raise ${game.betSize}')),
          OutlinedButton(onPressed: () => apply(PokerAction.fold), child: const Text('Fold')),
        ]),
        const SizedBox(height: 16),
        Wrap(spacing: 8, runSpacing: 8, children: [
          if (game.ended && game.stacks.where((n) => n > 0).length > 1)
            FilledButton(onPressed: nextHand, child: const Text('Next hand')),
          OutlinedButton(onPressed: ready ? () => newTable(game.seats, vsComputer) : null,
            child: const Text('New table')),
        ]),
        GameSection(title: 'Action log', child: Text(game.log.isEmpty ? 'Cards dealt' : game.log.reversed.take(12).toList().reversed.join('\n'))),
      ]);
  }
}
