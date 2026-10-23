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

  /// Versioned by the caller's Hive key. Only integer primitives are stored.
  List<int> snapshot() => [
    ...secret,
    guesses.length,
    for (final guess in guesses) ...guess,
  ];

  /// Reject corrupted or obsolete saves instead of loading an impossible game.
  static CodeBreakerGame? restore(CodeBreakerMode mode, List<int> data) {
    if (data.length < mode.length + 1) return null;
    final count = data[mode.length];
    if (count < 0 || count > mode.maxGuesses ||
        data.length != mode.length + 1 + count * mode.length) return null;
    final secret = data.take(mode.length).toList();
    final game = CodeBreakerGame(mode, secret: secret);
    if (!game.isValid(secret)) return null;
    for (var i = 0; i < count; i++) {
      final start = mode.length + 1 + i * mode.length;
      if (!game.submit(data.sublist(start, start + mode.length))) return null;
    }
    return game;
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
