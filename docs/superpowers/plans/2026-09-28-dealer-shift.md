# Dealer Shift Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans to implement in this session. Existing user authorization covers small development decisions and public source updates.

**Goal:** Give the existing ten-question loop the pace and purpose of a dealer game through bounded changes.

**Architecture:** Preserve QuestionFactory, poker evaluators, AnswerRecord schema, score/rating formulas and Game Center. Reuse the existing session, display feedback on the same table and derive a final shift evaluation from saved records.

**Tech Stack:** Swift, SwiftUI, SwiftData, XCTest, Xcode.

**Spec:** User request of 2026-09-28: make the current Appetize app more game-like through small changes, without replacing the project.

## Global Constraints
- Native iOS only; preserve existing user data and modes.
- Ten hands, an eight-correct shift objective; no new economy or betting.
- Daily stays one deterministic official attempt; practice remains repeatable.
- Existing score formula unchanged; retain measured response time without imposing a new time limit.

## Review Focus
- Answer feedback must freeze time and prevent double scoring (unit test).
- Ten daily hands must persist and resume as complete across all three modes (integration test).
- Small screens need scrollable content and a reachable next-hand control (simulator captures).
- Explanations must remain accessible without clearing the table (sheet + source review).
- Existing daily and rating calculations must remain unchanged (full XCTest suite).

## Task 1: Stable answer feedback
Files: DealerRushTests/LogicTests.swift, DealerRush/Services/TrainingSession.swift.
Interface: elapsedSeconds(at:) returns the saved outcome duration after submission.
- [x] Write freezing/double-score and ten-hand persistence tests before implementation.
- [x] Run existing Xcode workflow; confirm freezing assertion fails. Run 36454791655: 11 tests, one expected failure (30.58s displayed versus saved 0.00007s).
- [x] Return outcome.seconds when present; preserve next-hand clock reset.
- [ ] Run full XCTest suite; expect 11 tests, zero failures.

## Task 2: Dealer shift presentation
Files: DealerRush/Views/GameViews.swift, HomePracticeViews.swift, ProgressViews.swift, DealerRush/App/DealerRushApp.swift.
- [ ] Replace per-answer full-screen results with inline feedback and an explanation sheet.
- [ ] Keep hands visible and disable inputs after answer; fixed bottom confirm/next control.
- [ ] Show live eight-correct goal, measured time, combo and score.
- [ ] Reframe Home/Daily/Practice as shifts/tables; show final evaluation and actual saved rating change.
- [ ] Build and review actual simulator images; preserve native scrolling and Dynamic Type.

## Verification and delivery
- [ ] Inspect full suite and simulator build results, then publish updated simulator ZIP.
- [ ] State explicitly whether the existing Appetize deployment has been updated.

## Execution ledger
- Base: 9c51d45. Tests committed first; existing main workflow used because local environment has no Xcode.
- Scope decision: no additional briefing screen. Existing Home/Daily/Practice explain the goal, so starting play stays one tap.
