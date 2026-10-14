// lib/domain/entities/game_entities.dart


// --- ENUMS ---

enum Player {
  white,
  black,
}

extension PlayerExtension on Player {
  String get displayName => this == Player.white ? 'White' : 'Black';

  // Rakibi döndüren yardımcı metod
  Player get opponent => this == Player.white ? Player.black : Player.white;
}

enum GamePhase {
  initialRoll,      // Başlangıç zarı atılıyor (Local karar veriyor)
  playing,          // Oyun devam ediyor
  confirmation,     // Oyuncu hamlelerini yaptı, onay bekliyor
  gameOver,         // Oyun bitti
}

// --- ENTITIES ---

class Piece {
  final int id;
  final Player player;

  const Piece({required this.id, required this.player});

  Map<String, dynamic> toJson() => {
    'id': id,
    'player': player.name, // 'white' veya 'black'
  };

  factory Piece.fromJson(Map<String, dynamic> json) => Piece(
    id: json['id'],
    player: Player.values.firstWhere((e) => e.name == json['player']),
  );
}

class Point {
  final List<Piece> pieces;

  const Point({this.pieces = const []});

  int get pieceCount => pieces.length;
  Player? get player => pieces.isNotEmpty ? pieces.first.player : null;

  Point copyWith({List<Piece>? pieces}) {
    return Point(pieces: pieces ?? this.pieces);
  }

  Map<String, dynamic> toJson() => {
    'pieces': pieces.map((p) => p.toJson()).toList(),
  };

  factory Point.fromJson(Map<String, dynamic> json) => Point(
    pieces: (json['pieces'] as List).map((p) => Piece.fromJson(p)).toList(),
  );
}

class Move {
  final int from;
  final int to;
  final int die; // Hangi zar kullanıldı?

  const Move({required this.from, required this.to, required this.die});

  Map<String, dynamic> toJson() => {'from': from, 'to': to, 'die': die};

  factory Move.fromJson(Map<String, dynamic> json) => Move(
    from: json['from'],
    to: json['to'],
    die: json['die'],
  );
}

// --- STATE ---

class GameState {
  final List<Point> points;
  final List<Piece> whiteBar;
  final List<Piece> blackBar;
  final List<Piece> whiteHome;
  final List<Piece> blackHome;
  final Player currentPlayer;
  final List<int> dice;
  final GamePhase phase;

  // Başlangıç zarı değerleri (Opsiyonel, sadece initialRoll phase'inde anlamlı)
  final int? initialDieWhite;
  final int? initialDieBlack;

  // Animasyon durumları UI içindir, ama state senkronizasyonu için burada tutabiliriz
  final bool isRolling;

  const GameState({
    required this.points,
    required this.whiteBar,
    required this.blackBar,
    required this.whiteHome,
    required this.blackHome,
    required this.currentPlayer,
    required this.dice,
    required this.phase,
    this.initialDieWhite,
    this.initialDieBlack,
    this.isRolling = false,
  });

  // Sıfırdan oyun başlatma (Local için)
  factory GameState.newGame() {
    List<Point> startingPoints = List.generate(24, (_) => const Point());
    int pid = 0;

    // Standart Tavla Dizilimi
    // 24. hane (Index 0) - 2 Siyah
    startingPoints[0] = Point(pieces: List.generate(2, (_) => Piece(id: pid++, player: Player.black)));
    // 13. hane (Index 11) - 5 Siyah
    startingPoints[11] = Point(pieces: List.generate(5, (_) => Piece(id: pid++, player: Player.black)));
    // 8. hane (Index 16) - 3 Siyah
    startingPoints[16] = Point(pieces: List.generate(3, (_) => Piece(id: pid++, player: Player.black)));
    // 6. hane (Index 18) - 5 Siyah
    startingPoints[18] = Point(pieces: List.generate(5, (_) => Piece(id: pid++, player: Player.black)));

    // 19. hane (Index 5) - 5 Beyaz
    startingPoints[5] = Point(pieces: List.generate(5, (_) => Piece(id: pid++, player: Player.white)));
    // 17. hane (Index 7) - 3 Beyaz
    startingPoints[7] = Point(pieces: List.generate(3, (_) => Piece(id: pid++, player: Player.white)));
    // 12. hane (Index 12) - 5 Beyaz
    startingPoints[12] = Point(pieces: List.generate(5, (_) => Piece(id: pid++, player: Player.white)));
    // 1. hane (Index 23) - 2 Beyaz
    startingPoints[23] = Point(pieces: List.generate(2, (_) => Piece(id: pid++, player: Player.white)));

    return GameState(
      points: startingPoints,
      whiteBar: [],
      blackBar: [],
      whiteHome: [],
      blackHome: [],
      currentPlayer: Player.white, // Geçici, initial roll belirleyecek
      dice: [],
      phase: GamePhase.initialRoll,
      isRolling: false,
    );
  }

  GameState copyWith({
    List<Point>? points,
    List<Piece>? whiteBar,
    List<Piece>? blackBar,
    List<Piece>? whiteHome,
    List<Piece>? blackHome,
    Player? currentPlayer,
    List<int>? dice,
    GamePhase? phase,
    int? initialDieWhite,
    int? initialDieBlack,
    bool? isRolling,
    bool clearInitialDice = false, // Helper to clear dice
  }) {
    return GameState(
      points: points ?? this.points,
      whiteBar: whiteBar ?? this.whiteBar,
      blackBar: blackBar ?? this.blackBar,
      whiteHome: whiteHome ?? this.whiteHome,
      blackHome: blackHome ?? this.blackHome,
      currentPlayer: currentPlayer ?? this.currentPlayer,
      dice: dice ?? this.dice,
      phase: phase ?? this.phase,
      initialDieWhite: clearInitialDice ? null : (initialDieWhite ?? this.initialDieWhite),
      initialDieBlack: clearInitialDice ? null : (initialDieBlack ?? this.initialDieBlack),
      isRolling: isRolling ?? this.isRolling,
    );
  }

  // Helper Methods
  bool hasWon(Player player) {
    return player == Player.white ? whiteHome.length == 15 : blackHome.length == 15;
  }

  int pipCount(Player player) {
    // Pip: Taşların menzili. Home'daki taşlar 0, bardaki taşlar 25 sayılır.
    int total = 0;
    // Board points
    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      if (p.player == null) continue;
      final distance = player == Player.white ? (i + 1) : (24 - i);
      if (p.player == player) {
        total += distance * p.pieceCount;
      }
    }
    // Bar taşları
    final barPieces = player == Player.white ? whiteBar.length : blackBar.length;
    total += barPieces * 25;
    // Home taşları 0 pip
    return total;
  }

  Map<String, dynamic> toJson() => {
    'points': points.map((p) => p.toJson()).toList(),
    'whiteBar': whiteBar.map((p) => p.toJson()).toList(),
    'blackBar': blackBar.map((p) => p.toJson()).toList(),
    'whiteHome': whiteHome.map((p) => p.toJson()).toList(),
    'blackHome': blackHome.map((p) => p.toJson()).toList(),
    'currentPlayer': currentPlayer.name,
    'dice': dice,
    'phase': phase.name,
    'initialDieWhite': initialDieWhite,
    'initialDieBlack': initialDieBlack,
    'isRolling': isRolling,
  };

  factory GameState.fromJson(Map<String, dynamic> json) {
    return GameState(
      points: (json['points'] as List).map((p) => Point.fromJson(p)).toList(),
      whiteBar: (json['whiteBar'] as List).map((p) => Piece.fromJson(p)).toList(),
      blackBar: (json['blackBar'] as List).map((p) => Piece.fromJson(p)).toList(),
      whiteHome: (json['whiteHome'] as List).map((p) => Piece.fromJson(p)).toList(),
      blackHome: (json['blackHome'] as List).map((p) => Piece.fromJson(p)).toList(),
      currentPlayer: Player.values.firstWhere((e) => e.name == json['currentPlayer']),
      dice: List<int>.from(json['dice'] ?? []),
      phase: GamePhase.values.firstWhere(
              (e) => e.name == json['phase'],
          orElse: () => GamePhase.playing // Güvenlik önlemi
      ),
      initialDieWhite: json['initialDieWhite'],
      initialDieBlack: json['initialDieBlack'],
      isRolling: json['isRolling'] ?? false,
    );
  }
}


