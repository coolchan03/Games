import 'constants.dart';
import 'game_entities.dart';
import 'move_piece_use_case.dart';

typedef PossibleMove = ({int to, int die});

class GetPossibleMovesUseCase {
  final MovePieceUseCase _movePieceUseCase = MovePieceUseCase();
  bool enableMandatoryDieRule = true;

  List<PossibleMove> call({
    required GameState gameState,
    required int fromIndex,
  }) {
    final mandatoryDie = enableMandatoryDieRule
        ? _mandatoryDieIfOnlyOnePlayable(gameState)
        : null;

    final moves = _collectMoves(gameState, fromIndex);
    if (mandatoryDie != null) {
      return moves.where((m) => m.die == mandatoryDie).toList();
    }
    return moves;
  }

  /// Mevcut oyun durumu için tüm olası hamleleri döner.
  List<Move> getAllPossibleMoves(GameState gameState) {
    final moves = <Move>[];
    final player = gameState.currentPlayer;
    
    // 1. Check Bar
    final barIndex = player == Player.white ? whiteBarIndex : blackBarIndex;
    final bar = player == Player.white ? gameState.whiteBar : gameState.blackBar;
    
    if (bar.isNotEmpty) {
       final barMoves = call(gameState: gameState, fromIndex: barIndex);
       for (final pm in barMoves) {
         moves.add(Move(from: barIndex, to: pm.to, die: pm.die));
       }
       // Rule: If on bar, must move from bar. No other moves allowed until bar is empty.
       return moves;
    }

    // 2. Check Board Points
    for (int i = 0; i < gameState.points.length; i++) {
      if (gameState.points[i].player == player) {
        final pointMoves = call(gameState: gameState, fromIndex: i);
        for (final pm in pointMoves) {
          moves.add(Move(from: i, to: pm.to, die: pm.die));
        }
      }
    }
    
    return moves;
  }

  /// Asıl hareket üretimi (kural kontrolleri değişmeden) – zorunlu zar filtresi yok.
  List<PossibleMove> _collectMoves(GameState gameState, int fromIndex) {
    // Check if trying to move FROM home (impossible)
    if (fromIndex == whiteHomeIndex || fromIndex == blackHomeIndex) {
      return [];
    }

    // --- DEBUG LOGLARI (Sorunu anlamak için) ---
    //print("--- GetPossibleMoves CALL ---");
    //print("Phase: ${gameState.phase}, Dice: ${gameState.dice}");
    //print("Checking Index: $fromIndex, Player: ${gameState.currentPlayer}");
    //print("WhiteBar: ${gameState.whiteBar.length}, BlackBar: ${gameState.blackBar.length}");

    final player = gameState.currentPlayer;
    final bar = player == Player.white ? gameState.whiteBar : gameState.blackBar;
    final isTryingToPlayFromBar = fromIndex == (player == Player.white ? whiteBarIndex : blackBarIndex);

    // KURAL 1: BAR KONTROLÜ
    // Eğer barda taş varsa, önce oradan oynanmalı.
    if (bar.isNotEmpty) {
      if (isTryingToPlayFromBar) {
        //print("Result: Playing from Bar");
        return _getMovesFromBar(gameState);
      } else {
        //print("Result: REJECTED (Must play from bar first)");
        return [];
      }
    }

    // Bar boşsa ama bar alanına tıklandıysa boş dön
    if (isTryingToPlayFromBar) {
      //print("Result: REJECTED (Bar is empty but tried to play from bar)");
      return [];
    }

    // KURAL 2: BEARING OFF (TOPLAMA)
    if (_canBearOff(gameState, player)) {
      //print("Result: Bearing Off Logic");
      return _getBearingOffMoves(gameState, fromIndex);
    }

    // KURAL 3: NORMAL HAMLE
    //print("Result: Checking Normal Moves...");
    return _getMovesFromPoint(gameState, fromIndex);
  }

  // --- HELPER METHODS ---

  bool hasAnyPossibleMoves(GameState gameState) {
    final player = gameState.currentPlayer;
    final bar = player == Player.white ? gameState.whiteBar : gameState.blackBar;

    if (bar.isNotEmpty) {
      return _getMovesFromBar(gameState).isNotEmpty;
    }

    for (int i = 0; i < gameState.points.length; i++) {
      if (gameState.points[i].player == player) {
        if (call(gameState: gameState, fromIndex: i).isNotEmpty) {
          return true;
        }
      }
    }

    return false;
  }

  List<PossibleMove> _getMovesFromBar(GameState gameState) {
    final player = gameState.currentPlayer;
    final possibleMoves = <PossibleMove>[];

    for (final die in gameState.dice) {
      int toIndex;
      if (player == Player.white) {
        toIndex = 24 - die;
      } else {
        toIndex = die - 1;
      }

      // Bar'dan girişlerde de hedef kontrolü yapılır
      if (_isPathClear(gameState, player, -1, toIndex, die)) {
        possibleMoves.add((to: toIndex, die: die));
      }
    }
    return possibleMoves;
  }

  /// Eğer sadece tek zar oynanabiliyorsa ve her iki zar da teorik olarak oynanabiliyorsa
  /// Backgammon kuralı gereği yüksek zar zorunludur. Bu metod zorunlu zarı döner.
  int? _mandatoryDieIfOnlyOnePlayable(GameState state) {
    if (state.dice.length < 2) return null;
    if (state.dice.toSet().length == 1) return null; // double ise fark yok

    // Maksimum kaç zar kullanılabiliyor?
    final maxUsable = maxPlayableMoves(state, state.dice);
    if (maxUsable > 1) return null;

    // Hangi zar(lar) oynanabilir?
    final playableDice = <int>{};
    for (final die in state.dice) {
      final singleDieState = state.copyWith(dice: [die]);
      if (_hasAnyMoveWithState(singleDieState)) {
        playableDice.add(die);
      }
    }
    if (playableDice.isEmpty) return null;
    return playableDice.reduce((a, b) => a > b ? a : b); // en yüksek zar
  }

  /// Belirli bir state ve zar listesiyle en fazla kaç hamle yapılabilir? (Dice sayısı kadar derinlik)
  int maxPlayableMoves(GameState state, List<int> dice) {
    if (dice.isEmpty) return 0;

    final player = state.currentPlayer;
    final fromIndices = <int>[];
    final barList = player == Player.white ? state.whiteBar : state.blackBar;

    if (barList.isNotEmpty) {
      fromIndices.add(player == Player.white ? whiteBarIndex : blackBarIndex);
    } else {
      for (int i = 0; i < state.points.length; i++) {
        if (state.points[i].player == player) {
          fromIndices.add(i);
        }
      }
    }

    int best = 0;

    for (int i = 0; i < dice.length; i++) {
      final die = dice[i];
      final remainingDice = List<int>.from(dice)..removeAt(i);

      // Tek zarla üretilecek hamleleri görmek için state'i o zarla sınırla
      final stateWithDie = state.copyWith(dice: [die]);

      for (final from in fromIndices) {
        final moves = _collectMoves(stateWithDie, from);
        for (final pMove in moves) {
          final nextState = _movePieceUseCase(
            gameState: stateWithDie,
            move: Move(from: from, to: pMove.to, die: pMove.die),
          );
          final total = 1 + maxPlayableMoves(nextState, remainingDice);
          if (total > best) best = total;
        }
      }
    }

    return best;
  }

  bool _hasAnyMoveWithState(GameState state) {
    final player = state.currentPlayer;
    final bar = player == Player.white ? state.whiteBar : state.blackBar;
    if (bar.isNotEmpty) {
      return _getMovesFromBar(state).isNotEmpty;
    }

    for (int i = 0; i < state.points.length; i++) {
      if (state.points[i].player == player) {
        if (_collectMoves(state, i).isNotEmpty) {
          return true;
        }
      }
    }
    return false;
  }

  List<PossibleMove> _getBearingOffMoves(GameState gameState, int fromIndex) {
    final player = gameState.currentPlayer;
    final possibleMoves = <PossibleMove>[];
    final dice = gameState.dice;

    // Normal hamleleri de ekle (Toplamak zorunda değilsin, içeride de oynayabilirsin)
    possibleMoves.addAll(_getMovesFromPoint(gameState, fromIndex));

    for (final die in dice) {
      if (player == Player.white) {
        final distanceToHome = fromIndex + 1;

        // Tam isabet
        if (distanceToHome == die) {
          possibleMoves.add((to: whiteHomeIndex, die: die));
        }
        // Zar daha büyükse yalnızca en uzak taş toplanabilir (üstünde taş yoksa)
        else if (die > distanceToHome) {
          bool hasPieceBehind = false;
          for (int i = fromIndex + 1; i <= 5; i++) {
            if (gameState.points[i].player == Player.white) {
              hasPieceBehind = true;
              break;
            }
          }
          if (!hasPieceBehind) {
            possibleMoves.add((to: whiteHomeIndex, die: die));
          }
        }
      } else {
        // Black Logic
        final distanceToHome = 24 - fromIndex;

        if (distanceToHome == die) {
          possibleMoves.add((to: blackHomeIndex, die: die));
        } else if (die > distanceToHome) {
          bool hasPieceBehind = false;
          // Black home is 18..23, daha küçük indeksler daha uzaktır.
          for (int i = 18; i < fromIndex; i++) {
            if (gameState.points[i].player == Player.black) {
              hasPieceBehind = true;
              break;
            }
          }
          if (!hasPieceBehind) {
            possibleMoves.add((to: blackHomeIndex, die: die));
          }
        }
      }
    }

    return possibleMoves;
  }

  List<PossibleMove> _getMovesFromPoint(GameState gameState, int fromIndex) {
    final List<PossibleMove> possibleMoves = [];

    // Check valid board range. Bear-off indices (-2, 25) or others are not valid sources.
    if (fromIndex < 0 || fromIndex >= 24) {
      return possibleMoves;
    }

    // DEBUG: Phase kontrolü
    if (gameState.phase != GamePhase.playing) {
      //print("Result: REJECTED (Phase is not playing: ${gameState.phase})");
      return possibleMoves;
    }

    final player = gameState.currentPlayer;
    final point = gameState.points[fromIndex];

    // DEBUG: Oyuncu kontrolü
    if (point.player != player) {
      //print("Result: REJECTED (Point belongs to ${point.player})");
      return possibleMoves;
    }

    for (final die in gameState.dice) {
      int toIndex;
      if (player == Player.white) {
        toIndex = fromIndex - die;
      } else {
        toIndex = fromIndex + die;
      }

      if (toIndex >= 0 && toIndex < 24) {
        if (_isPathClear(gameState, player, fromIndex, toIndex, die)) {
          possibleMoves.add((to: toIndex, die: die));
        } else {
          //print("Path Blocked: From $fromIndex To $toIndex Die $die");
        }
      }
    }

    //print("Found Moves for index $fromIndex: ${possibleMoves.length}");
    return possibleMoves;
  }

  bool _isPathClear(GameState gameState, Player player, int fromIndex, int toIndex, int die) {
    // 1. Hedef Tahta Dışında mı?
    if (toIndex < 0 || toIndex >= 24) return false;

    final destinationPoint = gameState.points[toIndex];

    // 2. Hedef Nokta Dolu mu? (KAPI VAR MI?)
    // Eğer hedef noktada rakip varsa ve 1'den fazla taşı varsa (Kapı almışsa) GİDİLEMEZ.
    if (destinationPoint.player != player && destinationPoint.pieceCount > 1) {
      return false;
    }

    // --- ÖNEMLİ: ARA NOKTA KONTROLÜ (FOR DÖNGÜSÜ) BURADAN KALDIRILDI ---
    // Tavlada taşlar zıplayabilir. Sadece varış noktası önemlidir.

    return true;
  }

  bool _canBearOff(GameState gameState, Player player) {
    int piecesInHomeQuadrant = 0;

    final barList = player == Player.white ? gameState.whiteBar : gameState.blackBar;
    if (barList.isNotEmpty) {
      return false; // Bar boş olmadan toplama yapılamaz
    }

    if (player == Player.white) {
      // White Home: 0-5 indices
      for (int i = 0; i <= 5; i++) {
        if (gameState.points[i].player == Player.white) {
          piecesInHomeQuadrant += gameState.points[i].pieceCount;
        }
      }
    } else {
      // Black Home: 18-23 indices
      for (int i = 18; i <= 23; i++) {
        if (gameState.points[i].player == Player.black) {
          piecesInHomeQuadrant += gameState.points[i].pieceCount;
        }
      }
    }

    // Toplanmış taşları da hesaba katalım ki toplam 15 olsun
    final homeList = player == Player.white ? gameState.whiteHome : gameState.blackHome;
    piecesInHomeQuadrant += homeList.length;

    return piecesInHomeQuadrant == 15;
  }
}
