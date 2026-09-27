import SwiftUI
import SwiftData

@main struct DealerRushApp: App {
    var body: some Scene {
        WindowGroup { RootView() }
            .modelContainer(for: AnswerRecord.self)
    }
}

private struct RootView: View {
    @State private var launching = true
    @StateObject private var gameCenter = GameCenterManager.shared
    var body: some View {
        Group {
            if launching {
                VStack(spacing: 16) {
                    Image(systemName: "suit.spade.fill").font(.system(size: 54)).foregroundStyle(Theme.gold)
                    Text("DEALER\nRUSH").font(.system(size: 52, weight: .bold, design: .serif)).multilineTextAlignment(.center)
                    Text("POKER DEALER TRAINING GAME").font(.caption).tracking(2).foregroundStyle(Theme.muted)
                }.frame(maxWidth: .infinity, maxHeight: .infinity).rushBackground()
            } else {
                TabView {
                    NavigationStack { HomeView() }.tabItem { Label("홈", systemImage: "house.fill") }
                    NavigationStack { PracticeView() }.tabItem { Label("연습", systemImage: "suit.club.fill") }
                    NavigationStack { StatsView() }.tabItem { Label("통계", systemImage: "chart.bar.fill") }
                    NavigationStack { RankingView() }.tabItem { Label("랭킹", systemImage: "trophy.fill") }
                    NavigationStack { SettingsView() }.tabItem { Label("설정", systemImage: "gearshape.fill") }
                }.tint(Theme.gold).rushBackground()
            }
        }
        .task {
            gameCenter.authenticate()
            try? await Task.sleep(for: .milliseconds(750))
            launching = false
        }
    }
}
