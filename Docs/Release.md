# Release handoff

## Identity and signing

- App name: **DEALER RUSH**; version **1.0.0**; build **1**.
- Provisional bundle ID: `com.danbi.dealerrush`. Confirm availability, then use the same ID in App Store Connect and Signing & Capabilities.
- App icon: `Resources/Assets.xcassets/AppIcon.appiconset/Icon.png` (opaque 1024 px). Confirm the final icon on device and store listing.
- Enable Game Center on the App ID, configure three leaderboard IDs as in README, then validate authentication and real ranking entries with sandbox users.
- No microphone, camera, photo, contacts, location or tracking permission is requested. Local records use SwiftData and settings use UserDefaults. Review the privacy manifest and App Privacy answers against the exact final build.

## Device acceptance pass

1. Build and test in Xcode on at least a small and a large iPhone simulator; use landscape rotation, large text and VoiceOver checks.
2. Play 10 questions in each mode. Verify every generated showdown has unique cards, winners and chop; inspect the explanation after right and wrong answers.
3. Check multiple pots and participant eligibility. In an uncalled overbet, the unmatched amount must be returned and absent from pot totals.
4. Terminate and relaunch after answering daily questions 1–9; confirm the next question, score and stats persist. Advance the device date and verify a different set.
5. Test sound and haptic toggles on physical iPhone; check all buttons and keyboard dismissal.
6. Test Game Center signed in, signed out and unavailable. The three local modes must still work.
7. Archive Release, TestFlight internal test, inspect crash logs and screenshots, then submit for review.

## App Store text draft

**Subtitle:** Think fast. Deal accurately.

**Description:**

DEALER RUSH turns poker dealer decisions into quick training rounds. Compare Hold’em hands in Showdown, calculate main pots, and divide side pots across eligible players. Generated questions keep practice fresh. Build your accuracy, response time and combo, track your Dealer Rating, and return for a ten-question daily challenge. Optional Game Center leaderboards let you compare scores. No real-money wagering, cash payouts or in-app purchases.

**Keywords draft:** poker,dealer,holdem,showdown,side pot,pot calculation,training,card game

**Review notes draft:** This is an offline poker rules training game. It has no account, real-money wagering, purchase, cash-out or multiplayer. Game Center is optional. Test all three modes from Practice without signing in; Stats update after each answer. The Daily Challenge contains ten locally generated questions per calendar day. Game Center leaderboards need their configured IDs and an authenticated sandbox account.

**Age rating:** Answer Apple's current questionnaire based on a poker training game depicting cards and chips without betting or monetary prizes. The final rating is determined in App Store Connect. Verify territory-specific gambling or simulated gambling declarations with the actual screenshots and copy.

**Screenshots to capture on device:** Home, Showdown question, Pot Calculation question, Side Pot question, answer result, Stats, Daily Challenge and Game Center ranking with genuine sandbox scores. Do not submit a mockup as an in-app screenshot.
