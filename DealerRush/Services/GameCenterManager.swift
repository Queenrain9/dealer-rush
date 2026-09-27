import Foundation
import GameKit
import UIKit
import Combine

struct RankingEntry: Identifiable {
    let id: String
    let rank: Int
    let name: String
    let score: Int
    let local: Bool
}
struct DailyStanding {
    let rank: Int
    let total: Int
}
enum RankingScope: String, CaseIterable, Identifiable {
    case weekly, global, friends
    var id: String { rawValue }
    var title: String { switch self { case .weekly: return "주간"; case .global: return "전체"; case .friends: return "친구" } }
}

@MainActor final class GameCenterManager: ObservableObject {
    static let shared = GameCenterManager()
    static let weeklyID = "dealer_rush_rating_weekly"
    static let allTimeID = "dealer_rush_rating_all_time"
    static let dailyID = "dealer_rush_daily_score"
    @Published var authenticated = false
    @Published var status = "Game Center 연결을 확인 중입니다."
    @Published var entries: [RankingEntry] = []
    @Published var localEntry: RankingEntry?
    @Published var dailyStanding: DailyStanding?
    private init() {}

    func authenticate() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] controller, error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let controller {
                    let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
                    var presenter = scene?.keyWindow?.rootViewController
                    while let next = presenter?.presentedViewController { presenter = next }
                    presenter?.present(controller, animated: true)
                }
                self.authenticated = GKLocalPlayer.local.isAuthenticated
                if !self.authenticated { self.dailyStanding = nil; self.localEntry = nil }
                self.status = self.authenticated ? "Game Center 연결됨" : (error?.localizedDescription ?? "Game Center에 로그인하면 순위를 볼 수 있습니다.")
            }
        }
    }
    func publishRating(_ score: Int) {
        guard authenticated else { return }
        GKLeaderboard.submitScore(score, context: 0, player: GKLocalPlayer.local,
                                  leaderboardIDs: [Self.weeklyID, Self.allTimeID]) { _ in }
    }
    func publishDaily(_ score: Int) {
        guard authenticated else { return }
        GKLeaderboard.submitScore(score, context: 0, player: GKLocalPlayer.local,
                                  leaderboardIDs: [Self.dailyID]) { _ in }
    }
    func load(scope: RankingScope) {
        guard authenticated else { entries = []; localEntry = nil; status = "Game Center 로그인이 필요합니다."; return }
        let id = scope == .weekly ? Self.weeklyID : Self.allTimeID
        GKLeaderboard.loadLeaderboards(IDs: [id]) { [weak self] boards, error in
            guard let board = boards?.first else {
                Task { @MainActor [weak self] in self?.entries = []; self?.localEntry = nil; self?.status = error?.localizedDescription ?? "순위표 설정을 확인해 주세요." }
                return
            }
            board.loadEntries(for: scope == .friends ? .friendsOnly : .global,
                              timeScope: scope == .weekly ? .week : .allTime,
                              range: NSRange(location: 1, length: 25)) { local, list, _, error in
                Task { @MainActor [weak self] in
                    if let local {
                        self?.localEntry = RankingEntry(id: local.player.gamePlayerID, rank: local.rank,
                                                        name: local.player.displayName, score: local.score, local: true)
                    } else { self?.localEntry = nil }
                    self?.entries = (list ?? []).map { entry in
                        RankingEntry(id: entry.player.gamePlayerID, rank: entry.rank,
                                     name: entry.player.displayName, score: entry.score,
                                     local: entry.player.gamePlayerID == GKLocalPlayer.local.gamePlayerID)
                    }
                    self?.status = error?.localizedDescription ?? (list?.isEmpty == false ? "" : "아직 등록된 기록이 없습니다.")
                }
            }
        }
    }
    func loadDailyStanding() {
        guard authenticated else { dailyStanding = nil; return }
        dailyStanding = nil
        GKLeaderboard.loadLeaderboards(IDs: [Self.dailyID]) { [weak self] boards, _ in
            guard let board = boards?.first else { return }
            board.loadEntries(for: .global, timeScope: .today, range: NSRange(location: 1, length: 1)) { local, _, total, _ in
                Task { @MainActor [weak self] in
                    self?.dailyStanding = local.map { DailyStanding(rank: $0.rank, total: total) }
                }
            }
        }
    }
}
