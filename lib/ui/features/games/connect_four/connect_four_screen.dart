import 'dart:math';
import 'package:flutter/material.dart';

class ConnectFourScreen extends StatefulWidget {
  const ConnectFourScreen({super.key});
  @override
  State<ConnectFourScreen> createState() => _ConnectFourState();
}
class _ConnectFourState extends State<ConnectFourScreen> {
  final rng = Random();
  late List<List<int>> cells;
  int turn=1, difficulty=1, winner=0;
  bool versusAi=true, done=false;
  _ConnectFourState() { reset(); }
  void reset() {
    cells=List.generate(6, (_) => List.filled(7,0));
    turn=1; winner=0; done=false;
  }
  List<int> get legal => [for(var c=0;c<7;c++) if(cells[0][c]==0)c];
  bool four(List<List<int>> b,int p) {
    for(var r=0;r<6;r++) for(var c=0;c<7;c++)
      for(final d in const [[1,0],[0,1],[1,1],[1,-1]]) {
        bool ok=true;
        for(var k=0;k<4;k++) {
          final y=r+d[0]*k,x=c+d[1]*k;
          if(y<0||y>=6||x<0||x>=7||b[y][x]!=p) {ok=false;break;}
        }
        if(ok)return true;
      }
    return false;
  }
  void drop(List<List<int>> b,int col,int p) {
    for(var r=5;r>=0;r--) if(b[r][col]==0){b[r][col]=p;return;}
  }
  int search(List<List<int>> b,int depth,int p) {
    if(four(b,2))return 10000+depth;
    if(four(b,1))return -10000-depth;
    final choices=[for(var c=0;c<7;c++)if(b[0][c]==0)c];
    if(depth==0||choices.isEmpty)return List.generate(6,
      (r)=>b[r][3]==2?3:b[r][3]==1?-3:0).reduce((a,b)=>a+b);
    var best=p==2?-99999:99999;
    for(final c in choices) {
      final next=b.map((x)=>List<int>.from(x)).toList();
      drop(next,c,p);
      final v=search(next,depth-1,3-p);
      best=p==2?max(best,v):min(best,v);
    }
    return best;
  }
  int ai() {
    if(difficulty==0)return legal[rng.nextInt(legal.length)];
    var best=-99999; final options=<int>[];
    for(final c in legal) {
      final b=cells.map((x)=>List<int>.from(x)).toList();
      drop(b,c,2);
      final v=search(b,difficulty==1?2:4,1);
      if(v>best){best=v;options..clear()..add(c);}
      else if(v==best)options.add(c);
    }
    return options[rng.nextInt(options.length)];
  }
  void advance() {
    if(four(cells,turn)){winner=turn;done=true;}
    else if(legal.isEmpty){done=true;}
    else {turn=3-turn;}
  }
  void play(int col) {
    if(done||!legal.contains(col))return;
    setState((){
      drop(cells,col,turn);advance();
      if(versusAi&&!done){drop(cells,ai(),2);advance();}
    });
  }
  @override
  Widget build(BuildContext context) {
    final colors=Theme.of(context).colorScheme;
    return Scaffold(appBar:AppBar(title:const Text('Connect Four')),
      body:SafeArea(child:Center(child:ConstrainedBox(
        constraints:const BoxConstraints(maxWidth:620),
        child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
          SwitchListTile(title:const Text('Play against computer'),
            value:versusAi,onChanged:(v)=>setState((){versusAi=v;reset();})),
          if(versusAi)SegmentedButton<int>(segments:const [
              ButtonSegment(value:0,label:Text('Easy')),
              ButtonSegment(value:1,label:Text('Medium')),
              ButtonSegment(value:2,label:Text('Hard'))],
            selected:{difficulty},onSelectionChanged:(s)=>setState((){
              difficulty=s.first;reset();
            })),
          Padding(padding:const EdgeInsets.all(12),child:Text(
            done?(winner==0?'Draw!':versusAi&&winner==2
              ?'Computer wins!':'Player $winner wins!')
              :'Player $turn to move')),
          AspectRatio(aspectRatio:7/6,child:GridView.builder(
            physics:const NeverScrollableScrollPhysics(),itemCount:42,
            gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount:7),
            itemBuilder:(context,i){final r=i~/7,c=i%7,p=cells[r][c];
              return InkWell(onTap:()=>play(c),child:Padding(
                padding:const EdgeInsets.all(2),child:DecoratedBox(
                decoration:BoxDecoration(color:colors.primaryContainer,
                  borderRadius:BorderRadius.circular(6)),
                child:Center(child:FractionallySizedBox(
                  widthFactor:.75,heightFactor:.75,child:DecoratedBox(
                  decoration:BoxDecoration(shape:BoxShape.circle,
                    color:p==0?colors.surface:p==1
                      ?colors.tertiary:colors.primary))))));})),
          const SizedBox(height:16),
          FilledButton(onPressed:()=>setState(reset),
            child:const Text('New game'))
        ])))));
  }
}
