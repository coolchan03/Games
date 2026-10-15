import 'dart:math';
import 'package:flutter/material.dart';
import '../shared/card_face.dart';
import '../shared/playing_cards.dart';
import '../shared/game_page.dart';
import '../shared/game_storage.dart';
import '../shared/touch_cards.dart';
import 'nain_jaune_engine.dart';

class NainJauneScreen extends StatefulWidget {
  const NainJauneScreen({super.key});
  @override
  State<NainJauneScreen> createState() => _NainJauneScreenState();
}

class _NainJauneScreenState extends State<NainJauneScreen> {
  final rng = Random();
  late NainJauneGame game;
  bool ready = false, revealed = false, computer = true, thinking = false;
  int skill = 1, epoch = 0;
  String saveStatus = 'Loading the local table...';
  static const saveKey = 'nain_jaune_v1';
  static const rules =
      'Goal: collect the most chips by playing premium cards and emptying '
      'your hand. Each of 3–8 players starts with 100 virtual chips. '
      'At the start of each deal everyone puts 1, 2, 3, 4 and 5 chips '
      'into the five premium trays. The dealer gives out cards, leaving '
      'a face-down talon. The opening player may play any card. '
      'Continue ascending in rank regardless of suit: Ace, 2, 3... '
      'Jack, Queen, King. Whoever holds the next rank gets the turn. '
      'If nobody holds that rank, the last player starts a fresh run. '
      'A King ends a run and allows another lead. Playing the exact '
      'premium card takes its tray: 10♦, J♣, Q♠, K♥ or 7♦ (Yellow Dwarf). '
      'The first player to empty their hand wins the deal and collects '
      'the pip values of opponents remaining cards (face cards count 10). '
      'Players still holding premium cards pay twice that tray into it, '
      'up to their available chips. An uninterrupted all-card run is '
      'a Grand Opera and sweeps the remaining trays. Trays carry forward '
      'for up to five deals. This table has no real money or online play. '
      'Controls: tap a card, or hold it then drag it to the drop area. '
      'Only legal cards are highlighted. During local pass-and-play, '
      'each player reveals only their own hand.';

  @override
  void initState() {
    super.initState();
    game = NainJauneGame(random: rng);
    _restore();
  }

  Future<void> _restore() async {
    try {
      final data = await GameStorage.load(saveKey);
      if (!mounted) return;
      if (data != null) {
        game = NainJauneGame.fromJson(Map<String, dynamic>.from(data['game'] as Map));
        computer = data['computer'] == true && game.players == 4;
        skill = ((data['skill'] as int?) ?? 1).clamp(0, 2).toInt();
      }
      saveStatus = data == null ? 'Local match, saved automatically'
          : 'Match restored; private cards remain hidden';
    } catch (_) {
      saveStatus = 'Save unavailable; a new match is ready';
    }
    if (!mounted) return;
    setState(() => ready = true);
    _runBots();
  }

  Future<void> _save() async {
    try {
      await GameStorage.save(saveKey, {
        'game': game.toJson(), 'computer': computer, 'skill': skill,
      });
      if (mounted) setState(() => saveStatus = 'Saved on this device');
    } catch (_) {
      if (mounted) setState(() => saveStatus = 'Could not save this match');
    }
  }

  bool get canAct => ready && !thinking && !game.roundOver && revealed &&
      (!computer || game.current == 0);

  void _newMatch(int players, bool vsBots) {
    epoch++;
    setState(() {
      game = NainJauneGame(players: players, random: rng);
      computer = vsBots;
      thinking = false;
      revealed = false;
    });
    _save();
  }

  void _play(int index) {
    if (!canAct || !game.canPlay(index)) return;
    final before = game.current;
    setState(() {
      game.play(index);
      if (game.current != before || game.roundOver) revealed = false;
    });
    _save();
    _runBots();
  }

  Future<void> _runBots() async {
    if (!mounted || !ready || !computer || thinking ||
        game.roundOver || game.current == 0) return;
    final token = ++epoch;
    setState(() { thinking = true; revealed = false; });
    for (var step = 0; step < 52 && game.current != 0 && !game.roundOver; step++) {
      await Future<void>.delayed(const Duration(milliseconds: 120));
      if (!mounted || token != epoch) return;
      setState(() => game.play(game.chooseBotCard(skill, rng)));
      await _save();
    }
    if (mounted && token == epoch) setState(() => thinking = false);
  }

  void _nextDeal() {
    epoch++;
    setState(() {
      game.nextDeal();
      revealed = false;
      thinking = false;
    });
    _save();
    _runBots();
  }

  @override
  void dispose() { epoch++; super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final status = game.roundOver
        ? (game.matchOver
            ? 'Match complete — Player ${game.champion + 1} leads with ${game.chips[game.champion]} chips'
            : 'Deal ${game.round} won by Player ${game.winner! + 1}${game.grandOpera ? ' — Grand Opera!' : ''}')
        : (thinking ? 'Computer playing...' :
            'Deal ${game.round}/5 — Player ${game.current + 1} to play'
            '${game.expectedRank == null ? ' any card' : ' rank ${game.expectedRank}'}');

    return GamePage(
      title: 'Nain Jaune (Yellow Dwarf)',
      rules: rules,
      status: status,
      saveStatus: saveStatus,
      actions: [
        IconButton(
          tooltip: 'New game',
          icon: const Icon(Icons.restart_alt),
          onPressed: ready ? () => _newMatch(game.players, computer) : null,
        ),
      ],
      children: [
        DropdownButton<String>(
          isExpanded: true,
          value: computer ? 'bots' : '${game.players}',
          items: [
            const DropdownMenuItem(value: 'bots',
              child: Text('You vs 3 computer players (one device)')),
            for (var n = 3; n <= 8; n++)
              DropdownMenuItem(value: '$n',
                child: Text('$n players, pass-and-play on this device')),
          ],
          onChanged: !ready || thinking ? null : (choice) {
            if (choice == null) return;
            _newMatch(choice == 'bots' ? 4 : int.parse(choice), choice == 'bots');
          },
        ),
        if (computer) Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          children: [
            const Text('Computer level'),
            DropdownButton<int>(
              value: skill,
              items: const [
                DropdownMenuItem(value: 0, child: Text('Easy')),
                DropdownMenuItem(value: 1, child: Text('Medium')),
                DropdownMenuItem(value: 2, child: Text('Hard')),
              ],
              onChanged: !ready || thinking ? null : (level) {
                if (level == null) return;
                setState(() => skill = level);
                _save();
              },
            ),
          ],
        ),
        const Text('Changing player mode starts a fresh match.'),
        ExpansionTile(
          leading: const Icon(Icons.menu_book_outlined),
          title: const Text('How to play — quick guide'),
          childrenPadding: const EdgeInsets.all(12),
          children: const [
            Text('1. Lead any card, then follow upward by rank regardless of suit.'),
            Text('2. Only the player holding the next rank may continue.'),
            Text('3. Play a prize card to collect its chips; empty your hand to win.'),
            Text('4. Tap a card, or hold it and drag it to the play area.'),
            Text('5. Use the Rules button for the complete scoring and payout rules.'),
          ],
        ),
        GameSection(title: 'Five prize trays', child: Wrap(
          spacing: 10, runSpacing: 10, children: [
            for (var i = 0; i < 5; i++)
              SizedBox(width: 118, child: Column(children: [
                CardFace(card: PlayingCard.parse(NainJauneGame.premiumCodes[i])),
                const SizedBox(height: 3),
                Text('${game.trays[i]} chips',
                    style: Theme.of(context).textTheme.labelMedium),
                Text(NainJauneGame.premiumNames[i],
                    maxLines: 2, textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall),
              ])),
          ],
        )),
        GameSection(title: 'Players and chip counts', child: Wrap(
          spacing: 7, runSpacing: 8, children: [
            for (var seat = 0; seat < game.players; seat++)
              Chip(
                avatar: Icon(
                  seat == game.current ? Icons.person : Icons.people_outline,
                  size: 18,
                  color: colors.onSurfaceVariant,
                ),
                label: Text('P${seat + 1}: ${game.chips[seat]} chips · ${game.hands[seat].length} cards'),
                backgroundColor: seat == game.current ?
                    colors.primaryContainer : null,
              ),
          ],
        )),
        if (!game.roundOver && ready && !thinking && !revealed)
          FilledButton.icon(
            onPressed: () => setState(() => revealed = true),
            icon: const Icon(Icons.visibility_outlined),
            label: Text('View Player ${game.current + 1} cards'),
          ),
        if (!game.roundOver && ready && !thinking && revealed)
          GameSection(
            title: 'Your hand — tap or hold and drag',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CardDropZone<int>(
                  canAccept: (index) => canAct && game.canPlay(index),
                  onAccept: _play,
                  child: const SizedBox(height: 76, child: Center(
                    child: Text('Drop a card here (or tap it below)',
                        textAlign: TextAlign.center),
                  )),
                ),
                const SizedBox(height: 12),
                Wrap(spacing: 7, runSpacing: 10, children: [
                  for (var index = 0; index < game.hands[game.current].length; index++)
                    TouchCard<int>(
                      key: ValueKey(game.hands[game.current][index].id),
                      card: game.hands[game.current][index],
                      data: index,
                      selected: game.canPlay(index),
                      enabled: canAct && game.canPlay(index),
                      onTap: canAct && game.canPlay(index) ? () => _play(index) : null,
                    ),
                ]),
                const SizedBox(height: 8),
                Text('Legal cards are highlighted. The full hand is kept private '
                    'until the current player taps View.',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        if (game.roundOver)
          FilledButton(
            onPressed: !game.matchOver ? _nextDeal :
                () => _newMatch(game.players, computer),
            child: Text(game.matchOver ? 'Start new match' : 'Next deal'),
          ),
        GameSection(title: 'Last moves', child: Text(
          game.log.reversed.take(8).toList().reversed.join('\n'),
        )),
      ],
    );
  }
}
