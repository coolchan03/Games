# Games — FOSS Source Matrix

Updated 2026-10-14. One lightweight Flutter UI for web/Android.
The existing sidhant947/Puzzle (GPL-3.0) is the foundation.
Never embed whole browser apps or Android apps when a small engine or port is sufficient.

Status: Integrated = code and screen are in Games, but not necessarily CI/device verified.
Source verified = repository license checked, not integrated yet.
Research only = do not copy until an appropriate license is established.

| Game/group | Source repository | License | Status |
| --- | --- | --- | --- |
| Original 304 brain games | https://github.com/sidhant947/Puzzle | GPL-3.0 | Integrated as base |
| Connect Four | Original pure Dart | GPL-3.0 project | Integrated, 2P/AI |
| Tic-Tac-Toe | Original pure Dart | GPL-3.0 project | Integrated, 2P/AI |
| Blackjack | Original pure Dart | GPL-3.0 project | Integrated basic dealer; expand splitting/doubles |
| Reversi | https://github.com/redbrogdon/flutterflip | BSD-3-Clause | Integrated Dart board engine and AI |
| Mancala | https://github.com/z7workbench/minigames | MIT | Integrated sowing engine and AI |
| Checkers | https://github.com/felipersteles/checkers-with-ai | MIT | Integrated Dart rules and AI port |
| Detective Casebook | Original logic grid; reference https://github.com/KevinGundlach/LogikGen | MIT reference | Integrated 3 unique-solution original cases |
| Mahjong Solitaire (flat) | https://github.com/edave64/ED-Mahjong | MIT code; assets vary | Integrated 64-tile solvable format |
| Mahjong Solitaire (layered) | https://github.com/edave64/ED-Mahjong | MIT code; assets vary | Verified; port 3D layout rules |
| Shisen-Sho | https://github.com/zear/shisen-seki | MIT | Verified, C game rules |
| Chess | https://github.com/z7workbench/minigames | MIT | Verified Dart rules, AI and notation |
| Strong chess variants | https://github.com/fairy-stockfish/Fairy-Stockfish | GPL-3.0 | Verified optional engine, not base bundle |
| Backgammon Flutter | https://github.com/demirburakk/bbackgammon | GPL-3.0 | Verified Flutter code |
| Backgammon AI | https://github.com/hwatheod/gnubg-web | GPL-3.0 | Verified optional heavyweight AI |
| 1200+ solitaire variants | https://github.com/shlomif/PySolFC | GPL-3.0 | Verified Python rule engine collection |
| Klondike, Spider, FreeCell, Pyramid | https://github.com/vayun-mathur/Modern-Apps | GPL-3.0 | Verified Kotlin code, requires port |
| Hearts, Spades, Oh Hell, Bridge | https://github.com/dozingcat/CardsWithCats | GPL-3.0 | Verified Flutter/Dart card rules |
| Texas Hold'em | https://github.com/themez/texas-holdem-house | MIT | Verified TypeScript bot game engine |
| Poker rank evaluator | https://github.com/thlorenz/phe | MIT | Verified JavaScript ranking code |
| Dominoes, Mexican Train | https://github.com/johnmorrisdotca/domino | MIT | Verified JS/TS rules and AI |
| Ludo | https://github.com/nizwar/ludo_flutter | Apache-2.0 | Verified Flutter web source |
| Goose Game | https://github.com/bocaletto-luca/Goose-Game-Two-Player | GPL-3.0 | Verified browser rules |
| Russian Bank | https://github.com/RheaMars/russian-bank | MIT | Verified JavaScript rules |
| Air Hockey | https://github.com/peeweesusername/airhockey | GPL-3.0 | Verified Flutter/Dart |
| Riichi Mahjong | https://github.com/kobalab/Majiang | MIT | Verified JavaScript AI game |
| Oware AI | https://github.com/joansalasoler/oware | GPL-3.0 | Verified Java engine |
| Sudoku, Nonogram, Minesweeper | https://github.com/sidhant947/Puzzle | GPL-3.0 | Already included; do not duplicate |
| Word Search, Crossword, Cryptogram | https://github.com/sidhant947/Puzzle | GPL-3.0 | Already included; improve puzzles |
| Einstein riddles | https://github.com/sidhant947/Puzzle | GPL-3.0 | Already included; add whodunit variants |
| Many board game benchmarks | https://github.com/google-deepmind/open_spiel | Apache-2.0 | Verified C++ rules reference |

## Family's Game Pack parity
Reference: https://play.google.com/store/apps/details?id=org.softmotion.fpack.lite
The proprietary game pack must NOT be copied, only traditional game names as targets.
Still needed: Alquerque, Neutron, Bagh Chal, Bagh Bandi, Nine Men's Morris,
Chinese Checkers, Petits Chevaux, Snakes and Ladders, Nain Jaune, King's Corner,
Crazy Eights, Forty Thieves, Golf Solitaire, Peg Solitaire, Poker Squares,
Four Aces, Shut the Box, 421, Yatzy, Passe-Trappe, Memory and Animal War.
Find independent FOSS code or build compact pure Dart rules. Verify licenses.

## Implementation priority
1. Make GitHub Actions analyzer, tests, web release green.
2. Import existing pure Dart/Flutter game rules ahead of cross-language ports.
3. Add layered Mahjong and more solver-verified detective mysteries.
4. Port card engines; reuse one common card and poker evaluator.
5. Complete all Family's Game Pack categories, adding 2-6 player pass-and-play.
6. Add optional heavyweight AI without slowing down standard downloads.

## Quality rules
- Shared DesignSystem and common menu, card, board and result appearance.
- No mandatory network, account or real-money wagering.
- Prefer small assets, Unicode symbols, compact licensed vectors.
- Every new engine gets legal-move, win/loss, restart and edge-case tests.
- Generated puzzles promising a unique solution require solver verification.
- Distinguish source integration, CI build, and actual on-device testing.
