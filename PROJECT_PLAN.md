# Games - Implementation Plan

## Product
One offline-first Flutter application for Android and web (GitHub Pages), built from sidhant947/Puzzle under GPL-3.0. A single responsive visual system supplies navigation, game cards, board/piece rendering, card and dice assets, modes, dialogs, persistence, and accessibility. Do not embed whole mini-apps or use WebViews.

## Core rules
- All original Puzzle titles retained unless demonstrably broken or duplicate.
- Competitive games: local pass-and-play (2-6 where rules allow), AI with Easy/Medium/Hard where meaningful. Casino-style single-player games use consistent dealer rules, not artificially random "AI" difficulties.
- Blackjack/Poker: virtual chips only; no betting, payments, or real-money integration.
- Solo puzzles: clearly labeled solo; randomized seeds and daily challenges.
- Every game is a module registered in one library, shares a common design, and has restart, rules, persistence and accessibility plans.
- Installable web PWA, offline save on device, no user accounts. Lazy-load heavyweight engines, keep themes vector-based.
- Track license and provenance before copying code; leave MIT/BSD/Apache notices in LICENSES.

## Already in Puzzle
Word Search, Crossword, Cryptogram, Einstein Riddle, Sudoku, Nonogram, Minesweeper, Word Mastermind, 2048, and hundreds of other games. Improve rather than duplicate.

## Integration waves
1. Import Puzzle, establish unified library, common board/card themes, browser CI, add Connect Four with local 2P + AI.
2. Chess, Checkers, Reversi, Mancala, Gomoku, Dominoes, Ludo, Backgammon, Mahjong Solitaire and Shisen-Sho.
3. Blackjack, Texas Hold'em, Five Card Draw, video poker, Hearts, Spades, Bridge, Solitaire variations, Yatzy.
4. Full Family's Game Pack parity: Alquerque, Neutron, Oware, Bagh Chal/Bandi, Chinese Checkers, Nine Men's Morris, Goose, Petits Chevaux, Air Hockey, Passe-Trappe, 421 and remaining variants.
5. Extras: Go, Shogi, Riichi Mahjong, Chess variants, Gin Rummy, Cribbage, party/dice games and advanced deduction puzzles.
6. QA: Android + Chrome/Firefox/Safari/Edge, touch/mouse/keyboard, offline caching, local save restore, correct game rules, performance budgets and license audit.

## Source candidates
- Puzzle: https://github.com/sidhant947/Puzzle GPL-3.0
- MiniGames: https://github.com/z7workbench/minigames MIT; chess/Mancala/Yacht Dice
- Modern-Apps: https://github.com/vayun-mathur/Modern-Apps GPL-3.0; Kotlin rule reference, not an embedded Android app
- CardsWithCats: https://github.com/dozingcat/CardsWithCats GPL-3.0; Hearts/Spades/Oh Hell/Bridge
- ED-Mahjong: https://github.com/edave64/ED-Mahjong MIT code; verify asset licenses
- Shisen-Seki: https://github.com/zear/shisen-seki MIT
- Majiang: https://github.com/kobalab/Majiang MIT
- FlutterFlip: https://github.com/redbrogdon/flutterflip BSD-3-Clause
- Checkers: https://github.com/felipersteles/checkers-with-ai MIT
- Domino: https://github.com/johnmorrisdotca/domino MIT
- Fairy-Stockfish: https://github.com/fairy-stockfish/Fairy-Stockfish GPL-3.0
- PySolFC: https://github.com/shlomif/PySolFC GPL-3.0

## Current implementation status
Puzzle foundation imported and additional modules registered: Connect Four, Tic-Tac-Toe, Blackjack, Checkers, Mancala, Reversi, Detective Casebook, flat Mahjong Solitaire. GitHub Actions Flutter analysis/tests/web build succeeded for commit 92363ab; Pages deployment remains blocked until Pages is enabled with GitHub Actions as source. See PROJECT_GOALS.md for acceptance gates and docs/GAME_SOURCE_MATRIX.md for detailed game-by-game status.
