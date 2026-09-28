# DEALER RUSH 1.0

Native SwiftUI iPhone training game based on `Docs/DesignDirection-v1.jpeg`. Showdown, Pot Calculation and Side Pot generate questions locally. No cash, betting, account, backend, WebView or third-party packages.

## Open and run

Requires macOS with Xcode 16 or newer, iOS 17 SDK or newer, and an iPhone simulator. Open `DealerRush.xcodeproj`, select the shared `DealerRush` scheme, choose an iPhone simulator, then Run. The minimum deployment target is iOS 17. The project is portrait only.

### Free personal iPhone install from Xcode

The Run action uses Debug, which does not request the Game Center entitlement. This allows the core offline game and saved stats to run with a free Apple Account's Personal Team; online ranking needs a paid team and configured Game Center. Release retains the Game Center entitlement for future TestFlight/App Store distribution.

1. On a Mac, install Xcode 16 or newer. Download the source repository ZIP from GitHub (Code → Download ZIP) and unzip it. The Appetize simulator ZIP is not the Xcode source project.
2. Open `DealerRush.xcodeproj`. In Xcode → Settings → Apple Accounts, add your own Apple Account. Connect your iPhone by cable, unlock it and tap Trust if prompted. The phone needs iOS 17 or newer.
3. Select the blue `DealerRush` project icon, then the `DealerRush` app target (not `DealerRushTests`). In Signing & Capabilities, keep Automatically manage signing on and choose your `Personal Team`. If Xcode reports the bundle identifier is unavailable, change it to a unique reverse-domain identifier such as `com.yourname.dealerrush.personal`. Do not change the Release/Game Center entitlement to make a personal build.
4. Choose your connected iPhone in Xcode's device picker. On the phone, enable Settings → Privacy & Security → Developer Mode if Xcode asks, then restart and confirm. Press Xcode's Run (▶︎) button. Xcode builds, signs and installs the app on your home screen.

Free Personal Team provisioning expires periodically, so use Run again when the app stops opening. Xcode's signing errors or an older iOS version must be resolved on that Mac and device. Never send Apple Account passwords or signing certificates to this repository.

### No Mac: build on GitHub, install from a Windows PC

The `iPhone Device IPA` GitHub Actions workflow builds an **unsigned iPhone device app** on a hosted Mac. Download its `DealerRush-iPhone-Unsigned-IPA` artifact, unzip the outer artifact archive, and use the inner `DealerRush-Unsigned.ipa`. This is different from the simulator ZIP and does not install by tapping the file on an iPhone.

On your own Windows PC, an IPA sideloading tool such as AltStore Classic or Sideloadly can sign the IPA with your free Apple Account and install it on a USB-connected iPhone. Follow the tool's official instructions; enter your Apple Account only on your own computer, never into GitHub or chat. Free personal signing expires after seven days and needs refreshing with the same account and bundle identifier. Game Center rankings are unavailable in this Debug build, while offline play and local records work. Reinstall over the existing app to preserve local data; deleting the app deletes its local records. For a durable beta install without weekly refreshing, use an Apple Developer Program membership and TestFlight.

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

GitHub Actions builds the native app with Xcode, runs XCTest on an iPhone simulator, and uploads an unsigned simulator app ZIP plus actual screen captures. The simulator ZIP is suitable for Appetize; it cannot be installed directly on a physical iPhone. Physical-device signing, device QA, Archive and App Store submission still require the owner’s Apple development setup.


## Build 2: Dealer shift flow

The existing ten-question session is presented as a ten-hand table shift. The player aims for eight accurate decisions; ten correct decisions earn a Perfect Shift evaluation. Cards and pot information remain visible after answering, with compact feedback and a next-hand button. Detailed explanations open in a native sheet. The final report uses saved answers for score, time, best combo and rating change. Home, Daily and the Play tab lead into the same loop.

The poker engines, daily seeds, storage schema and score/rating formulas are unchanged. The answer timer freezes on submission and resets for the next hand. There is no new economy, currency, betting or account system.
