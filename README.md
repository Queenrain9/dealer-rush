# DEALER RUSH 1.0

Native SwiftUI iPhone training game based on `Docs/DesignDirection-v1.jpeg`. Showdown, Pot Calculation and Side Pot generate questions locally. No cash, betting, account, backend, WebView or third-party packages.

## Open and run

Requires macOS with Xcode 16 or newer, iOS 17 SDK or newer, and an iPhone simulator. Open `DealerRush.xcodeproj`, select the shared `DealerRush` scheme, choose an iPhone simulator, then Run. The minimum deployment target is iOS 17. The project is portrait only. To run on a physical iPhone, set your Development Team under Signing & Capabilities, use an available bundle identifier and enable Game Center for that App ID.

CLI verification on a Mac:

```sh
xcodebuild -project DealerRush.xcodeproj -scheme DealerRush -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO build test
```

Choose a simulator installed on your Mac if `iPhone 16` is unavailable. Run the `DealerRushTests` scheme test action from Xcode. Validate on small and large iPhones with Dynamic Type and VoiceOver.

## Structure

| Location | Purpose |
| --- | --- |
| `DealerRush/App` | App entry and five-tab navigation |
| `DealerRush/Models` | Card, question, pot and saved attempt types |
| `DealerRush/Logic` | Seven-card evaluation, pot layers, seeded generator, score and rating |
| `DealerRush/Services` | Session state, Game Center and native feedback |
| `DealerRush/Views` | Home, practice, games, result, stats, daily, ranking, settings |
| `DealerRush/Resources` | App icon, sound effects, Game Center entitlement, privacy manifest |
| `DealerRushTests` | Unit tests for evaluation, pots and generation |

Every answer is saved through SwiftData with its session, question index and rating change. Settings use UserDefaults. The local date defines the daily ten-question seed, completion and streak. A daily attempt resumes at its next unanswered question after relaunch; practice starts a fresh ten-question session. Unmatched all-in excess is returned rather than counted as a side pot. The current rating starts at 1,000; correct answers add score-based rating points and wrong answers subtract 12. Score depends on correctness, response time, combo and difficulty. Tier, mastery and recent progress are derived from saved answers rather than fixture data.

## Game Center

The project declares the Game Center entitlement. In the Apple Developer account, enable Game Center for the final App ID. In App Store Connect, set up these leaderboard identifiers with integer score, descending order and best score:

| ID | Intended setup |
| --- | --- |
| `dealer_rush_rating_weekly` | Recurring weekly rating leaderboard |
| `dealer_rush_rating_all_time` | Classic all-time rating leaderboard |
| `dealer_rush_daily_score` | Recurring daily score leaderboard |

Match the displayed Weekly / Global / Friends filters to the configuration. Friends reads Game Center friends for the all-time board; there is no custom social graph. Authenticate using a Game Center sandbox account on a signed device or supported simulator. If Game Center is unavailable, local play and stats continue and the ranking screen shows its actual connection state. The weekly Game Center board records each submitted best score for its recurrence period; it does not retroactively lower a published best when local rating falls. Daily rank only appears after a real Game Center response. The local daily seed is deterministic per device date, but there is no server-synchronized global question set or participant percentile.

## Release

Set the final bundle identifier and Development Team in Xcode. Verify Game Center IDs, entitlement and capabilities. Run tests, perform device QA, capture App Store screenshots from the actual app, then select Product → Archive → Distribute App → App Store Connect → Upload. Set version 1.0.0 and increment build number for each TestFlight upload. Complete the privacy and age rating questionnaires in App Store Connect using actual app behavior. See `Docs/Release.md` for copy and a handoff checklist.

This source was authored in a Linux workspace without Xcode. It has not been compiled, run in Simulator, device tested, archived, uploaded or approved by Apple. These gates must be completed on a Mac before it can be called a release build.
