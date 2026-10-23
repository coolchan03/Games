/// English (33-hole cross) and European (37-hole) peg solitaire.
class PegBoard {
  PegBoard({this.european = false}) {
    for (var r = 0; r < 7; r++) {
      for (var c = 0; c < 7; c++) {
        final arm = (r >= 2 && r <= 4) || (c >= 2 && c <= 4);
        final corner = european && (r == 1 || r == 5) && (c == 1 || c == 5);
        holes[r * 7 + c] = arm || corner;
      }
    }
    for (var i = 0; i < 49; i++) {
      pegs[i] = holes[i];
    }
    pegs[24] = false;
  }

  final bool european;
  final holes = List.filled(49, false);
  final pegs = List.filled(49, false);
  final List<(int, int, int)> history = [];

  int get remaining => pegs.where((p) => p).length;

  /// Only occupied holes are stored, never the shape or undo references.
  List<int> snapshot() => [for (final occupied in pegs) occupied ? 1 : 0];

  bool restore(List<int> data) {
    if (data.length != 49 || data.any((v) => v != 0 && v != 1)) {
      return false;
    }
    for (var i = 0; i < 49; i++) {
      if (data[i] == 1 && !holes[i]) return false;
    }
    final count = data.where((v) => v == 1).length;
    if (count < 1 || count > holes.where((h) => h).length - 1) {
      return false;
    }
    for (var i = 0; i < 49; i++) {
      pegs[i] = data[i] == 1;
    }
    history.clear();
    return true;
  }

  /// Jump over [over] into [to]; null if illegal.
  (int, int)? _jump(int from, int to) {
    final fr = from ~/ 7, fc = from % 7, tr = to ~/ 7, tc = to % 7;
    if (!((fr == tr && (fc - tc).abs() == 2) || (fc == tc && (fr - tr).abs() == 2))) return null;
    final over = ((fr + tr) ~/ 2) * 7 + (fc + tc) ~/ 2;
    if (!pegs[from] || !pegs[over] || !holes[to] || pegs[to]) return null;
    return (over, to);
  }

  List<int> targets(int from) => [
        for (final d in const [-14, 14, -2, 2])
          if (from + d >= 0 && from + d < 49 && _jump(from, from + d) != null) from + d
      ];

  bool move(int from, int to) {
    final j = _jump(from, to);
    if (j == null) return false;
    pegs[from] = false;
    pegs[j.$1] = false;
    pegs[to] = true;
    history.add((from, j.$1, to));
    return true;
  }

  void undo() {
    if (history.isEmpty) return;
    final (from, over, to) = history.removeLast();
    pegs[from] = true;
    pegs[over] = true;
    pegs[to] = false;
  }

  bool get stuck => ![for (var i = 0; i < 49; i++) if (pegs[i]) i].any((i) => targets(i).isNotEmpty);
  bool get perfect => remaining == 1 && pegs[24];
}
