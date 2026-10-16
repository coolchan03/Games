# Games — Phone Touch & Difficulty Audit (2026-10-15)

**Focus:** Polish rather than add more games; the registered catalog remains 370.

## Changes under test

- New common `GridBoardTouchArea` maps actual finger coordinates to grid
  cells, accepts both tap-to-select and a continuous single-finger drag,
  and rejects outside-board, cancelled, or same-cell drops without
  snapping accidentally to the board edge.
- Adapted **Bagh Bandi**, **Bagh Chal**, **Alquerque**, and **Neutron**.
  A held source piece is selected to reveal legal targets before release.
  Legacy rule engines, player options, pass-and-play and saves are retained.
  In **Bagh Chal**, goat placement remains tap-on-empty-square; dragging
  begins once there are pieces to move.
- **Passe-Trappe** puck-selection radius increased for finger access.
  **Easy, Medium and Hard** now have separate launch speeds and aim jitter;
  the existing screen also varies shot frequency across those tiers.
- Bagh Bandi already offers **three distinct computer behaviors**:
  Easy shuffles among legal moves, Medium evaluates immediate positions,
  and Hard examines a responding opponent move. Same-device play
  bypasses the AI and remains available for each game.

## Regression gates

- Widget tests emulate a 360-dp portrait phone: a tap selects exactly
  once; a continuous drag from its original square executes a move
  without a duplicate tap; off-board and cancelled drags do nothing.
- Integrated drag tests cover opening moves in Alquerque, Bagh Chal
  and Neutron, including the existing scrollable shared page.
- Difficulty test verifies three different shot speeds with a seeded
  random generator, and legal non-mutating AI choices for Bagh Bandi.
- Catalog and guide audits must remain 370/370, with no missing game.
- GitHub Actions must pass Flutter analyzer, **complete** test suite,
  release web build, and permanent-signature Android APK build.
- Do not equate widget simulation with a physical Android finger test.

## Outstanding after this batch

- Physical Android phone/tablet testing of grab/drag responsiveness and
  accessibility, including narrow, tall, landscape and large-font cases.
- More screens from the ~304 original Puzzle games need consistent
  touch-first affordances, autosave, and effective in-game help.
- Larger library redesign, genuine PWA offline-reload testing,
  and selected complex games (Bridge, Riichi Mahjong, Shogi, Canasta)
  remain deferred behind polish.
