import 'dart:math';

import 'package:flutter/material.dart';

import '../common/card_view.dart';
import '../common/cards/card.dart';
import '../common/cards/rollout.dart';
import '../common/game_kit.dart';
import '../common/trick_table.dart';
import 'engine/hearts.dart';
import 'engine/hearts_ai.dart';

const _names = ['You', 'West', 'North', 'East'];

/// Hearts with the GPL-3.0 rules engine and Monte Carlo AI from
/// dozingcat/CardsWithCats.
class HeartsScreen extends StatefulWidget {
  const HeartsScreen({super.key});
  @override
  State<HeartsScreen> createState() => _HeartsScreenState();
}

class _HeartsScreenState extends State<HeartsScreen> {
  final rng = Random();
  late HeartsMatch match;
  AiLevel level = AiLevel.medium;
  final Set<PlayingCard> toPass = {};
  bool busy = false;
  List<PlayingCard>? shownTrick;
  int shownLeader = 0;
  int? shownWinner;
  int generation = 0;

  HeartsRound get round => match.currentRound;

  @override
  void initState() {
    super.initState();
    _newMatch();
  }

  void _newMatch() {
    generation++;
    match = HeartsMatch(HeartsRuleSet(), rng);
    toPass.clear();
    shownTrick = null;
    busy = false;
    WidgetsBinding.instance.addPostFrameCallback((_) => _runComputer());
  }

  String get passLabel {
    switch (round.passDirection) {
      case 1:
        return 'left';
      case 2:
        return 'across';
      case 3:
        return 'right';
      default:
        return 'nowhere';
    }
  }

  PlayingCard _aiCard() {
    final req = CardToPlayRequest.fromRound(round);
    if (level == AiLevel.easy) return makeMixedRandomOrAvoidPoints(.35)(req, rng);
    final ms = thinkMillis(level.index);
    return chooseCardMonteCarlo(
            req,
            MonteCarloParams(maxRounds: 30, rolloutsPerRound: 30, maxTimeMillis: ms),
            chooseCardAvoidingPoints,
            rng)
        .bestCard;
  }

  Future<void> _runComputer() async {
    final token = generation;
    if (busy) return;
    busy = true;
    while (mounted && token == generation &&
        round.status == HeartsRoundStatus.playing &&
        !round.isOver() &&
        round.currentPlayerIndex() != 0) {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (!mounted || token != generation) return;
      final card = _aiCard();
      await _play(card, token);
    }
    if (mounted && token == generation) setState(() => busy = false);
  }

  Future<void> _play(PlayingCard card, int token) async {
    final leader = round.currentTrick.leader;
    final before = List<PlayingCard>.from(round.currentTrick.cards)..add(card);
    setState(() => round.playCard(card));
    if (before.length == 4) {
      setState(() {
        shownTrick = before;
        shownLeader = leader;
        shownWinner = round.previousTricks.last.winner;
      });
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (!mounted || token != generation) return;
      setState(() {
        shownTrick = null;
        shownWinner = null;
      });
    }
  }

  void _pass() {
    for (var p = 1; p < 4; p++) {
      round.setPassedCardsForPlayer(
          p,
          chooseCardsToPass(CardsToPassRequest(
            rules: round.rules,
            scoresBeforeRound: round.initialScores,
            hand: round.players[p].hand,
            direction: round.passDirection,
            numCards: round.rules.numPassedCards,
          )));
    }
    round.setPassedCardsForPlayer(0, toPass.toList());
    setState(() {
      round.passCards();
      toPass.clear();
    });
    _runComputer();
  }

  Future<void> _tapCard(PlayingCard card) async {
    if (round.status == HeartsRoundStatus.passing) {
      setState(() {
        if (!toPass.remove(card) && toPass.length < round.rules.numPassedCards) {
          toPass.add(card);
        }
      });
      return;
    }
    if (busy || shownTrick != null || round.isOver()) return;
    if (round.currentPlayerIndex() != 0) return;
    if (!round.legalPlaysForCurrentPlayer().contains(card)) return;
    final token = generation;
    busy = true;
    await _play(card, token);
    busy = false;
    _runComputer();
  }

  void _nextHand() {
    setState(() {
      match.finishRound();
      toPass.clear();
    });
    _runComputer();
  }

  @override
  Widget build(BuildContext context) {
    final r = round;
    final taken = r.pointsTaken();
    final scores = match.scores;
    final over = r.isOver();
    final passing = r.status == HeartsRoundStatus.passing;
    final myTurn = !over && !passing && r.currentPlayerIndex() == 0 && shownTrick == null;
    String status;
    if (over && match.isMatchOver()) {
      final w = match.winningPlayers();
      status = w.contains(0) ? 'You win the match!' : '${_names[w.first]} wins the match';
    } else if (over) {
      status = 'Hand over — points this hand: '
          '${[for (var i = 0; i < 4; i++) '${_names[i]} ${taken[i]}'].join(', ')}';
    } else if (passing) {
      status = 'Choose 3 cards to pass $passLabel';
    } else if (myTurn) {
      status = 'Your turn';
    } else {
      status = '${_names[r.currentPlayerIndex()]} is playing…';
    }
    final trick = shownTrick ?? r.currentTrick.cards;
    final leader = shownTrick != null ? shownLeader : r.currentTrick.leader;
    final hand = sortedForDisplay(r.players[0].hand);
    return GameScaffold(
      title: 'Hearts',
      onNewGame: () => setState(_newMatch),
      rules: 'Four players, 13 tricks. Follow suit if you can. Each heart is '
          'one point and the Queen of Spades is 13 — low score wins when '
          'someone reaches 100.\n\nBefore each hand pass three cards (left, '
          'right, across, then no pass). The holder of the 2♣ leads it. Hearts '
          'cannot be led until one has been played. Take all hearts and the '
          'Q♠ to "shoot the moon": everyone else gets 26 instead.',
      children: [
        SegmentedButton<AiLevel>(
          segments: [
            for (final l in AiLevel.values) ButtonSegment(value: l, label: Text(l.label)),
          ],
          selected: {level},
          onSelectionChanged: (s) => setState(() => level = s.first),
        ),
        StatusBanner(status, highlight: myTurn || passing || over),
        TrickTable(
          names: _names,
          info: [
            for (var i = 0; i < 4; i++) 'Score ${scores[i]} · +${taken[i]}',
          ],
          trickCards: trick,
          trickLeader: leader,
          active: myTurn || over || passing ? null : r.currentPlayerIndex(),
          winner: shownWinner,
        ),
        const SizedBox(height: 8),
        HandView(
          cards: hand,
          selected: toPass,
          playable: myTurn ? r.legalPlaysForCurrentPlayer().toSet() : null,
          onTap: _tapCard,
        ),
        const SizedBox(height: 8),
        if (passing)
          FilledButton(
            onPressed: toPass.length == r.rules.numPassedCards ? _pass : null,
            child: Text('Pass ${toPass.length}/3 cards $passLabel'),
          ),
        if (over && !match.isMatchOver())
          FilledButton(onPressed: _nextHand, child: const Text('Next hand')),
        if (over && match.isMatchOver())
          FilledButton(
              onPressed: () => setState(_newMatch), child: const Text('New match')),
      ],
    );
  }
}
