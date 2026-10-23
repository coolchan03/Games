// Scoring adapted from z7workbench/minigames
// lib/games/hit_and_blow/hit_and_blow_provider.dart (MIT, Copyright (c) 2021
// ZeroGo Yoosee). Hint solver added for Games.
import 'dart:math';

class CodeBreakerMode {
  const CodeBreakerMode(this.name, this.length, this.symbols, this.duplicates, this.maxGuesses);
  final String name;
  final int length;
  final int symbols;
  final bool duplicates;
  final int maxGuesses;

  static const easy = CodeBreakerMode('Easy', 4, 6, false, 10);
  static const classic = CodeBreakerMode('Classic', 4, 6, true, 10);
  static const hard = CodeBreakerMode('Hard', 5, 8, true, 12);
  static const all = [easy, classic, hard];

  /// The 20 numbered levels: longer codes, more colours, repeats and fewer
  /// guesses make them progressively harder. Each attempt draws a new
  /// secret code, so a failed level can be retried fairly.
  static const levels = [
    CodeBreakerMode('Level 1', 3, 4, false, 8),
    CodeBreakerMode('Level 2', 3, 5, false, 8),
    CodeBreakerMode('Level 3', 3, 6, false, 8),
    CodeBreakerMode('Level 4', 4, 5, false, 10),
    CodeBreakerMode('Level 5', 4, 6, false, 10),
    CodeBreakerMode('Level 6', 3, 4, true, 8),
    CodeBreakerMode('Level 7', 3, 6, true, 8),
    CodeBreakerMode('Level 8', 4, 6, false, 8),
    CodeBreakerMode('Level 9', 4, 6, true, 10),
    CodeBreakerMode('Level 10', 4, 7, false, 10),
    CodeBreakerMode('Level 11', 4, 7, true, 10),
    CodeBreakerMode('Level 12', 4, 8, false, 10),
    CodeBreakerMode('Level 13', 4, 6, true, 8),
    CodeBreakerMode('Level 14', 4, 8, true, 10),
    CodeBreakerMode('Level 15', 5, 6, false, 10),
    CodeBreakerMode('Level 16', 5, 7, false, 10),
    CodeBreakerMode('Level 17', 5, 8, false, 12),
    CodeBreakerMode('Level 18', 5, 6, true, 12),
    CodeBreakerMode('Level 19', 5, 7, true, 12),
    CodeBreakerMode('Level 20', 5, 8, true, 10),
  ];
}

/// (hits, blows): hits = right symbol, right place; blows = right symbol, wrong place.
(int, int) scoreGuess(List<int> guess, List<int> target) {
  var hits = 0;
  final tCounts = <int, int>{}, gCounts = <int, int>{};
  for (var i = 0; i < guess.length; i++) {
    if (guess[i] == target[i]) {
      hits++;
    } else {
      tCounts[target[i]] = (tCounts[target[i]] ?? 0) + 1;
      gCounts[guess[i]] = (gCounts[guess[i]] ?? 0) + 1;
    }
  }
  var blows = 0;
  gCounts.forEach((d, n) => blows += min(n, tCounts[d] ?? 0));
  return (hits, blows);
}

class CodeBreakerGame {
  CodeBreakerGame(this.mode, {Random? random, List<int>? secret})
      : _random = random ?? Random() {
    this.secret = secret ?? _makeSecret();
  }

  final CodeBreakerMode mode;
  final Random _random;
  late final List<int> secret;
  final List<List<int>> guesses = [];
  final List<(int, int)> feedback = [];

  List<int> _makeSecret() {
    if (mode.duplicates) {
      return List.generate(mode.length, (_) => _random.nextInt(mode.symbols));
    }
    final pool = List.generate(mode.symbols, (i) => i)..shuffle(_random);
    return pool.sublist(0, mode.length);
  }

  bool get won => feedback.isNotEmpty && feedback.last.$1 == mode.length;
  bool get lost => !won && guesses.length >= mode.maxGuesses;
  bool get over => won || lost;

  bool isValid(List<int> guess) =>
      guess.length == mode.length &&
      guess.every((s) => s >= 0 && s < mode.symbols) &&
      (mode.duplicates || guess.toSet().length == guess.length);

  bool submit(List<int> guess) {
    if (over || !isValid(guess)) return false;
    guesses.add(List.of(guess));
    feedback.add(scoreGuess(guess, secret));
    return true;
  }

  /// All codes still consistent with every clue so far (enumerated lazily).
  Iterable<List<int>> consistentCodes() sync* {
    final code = List.filled(mode.length, 0);
    final total = pow(mode.symbols, mode.length).toInt();
    for (var n = 0; n < total; n++) {
      var x = n;
      for (var i = mode.length - 1; i >= 0; i--) {
        code[i] = x % mode.symbols;
        x ~/= mode.symbols;
      }
      if (!mode.duplicates && code.toSet().length != code.length) continue;
      var ok = true;
      for (var g = 0; g < guesses.length && ok; g++) {
        ok = scoreGuess(guesses[g], code) == feedback[g];
      }
      if (ok) yield List.of(code);
    }
  }

  /// A guess that agrees with every clue so far (a "never contradict yourself"
  /// hint), chosen at random among the candidates.
  List<int>? hint() {
    final all = consistentCodes().take(5000).toList();
    if (all.isEmpty) return null;
    return all[_random.nextInt(all.length)];
  }
}
