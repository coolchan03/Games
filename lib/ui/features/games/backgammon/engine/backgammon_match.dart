// Turn controller for the bbackgammon (GPL-3.0) rules engine. Adds the
// "use as many dice as possible" rule at turn level, opening roll, doubles
// and a search-based computer player built on HeuristicEvaluator.
import 'dart:math';

import 'constants.dart';
import 'game_entities.dart';
import 'get_possible_moves.dart';
import 'heuristic_evaluator.dart';
import 'move_piece_use_case.dart';

class BackgammonMatch {
  BackgammonMatch({Random? random}) : rng = random ?? Random() {
    _generator.enableMandatoryDieRule = false;
    state = GameState.newGame().copyWith(phase: GamePhase.playing);
    _openingRoll();
  }

  final Random rng;
  final _generator = GetPossibleMovesUseCase();
  final _apply = MovePieceUseCase();
  late GameState state;

  /// States since the start of the current turn, for undo.
  final List<GameState> turnHistory = [];
  List<int> rolled = [];
  String? message;

  Player? get winner => state.hasWon(Player.white)
      ? Player.white
      : state.hasWon(Player.black)
          ? Player.black
          : null;

  bool get needsRoll => winner == null && state.dice.isEmpty;

  void _openingRoll() {
    int a, b;
    do {
      a = rng.nextInt(6) + 1;
      b = rng.nextInt(6) + 1;
    } while (a == b);
    final first = a > b ? Player.white : Player.black;
    state = state.copyWith(currentPlayer: first, dice: [a, b]);
    rolled = [a, b];
    message = 'Opening roll: White $a, Black $b — ${first.displayName} starts';
    turnHistory.clear();
    _passIfStuck();
  }

  void roll({List<int>? fixed}) {
    if (!needsRoll) return;
    final a = fixed?[0] ?? rng.nextInt(6) + 1;
    final b = fixed?[1] ?? rng.nextInt(6) + 1;
    rolled = [a, b];
    state = state.copyWith(dice: a == b ? [a, a, a, a] : [a, b]);
    message = null;
    turnHistory.clear();
    _passIfStuck();
  }

  void _passIfStuck() {
    if (legalMoves().isEmpty) {
      message = '${state.currentPlayer.displayName} rolled ${rolled.join('-')} and cannot move';
      _endTurn();
    }
  }

  void _endTurn() {
    state = state.copyWith(currentPlayer: state.currentPlayer.opponent, dice: []);
    turnHistory.clear();
  }

  List<Move> _singleMoves(GameState s) => _generator.getAllPossibleMoves(s);

  GameState _after(GameState s, Move m) => _apply(gameState: s, move: m);

  /// Can [needed] more dice be played from [s]? (depth-first, early exit)
  bool _reach(GameState s, int needed) {
    if (needed <= 0) return true;
    if (s.dice.isEmpty) return false;
    for (final m in _singleMoves(s)) {
      if (_reach(_after(s, m), needed - 1)) return true;
    }
    return false;
  }

  int _maxDice(GameState s) {
    for (var n = s.dice.length; n > 0; n--) {
      if (_reach(s, n)) return n;
    }
    return 0;
  }

  /// Moves that keep the maximum number of dice playable this turn.
  List<Move> legalMoves() {
    if (winner != null || state.dice.isEmpty) return [];
    final all = _singleMoves(state);
    if (all.isEmpty) return [];
    final max = _maxDice(state);
    var legal = [
      for (final m in all)
        if (_reach(_after(state, m), max - 1)) m
    ];
    // Only one die playable: the larger one must be used if possible.
    if (max == 1 && state.dice.length == 2 && state.dice[0] != state.dice[1]) {
      final high = state.dice.reduce((a, b) => a > b ? a : b);
      final withHigh = legal.where((m) => m.die == high).toList();
      if (withHigh.isNotEmpty) legal = withHigh;
    }
    // Collapse moves that differ only by which equal die is used.
    final seen = <String>{};
    return [
      for (final m in legal)
        if (seen.add('${m.from}:${m.to}')) m
    ];
  }

  bool play(Move m) {
    final legal = legalMoves();
    final match = legal.where((x) => x.from == m.from && x.to == m.to).toList();
    if (match.isEmpty) return false;
    turnHistory.add(state);
    state = _after(state, match.first);
    if (winner != null) {
      state = state.copyWith(phase: GamePhase.gameOver);
      return true;
    }
    if (state.dice.isEmpty || legalMoves().isEmpty) _endTurn();
    return true;
  }

  bool get canUndo => turnHistory.isNotEmpty;

  void undo() {
    if (turnHistory.isEmpty) return;
    state = turnHistory.removeLast();
  }

  /// Compact position key used to deduplicate equivalent move orders.
  static String key(GameState s) {
    final b = StringBuffer();
    for (final p in s.points) {
      b.write(p.player == null ? '0' : '${p.player == Player.white ? '+' : '-'}${p.pieceCount}');
      b.write(',');
    }
    b.write('${s.whiteBar.length}/${s.blackBar.length}/${s.whiteHome.length}/${s.blackHome.length}');
    return b.toString();
  }

  /// All complete turns (lists of moves) for the side to move, deduplicated by
  /// final position.
  Map<String, (List<Move>, GameState)> _turns() {
    final max = _maxDice(state);
    final results = <String, (List<Move>, GameState)>{};
    final visited = <String>{};
    void dfs(GameState s, List<Move> seq) {
      if (seq.length == max) {
        results.putIfAbsent(key(s), () => (seq, s));
        return;
      }
      for (final m in _singleMoves(s)) {
        final next = _after(s, m);
        if (!visited.add('${seq.length}|${key(next)}|${next.dice.join()}')) continue;
        dfs(next, [...seq, m]);
      }
    }

    dfs(state, []);
    if (max == 1 && state.dice.length == 2 && state.dice[0] != state.dice[1]) {
      final high = state.dice.reduce((a, b) => a > b ? a : b);
      final withHigh = Map.fromEntries(results.entries.where((e) => e.value.$1.first.die == high));
      if (withHigh.isNotEmpty) return withHigh;
    }
    return results;
  }

  /// Picks a full turn for the computer. [skill]: 0 random, 1 noisy, 2 best.
  List<Move> computerTurn(int skill) {
    final turns = _turns().values.toList();
    if (turns.isEmpty) return [];
    if (skill == 0 && rng.nextDouble() < .6) return turns[rng.nextInt(turns.length)].$1;
    const eval = HeuristicEvaluator();
    final me = state.currentPlayer;
    (List<Move>, GameState)? best;
    var bestScore = double.negativeInfinity;
    for (final t in turns) {
      var score = eval.evaluate(t.$2, me);
      if (skill == 1) score += (rng.nextDouble() - .5) * 60;
      if (score > bestScore) {
        bestScore = score;
        best = t;
      }
    }
    return best!.$1;
  }

  /// Gammon (2) or backgammon (3) multiplier for the finished game.
  int get resultPoints {
    final w = winner;
    if (w == null) return 0;
    final loserOff = w == Player.white ? state.blackHome.length : state.whiteHome.length;
    if (loserOff > 0) return 1;
    final loser = w.opponent;
    final loserBar = loser == Player.white ? state.whiteBar.length : state.blackBar.length;
    // Winner's home board: white 0-5, black 18-23.
    final inWinnerHome = [
      for (var i = 0; i < 24; i++)
        if ((w == Player.white ? i <= 5 : i >= 18) && state.points[i].player == loser) i
    ];
    return loserBar > 0 || inWinnerHome.isNotEmpty ? 3 : 2;
  }
}

const bearOffWhite = whiteHomeIndex;
const bearOffBlack = blackHomeIndex;
