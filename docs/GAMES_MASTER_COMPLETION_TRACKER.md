# Games master completion tracker

Updated 2026-10-22. Machine-readable source: `docs/GAMES_MASTER_COMPLETION_TRACKER.csv` (370 unique game IDs).

## Current assessment

{'NOT_REVIEWED': 348, 'NEEDS_IMPLEMENTATION': 0, 'IMPLEMENTED_UNVERIFIED': 21, 'TEST_FAILED': 0, 'VERIFIED': 0, 'BLOCKED': 1}

The six legacy 20-level campaigns (Detective Casebook, Nonogram, Minesweeper, Sokoban, Sudoku, Classic Maze) have reported level coverage but are not yet certified end-to-end. Word Search has 20 generated candidates on a separate branch, but its Windows screen file is currently inaccessible and the original audit fails with PermissionError. This is a blocker rather than a reason to delete/reset the file.

Six solitaire titles have web/Android CI-verified implementation changes on main at `fb47744`, including drag handling, dead-end messaging where applicable, and landscape improvements. Physical device testing remains pending. GitHub CI success does not equal every game being gameplay-verified.

## Next engineering work

1. Diagnose Windows permissions / filesystem state for `lib/ui/features/games/word_search/word_search_screen.dart` without deleting it or resetting the workspace. Re-run `python tool/audit_level_progression.py --csv docs/LEVEL_COVERAGE_AUDIT_20261020.csv`, then reconcile the Word Search branch and its tests.
2. Certify the six existing 20-level campaigns, including saving, browser/mobile input, solution correctness and meaningful difficulty.
3. Build at least 20 validated levels for level-based games where missing. First group: Akari, Kakuro, Einstein Riddle, Futoshiki, Hitori, Nurikabe, Slitherlink, Binary Puzzle, Cryptogram, Word Mastermind.
4. Classify all remaining games by actual mechanics, separating replayable games from campaign games.
5. Verify restart/help/offline/resume and touch controls across the catalog, then obtain Android device feedback and release.

## Certification states

`NOT_REVIEWED`, `NEEDS_IMPLEMENTATION`, `IMPLEMENTED_UNVERIFIED`, `TEST_FAILED`, `VERIFIED`, `BLOCKED`. Zero games are marked VERIFIED solely by source inspections or catalog registration. Each row tracks missing evidence explicitly rather than fabricating completion.
