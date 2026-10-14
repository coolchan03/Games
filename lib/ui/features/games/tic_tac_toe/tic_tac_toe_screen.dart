import 'dart:math';
import 'package:flutter/material.dart';

class TicTacToeScreen extends StatefulWidget {
  const TicTacToeScreen({super.key});
  @override
  State<TicTacToeScreen> createState()=>_TicTacToeState();
}
class _TicTacToeState extends State<TicTacToeScreen> {
  final random=Random();
  List<int> board=List.filled(9,0);
  bool vsAi=true;
  int difficulty=1,turn=1;
  int get result {
    for(final line in const [[0,1,2],[3,4,5],[6,7,8],
        [0,3,6],[1,4,7],[2,5,8],[0,4,8],[2,4,6]]) {
      final p=board[line[0]];
      if(p!=0&&line.every((i)=>board[i]==p))return p;
    }
    return board.every((p)=>p!=0)?3:0;
  }
  void reset()=>setState((){board=List.filled(9,0);turn=1;});
  int minimax(int player) {
    final r=result;
    if(r!=0)return r==3?0:r==2?10:-10;
    final options=[for(var i=0;i<9;i++)if(board[i]==0)i];
    var best=player==2?-100:100;
    for(final i in options) {
      board[i]=player;
      final score=minimax(3-player);
      board[i]=0;
      best=player==2?max(best,score):min(best,score);
    }
    return best;
  }
  int aiMove() {
    final options=[for(var i=0;i<9;i++)if(board[i]==0)i];
    if(difficulty==0)return options[random.nextInt(options.length)];
    var best=-100;final good=<int>[];
    for(final i in options) {
      board[i]=2;
      final score=minimax(1);
      board[i]=0;
      if(score>best){best=score;good..clear()..add(i);}
      else if(score==best)good.add(i);
    }
    if(difficulty==1&&random.nextDouble()<.35)
      return options[random.nextInt(options.length)];
    return good[random.nextInt(good.length)];
  }
  void play(int i) {
    if(result!=0||board[i]!=0)return;
    setState((){
      board[i]=turn;
      if(result==0) {
        turn=3-turn;
        if(vsAi) {board[aiMove()]=2;turn=1;}
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    final r=result;
    return Scaffold(appBar:AppBar(title:const Text('Tic-Tac-Toe')),
      body:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:450),
      child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
        SwitchListTile(title:const Text('Play against computer'),value:vsAi,
          onChanged:(v)=>setState((){vsAi=v;board=List.filled(9,0);turn=1;})),
        if(vsAi)SegmentedButton<int>(segments:const [
            ButtonSegment(value:0,label:Text('Easy')),
            ButtonSegment(value:1,label:Text('Medium')),
            ButtonSegment(value:2,label:Text('Hard'))],
          selected:{difficulty},onSelectionChanged:(s)=>setState((){
            difficulty=s.first;board=List.filled(9,0);turn=1;
          })),
        Padding(padding:const EdgeInsets.all(16),child:Text(r==3?'Draw':
          r==2&&vsAi?'Computer wins':r!=0?'Player $r wins':'Player $turn to move')),
        AspectRatio(aspectRatio:1,child:GridView.builder(itemCount:9,
          physics:const NeverScrollableScrollPhysics(),
          gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:3),
          itemBuilder:(context,i)=>Card(child:InkWell(onTap:()=>play(i),
            child:Center(child:Text(board[i]==0?'':board[i]==1?'X':'O',
              style:Theme.of(context).textTheme.displayLarge))))),
        Padding(padding:const EdgeInsets.all(16),
          child:FilledButton(onPressed:reset,child:const Text('New game')))
      ])))));
  }
}
