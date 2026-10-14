import 'dart:math';

import 'package:flutter/material.dart';

import '../common/card_view.dart';
import '../common/cards/card.dart';
import '../common/cards/rollout.dart';
import '../common/game_kit.dart';
import '../common/trick_table.dart';
import 'engine/spades.dart';
import 'engine/spades_ai.dart';

const _names = ['You', 'West', 'North (partner)', 'East'];

/// Partnership Spades with the GPL-3.0 rules engine and AI from
/// dozingcat/CardsWithCats. You and North play against West and East.
class SpadesScreen extends StatefulWidget {
  const SpadesScreen({super.key});
  @override
  State<SpadesScreen> createState() => _SpadesScreenState();
}

class _SpadesScreenState extends State<SpadesScreen> {
  final rng = Random();
  late SpadesMatch match;
  AiLevel level = AiLevel.medium;
  bool busy = false;
  int myBid = 3;
  List<PlayingCard>? shownTrick;
  int shownLeader = 0;
  int? shownWinner;
  int generation = 0;

  SpadesRound get round => match.currentRound;

  @override
  void initState() {
    super.initState();
    _newMatch();
  }

  void _newMatch() {
    generation++;
    match = SpadesMatch(SpadesRuleSet(pointLimit: 300), rng);
    shownTrick = null;
    busy = false;
    WidgetsBinding.instance.addPostFrameCallback((_) => _runComputer());
  }

  int _tricksWon(int p) => round.previousTricks.where((t) => t.winner == p).length;

  PlayingCard _aiCard() {
    final req = CardToPlayRequest.fromRound(round);
    if (level == AiLevel.easy) return chooseCardToMakeBids(req, rng);
    return chooseCardMonteCarlo(
            req,
            MonteCarloParams(
                maxRounds: 30, rolloutsPerRound: 30, maxTimeMillis: thinkMillis(level.index)),
            chooseCardRandom,
            rng)
        .bestCard;
  }

  Future<void> _runComputer() async {
    final token = generation;
    if (busy) return;
    busy = true;
    while (mounted && token == generation && !round.isOver()) {
      if (round.status == SpadesRoundStatus.bidding) {
        final bidder = round.currentBidder();
        if (bidder == 0) break;
        await Future<void>.delayed(const Duration(milliseconds: 250));
        if (!mounted || token != generation) return;
        final bid = chooseBid(BidRequest(
          rules: round.rules,
          scoresBeforeRound: round.initialScores,
          otherBids: round.bidsInOrderMade(),
          hand: round.players[bidder].hand,
        ));
        setState(() => round.setBidForPlayer(bid: bid, playerIndex: bidder));
        continue;
      }
      if (round.currentPlayerIndex() == 0) break;
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (!mounted || token != generation) return;
      await _play(_aiCard(), token);
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

  void _bid() {
    setState(() => round.setBidForPlayer(bid: myBid, playerIndex: 0));
    _runComputer();
  }

  Future<void> _tapCard(PlayingCard card) async {
    if (busy || shownTrick != null || round.isOver()) return;
    if (round.status != SpadesRoundStatus.playing || round.currentPlayerIndex() != 0) return;
    if (!round.legalPlaysForCurrentPlayer().contains(card)) return;
    final token = generation;
    busy = true;
    await _play(card, token);
    busy = false;
    _runComputer();
  }

  void _nextHand() {
    setState(match.finishRound);
    _runComputer();
  }

  @override
  Widget build(BuildContext context) {
    final r = round;
    final over = r.isOver();
    final bidding = r.status == SpadesRoundStatus.bidding;
    final myBidTurn = bidding && !busy && r.currentBidder() == 0;
    final myTurn = !over && !bidding && r.currentPlayerIndex() == 0 && shownTrick == null;
    final scores = match.scores;
    String status;
    if (over && match.isMatchOver()) {
      status = match.winningTeam() == 0
          ? 'You and North win the match!'
          : 'West and East win the match';
    } else if (over) {
      final pts = r.pointsTaken();
      status = 'Hand over — your team ${pts[0].totalRoundPoints >= 0 ? '+' : ''}'
          '${pts[0].totalRoundPoints}, opponents ${pts[1].totalRoundPoints >= 0 ? '+' : ''}'
          '${pts[1].totalRoundPoints}';
    } else if (myBidTurn) {
      status = 'Your bid: how many tricks will you take?';
    } else if (bidding) {
      status = 'Bidding…';
    } else if (myTurn) {
      status = 'Your turn';
    } else {
      status = '${_names[r.currentPlayerIndex()]} is playing…';
    }
    String bidText(int p) {
      final b = r.players[p].bid;
      if (b == null) return 'Bid —';
      return '${b == 0 ? 'Nil' : 'Bid $b'} · Won ${_tricksWon(p)}';
    }

    return GameScaffold(
      title: 'Spades',
      onNewGame: () => setState(_newMatch),
      rules: 'Partnership game: you and North versus West and East. Spades '
          'are always trump. Each player bids how many tricks they expect '
          'to win (0 = Nil). Follow suit if you can; spades cannot be led '
          'until broken.\n\nA team that makes its combined bid scores 10 '
          'per trick bid plus 1 per extra trick ("bag"); every 10 bags costs '
          '100. Missing the bid loses 10 per trick bid. A successful Nil is '
          '+100, a failed one −100. First team to 300 wins.',
      children: [
        SegmentedButton<AiLevel>(
          segments: [
            for (final l in AiLevel.values) ButtonSegment(value: l, label: Text(l.label)),
          ],
          selected: {level},
          onSelectionChanged: (s) => setState(() => level = s.first),
        ),
        StatusBanner('$status\nYour team ${scores[0]} · Opponents ${scores[1]}',
            highlight: myTurn || myBidTurn || over),
        TrickTable(
          names: _names,
          info: [for (var i = 0; i < 4; i++) bidText(i)],
          trickCards: shownTrick ?? r.currentTrick.cards,
          trickLeader: shownTrick != null ? shownLeader : r.currentTrick.leader,
          active: myTurn || over || bidding ? null : r.currentPlayerIndex(),
          winner: shownWinner,
        ),
        const SizedBox(height: 8),
        HandView(
          cards: sortedForDisplay(r.players[0].hand),
          playable: myTurn ? r.legalPlaysForCurrentPlayer().toSet() : null,
          onTap: _tapCard,
        ),
        if (myBidTurn) ...[
          Row(children: [
            IconButton.filledTonal(
                onPressed: myBid > 0 ? () => setState(() => myBid--) : null,
                icon: const Icon(Icons.remove)),
            Expanded(
              child: Text(myBid == 0 ? 'Nil' : '$myBid tricks',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge),
            ),
            IconButton.filledTonal(
                onPressed: myBid < 13 ? () => setState(() => myBid++) : null,
                icon: const Icon(Icons.add)),
          ]),
          const SizedBox(height: 8),
          FilledButton(onPressed: _bid, child: const Text('Place bid')),
        ],
        if (over && !match.isMatchOver())
          FilledButton(onPressed: _nextHand, child: const Text('Next hand')),
        if (over && match.isMatchOver())
          FilledButton(
              onPressed: () => setState(_newMatch), child: const Text('New match')),
      ],
    );
  }
}
