# Added games: 20-level audit

Updated: 2026-10-23

Scope: the 66 games added on top of upstream Puzzle (see
`docs/GAMES_NEW_66_ONLY_HANDOFF_20261023.md`). Following the handoff's rule,
level-based games must offer at least 20 distinct, solvable, numbered levels
with offline progress; competitive and replayable card, board and dice games
qualify through complete rules, AI difficulties and local multiplayer instead
of artificial numbered levels.

## Level-based games: all 12 now have 20 levels

| Game | Before | Now | How the 20 levels are checked |
| --- | --- | --- | --- |
| Detective Casebook | 20 cases | unchanged | `twenty_level_campaign_test.dart` |
| Sokoban | 20 per difficulty | unchanged | `sokoban_level_coverage_test.dart` |
| Mahjong Solitaire | 9 layouts, free play | 20 levels (Beginner ×2, 8 layouts ×2, 2 extra deals) | each fixed deal cleared by its recorded solution |
| Code Breaker | 3 modes | 20 levels (3–5 pegs, 4–8 colours, repeats, 8–12 tries) | configurations distinct and valid |
| Signpost | size picker | 20 levels, 4×4 → 6×6 | each has exactly one solution |
| Sixteen | size picker | 20 levels, 3×3 → 5×5, scramble grows | fixed, distinct, scrambled by legal moves |
| Twiddle | 4 presets | 20 levels, 3×3/2×2 → 5×5/3×3 | fixed, distinct, scrambled by legal moves |
| Black Box | ball picker | 20 levels, 5×5/2 balls → 10×10/8 balls | distinct; laser-equivalent answers accepted |
| Same Game | colour picker | 20 levels, 5×5/2 colours → 12×12/5 colours | every board built clearable |
| Inertia | size picker | 20 levels, 6×6 → 12×12 | test solver collects every gem |
| Tower of Hanoi | disc picker | 20 levels, 3–8 discs incl. scrambled starts | minimum checked by full search; hint solves optimally |
| Peg Solitaire | 2 boards | 20 levels (13 patterns + all 7 full-board starts) | each solved to one peg by a solver |

All new campaigns share `common/campaign_level_bar.dart`: a numbered level
picker with ticks for completed levels, previous/next, "Next level" after a
win, and offline storage of the selected level and completions through
`CampaignProgress`. Tests: `test/games/added_puzzle_campaigns_test.dart`.

### Defects found and fixed during the audit

- **Same Game:** the "always clearable" generator could never fill a board
  with an odd height and silently fell back to a random, possibly unclearable
  board. New columns are now three tiles tall on odd heights.
- **Black Box:** a guess that no laser could tell apart from the real layout
  was marked wrong; it now counts as correct, as in Tatham's `blackbox.c`.
- **Peg Solitaire:** the European 37-hole board started with the centre
  empty, a start that can never finish with one peg. The campaign uses the
  English board, where every level is proven solvable.

## Also added

- **Triangle peg game:** the 15-hole triangle peg game, as a second mode in Peg
  Solitaire (no new catalogue registration, so the 370-game catalogue is
  unchanged). Tap any peg to start, jump along rows or diagonals, and get
  the traditional rating for the pegs left. All 15 starting holes are
  solvable to one peg.

## Replayable games (no numbered levels by design)

Nim and Memory Pairs (vs computer / 2 players), the 8 solitaire card games
(new random deal each game), and the B4–B8 card, board, dice and party games
(44 titles) are replayable sessions with AI difficulties or local players.
They were not given artificial levels.

## Visual refresh

Mahjong Solitaire (drawn traditional tile faces, ivory and jade tiles, felt
table), Mancala and Oware (shared wooden board, carved pits, glass-bead
seeds, end stores), Peg Solitaire (wooden board, marbles; wooden triangle
board with coloured pegs), Connect Four (classic blue frame, glossy discs,
winning line highlight), Tic-Tac-Toe (drawn grid, X and O marks, winning
line) and Same Game (glossy tiles). Mancala, Connect Four and Tic-Tac-Toe
moved onto the shared `GameScaffold`, so they now have rules, New game and
win tracking like the other added games.

## Still open

Physical Android QA (portrait, landscape, drag) and an offline PWA reload
check are still required for every game above. Automated tests do not
replace them.
