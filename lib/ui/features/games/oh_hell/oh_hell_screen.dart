import 'dart:math';

import 'package:flutter/material.dart';

import '../common/card_view.dart';
import '../common/cards/card.dart';
import '../common/cards/rollout.dart';
import '../common/game_kit.dart';
import '../common/trick_table.dart';
import 'engine/ohhell.dart';
import 'engine/ohhell_ai.dart';

const _names = ['You', 'West', 'North', 'East'];

/// Oh Hell (Oh Pshaw) with the GPL-3.0 rules engine and AI from
/// dozingcat/CardsWithCats.
class OhHellScreen extends StatefulWidget {
  const OhHellScreen({super.key});
  @override
  State<OhHellScreen> createState() => _OhHellScreenState();
}

class _OhHellScreenState extends State<OhHellScreen> {
  final rng = Random();
  late OhHellMatch match;
  AiLevel level = AiLevel.medium;
  bool busy = false;
  int myBid = 0;
  List<PlayingCard>? shownTrick;
  int shownLeader = 0;
  int? shownWinner;
  int generation = 0;

  OhHellRound get round => match.currentRound;

  @override
  void initState() {
    super.initState();
    _newMatch();
  }

  void _newMatch() {
    generation++;
    match = OhHellMatch(
        OhHellRuleSet(
            roundSequenceVariation: OhHellRoundSequenceVariation.oneToThirteen,
            bidTotalCantEqualTricks: true),
        rng);
    shownTrick = null;
    busy = false;
    myBid = 0;
    WidgetsBinding.instance.addPostFrameCallback((_) => _runComputer());
  }

  int _tricksWon(int p) => round.previousTricks.where((t) => t.winner == p).length;

  PlayingCard _aiCard() {
    final req = CardToPlayRequest.fromRound(round);
    final ms = level == AiLevel.easy ? 30 : thinkMillis(level.index);
    return chooseCardMonteCarlo(
            req,
            MonteCarloParams(
                maxRounds: level == AiLevel.easy ? 3 : 30,
                rolloutsPerRound: level == AiLevel.easy ? 5 : 30,
                maxTimeMillis: ms),
            chooseCardRandom,
            rng)
        .bestCard;
  }

  Future<void> _runComputer() async {
    final token = generation;
    if (busy) return;
    busy = true;
    while (mounted && token == generation && !round.isOver()) {
      if (round.status == OhHellRoundStatus.bidding) {
        final bidder = round.currentBidder();
        if (bidder == 0) break;
        await Future<void>.delayed(const Duration(milliseconds: 250));
        if (!mounted || token != generation) return;
        final bid = chooseBid(
            BidRequest(
              rules: round.rules,
              scoresBeforeRound: round.initialScores,
              otherBids: round.bidsInOrderMade(),
              trumpCard: round.trumpCard,
              dealerHasTrumpCard: round.dealerHasTrumpCard(),
              hand: round.players[bidder].hand,
            ),
            rng);
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
    if (myBid == round.disallowedBidForCurrentBidder()) return;
    setState(() => round.setBidForPlayer(bid: myBid, playerIndex: 0));
    _runComputer();
  }

  Future<void> _tapCard(PlayingCard card) async {
    if (busy || shownTrick != null || round.isOver()) return;
    if (round.status != OhHellRoundStatus.playing || round.currentPlayerIndex() != 0) return;
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
      myBid = 0;
    });
    _runComputer();
  }

  @override
  Widget build(BuildContext context) {
    final r = round;
    final over = r.isOver();
    final bidding = r.status == OhHellRoundStatus.bidding;
    final myBidTurn = bidding && !busy && r.currentBidder() == 0;
    final myTurn = !over && !bidding && r.currentPlayerIndex() == 0 && shownTrick == null;
    final scores = match.scores;
    final forbidden = myBidTurn ? r.disallowedBidForCurrentBidder() : null;
    String status;
    if (over && match.isMatchOver()) {
      final w = match.winningPlayers();
      status = w.contains(0) ? 'You win the match!' : '${_names[w.first]} wins the match';
    } else if (over) {
      status = 'Hand over';
    } else if (myBidTurn) {
      status = 'Bid exactly how many tricks you will take';
    } else if (bidding) {
      status = 'Bidding…';
    } else if (myTurn) {
      status = 'Your turn';
    } else {
      status = '${_names[r.currentPlayerIndex()]} is playing…';
    }
    String info(int p) {
      final b = r.players[p].bid;
      return '${scores[p]} pts · ${b == null ? 'Bid —' : 'Bid $b · Won ${_tricksWon(p)}'}';
    }

    return GameScaffold(
      title: 'Oh Hell',
      onNewGame: () => setState(_newMatch),
      rules: 'Thirteen hands, dealing 1 card each in the first hand up to 13 '
          'in the last. A card turned up from the deck sets trump. Everyone '
          'bids the exact number of tricks they expect to take; the dealer '
          'cannot bid a number that makes the bids add up to the tricks '
          'available.\n\nFollow suit if you can. Score 1 point per trick plus '
          '10 for hitting your bid exactly. Highest score after 13 hands wins.',
      children: [
        SegmentedButton<AiLevel>(
          segments: [
            for (final l in AiLevel.values) ButtonSegment(value: l, label: Text(l.label)),
          ],
          selected: {level},
          onSelectionChanged: (s) => setState(() => level = s.first),
        ),
        StatusBanner(
            '$status\nHand ${match.previousRounds.length + 1} · '
            '${r.numCardsPerPlayer} card${r.numCardsPerPlayer == 1 ? '' : 's'}',
            highlight: myTurn || myBidTurn || over),
        TrickTable(
          names: _names,
          info: [for (var i = 0; i < 4; i++) info(i)],
          trickCards: shownTrick ?? r.currentTrick.cards,
          trickLeader: shownTrick != null ? shownLeader : r.currentTrick.leader,
          active: myTurn || over || bidding ? null : r.currentPlayerIndex(),
          winner: shownWinner,
          center: r.currentTrick.cards.isEmpty && shownTrick == null
              ? Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('Trump', style: TextStyle(color: Colors.white70)),
                  CardView(card: r.trumpCard, width: 44),
                ])
              : null,
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
              child: Text(
                  '$myBid trick${myBid == 1 ? '' : 's'}'
                  '${forbidden == myBid ? ' (not allowed)' : ''}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge),
            ),
            IconButton.filledTonal(
                onPressed: myBid < r.numCardsPerPlayer ? () => setState(() => myBid++) : null,
                icon: const Icon(Icons.add)),
          ]),
          const SizedBox(height: 8),
          FilledButton(
              onPressed: forbidden == myBid ? null : _bid, child: const Text('Place bid')),
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
