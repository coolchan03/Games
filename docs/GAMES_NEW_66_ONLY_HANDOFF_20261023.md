# Games - Finish the 66 added games (new-chat handoff)

**Prepared:** October 23, 2026  
**Repo:** https://github.com/coolchan03/Games  
**Website:** https://coolchan03.github.io/Games/  
**Workspace:** `P:\AI Projects\Games` - **connection:** `@new-tunnel`

## Scope: DO NOT rebuild the original games

- The upstream 304 games are an established baseline. Only touch them for a specific user-requested tweak, a critical failure, or a regression caused by shared code. Do not enforce a new 20-level campaign on all 304.
- **Only these 66 registry additions** need full completion work: verify what is already implemented, fix incomplete mechanics, provide appropriate levels or replay modes, reliable saving, clear help/restart, touch/landscape polish, offline play, and CI + device QA.
- No new registrations, no Bridge/Riichi/Shogi expansion, no online multiplayer, no duplicate repositories. Preserve all 370 registrations and existing progress.
- If a new game is actually **level-based**, supply ?20 genuinely distinct playable stages, valid solutions and meaningful progression with local save. Replayable card/board/dice games need rule-complete sessions, suitable AI/modes/difficulties, not 20 artificial levels. Where classification is ambiguous, inspect the actual UI first.

## Evidence that these are exactly the new 66

- Upstream `sidhant947/Puzzle` pinned SHA 5d69d5f582b198a0f7244a483c3f5d20bcd9a4f3 has **304 GameMetadata registry symbols**.
- Fork `coolchan03/Games` main pinned SHA 0012f24576166776ec9826b153eb6b9d101d4953 has **370**; exact registry symbol difference is **66**, with **no original entries removed**.
- Sources: https://github.com/sidhant947/Puzzle/blob/5d69d5f582b198a0f7244a483c3f5d20bcd9a4f3/lib/data/game_registry.dart and https://github.com/coolchan03/Games/blob/0012f24576166776ec9826b153eb6b9d101d4953/lib/data/game_registry.dart
- **Important correction:** Akari, Kakuro, Einstein Riddle, Futoshiki, Hitori, Nurikabe, Slitherlink, Binary Puzzle, Cryptogram and Word Mastermind belong to the **original 304**. Prior improvements to them stay, but do not continue the added-games project by expanding these originals.
- Of these 66, the pre-existing master tracker marked **49 NOT_REVIEWED** and **17 IMPLEMENTED_UNVERIFIED**. This is an evidence status, **not** proof that 49 games are broken. Many already have integrated code and tests.

## Current verified checkpoint and safeguards

- Latest verified GitHub `main` at handoff preparation: 0012f24576166776ec9826b153eb6b9d101d4953; web and signed Android CI succeeded, with 5,510 tests reported for the latest Kakuro main build. Verify HEAD again before changes.
- Local `P:\AI Projects\Games` is on older branch `pro-classics-solitaire-drag-landscape-20261022` at `0459c22`; it does **not** match GitHub main. It has an uncommitted `lib/ui/features/games/word_search/word_search_screen.dart` change; **do not overwrite, discard, stash or reset it**.
- Secondary worktree `P:\AI Projects\Games-Menu-Polish` exists. Inspect its status before touching. Do not add another clone/worktree unnecessarily.
- Read `P:\AI Projects\TUNNEL_STORAGE_GUARDRAILS.md` first. Reuse dependencies on P:, protect `P:\Recovery_20261016_135758`, warn at 5 GiB of temporary files and pause disk-heavy work at 10 GiB.
- Every GitHub write (commits, branches, merges, releases) must use **@new-tunnel**. GitHub connector can be used read-only. Test commits on focused branches before publishing to main.

## Eight completion batches (66 games total)

| Batch | Count | Group | Completion priority |
|---|---:|---|---|
| B1 | 4 | Deduction, mysteries and puzzle depth | Check existing 20-case campaigns, puzzle uniqueness, hints, save/resume, layouts and modes. |
| B2 | 10 | Compact logic and spatial puzzles | Reuse generator, solver and progression systems where relevant; validate legal moves, undo, hints and level/replay design. |
| B3 | 8 | Solitaire and drag controls | Verify all legal drag/drop destinations, stacks, dead-end messaging, restart, undo and landscape card visibility. |
| B4 | 8 | Poker and complex table cards | Check hand evaluation, virtual-chip betting, payouts, bots, private hands, state restore and game restart. |
| B5 | 6 | Trick-taking and simple cards | Check bids, round scoring, turn order, hidden cards, AI difficulty, local seats and help. |
| B6 | 10 | Popular abstract strategy boards | Rules, win/draw, undo, AI levels, 2-player turns, piece dragging and zoom in landscape. |
| B7 | 10 | Traditional boards and strategy | Capture rules, legal-move enforcement, turn order, dice, scoring, bots, save and phone controls. |
| B8 | 10 | Family, dice, physics and casual | Fair dice, pass-and-play, local AI, touch flick/drag, responsive layout, endgame, save/restart and offline. |

## EXACT 66-game list (canonical registry IDs)

### B1 - Deduction, mysteries and puzzle depth (4)

**Detective Casebook** (`detective_casebook`); **Sokoban** (`sokoban`); **Mahjong Solitaire** (`mahjong_solitaire`); **Code Breaker** (`code_breaker`).

### B2 - Compact logic and spatial puzzles (10)

**Signpost** (`signpost`); **Sixteen** (`sixteen`); **Twiddle** (`twiddle`); **Black Box** (`black_box`); **Same Game** (`same_game`); **Inertia** (`inertia`); **Tower of Hanoi** (`tower_of_hanoi`); **Peg Solitaire** (`peg_solitaire`); **Nim** (`nim`); **Memory Pairs** (`memory_pairs`).

### B3 - Solitaire and drag controls (8)

**Klondike Solitaire** (`klondike`); **FreeCell** (`freecell`); **Spider Solitaire** (`spider`); **Golf Solitaire** (`golf_solitaire`); **Pyramid Solitaire** (`pyramid`); **Forty Thieves** (`forty_thieves`); **Aces Up** (`aces_up`); **Poker Squares** (`poker_squares`).

### B4 - Poker and complex table cards (8)

**Blackjack** (`blackjack`); **Texas Hold'em** (`texas_holdem`); **Five Card Draw** (`five_card_draw`); **Video Poker** (`video_poker`); **Cribbage** (`cribbage`); **Gin Rummy** (`gin_rummy`); **King's Corner** (`kings_corner`); **Nain Jaune** (`nain_jaune`).

### B5 - Trick-taking and simple cards (6)

**Hearts** (`hearts`); **Spades** (`spades`); **Oh Hell** (`oh_hell`); **Crazy Eights** (`crazy_eights`); **Go Fish** (`go_fish`); **War** (`war`).

### B6 - Popular abstract strategy boards (10)

**Chess** (`chess`); **Checkers** (`checkers`); **Reversi** (`reversi`); **Connect Four** (`connect_four`); **Mancala** (`mancala`); **Oware** (`oware`); **Gomoku** (`gomoku`); **Hex** (`hex`); **Go** (`go_game`); **Nine Men's Morris** (`nine_mens_morris`).

### B7 - Traditional boards and strategy (10)

**Backgammon** (`backgammon`); **Ludo** (`ludo`); **Alquerque** (`alquerque`); **Bagh Chal** (`bagh_chal`); **Bagh Bandi** (`bagh_bandi`); **Neutron** (`neutron`); **Chinese Checkers** (`chinese_checkers`); **Dominoes** (`dominoes`); **Dots and Boxes** (`dots_and_boxes`); **Battleship** (`battleship`).

### B8 - Family, dice, physics and casual (10)

**Game of the Goose** (`goose_game`); **Petits Chevaux** (`petits_chevaux`); **Snakes and Ladders** (`snakes_and_ladders`); **Air Hockey** (`air_hockey`); **Passe-Trappe** (`passe_trappe`); **421 (Dice)** (`dice_421`); **Liar's Dice** (`liars_dice`); **Yacht Dice** (`yacht_dice`); **Shut the Box** (`shut_the_box`); **Tic-Tac-Toe** (`tic_tac_toe`).

**Counts:** 4 + 10 + 8 + 8 + 6 + 10 + 10 + 10 = **66 distinct titles**.

## Reuse existing work; avoid rewriting for the sake of activity

- **Detective Casebook:** 20-case campaign already added. Validate clue correctness, answer integrity, save and mobile UI.
- **Sokoban:** 20 levels per difficulty previously built; check hard/medium solvability, touch dragging and restart.
- **Mahjong Solitaire:** eight solvable layouts documented; test actual replay/layout selection. Do not assume it requires 20 numbered levels if the product presents free-play modes.
- **Solitaire:** Klondike, Spider, FreeCell have new drag-to-destination and dead-end handling; Golf, Pyramid and Aces Up have relevant drag actions. Verify those changes on phone landscape and fill missing gaps, not rebuild.
- All new games are registered. Tests and 360dp smoke coverage exist in test/games, but not every rule, save path or physical-device scenario has been certified.

## Batch execution contract - implement, test, publish

1. Connect `@new-tunnel`, read guardrails, inspect `git status`, HEAD, all worktrees and remote `main` SHA. Read this document and `docs/GAMES_66_ADDITIONS_TRACKER.csv`.
2. Work on **one batch at a time**, grouping compatible engines; first inspect current source, relevant tests and manual-visible controls. Record actual gaps. Skip an already-correct feature instead of rewriting it.
3. Prioritize broken gameplay, then levels/modes, local saving, drag/mobile landscape, instructions/restart, offline reliability and final polish.
4. Reuse shared components (campaign progression, game scaffold, card/board controls) but do not force different mechanics into a single engine.
5. Add edge-case engine tests, 360dp and short-landscape widget tests, offline save/resume tests, and browser smoke tests. Verify PWA in **network-disabled reload** separately. Automated tests do not certify physical Android.
6. Format/analyze/test/build via GitHub Actions; inspect diffs and secrets, push all writes through tunnel, record commit SHA and actual CI result. Merge to main only after green checks. No false release claims.
7. Update **only the 66-game completion tracker** for newly added games. Keep states `NOT_REVIEWED`, `NEEDS_IMPLEMENTATION`, `IMPLEMENTED_UNVERIFIED`, `TEST_FAILED`, `VERIFIED`, `BLOCKED`. Require evidence before marking `VERIFIED`.
8. After eight batches: final regression guarding 370 registered titles, manual Android (portrait+landscape+drag), desktop/mobile browser, PWA offline, save durability, public GitHub Pages and a signed Android APK/release.

## Immediate work for the new chat

- Start **B1** by rechecking Detective Casebook, Sokoban, Mahjong Solitaire and Code Breaker. Detective and Sokoban already have reported 20-level campaigns; finish actual shortcomings. Verify Mahjong variety and Code Breaker modes rather than adding arbitrary content.
- Do real code work and publish the first verified B1 fixes through the tunnel. Then proceed to B2 and subsequent batches automatically when the user says `Next please`.
- For each batch report: **Batch / Games assessed / Code fixes / Tests passed / Branch + SHA + CI / Mobile QA outstanding / Remaining new-game count / Next**.

## Tracker reconciliation

- The old 370-row tracker contained `poker` instead of actual registered ID `five_card_draw`. This handoff commit corrects that one ID/title while preserving row count, status and all other records.
- Dedicated file `docs/GAMES_66_ADDITIONS_TRACKER.csv` has one row per addition, actual metadata filename, gameplay policy, source test-reference hints, and explicit QA fields. A source reference is **not** proof of a passing game-specific test.

**Completion condition:** all 66 additions individually evaluated and finished as applicable, no known game-breaking defect, valid 20-level campaigns only where appropriate, modes for replayable titles, readable controls on mobile landscape, help/restart/saving/offline, and verified final web/APK releases. Original 304 retained, not remodeled.
