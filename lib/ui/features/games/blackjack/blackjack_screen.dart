import 'dart:math';
import 'package:flutter/material.dart';

/// Offline blackjack: virtual scores only, no real-money wagering.
class BlackjackScreen extends StatefulWidget {
  const BlackjackScreen({super.key});
  @override
  State<BlackjackScreen> createState() => _BlackjackState();
}
class _BlackjackState extends State<BlackjackScreen> {
  final random=Random();
  final suits=const ['♠','♥','♦','♣'];
  final faces=const ['A','2','3','4','5','6','7','8','9','10','J','Q','K'];
  List<String> player=[],dealer=[];
  bool ended=false;
  String result='';
  int wins=0,losses=0,pushes=0;

  _BlackjackState(){deal();}
  String draw()=>'${faces[random.nextInt(faces.length)]}${suits[random.nextInt(suits.length)]}';
  int value(List<String> hand) {
    var total=0,aces=0;
    for(final card in hand) {
      final face=card.substring(0,card.length-1);
      if(face=='A'){total+=11;aces++;}
      else{final num=int.tryParse(face);total+=num??10;}
    }
    while(total>21&&aces>0){total-=10;aces--;}
    return total;
  }
  void deal() {
    player=[draw(),draw()];dealer=[draw(),draw()];
    ended=false;result='';
    if(value(player)==21||value(dealer)==21){settle(natural:true);}
  }
  void settle({bool natural=false}) {
    if(!natural) {
      while(value(dealer)<17)dealer.add(draw());
    }
    final p=value(player),d=value(dealer);
    if(p>21){losses++;result='Bust — dealer wins';}
    else if(d>21||p>d){wins++;result='You win!';}
    else if(d>p){losses++;result='Dealer wins';}
    else{pushes++;result='Push — draw';}
    ended=true;
  }
  void hit() {
    if(ended)return;
    setState((){
      player.add(draw());
      if(value(player)>21)settle();
      else if(value(player)==21)settle();
    });
  }
  void stand() {if(!ended)setState(()=>settle());}
  Widget cards(List<String> hand,{bool hide=false}) {
    return Wrap(spacing:8,runSpacing:8,
      children:[for(var i=0;i<hand.length;i++)
        Container(width:65,height:96,alignment:Alignment.center,
          decoration:BoxDecoration(
            color:Theme.of(context).colorScheme.surfaceContainerHighest,
            border:Border.all(color:Theme.of(context).colorScheme.outline),
            borderRadius:BorderRadius.circular(8)),
          child:Text(hide&&i==1?'?':hand[i],
            style:Theme.of(context).textTheme.titleLarge))]);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:AppBar(title:const Text('Blackjack')),
      body:SafeArea(child:Center(child:ConstrainedBox(
        constraints:const BoxConstraints(maxWidth:600),
        child:Padding(padding:const EdgeInsets.all(20),child:Column(
          mainAxisAlignment:MainAxisAlignment.center,
          crossAxisAlignment:CrossAxisAlignment.stretch,children:[
          Text('Dealer ${ended?value(dealer):value([dealer.first])}',
            style:Theme.of(context).textTheme.titleMedium),
          const SizedBox(height:8),cards(dealer,hide:!ended),
          const SizedBox(height:30),
          Text('You ${value(player)}',
            style:Theme.of(context).textTheme.titleMedium),
          const SizedBox(height:8),cards(player),
          const SizedBox(height:24),
          Text(ended?result:'Hit or stand?',
            textAlign:TextAlign.center,
            style:Theme.of(context).textTheme.titleLarge),
          const SizedBox(height:20),
          if(!ended)Row(children:[
            Expanded(child:FilledButton(onPressed:hit,child:const Text('Hit'))),
            const SizedBox(width:10),
            Expanded(child:OutlinedButton(onPressed:stand,child:const Text('Stand')))
          ])else FilledButton(onPressed:()=>setState(deal),
            child:const Text('Deal again')),
          const SizedBox(height:16),
          Text('Wins $wins  ·  Losses $losses  ·  Pushes $pushes',
            textAlign:TextAlign.center),
          const SizedBox(height:8),
          const Text('Offline • standard dealer stands on soft 17 • virtual scores only',
            textAlign:TextAlign.center)
        ]))))));
  }
}
