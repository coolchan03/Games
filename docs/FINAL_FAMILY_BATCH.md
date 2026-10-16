# Final Family Classics Batch

Base: dee600cf4f3161195f0091ead845935104a201b8 (main, 2026-10-15)
Worktree: C:\Users\coolc\Games-Final-Family-20261015
Branch: games-final-family-20261015

## Objectives and acceptance
1. Bagh Bandi: specifically **2** Bengal tigers vs **20** goats,
   initially stacked in four groups of five on the Alquerque board;
   **not** the existing 4-tiger Bagh Chal. Alternating legal moves,
   single-goat jumps including stacks, immobility victory, drawn-out
   games end as draw, AI and same-device play, responsive touch controls,
   saved/restored games, how-to-play, and rule tests.
2. Passe-Trappe: offline 10-puck tabletop dexterity game with a single
   center gate, elastic-style drag-back release, collisions, computer
   opponent or same-device two-sided play, tap-to-aim fallback, accessible
   rules, win detection, pause/restart, and persistence.
3. Register each in the 368-game catalog; automated catalog/guide
   coverage and narrow-phone smoke tests. Update license/source matrix,
   goals and project plan.
4. Run complete GitHub Actions analyzer/tests/web build and Android
   build. Merge via Surface Tunnel only after checks pass; verify Pages
   deployment and actual revision.

Ruling: Historical Bagh Bandi rule sources differ on multiple captures
per turn; implement exactly one optional jump per turn for predictable
offline play. Document that choice in the game guide.
Ruling: Some sources describe tigers winning after unspecified enough
goats eaten; use capture of all goats or the goat side with no legal
moves, plus a quiet-move draw cap. No arbitrary Bagh Chal five-goat
threshold for the two-tiger Bagh Bandi variant.
Ruling: Physical Passe-Trappe is simultaneous. Support simultaneous
two-thumb local play, plus a computer mode for one-phone play; no
networked modes.

## Progress
- [ ] Tests first: Bagh Bandi and Passe-Trappe rule, saves and phone smoke
- [ ] Engines + AI/physics
- [ ] Phone UI and shared rules
- [ ] Catalog, help guide, provenance documentation
- [ ] Analyzer/full tests/web+Android workflows
- [ ] Merge, live Pages and signed APK confirmation
