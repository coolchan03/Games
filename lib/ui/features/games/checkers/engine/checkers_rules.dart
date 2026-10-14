import 'dart:math';

/// English/American checkers. Rules adapted from the MIT-licensed
/// felipersteles/checkers-with-ai logical move engine.
class CheckersMove {
  final int from, to;
  final List<int> captured;
  const CheckersMove(this.from, this.to, [this.captured = const []]);
  bool get isCapture => captured.isNotEmpty;
}
class CheckersPosition {
  /// 0 empty, 1 white man, 2 black man, 3 white king, 4 black king.
  final List<int> cells;
  final int turn;
  const CheckersPosition(this.cells, this.turn);
  factory CheckersPosition.start() => CheckersPosition(
    List.generate(64, (i) {
      final row=i~/8,col=i%8;
      return (row+col)%2==0?0:row<3?2:row>4?1:0;
    }), 1,
  );
  static int owner(int v) => v==1||v==3?1:v==2||v==4?2:0;
  static bool within(int row,int col) =>
      row>=0&&row<8&&col>=0&&col<8;
  static List<List<int>> directions(int piece) =>
      piece==3||piece==4
          ? const [[-1,-1],[-1,1],[1,-1],[1,1]]
          : piece==1 ? const [[-1,-1],[-1,1]]
              : const [[1,-1],[1,1]];
  static int promote(int piece,int row) =>
      piece==1&&row==0?3:piece==2&&row==7?4:piece;

  void captureChains(List<int> b,int origin,int current,
      List<int> eaten,List<CheckersMove> output) {
    final piece=b[current];
    final row=current~/8,col=current%8;
    var more=false;
    for(final d in directions(piece)) {
      final mr=row+d[0],mc=col+d[1];
      final nr=row+2*d[0],nc=col+2*d[1];
      if(!within(mr,mc)||!within(nr,nc))continue;
      final mid=mr*8+mc,end=nr*8+nc;
      if(owner(b[mid])==0||owner(b[mid])==owner(piece)||b[end]!=0)continue;
      more=true;
      final after=List<int>.from(b);
      after[current]=0;
      after[mid]=0;
      final newPiece=promote(piece,nr);
      after[end]=newPiece;
      final captures=[...eaten,mid];
      if(newPiece!=piece) {
        // In English checkers promotion ends a capture turn.
        output.add(CheckersMove(origin,end,captures));
      } else {
        captureChains(after,origin,end,captures,output);
      }
    }
    if(!more&&eaten.isNotEmpty){
      output.add(CheckersMove(origin,current,eaten));
    }
  }

  List<CheckersMove> get legalMoves {
    final captures=<CheckersMove>[];
    final slides=<CheckersMove>[];
    for(var i=0;i<64;i++) {
      final piece=cells[i];
      if(owner(piece)!=turn)continue;
      captureChains(cells,i,i,[],captures);
      final r=i~/8,c=i%8;
      for(final dir in directions(piece)) {
        final nr=r+dir[0],nc=c+dir[1];
        if(within(nr,nc)&&cells[nr*8+nc]==0) {
          slides.add(CheckersMove(i,nr*8+nc));
        }
      }
    }
    return captures.isNotEmpty?captures:slides;
  }
  CheckersPosition play(CheckersMove move) {
    final next=List<int>.from(cells);
    final piece=next[move.from];
    next[move.from]=0;
    for(final index in move.captured)next[index]=0;
    next[move.to]=promote(piece,move.to~/8);
    return CheckersPosition(next,3-turn);
  }
  bool get complete => legalMoves.isEmpty;
  int? get winner => complete?3-turn:null;
}
class CheckersComputer {
  final Random random=Random();
  int score(CheckersPosition s) {
    if(s.complete)return s.turn==2?-100000:100000;
    var value=0;
    for(var i=0;i<64;i++) {
      final p=s.cells[i];
      if(p==0)continue;
      final row=i~/8;
      final strength=p==3||p==4?175:100;
      final bonus=p==1?7-row:p==2?row:0;
      value+=p==2||p==4?strength+bonus:-(strength+bonus);
    }
    return value;
  }
  int search(CheckersPosition s,int depth,int alpha,int beta) {
    if(depth==0||s.complete)return score(s);
    if(s.turn==2) {
      var best=-999999;
      for(final move in s.legalMoves){
        best=max(best,search(s.play(move),depth-1,alpha,beta));
        alpha=max(alpha,best);
        if(alpha>=beta)break;
      }
      return best;
    }
    var best=999999;
    for(final move in s.legalMoves){
      best=min(best,search(s.play(move),depth-1,alpha,beta));
      beta=min(beta,best);
      if(alpha>=beta)break;
    }
    return best;
  }
  CheckersMove choose(CheckersPosition game,int difficulty) {
    final moves=game.legalMoves;
    if(difficulty==0||moves.length==1)return moves[random.nextInt(moves.length)];
    var highest=-999999;
    final best=<CheckersMove>[];
    for(final m in moves){
      final next=game.play(m);
      final value=difficulty==1?score(next)
        :search(next,3,-999999,999999);
      if(value>highest){
        highest=value;
        best..clear()..add(m);
      }else if(value==highest)best.add(m);
    }
    return best[random.nextInt(best.length)];
  }
}
