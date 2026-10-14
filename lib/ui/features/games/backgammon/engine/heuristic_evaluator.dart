import 'game_entities.dart';

class HeuristicEvaluator {
  const HeuristicEvaluator();

  double evaluate(GameState state, Player player) {
    // 1. KAZANMA/KAYBETME DURUMU
    if (state.hasWon(player)) return 100000.0;
    if (state.hasWon(player.opponent)) return -100000.0;

    double score = 0.0;
    
    // Temel Pip Sayımı (Yarış Faktörü)
    final myPip = state.pipCount(player);
    final oppPip = state.pipCount(player.opponent);
    final pipDiff = oppPip - myPip;
    score += pipDiff * 1.5; 

    // --- TEMEL FAKTÖRLER ---

    // Kırık Taşlar (Bar)
    final myBar = player == Player.white ? state.whiteBar : state.blackBar;
    score -= myBar.length * 80.0; 

    // Rakibi Kırma (Hit)
    final oppBar = player == Player.white ? state.blackBar : state.whiteBar;
    score += oppBar.length * 40.0; 

    // Toplanan Taşlar (Bear-off)
    final myHomeOff = player == Player.white ? state.whiteHome : state.blackHome;
    score += myHomeOff.length * 30.0;

    // --- STRATEJİK FAKTÖRLER ---
    score += _calculatePrimeScore(state, player);
    score += _calculateBlotRisk(state, player);
    score += _calculateKeyPoints(state, player);
    score += _calculateStragglerLogic(state, player); // İsmi güncelledim

    return score;
  }

  /// Yan yana kapıların (Prime) gücünü hesaplar.
  double _calculatePrimeScore(GameState state, Player player) {
    double primeScore = 0.0;
    int consecutiveBlocks = 0;
    
    for (int i = 0; i < state.points.length; i++) {
      final point = state.points[i];
      if (point.player == player && point.pieces.length >= 2) {
        consecutiveBlocks++;
      } else {
        if (consecutiveBlocks > 0) {
          primeScore += _scoreForPrimeLength(consecutiveBlocks);
        }
        consecutiveBlocks = 0;
      }
    }
    if (consecutiveBlocks > 0) {
      primeScore += _scoreForPrimeLength(consecutiveBlocks);
    }

    return primeScore;
  }

  double _scoreForPrimeLength(int length) {
    switch (length) {
      case 1: return 2.0;
      case 2: return 6.0;
      case 3: return 15.0;
      case 4: return 30.0; 
      case 5: return 60.0; 
      case 6: return 150.0; 
      default: return length > 6 ? 160.0 : 0.0;
    }
  }

  /// Açıkların (Blot) riskini hesaplar.
  double _calculateBlotRisk(GameState state, Player player) {
    double riskPenalty = 0.0;
    final opponent = player.opponent;
    final oppBar = player == Player.white ? state.blackBar : state.whiteBar;
    final bool isOpponentOnBar = oppBar.isNotEmpty;

    for (int i = 0; i < state.points.length; i++) {
      final point = state.points[i];
      
      if (point.player == player && point.pieces.length == 1) {
        bool isDirectShot = false; 
        bool isIndirectShot = false; 
        bool isInMyHomeBoard = false;

        // Ev içi kontrolü (White: 0-5, Black: 18-23)
        if (player == Player.white) {
          if (i >= 0 && i <= 5) isInMyHomeBoard = true;
        } else {
          if (i >= 18 && i <= 23) isInMyHomeBoard = true;
        }

        if (isOpponentOnBar && isInMyHomeBoard) {
            riskPenalty += 250.0; // Çok çok büyük ceza (Arttırıldı: 150 -> 250)
        }

        // Rakip taşlarını tara
        for (int j = 0; j < state.points.length; j++) {
          final enemyPoint = state.points[j];
          if (enemyPoint.player == opponent && enemyPoint.pieces.isNotEmpty) {
            int distance;
            
            if (player == Player.white) {
              // White (23->0). i indeksindeyim. Rakip (0->23) j indeksinde.
              // Rakip arkamda (küçük indekste) ise vurabilir.
              distance = i - j;
            } else {
              // Black (0->23). i indeksindeyim. Rakip (23->0) j indeksinde.
              // Rakip arkamda (büyük indekste) ise vurabilir.
              distance = j - i;
            }

            if (distance > 0) {
              if (distance <= 6) {
                isDirectShot = true;
              } else if (distance <= 12) {
                isIndirectShot = true;
              }
            }
          }
        }
        
        if (isOpponentOnBar) {
            if (player == Player.white && i <= 6) isDirectShot = true;
            if (player == Player.black && i >= 17) isDirectShot = true;
        }

        if (isDirectShot) {
          riskPenalty += 60.0; // Arttırıldı (45 -> 60)
          if (isInMyHomeBoard) riskPenalty += 40.0; // Arttırıldı (35 -> 40)
        } else if (isIndirectShot) {
          riskPenalty += 18.0; // Arttırıldı (12 -> 18)
        } else {
          riskPenalty += 6.0; // Arttırıldı (4 -> 6)
        }
      }
    }
    return -riskPenalty;
  }

  double _calculateKeyPoints(GameState state, Player player) {
    double score = 0.0;
    
    int myFivePoint = player == Player.white ? 5 : 18;
    int oppFivePoint = player == Player.white ? 18 : 5;
    int myBarPoint = player == Player.white ? 6 : 17;

    if (_ownsPoint(state, myFivePoint, player)) score += 35.0;
    if (_ownsPoint(state, oppFivePoint, player)) score += 45.0; 
    if (_ownsPoint(state, myBarPoint, player)) score += 30.0;

    return score;
  }

  /// Geride kalan taş (Straggler) Analizi - GÜÇLENDİRİLMİŞ
  double _calculateStragglerLogic(GameState state, Player player) {
    double score = 0.0;
    
    int furthestIndex = -1;
    bool hasStraggler = false;
    
    // En uzaktaki taşı bul
    if (player == Player.white) {
      // White için en uzak = en büyük indeks (23)
      for (int i = 23; i >= 6; i--) { 
        if (state.points[i].player == player && state.points[i].pieces.isNotEmpty) {
          furthestIndex = i;
          hasStraggler = true;
          break; 
        }
      }
    } else {
      // Black için en uzak = en küçük indeks (0)
      for (int i = 0; i <= 17; i++) { 
        if (state.points[i].player == player && state.points[i].pieces.isNotEmpty) {
          furthestIndex = i;
          hasStraggler = true;
          break;
        }
      }
    }

    if (hasStraggler) {
      // Uzaklık hesabı
      int distanceToSafety = player == Player.white ? furthestIndex : (23 - furthestIndex);
      
      // ÇOK ÖNEMLİ DEĞİŞİKLİK:
      // Mesafe cezaları daha makul seviyeye çekildi.
      
      double distancePenalty = distanceToSafety * 2.0; // Düşürüldü (4.0 -> 2.0)

      // Rakip evindeyse (18+ mesafe) ceza.
      if (distanceToSafety > 18) {
         distancePenalty += 20.0; // Düşürüldü (40.0 -> 20.0)
      }

      score -= distancePenalty;

      // TEK Mİ? (LONE STRAGGLER)
      if (state.points[furthestIndex].pieces.length == 1) {
          score -= 30.0; // Düşürüldü (50.0 -> 30.0)
      }

      // STRAGGLER VARKEN İÇERİ GÖMME CEZASI
      int buriedPieces = 0;
      if (player == Player.white) {
        if (state.points[0].player == player) buriedPieces += state.points[0].pieceCount;
        if (state.points[1].player == player) buriedPieces += state.points[1].pieceCount;
      } else {
        if (state.points[23].player == player) buriedPieces += state.points[23].pieceCount;
        if (state.points[22].player == player) buriedPieces += state.points[22].pieceCount;
      }
      
      if (buriedPieces > 2) { 
         score -= buriedPieces * 6.0; // Düşürüldü (12.0 -> 6.0)
      }
    }

    // YIĞILMA (STACKING)
    for (final point in state.points) {
      if (point.player == player && point.pieces.length > 5) {
        int extra = point.pieces.length - 5;
        score -= extra * 4.0;
      }
    }

    return score;
  }

  bool _ownsPoint(GameState state, int index, Player player) {
    if (index < 0 || index >= state.points.length) return false;
    final point = state.points[index];
    return point.player == player && point.pieces.length >= 2;
  }
}
