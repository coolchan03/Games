# Games master completion tracker

Updated: 2026-10-22. Local audit: 370 registered screens.

## Status policy

`NOT_REVIEWED`, `NEEDS_IMPLEMENTATION`, `IMPLEMENTED_UNVERIFIED`, `TEST_FAILED`, `VERIFIED`, `BLOCKED`. Source inspection does not equal gameplay verification. Use `docs/LEVEL_COVERAGE_AUDIT_20261020.csv` for the 370-row machine-readable inventory, retaining its historical status values until reconciled.

## Campaigns awaiting final certification

| Game | Candidate levels | Status | Remaining evidence |
| --- | ---: | --- | --- |
| Detective Casebook | 20 | IMPLEMENTED_UNVERIFIED | Current tests, device QA |
| Nonogram | 20 | IMPLEMENTED_UNVERIFIED | Current tests, touch QA |
| Minesweeper | 20 | IMPLEMENTED_UNVERIFIED | Current tests; guess limitations |
| Sokoban | 20 per difficulty | IMPLEMENTED_UNVERIFIED | Medium/Hard solvability |
| Sudoku | 20 | IMPLEMENTED_UNVERIFIED | CI, offline persistence |
| Classic Maze | 20 | IMPLEMENTED_UNVERIFIED | CI, offline persistence |
| Word Search | 20 generated candidates | IMPLEMENTED_UNVERIFIED | Board tests, UI tests, offline reload |

The other 363 games remain unclassified or not certified. This is not evidence that they are broken. In the legacy CSV, only six campaigns count toward the previously audited minimum.

## Current uncommitted batch

Word Search engine/provider changes were preserved. Level selector, navigation, theme display, restart, and campaign test were added locally. The machine-readable audit was re-run and reported 370 games and six previously audited campaigns. Flutter/Dart were not found on PATH, so the new Word Search changes have not passed executable tests. No push or release certification yet.

## Required 370-game row fields

Game ID, name, genre, level-based/replayable category, existing level count, verified playable count, mechanics, instructions, save/progression, mobile controls, automated tests, issues, priority, final status. Unknown classification remains `NOT_REVIEWED`. Maintain separate automated, browser, and physical Android verification results.

Next: finish Word Search validation; then Akari, Kakuro, Einstein Riddle, Futoshiki, Hitori, Nurikabe, Slitherlink, Binary Puzzle, Cryptogram, Word Mastermind.
