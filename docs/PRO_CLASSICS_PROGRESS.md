# Classics implementation ledger - 2026-10-14

Plan: PRO_SESSION_HANDOFF.md; specification: PROJECT_GOALS.md.
Base: 958637e1cb48df609943ca55770de8f0a6f3c99a.
Workspace: existing clean checkout, branch pro-classics-20261014.
All commits and pushes through Tunnel; no laptop SDK installations.

## Batch gates
1. Priority catalog regression tests: RED before implementation.
2. Chess: licensed Dart rules, local/AI, legal highlights, promotion, saves.
3. Poker: common real deck, licensed evaluator, Hold'em and draw rounds.
4. Mahjong: layered freedom rules, solvable generation, undo and saves.
5. Detective: nine cases, real difficulty differences, daily seeds, saved notes.
6. Design: common game surface/cards/rules and persistent style presets.
7. Full analyzer, tests, web build, Pages deployment and HTTP verification.

## Decisions
- Keep the existing Flutter application; do not embed separate game runtimes.
- Work on a feature branch and publish to main only after automated gates pass.
- Chess rules will reuse chess.dart; evaluate direct Dart poker reuse before ports.
- Manual browser/Android and complete catalog parity remain separate gates.

## Evidence
Pending. Record exact commits, workflow IDs, test results, and remaining work here.
