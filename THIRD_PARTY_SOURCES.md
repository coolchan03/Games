# Third-party game code and attribution

Games is based on sidhant947/Puzzle (GPL-3.0). Existing upstream notices remain.

## Copied source — Reversi
- Source: https://github.com/redbrogdon/flutterflip
- Original files: packages/flutterflip_shared/lib/game_board.dart and game_board_scorer.dart
- Location: lib/ui/features/games/reversi/engine/
- License: BSD 3-Clause, Copyright 2018 The Chromium Authors. All rights reserved.
- The original license text is preserved in THIRD_PARTY_LICENSES/flutterflip-BSD-3-Clause.txt.
- UI and selectable difficulty AI added here without embedding the upstream app.

## Copied source — Mancala
- Source: https://github.com/z7workbench/minigames
- Original file: lib/games/mancala/models/mancala_state.dart
- Location: lib/ui/features/games/mancala/engine/
- License: MIT, Copyright (c) 2021 ZeroGo Yoosee.
- Original license text preserved in THIRD_PARTY_LICENSES/minigames-MIT.txt.
- UI and turn-aware alpha-beta AI added here without importing the upstream DB.

## Adapted source — Checkers
- Source: https://github.com/felipersteles/checkers-with-ai
- Reference files: machine.js and game.js (logical move rules, mandatory captures, chain jumps, AI minimax).
- Location: lib/ui/features/games/checkers/engine/checkers_rules.dart
- License: MIT; original LICENSE retained at THIRD_PARTY_LICENSES/checkers-MIT.txt.
- Reimplemented English/American rules in pure Dart without the original DOM or JavaScript runtime, with local two-player and selectable AI.

## Copied source — Mahjong tile matching
- Source: https://github.com/edave64/ED-Mahjong
- Original file: lib/engine/pieces/mahjong_tile.dart
- Location: lib/ui/features/games/mahjong_solitaire/engine/mahjong_tile.dart
- License: MIT for source code; the original project licenses graphical assets separately. LICENSE retained at THIRD_PARTY_LICENSES/ED-Mahjong-MIT.txt.
- No upstream art assets were copied. Games adds a compact 64-tile single-layer arrangement with guaranteed solution sequences, using standard Unicode Mahjong glyphs. Full layered Mahjong Solitaire remains planned.

## Copied source — Chess
- Source: https://github.com/z7workbench/minigames
- Original files: lib/games/chess_intl/models/*, ai/*, logic/* (rules, FEN, SAN, PGN, easy and alpha-beta AI)
- Location: lib/ui/features/games/chess/engine/
- License: MIT, Copyright (c) 2021 ZeroGo Yoosee (THIRD_PARTY_LICENSES/minigames-MIT.txt).
- Changes: an unused counter field was removed; the Games UI is new.

## Copied source — Yacht Dice and Code Breaker
- Source: https://github.com/z7workbench/minigames (MIT, as above)
- Original files: lib/games/yacht_dice/models/{scoring,scoring_category,yacht_dice_state}.dart and ai/*;
  scoring logic from lib/games/hit_and_blow/hit_and_blow_provider.dart.
- Location: lib/ui/features/games/yacht_dice/engine/ and lib/ui/features/games/code_breaker/
- Changes: the Riverpod provider turn logic was adapted into a plain Dart controller
  (yacht_game.dart); Code Breaker adds colour pegs, modes and a consistency hint solver.

## Copied source — Hearts, Spades, Oh Hell and shared card model
- Source: https://github.com/dozingcat/CardsWithCats
- Original files: lib/cards/{card,trick,round,rollout}.dart, lib/hearts/{hearts,hearts_ai}.dart,
  lib/spades/{spades,spades_ai}.dart, lib/ohhell/{ohhell,ohhell_ai}.dart
- Location: lib/ui/features/games/common/cards/, hearts/engine/, spades/engine/, oh_hell/engine/
- License: GPL-3.0 (same as Games); copy in THIRD_PARTY_LICENSES/CardsWithCats-GPL-3.0.txt.
- Changes: package imports rewritten to relative paths. The card artwork and cat images
  were not copied; Games draws cards with vector widgets (common/card_view.dart).

## Copied source — Backgammon
- Source: https://github.com/demirburakk/bbackgammon (backgammon_shared package)
- Original files: lib/src/entities/game_entities.dart, lib/src/logic/heuristic_evaluator.dart,
  lib/src/usecases/get_possible_moves.dart, lib/src/usecases/move_piece_use_case.dart,
  lib/src/common/constants.dart (board indices only)
- Location: lib/ui/features/games/backgammon/engine/
- License: GPL-3.0 (THIRD_PARTY_LICENSES/bbackgammon-GPL-3.0.txt)
- Changes: imports made relative; maxPlayableMoves made public. New backgammon_match.dart
  adds opening roll, doubles, the "use as many dice as possible" rule and a full-turn search AI.

## Adapted data — Ludo
- Source: https://github.com/nizwar/ludo_flutter lib/constants.dart (route and safe squares)
- License: Apache-2.0 (THIRD_PARTY_LICENSES/ludo_flutter-Apache-2.0.txt, NOTICE in ludo_flutter-NOTICE.txt)
- Location: lib/ui/features/games/ludo/ludo_engine.dart. Engine (fair dice), AI and UI are new.

## Original pure-Dart games written for Games
Texas Hold'em, Video Poker, poker evaluator, Klondike, FreeCell (Microsoft deal numbering
algorithm), Spider, Golf, Pyramid, Nine Men's Morris, Gomoku, Dots and Boxes, Battleship,
Snakes and Ladders, Peg Solitaire, Shut the Box, Tower of Hanoi and Memory Pairs. These
implement traditional public-domain rules and include no third-party code.

## Research and future port candidates
- https://github.com/edave64/ED-Mahjong — Flutter MIT game engine; assets separately licensed
- https://github.com/felipersteles/checkers-with-ai — MIT, JavaScript rules and AI
- https://github.com/johnmorrisdotca/domino — MIT, JS/TS Mexican Train and computer seats
- https://github.com/shlomif/PySolFC — GPL-3.0, Python solitaire collection
- https://github.com/KevinGundlach/LogikGen — MIT, logic-grid generators and constraints (C#)
- https://github.com/obijywk/grilops — MIT, Python grid puzzle solver
- https://github.com/bocaletto-luca/Cluedo-Multiplayer — GPL-3.0, browser deduction game

No unlicensed crime-game repositories are copied. The original Detective Casebook
content is created for Games and requires no web API or separate runtime.
