# Games — FOSS Source Matrix

Updated 2026-10-15. One lightweight Flutter UI for web/Android.
The existing sidhant947/Puzzle (GPL-3.0) is the foundation.
Never embed whole browser apps or Android apps when a small engine or port is sufficient.

Status key:
- **Integrated** — engine + screen in Games, registered in the catalogue, covered by engine
  tests and the 360 dp widget smoke test (`test/games/`), and passing `flutter analyze`,
  `flutter test` and `flutter build web` in GitHub Actions. Not yet checked by hand on Android devices.
- **Verified source** — licence checked, not integrated.
- Details of copied code and licences: [THIRD_PARTY_SOURCES.md](../THIRD_PARTY_SOURCES.md).

## Board and strategy

| Game | Source | License | Status |
| --- | --- | --- | --- |
| Chess | z7workbench/minigames (rules, FEN/SAN, alpha-beta AI) | MIT | Integrated, 2P / 3 AI levels |
| Checkers | felipersteles/checkers-with-ai (rules reference) | MIT | Integrated (earlier) |
| Reversi | redbrogdon/flutterflip | BSD-3-Clause | Integrated (earlier) |
| Connect Four, Tic-Tac-Toe | Original | GPL-3.0 | Integrated (earlier) |
| Mancala (Kalah) | z7workbench/minigames | MIT | Integrated (earlier) |
| Oware (Abapa) | Original | GPL-3.0 | Integrated, 2P / AI |
| Backgammon | demirburakk/bbackgammon (rules, heuristic) | GPL-3.0 | Integrated, gammons, max-dice rule, AI |
| Ludo | nizwar/ludo_flutter (route tables) + original engine | Apache-2.0 | Integrated, 2–4 players, AI, larger touch controls |
| Petits Chevaux | Original controller using existing Ludo track | GPL-3.0 (route reference Apache-2.0) | Integrated, 2–4 players/AI, exact finish, local saves |
| Go (9×9, 13×13) | Original | GPL-3.0 | Integrated, ko/suicide, area scoring, MC AI |
| Hex | Original | GPL-3.0 | Integrated, MC (AMAF) AI |
| Gomoku | Original | GPL-3.0 | Integrated |
| Nine Men's Morris | Original | GPL-3.0 | Integrated, alpha-beta AI |
| Alquerque | Original | GPL-3.0 | Integrated, compulsory chained captures |
| Bagh Chal | Original | GPL-3.0 | Integrated, play goats or tigers |
| Neutron | Original | GPL-3.0 | Integrated |
| Chinese Checkers | Original | GPL-3.0 | Integrated, 2/3/6 players |
| Dots and Boxes | Original | GPL-3.0 | Integrated, chain-aware AI |
| Battleship | Original | GPL-3.0 | Integrated, probability-density AI |
| Snakes and Ladders | Original | GPL-3.0 | Integrated, 2–4 players |
| Dominoes (draw) | Original (johnmorrisdotca/domino reviewed) | GPL-3.0 | Integrated, 2–4 players |
| Shogi, Xiangqi, Fairy-Stockfish variants | fairy-stockfish/Fairy-Stockfish | GPL-3.0 | Verified source — heavyweight, not bundled |
| Riichi Mahjong | kobalab/Majiang | MIT | Verified source — JS port pending |

## Cards

| Game | Source | License | Status |
| --- | --- | --- | --- |
| Hearts, Spades, Oh Hell | dozingcat/CardsWithCats (rules + Monte Carlo AI) | GPL-3.0 | Integrated |
| Bridge | dozingcat/CardsWithCats | GPL-3.0 | Verified — needs native DD solver, not ported |
| Texas Hold'em | Original (shared evaluator) | GPL-3.0 | Integrated, side pots, 3 bots |
| Video Poker | Original | GPL-3.0 | Integrated, EV hold advice |
| Blackjack | Original | GPL-3.0 | Integrated, shoe, double/split, strategy advice |
| Gin Rummy | Original | GPL-3.0 | Integrated, optimal melds, layoffs |
| Cribbage | Original | GPL-3.0 | Integrated |
| King's Corner | Original engine; shared card deck and vector UI | GPL-3.0 | Integrated, local 2-4 / casual AI, local save |
| Nain Jaune | Original GPL-3.0 rules engine; shared touch cards, deck and storage | GPL-3.0 | Integrated, 3-8 pass-and-play / casual AI, 5 trays, local save |
| Crazy Eights, Go Fish, War | Original | GPL-3.0 | Integrated |
| Klondike, FreeCell, Spider, Golf, Pyramid | Original (rules as in PySolFC) | GPL-3.0 | Integrated; FreeCell uses Microsoft deal numbers |
| Forty Thieves, Aces Up, Poker Squares | Original | GPL-3.0 | Integrated |
| 1000+ further solitaires | shlomif/PySolFC | GPL-3.0 | Verified source |
| Russian Bank | RheaMars/russian-bank | MIT | Verified source |

## Dice and casual

| Game | Source | License | Status |
| --- | --- | --- | --- |
| Yacht Dice | z7workbench/minigames (scoring + AI) | MIT | Integrated, 1–4 players / AI |
| 421 (dice) | Original Dart charge/discharge controller | GPL-3.0 | Integrated, 2–4 local players or AI, save/restore |
| Liar's Dice | Original | GPL-3.0 | Integrated |
| Shut the Box | Original | GPL-3.0 | Integrated |
| Memory Pairs | Original | GPL-3.0 | Integrated |
| Air Hockey | Original lightweight physics (peeweesusername/airhockey reviewed; it needs Flame/Forge2D) | GPL-3.0 | Integrated, vs AI or 2 players multi-touch |
| Game of the Goose | Original | GPL-3.0 | Integrated, 2–4 players |

## Puzzles and deduction

| Game | Source | License | Status |
| --- | --- | --- | --- |
| ~300 original brain games, Sudoku, Nonogram, Minesweeper, Crossword, Word Search, Cryptogram, Einstein riddle and the Tatham-style grid puzzles | sidhant947/Puzzle | GPL-3.0 | Included as base |
| Inertia, Same Game, Black Box, Twiddle, Sixteen, Signpost | Simon Tatham's Portable Puzzle Collection | MIT | Integrated (Inertia generator ported; others re-implemented) |
| Galaxies, Map, Tracks, Undead, Net, Pearl variants | Simon Tatham's Portable Puzzle Collection | MIT | Verified source |
| Mahjong Solitaire (layered) | edave64/ED-Mahjong (tile rules) + KDE KMahjongg layouts | MIT / GPL-2.0+ | Integrated, 8 layouts, always solvable |
| Detective Casebook | Original logic engine | GPL-3.0 | Integrated, 12 cases + generated daily/random, solver-verified |
| Code Breaker (Mastermind) | z7workbench/minigames Hit & Blow scoring | MIT | Integrated |
| Sokoban | Original generator (reverse pulls) | GPL-3.0 | Integrated, BFS-verified in tests |
| Peg Solitaire, Tower of Hanoi, Nim | Original | GPL-3.0 | Integrated |

## Family's Game Pack parity
Reference only: https://play.google.com/store/apps/details?id=org.softmotion.fpack.lite —
the proprietary pack is not copied; only traditional game names are targets.

Now available: Alquerque, Neutron, Bagh Chal, Nine Men's Morris, Chinese Checkers, Snakes and
Ladders, Crazy Eights, Forty Thieves, Golf Solitaire, Peg Solitaire, Poker Squares, Aces Up
("Four Aces"), Shut the Box, Yatzy (Yacht Dice), Memory, War, Ludo, Backgammon, Dominoes,
Checkers, Chess, Reversi, Mancala/Oware, Connect Four, Battleship, Dots and Boxes, Game of the
Goose, Air Hockey, King's Corner, Petits Chevaux and 421.

Still missing: Bagh Bandi and Passe-Trappe.

## Quality rules
- Shared GameScaffold, opponent picker, status banner, card/dice/disc widgets.
- No mandatory network, account or real-money wagering. Web build serves its own CanvasKit and a
  bundled symbol font.
- Every new engine has legal-move, end-state and edge-case tests; generated puzzles that promise a
  solution are solver-verified (Detective, Mahjong, Same Game, Signpost, Sokoban, Inertia).
- Distinguish source integration, CI build, and actual on-device testing.
