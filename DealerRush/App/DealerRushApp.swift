import SwiftUI
import SwiftData

@main struct DealerRushApp: App {
    var body: some Scene {
        WindowGroup { RootView() }
            .modelContainer(for: AnswerRecord.self)
    }
}

private enum ScreenshotRoute: String {
    case home
    case practice
    case showdown
    case pot
    case sidepot
    case daily
    case stats
    case settings
}

private struct RootView: View {
    @State private var launching = true
    @StateObject private var gameCenter = GameCenterManager.shared

    private var screenshotRoute: ScreenshotRoute? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let flagIndex = arguments.firstIndex(of: "--screenshot"),
              arguments.indices.contains(flagIndex + 1) else { return nil }
        return ScreenshotRoute(rawValue: arguments[flagIndex + 1])
    }

    var body: some View {
        Group {
            if let route = screenshotRoute {
                screenshotView(route)
            } else if launching {
                VStack(spacing: 16) {
                    Image(systemName: "suit.spade.fill")
                        .font(.system(size: 54))
                        .foregroundStyle(Theme.gold)
                    Text("DEALER\nRUSH")
                        .font(.system(size: 52, weight: .bold, design: .serif))
                        .multilineTextAlignment(.center)
                    Text("THINK FAST. DEAL RIGHT.")
                        .font(.caption)
                        .tracking(2)
                        .foregroundStyle(Theme.muted)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .rushBackground()
            } else {
                TabView {
                    NavigationStack { HomeView() }
                        .tabItem { Label("홈", systemImage: "house.fill") }
                    NavigationStack { PracticeView() }
                        .tabItem { Label("플레이", systemImage: "suit.club.fill") }
                    NavigationStack { StatsView() }
                        .tabItem { Label("통계", systemImage: "chart.bar.fill") }
                    NavigationStack { RankingView() }
                        .tabItem { Label("랭킹", systemImage: "trophy.fill") }
                    NavigationStack { SettingsView() }
                        .tabItem { Label("설정", systemImage: "gearshape.fill") }
                }
                .tint(Theme.gold)
                .rushBackground()
            }
        }
        .task {
            guard screenshotRoute == nil else {
                launching = false
                return
            }
            gameCenter.authenticate()
            try? await Task.sleep(for: .milliseconds(750))
            launching = false
        }
    }

    @ViewBuilder
    private func screenshotView(_ route: ScreenshotRoute) -> some View {
        switch route {
        case .home:
            NavigationStack { HomeView() }
        case .practice:
            NavigationStack { PracticeView() }
        case .showdown:
            NavigationStack { GameScreen(mode: .showdown, practiceDifficulty: .intermediate) }
        case .pot:
            NavigationStack { GameScreen(mode: .potCalculation, practiceDifficulty: .intermediate) }
        case .sidepot:
            NavigationStack { GameScreen(mode: .sidePot, practiceDifficulty: .advanced) }
        case .daily:
            NavigationStack { DailyView() }
        case .stats:
            NavigationStack { StatsView() }
        case .settings:
            NavigationStack { SettingsView() }
        }
    }
}
