import 'dart:math';
import 'package:flutter/material.dart';
import '../shared/card_face.dart';
import '../shared/game_page.dart';
import '../shared/game_storage.dart';
import 'kings_corner_game.dart';

class KingsCornerScreen extends StatefulWidget {
  const KingsCornerScreen({super.key});

  @override
  State<KingsCornerScreen> createState() => _KingsCornerScreenState();
}

class _KingsCornerScreenState extends State<KingsCornerScreen> {
  final random = Random();
  late KingsCornerGame game;
  bool ready = false, revealed = false, vsComputer = true, thinking = false;
  int epoch = 0;
  int? selectedCard, selectedPile;
  String saveMessage = 'Loading local game...';

  @override
  void initState() {
    super.initState();
    game = KingsCornerGame(random: random);
    restore();
  }

  Future<void> restore() async {
    try {
      final data = await GameStorage.load('kings_corner_v1');
      if (!mounted) return;
      if (data != null) {
        game = KingsCornerGame.fromJson(Map<String, dynamic>.from(data['game'] as Map));
        vsComputer = data['computer'] == true && game.players == 2;
      }
      saveMessage = data == null ? 'Offline local game' : 'Saved game restored; hands are private';
    } catch (_) {
      saveMessage = 'Save could not be restored; a new game is ready';
    }
    if (!mounted) return;
    setState(() => ready = true);
    runComputer();
  }

  Future<void> save() async {
    try {
      await GameStorage.save('kings_corner_v1', {
        'game': game.toJson(),
        'computer': vsComputer,
      });
      if (mounted) setState(() => saveMessage = 'Progress saved on this device');
    } catch (_) {
      if (mounted) setState(() => saveMessage = 'Save unavailable; keep this game open');
    }
  }

  bool get canAct => ready && !thinking && !game.finished && revealed &&
      (!vsComputer || game.current != 1);

  void newGame(int players, bool computer) {
    epoch++;
    setState(() {
      game = KingsCornerGame(players: players, random: random);
      vsComputer = computer;
      thinking = false;
      revealed = false;
      selectedCard = null;
      selectedPile = null;
    });
    save();
  }

  void selectCard(int index) {
    if (!canAct) return;
    setState(() {
      selectedCard = selectedCard == index ? null : index;
      selectedPile = null;
    });
  }

  void selectTableau(int index) {
    if (!canAct) return;
    var changed = false;
    setState(() {
      if (selectedCard != null) {
        changed = game.playCard(selectedCard!, index);
        selectedCard = null;
        selectedPile = null;
      } else if (selectedPile != null) {
        if (selectedPile == index) {
          selectedPile = null;
        } else {
          changed = game.movePile(selectedPile!, index);
          selectedPile = null;
        }
      } else if (index < 4 && game.piles[index].isNotEmpty) {
        selectedPile = index;
      }
      if (game.finished) revealed = false;
    });
    if (changed) save();
  }

  void endTurn() {
    if (!canAct) return;
    setState(() {
      game.endTurn();
      revealed = false;
      selectedCard = null;
      selectedPile = null;
    });
    save();
    runComputer();
  }

  Future<void> runComputer() async {
    if (!mounted || !ready || !vsComputer || thinking ||
        game.finished || game.current != 1) return;
    final token = ++epoch;
    setState(() {
      thinking = true;
      revealed = false;
    });
    await Future<void>.delayed(const Duration(milliseconds: 260));
    if (!mounted || token != epoch) return;
    setState(() {
      game.playGreedyTurn();
      thinking = false;
    });
    await save();
  }

  @override
  void dispose() {
    epoch++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameOver = game.finished;
    const labels = [
      'North', 'East', 'South', 'West',
      'Corner 1', 'Corner 2', 'Corner 3', 'Corner 4',
    ];
    final status = gameOver
        ? 'Round finished - Player ${game.winner! + 1} wins. Penalties: ${game.penaltyScores.join(' / ')}'
        : 'Player ${game.current + 1} turn - ${thinking ? 'computer playing' : 'stock: ${game.stock.remaining}'}';
    return GamePage(
      title: "King's Corner",
      rules: 'Draw one card automatically at the start of each turn. '
          'Tap a card, then a pile, to build down one rank in alternating red/black. '
          'Only kings may start the four corner piles. Tap a side pile, then '
          'another pile, to move the entire stack if its bottom card fits. '
          'Any card may start an emptied side pile. Make as many moves as you like, '
          'then end your turn. The first player to empty their hand wins. '
          'When the stock is empty and every player passes, the fewest penalty '
          'points wins (10 for a king, 1 for any other card). '
          'Computer mode is heads-up; local pass-and-play allows 2-4 people. '
          'Hands stay hidden between turns and after a saved-game restore.',
      status: status,
      saveStatus: saveMessage,
      actions: [
        IconButton(
          tooltip: 'New game',
          onPressed: ready ? () => newGame(game.players, vsComputer) : null,
          icon: const Icon(Icons.restart_alt),
        ),
      ],
      children: [
        DropdownButton<String>(
          isExpanded: true,
          value: vsComputer ? 'computer' : '${game.players}',
          items: [
            const DropdownMenuItem(value: 'computer', child: Text('You vs casual computer')),
            for (final n in [2, 3, 4])
              DropdownMenuItem(value: '$n', child: Text('$n local players')),
          ],
          onChanged: !ready || thinking ? null : (choice) {
            if (choice != null) {
              newGame(choice == 'computer' ? 2 : int.parse(choice),
                  choice == 'computer');
            }
          },
        ),
        const Text('Changing opponents starts a new game.'),
        GameSection(
          title: 'Tableau',
          child: Wrap(
            spacing: 6,
            runSpacing: 12,
            children: [
              for (var index = 0; index < 8; index++)
                SizedBox(
                  width: 88,
                  child: Column(
                    children: [
                      Text(labels[index], textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelSmall),
                      CardFace(
                        card: game.piles[index].isEmpty ? null : game.piles[index].last,
                        selected: selectedPile == index,
                        onTap: canAct ? () => selectTableau(index) : null,
                      ),
                      Text(game.piles[index].isEmpty
                          ? (index < 4 ? 'Open side' : 'King only')
                          : '${game.piles[index].length} cards',
                          style: Theme.of(context).textTheme.labelSmall),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (selectedCard != null)
          const Text('Select a tableau pile to place your card.'),
        if (selectedPile != null)
          const Text('Select a destination to move the entire side pile.'),
        for (var seat = 0; seat < game.players; seat++)
          GameSection(
            title: 'Player ${seat + 1}${vsComputer && seat == 1 ? ' (computer)' : ''}: '
                '${game.hands[seat].length} cards',
            child: seat == game.current && revealed && !thinking && !gameOver
                ? Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var index = 0; index < game.hands[seat].length; index++)
                        CardFace(
                          card: game.hands[seat][index],
                          selected: selectedCard == index,
                          onTap: canAct ? () => selectCard(index) : null,
                        ),
                    ],
                  )
                : const Text('Hand hidden until it is this player\'s turn'),
          ),
        if (ready && !gameOver && !thinking && !revealed)
          FilledButton.icon(
            onPressed: () => setState(() => revealed = true),
            icon: const Icon(Icons.visibility),
            label: Text('View Player ${game.current + 1} cards'),
          ),
        if (canAct)
          FilledButton(
            onPressed: endTurn,
            child: const Text('End turn'),
          ),
        if (gameOver)
          FilledButton(
            onPressed: () => newGame(game.players, vsComputer),
            child: const Text('Play again'),
          ),
      ],
    );
  }
}
