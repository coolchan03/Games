import 'dart:math';

import 'package:flutter/material.dart';
import '../common/game_kit.dart';
import 'casebook_engine.dart';

class DetectiveCasebookScreen extends StatefulWidget {
  const DetectiveCasebookScreen({super.key});
  @override
  State<DetectiveCasebookScreen> createState() => _DetectiveScreenState();
}
class _DetectiveScreenState extends State<DetectiveCasebookScreen> {
  int caseIndex = 0, hints = 0;
  int? accusation;
  bool solved = false;
  String? message;
  String notebookTab = 'Rooms';
  final Set<int> checked = {};
  final Map<String,int> notes = {};
  DetectiveCase? generated;
  CaseDifficulty generatedDifficulty = CaseDifficulty.easy;
  DetectiveCase get game => generated ?? DetectiveCasebook.cases[caseIndex];
  void _reset() {
    hints=0;accusation=null;solved=false;message=null;
    checked.clear();notes.clear();
  }
  void selectCase(int n) => setState(() {
    caseIndex=n;generated=null;_reset();
  });
  void dailyCase() => setState(() {
    final now=DateTime.now();
    final seed=now.year*10000+now.month*100+now.day;
    generated=DetectiveCasebook.generate(seed,difficulty:generatedDifficulty);
    _reset();
  });
  void randomCase() => setState(() {
    generated=DetectiveCasebook.generate(Random().nextInt(1000000),
      difficulty:generatedDifficulty);
    _reset();
  });
  void submit() {
    if(accusation==null)return;
    setState((){
      solved=game.accuse(game.suspects[accusation!]);
      if(solved)reportCompletion(context,'detective_casebook');
      message=solved?'Case closed! Your conclusion fits every clue.'
        :'That accusation does not fit the evidence. Try another suspect.';
    });
  }
  Future<void> reveal() async {
    final ok=await showDialog<bool>(context:context,
      builder:(ctx)=>AlertDialog(
        title:const Text('Spoil the solution?'),
        content:const Text('The culprit and evidence trail will be revealed.'),
        actions:[
          TextButton(onPressed:()=>Navigator.pop(ctx,false),
            child:const Text('Cancel')),
          FilledButton(onPressed:()=>Navigator.pop(ctx,true),
            child:const Text('Reveal')),
        ]));
    if(!mounted||ok!=true)return;
    setState((){
      accusation=game.culpritIndex;solved=true;
      message='${game.culprit} had the ${game.incidentObject.toLowerCase()}, '
        'visited the ${game.rooms[game.incidentRoomIndex]}, '
        'and arrived at ${game.times[game.incidentTimeIndex]}.';
    });
  }
  String get hint {
    if(hints==1)return 'Follow the ${game.incidentObject.toLowerCase()} '
        'through the witness statements. Who held it?';
    if(hints==2)return 'The person with the '
        '${game.incidentObject.toLowerCase()} visited the '
        '${game.rooms[game.incidentRoomIndex]}.';
    return 'The weapon arrived at '
        '${game.times[game.incidentTimeIndex]}.';
  }
  Widget notebook(BuildContext context) {
    final values=notebookTab=='Rooms'?game.rooms:
      notebookTab=='Times'?game.times:game.objects;
    final scheme=Theme.of(context).colorScheme;
    return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      DropdownButton<String>(value:notebookTab,items:const [
        DropdownMenuItem(value:'Rooms',child:Text('Suspects × rooms')),
        DropdownMenuItem(value:'Times',child:Text('Suspects × times')),
        DropdownMenuItem(value:'Objects',child:Text('Suspects × objects')),
      ],onChanged:(v){if(v!=null)setState(()=>notebookTab=v);}),
      const Text('Tap cells: ? → × excluded → ✓ possible. '
        'These are your personal notes.'),
      const SizedBox(height:12),
      SingleChildScrollView(scrollDirection:Axis.horizontal,
        child:Column(children:[
          Row(children:[
            const SizedBox(width:118),
            for(final label in values)
              SizedBox(width:90,child:Text(label,textAlign:TextAlign.center,
                maxLines:2,overflow:TextOverflow.ellipsis)),
          ]),
          for(var s=0;s<4;s++)
            Row(children:[
              SizedBox(width:118,child:Text(game.suspects[s],maxLines:2,
                overflow:TextOverflow.ellipsis)),
              for(var v=0;v<4;v++)
                SizedBox(width:90,height:48,
                  child:InkWell(onTap:(){
                    final key='$notebookTab/$s/$v';
                    setState(()=>notes[key]=((notes[key]??0)+1)%3);
                  },child:Card(
                    color:(notes['$notebookTab/$s/$v']??0)==2
                      ?scheme.primaryContainer:scheme.surfaceContainer,
                    child:Center(child:Text(switch(notes['$notebookTab/$s/$v']??0){
                      1=>'×',2=>'✓',_=>'?',
                    },style:Theme.of(context).textTheme.titleMedium)),
                  )),
                ),
            ]),
        ]),
      ),
    ]);
  }
  @override
  Widget build(BuildContext context) {
    final c=game;
    return Scaffold(appBar:AppBar(title:const Text('Detective Casebook')),
      body:SafeArea(child:Center(child:ConstrainedBox(
        constraints:const BoxConstraints(maxWidth:750),
        child:ListView(padding:const EdgeInsets.all(16),children:[
          const Text('Read the clues and solve each mystery using logic. '
            'Every case — including generated daily and random cases — is '
            'checked by a solver to have exactly one solution. Hard cases '
            'contain no direct statements of where anyone was.'),
          const SizedBox(height:12),
          DropdownButton<int>(
            isExpanded:true,value:generated==null?caseIndex:-1,
            items:[
              if(generated!=null)DropdownMenuItem(value:-1,
                child:Text(generated!.title,overflow:TextOverflow.ellipsis)),
              for(var i=0;i<DetectiveCasebook.cases.length;i++)
                DropdownMenuItem(value:i,child:Text(
                  'Case ${i+1}: ${DetectiveCasebook.cases[i].title}'
                  '${DetectiveCasebook.cases[i].difficulty==CaseDifficulty.hard?' (hard)':''}',
                  overflow:TextOverflow.ellipsis))],
            onChanged:(v){if(v!=null&&v>=0)selectCase(v);}),
          Wrap(spacing:8,runSpacing:8,crossAxisAlignment:WrapCrossAlignment.center,children:[
            SegmentedButton<CaseDifficulty>(
              segments:const [
                ButtonSegment(value:CaseDifficulty.easy,label:Text('Easy')),
                ButtonSegment(value:CaseDifficulty.hard,label:Text('Hard')),
              ],
              selected:{generatedDifficulty},
              onSelectionChanged:(v)=>setState(()=>generatedDifficulty=v.first)),
            OutlinedButton.icon(onPressed:dailyCase,
              icon:const Icon(Icons.today_outlined),label:const Text('Daily case')),
            OutlinedButton.icon(onPressed:randomCase,
              icon:const Icon(Icons.casino_outlined),label:const Text('New random case')),
          ]),
          const SizedBox(height:10),
          Card(child:Padding(padding:const EdgeInsets.all(16),
            child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text(c.title,style:Theme.of(context).textTheme.titleLarge),
              const SizedBox(height:10),
              Text(c.summary),
            ]))),
          const SizedBox(height:12),
          Text('Witness statements and evidence',
            style:Theme.of(context).textTheme.titleMedium),
          for(var i=0;i<c.clues.length;i++)
            CheckboxListTile(
              dense:true,
              contentPadding:const EdgeInsets.symmetric(horizontal:8),
              controlAffinity:ListTileControlAffinity.leading,
              value:checked.contains(i),title:Text(c.clues[i].text),
              onChanged:(v)=>setState((){
                if(v==true){checked.add(i);}else{checked.remove(i);}
              }),
            ),
          Card(child:ExpansionTile(
            title:const Text('Deduction notebook'),
            subtitle:const Text('Cross out impossibilities and mark hypotheses'),
            children:[Padding(padding:const EdgeInsets.all(12),
              child:notebook(context))],
          )),
          const SizedBox(height:16),
          Text('Who is responsible?',
            style:Theme.of(context).textTheme.titleMedium),
          const SizedBox(height:10),
          Wrap(spacing:8,runSpacing:8,children:[
            for(var i=0;i<c.suspects.length;i++)
              ChoiceChip(label:Text(c.suspects[i]),selected:accusation==i,
                onSelected:solved?null:(_)=>setState((){
                  accusation=i;message=null;
                })),
          ]),
          const SizedBox(height:14),
          FilledButton.icon(
            onPressed:accusation==null||solved?null:submit,
            icon:const Icon(Icons.fact_check_outlined),
            label:const Text('Submit accusation')),
          if(message!=null)Padding(padding:const EdgeInsets.only(top:12),
            child:Text(message!,style:Theme.of(context).textTheme.titleSmall)),
          if(hints>0)Padding(padding:const EdgeInsets.symmetric(vertical:12),
            child:Text(hint)),
          Wrap(spacing:8,children:[
            TextButton.icon(
              onPressed:hints<3&&!solved?()=>setState(()=>hints++):null,
              icon:const Icon(Icons.lightbulb_outline),
              label:Text('Hint ($hints/3)')),
            TextButton.icon(
              onPressed:solved?null:reveal,
              icon:const Icon(Icons.visibility_outlined),
              label:const Text('Reveal solution')),
          ]),
          const SizedBox(height:28),
        ]),
      ))),
    );
  }
}
