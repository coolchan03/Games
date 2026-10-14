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
