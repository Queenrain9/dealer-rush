# Implementation phases

1. SwiftUI app, shared design tokens, root tabs, home and practice.
2. Card and hand logic, showdown generator and playable screen.
3. Contribution layer calculator, main pot generation and playable screen.
4. Side pot generation, eligibility and multi-field answer screen.
5. SwiftData attempts, score, combo, rating and real stats.
6. Stable date seeded ten-question challenge and resumable progress.
7. Optional GameKit authentication, score reporting and leaderboard reader.
8. Sound, haptics, persisted settings and interface polish.
9. XCTest for poker and deterministic generation; device QA.
10. Signing, Game Center setup, TestFlight and store metadata.

The first eight phases are represented in the source project, including the current Home → Daily → Answer → Result → Rating → Stats flow. Tests are written but must be executed in Xcode. Phase 10 requires a simulator, iPhone and Apple account setup before release can be claimed.
