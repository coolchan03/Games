// Turn controller adapted from z7workbench/minigames
// lib/games/yacht_dice/yacht_dice_provider.dart (MIT, Copyright (c) 2021
// ZeroGo Yoosee), with Riverpod and persistence removed so the same logic
// can drive a plain StatefulWidget and unit tests.
import 'dart:math';

import 'ai/easy_ai.dart';
import 'ai/hard_ai.dart';
import 'ai/medium_ai.dart';
import 'ai/yacht_ai.dart';
import 'scoring.dart';
import 'scoring_category.dart';
import 'yacht_dice_state.dart';

const upperCategories = [
  ScoringCategory.ones,
  ScoringCategory.twos,
  ScoringCategory.threes,
  ScoringCategory.fours,
  ScoringCategory.fives,
  ScoringCategory.sixes,
];

class YachtGame {
  YachtGame({int humans = 1, AiDifficulty? ai, Random? random})
      : _random = random ?? Random(),
        state = YachtDiceState(
          phase: GamePhase.rolling,
          currentPlayerIndex: 0,
          roundsCompleted: 0,
          aiDifficulty: ai,
          players: [
            for (var i = 0; i < humans; i++)
              PlayerState.initial(
                  name: humans == 1 ? 'You' : 'Player ${i + 1}',
                  type: PlayerType.human),
            if (ai != null) PlayerState.initial(name: 'Computer', type: PlayerType.ai),
          ],
        );

  final Random _random;
  YachtDiceState state;

  PlayerState get current => state.players[state.currentPlayerIndex];
  bool get isOver => state.isGameOver;
  bool get canRoll => !isOver && current.rollsRemaining > 0;
  bool get hasRolled => current.rollsRemaining < 3 && !current.dice.contains(0);

  void _replaceCurrent(PlayerState p) {
    final players = List<PlayerState>.from(state.players);
    players[state.currentPlayerIndex] = p;
    state = state.copyWith(players: players);
  }

  void roll() {
    if (!canRoll) return;
    final dice = List<int>.from(current.dice);
    final firstRoll = current.rollsRemaining == 3;
    for (var i = 0; i < 5; i++) {
      if (firstRoll || !current.kept[i]) dice[i] = _random.nextInt(6) + 1;
    }
    _replaceCurrent(current.copyWith(
      dice: dice,
      kept: firstRoll ? List.filled(5, false) : null,
      rollsRemaining: current.rollsRemaining - 1,
    ));
  }

  void toggleKeep(int index) {
    if (!hasRolled || current.rollsRemaining == 0) return;
    final kept = List<bool>.from(current.kept);
    kept[index] = !kept[index];
    _replaceCurrent(current.copyWith(kept: kept));
  }

  bool select(ScoringCategory category) {
    if (isOver || !hasRolled || current.scores[category] != null) return false;
    final scores = Map<ScoringCategory, int?>.from(current.scores);
    scores[category] = calculateScore(current.dice, category);
    final upper = upperCategories.map((c) => scores[c] ?? 0).reduce((a, b) => a + b);
    final bonus = calculateBonus(upper);
    final total = scores.values.whereType<int>().fold(0, (a, b) => a + b) + bonus;
    _replaceCurrent(current.copyWith(
      scores: scores,
      totalScore: total,
      bonusEarned: bonus,
      dice: List.filled(5, 0),
      kept: List.filled(5, false),
      rollsRemaining: 3,
    ));
    state = state.copyWith(roundsCompleted: state.roundsCompleted + 1);
    if (state.isGameOver) {
      state = state.copyWith(phase: GamePhase.gameOver);
    } else {
      state = state.copyWith(
          currentPlayerIndex: (state.currentPlayerIndex + 1) % state.players.length);
    }
    return true;
  }

  YachtAi? get _ai => switch (state.aiDifficulty) {
        AiDifficulty.easy => EasyAi(),
        AiDifficulty.medium => MediumAi(),
        AiDifficulty.hard => HardAi(),
        null => null,
      };

  /// Performs one computer action (roll, keep+roll, or score).
  /// Returns false once the computer's turn is over.
  Future<bool> aiStep() async {
    if (isOver || current.type != PlayerType.ai) return false;
    if (!hasRolled) {
      roll();
      return true;
    }
    if (current.rollsRemaining <= 0) {
      ScoringCategory? best;
      var bestScore = -1;
      for (final c in ScoringCategory.values) {
        if (current.scores[c] != null) continue;
        final s = calculateScore(current.dice, c);
        if (s > bestScore) {
          bestScore = s;
          best = c;
        }
      }
      select(best!);
      return false;
    }
    final decision = await _ai!.decide(state);
    if (decision.categoryToSelect != null) {
      select(decision.categoryToSelect!);
      return false;
    }
    _replaceCurrent(current.copyWith(kept: decision.diceToKeep));
    roll();
    return true;
  }

  List<PlayerState> get winners {
    final best = state.players.map((p) => p.totalScore).reduce(max);
    return state.players.where((p) => p.totalScore == best).toList();
  }
}
