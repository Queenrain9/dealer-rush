import SwiftUI
import SwiftData

struct DailyView: View {
    @Query private var allRecords: [AnswerRecord]
    @StateObject private var gameCenter = GameCenterManager.shared
    private var key: String { DailyChallenge.key() }
    private var records: [AnswerRecord] { allRecords.filter { $0.dailyKey == key } }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                ScreenTitle(eyebrow: key, title: "오늘의 근무")
                Panel {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("TODAY’S SHIFT").font(.caption.weight(.bold)).tracking(1.4).foregroundStyle(Theme.gold)
                        Text("매일 새로 열리는 10핸드 테이블.").font(.headline)
                        Text("목표는 정확한 판정 8회. 속도와 연속 성공으로 점수를 높이세요. 하루 한 번의 공식 기록이며, 중간에 나가도 이어서 플레이할 수 있어요.").font(.subheadline).foregroundStyle(Theme.muted)
                        ProgressView(value: Double(records.count), total: 10).tint(Theme.gold)
                        HStack { info("\(records.count)/10", "핸드"); info("\(records.filter(\.correct).count)", "정답"); info("1회", "공식 기록") }
                    }
                }
                if records.count < 10 {
                    NavigationLink { GameScreen(dailyKey: key) } label: {
                        Text(records.isEmpty ? "테이블 맡기" : "근무 이어가기").font(.headline).frame(maxWidth: .infinity).frame(minHeight: 54).background(Theme.red.gradient, in: RoundedRectangle(cornerRadius: 16))
                    }.buttonStyle(.plain)
                } else {
                    Panel {
                        VStack(alignment: .leading, spacing: 12) {
                            Label(records.allSatisfy(\.correct) ? "PERFECT SHIFT" : records.filter(\.correct).count >= 8 ? "근무 목표 달성" : "오늘의 근무 완료", systemImage: "checkmark.circle.fill").foregroundStyle(Theme.gold)
                            Text("\(records.reduce(0) { $0 + $1.points }.formatted()) XP").font(.largeTitle.bold()).foregroundStyle(Theme.gold)
                            Text("정확도 \(Int(Double(records.filter(\.correct).count) / 10 * 100))% · 총 \(String(format: "%.1f", records.map(\.responseSeconds).reduce(0,+)))초")
                            if let standing = gameCenter.dailyStanding {
                                Text("Game Center 오늘 순위 #\(standing.rank) / \(standing.total.formatted())")
                                    .font(.subheadline).foregroundStyle(Theme.ivory)
                            } else {
                                Text(gameCenter.authenticated ? "오늘 순위가 아직 준비되지 않았습니다." : "Game Center에 로그인하면 오늘 순위를 확인할 수 있습니다.")
                                    .font(.caption).foregroundStyle(Theme.muted)
                            }
                        }
                    }
                }
            }.padding(20)
        }.navigationTitle("오늘의 근무").navigationBarTitleDisplayMode(.inline)
            .onAppear { if records.count == 10 { gameCenter.loadDailyStanding() } }
            .rushBackground()
    }
    private func info(_ value: String, _ label: String) -> some View {
        VStack { Text(value).font(.title3.bold()); Text(label).font(.caption).foregroundStyle(Theme.muted) }.frame(maxWidth: .infinity)
    }
}

struct StatsView: View {
    @Query(sort: \AnswerRecord.answeredAt, order: .reverse) private var records: [AnswerRecord]
    private var stats: TrainingStats { TrainingStats(records: records) }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ScreenTitle(eyebrow: "MY RECORD", title: "내 기록")
                RatingHeroCard(rating: stats.rating)
                if let change = stats.comparison {
                    Panel {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("최근 10핸드와 이전 10핸드").font(.headline)
                            comparisonRow("Dealer Rating", "\(change.olderRating.formatted())", "\(change.recentRating.formatted())")
                            comparisonRow("정확도", "\(Int(change.olderAccuracy * 100))%", "\(Int(change.recentAccuracy * 100))%")
                            comparisonRow("평균 시간", String(format: "%.1f초", change.olderAverageSeconds), String(format: "%.1f초", change.recentAverageSeconds))
                        }
                    }
                }
                HStack(spacing: 10) {
                    stat("\(Int(stats.accuracy * 100))%", "정확도")
                    stat(String(format: "%.1f초", stats.averageSeconds), "평균 시간")
                    stat("×\(stats.bestCombo)", "최고 콤보")
                }
                Text("총 \(stats.total)문제 해결").foregroundStyle(Theme.muted)
                Text("모드별 기록").font(.headline)
                ForEach(TrainingMode.allCases) { mode in
                    let value = stats.forMode(mode)
                    let mastery = stats.mastery(for: mode)
                    Panel {
                        HStack {
                            Image(systemName: mode.icon).foregroundStyle(Theme.gold).frame(width: 32)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(mode.title).font(.headline)
                                Text("Lv.\(mastery.level) · 숙련도 \(mastery.percent)% · \(value.total)문제")
                                    .font(.caption).foregroundStyle(Theme.muted)
                                ProgressView(value: Double(mastery.percent), total: 100).tint(Theme.gold)
                            }
                        }
                    }
                }
                NavigationLink { RankingView() } label: {
                    Label("Game Center 랭킹", systemImage: "trophy.fill").font(.headline).frame(maxWidth: .infinity).frame(minHeight: 52).background(Theme.forest, in: RoundedRectangle(cornerRadius: 16))
                }.buttonStyle(.plain)
            }.padding(20)
        }.navigationBarHidden(true).rushBackground()
    }
    private func stat(_ value: String, _ title: String) -> some View {
        VStack(spacing: 7) { Text(value).font(.title3.bold()).minimumScaleFactor(0.75).lineLimit(1); Text(title).font(.caption).foregroundStyle(Theme.muted) }
            .frame(maxWidth: .infinity).padding(.vertical, 16).background(Theme.panel, in: RoundedRectangle(cornerRadius: 14))
    }
    private func comparisonRow(_ label: String, _ before: String, _ after: String) -> some View {
        HStack { Text(label); Spacer(); Text(before).foregroundStyle(Theme.muted); Image(systemName: "arrow.right").font(.caption).foregroundStyle(Theme.muted); Text(after).foregroundStyle(Theme.gold) }
            .font(.subheadline).monospacedDigit()
    }
}

struct RankingView: View {
    @StateObject private var gameCenter = GameCenterManager.shared
    @State private var scope: RankingScope = .weekly
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ScreenTitle(eyebrow: "GAME CENTER", title: "랭킹")
                Picker("범위", selection: $scope) {
                    ForEach(RankingScope.allCases) { option in Text(option.title).tag(option) }
                }.pickerStyle(.segmented)
                if let mine = gameCenter.localEntry {
                    Panel {
                        HStack {
                            Image(systemName: "crown.fill").foregroundStyle(Theme.gold)
                            VStack(alignment: .leading) { Text("내 순위 #\(mine.rank)").font(.headline); Text(mine.name).font(.caption).foregroundStyle(Theme.muted) }
                            Spacer(); Text(mine.score.formatted()).font(.headline).monospacedDigit()
                        }
                    }
                }
                if gameCenter.entries.isEmpty {
                    Panel { Text(gameCenter.status).foregroundStyle(Theme.muted) }
                } else {
                    ForEach(gameCenter.entries.filter { !$0.local }) { entry in
                        Panel {
                            HStack {
                                Text("\(entry.rank)").font(.headline).foregroundStyle(Theme.gold).frame(width: 36)
                                Text(entry.name).fontWeight(entry.local ? .bold : .regular).lineLimit(1)
                                Spacer(); Text(entry.score.formatted()).monospacedDigit()
                            }
                        }
                    }
                }
            }.padding(20)
        }.navigationTitle("랭킹").navigationBarTitleDisplayMode(.inline)
            .onAppear { gameCenter.load(scope: scope) }
            .onChange(of: scope) { _, newValue in gameCenter.load(scope: newValue) }
            .rushBackground()
    }
}

struct SettingsView: View {
    @AppStorage("sound") private var sound = true
    @AppStorage("haptics") private var haptics = true
    @StateObject private var gameCenter = GameCenterManager.shared
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                ScreenTitle(eyebrow: "PREFERENCES", title: "설정")
                Panel {
                    VStack(spacing: 16) {
                        Toggle("사운드", isOn: $sound)
                        Divider()
                        Toggle("햅틱", isOn: $haptics)
                    }.tint(Theme.gold)
                }
                Panel {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Game Center", systemImage: "trophy.fill").foregroundStyle(Theme.gold)
                        Text(gameCenter.status).font(.subheadline).foregroundStyle(Theme.muted)
                        if !gameCenter.authenticated { Button("다시 연결") { gameCenter.authenticate() }.font(.subheadline.bold()).padding(.top, 5) }
                    }
                }
                Text("DEALER RUSH 1.0 · 기기에서 플레이 기록을 저장합니다. 실제 현금 및 베팅 기능은 없습니다.")
                    .font(.footnote).foregroundStyle(Theme.muted)
            }.padding(20)
        }.navigationBarHidden(true).rushBackground()
    }
}
