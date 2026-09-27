import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \AnswerRecord.answeredAt, order: .reverse) private var records: [AnswerRecord]
    @StateObject private var gameCenter = GameCenterManager.shared
    private var today: String { DailyChallenge.key() }
    private var dailyCount: Int { records.filter { $0.dailyKey == today }.count }
    private var lastMode: TrainingMode { records.first.flatMap { TrainingMode(rawValue: $0.mode) } ?? .showdown }
    private var stats: TrainingStats { TrainingStats(records: records) }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("DEALER RUSH").font(.caption.weight(.semibold)).tracking(2).foregroundStyle(Theme.gold)
                    Text("오늘도 정확하게.").font(.system(.title2, design: .serif, weight: .semibold))
                }.padding(.bottom, 4)
                RatingHeroCard(rating: stats.rating)
                NavigationLink { DailyView() } label: {
                    Panel {
                        VStack(alignment: .leading, spacing: 13) {
                            HStack {
                                Image(systemName: "checkmark.seal.fill").font(.title2).foregroundStyle(Theme.gold)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("TODAY'S DEALER TEST").font(.caption.weight(.bold)).tracking(1.2).foregroundStyle(Theme.gold)
                                    Text(dailyCount == 10 ? "오늘의 테스트 완료" : "오늘의 10문제에 도전하세요").font(.subheadline)
                                }
                                Spacer(); Image(systemName: "chevron.right").foregroundStyle(Theme.muted)
                            }
                            HStack(spacing: 14) {
                                Label("10문제", systemImage: "checkmark.circle")
                                Label("공식 기록 1회", systemImage: "rosette")
                                Spacer(minLength: 0)
                            }.font(.caption).foregroundStyle(Theme.muted)
                            ProgressView(value: Double(dailyCount), total: 10).tint(Theme.gold)
                            Text(dailyCount == 10 ? "오늘의 기록 보기" : dailyCount == 0 ? "오늘의 테스트 시작하기  →" : "\(dailyCount)/10 · 이어서 도전하기  →")
                                .font(.subheadline.weight(.semibold)).frame(maxWidth: .infinity).frame(minHeight: 44)
                                .background(Theme.ivory, in: RoundedRectangle(cornerRadius: 12)).foregroundStyle(Theme.background)
                        }
                    }
                }.buttonStyle(.plain)
                NavigationLink { GameScreen(mode: lastMode) } label: {
                    Panel {
                        HStack(spacing: 15) {
                            Image(systemName: lastMode.icon).font(.title2).foregroundStyle(Theme.gold).frame(width: 42)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("최근 모드 연습하기").font(.caption).foregroundStyle(Theme.muted)
                                Text(lastMode.title).font(.headline)
                            }
                            Spacer(); Image(systemName: "play.circle.fill").font(.title).foregroundStyle(Theme.ivory)
                        }.frame(minHeight: 48)
                    }
                }.buttonStyle(.plain)
                HStack(spacing: 4) {
                    summary("\(Int(stats.accuracy * 100))%", "정확도")
                    summary(String(format: "%.1f초", stats.averageSeconds), "평균 시간")
                    summary("×\(stats.bestCombo)", "최고 콤보")
                    summary("\(DailyChallenge.streak(records: records))일", "연속 출석")
                }.padding(.top, 5)
            }.padding(20)
        }
        .navigationBarHidden(true)
        .onAppear(perform: syncScores)
        .onChange(of: gameCenter.authenticated) { _, connected in if connected { syncScores() } }
        .rushBackground()
    }
    private func syncScores() {
        guard gameCenter.authenticated else { return }
        gameCenter.publishRating(TrainingStats(records: records).rating)
        let todayRecords = records.filter { $0.dailyKey == today }
        if todayRecords.count == 10 { gameCenter.publishDaily(todayRecords.reduce(0) { $0 + $1.points }) }
    }
    private func summary(_ value: String, _ label: String) -> some View {
        VStack(spacing: 5) {
            Text(value).font(.subheadline.weight(.semibold)).minimumScaleFactor(0.7).lineLimit(1)
            Text(label).font(.caption2).foregroundStyle(Theme.muted).lineLimit(1)
        }.frame(maxWidth: .infinity)
    }
}

struct PracticeView: View {
    @Query(sort: \AnswerRecord.answeredAt, order: .reverse) private var records: [AnswerRecord]
    @State private var selectedDifficulty: Difficulty = .beginner
    private let upcoming = [("Minimum Raise", "최소 레이즈", "arrow.up.right"), ("Action Order", "액션 순서", "arrow.triangle.2.circlepath"), ("Pot Odds", "팟 오즈", "percent")]
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ScreenTitle(eyebrow: "TRAINING", title: "연습하기")
                Text("하나의 커리어, 세 가지 딜러 판단 훈련.").foregroundStyle(Theme.muted)
                Picker("난이도", selection: $selectedDifficulty) {
                    ForEach(Difficulty.allCases) { difficulty in Text(difficulty.title).tag(difficulty) }
                }.pickerStyle(.segmented)
                ForEach(TrainingMode.allCases) { mode in
                    let mastery = TrainingStats(records: records).mastery(for: mode)
                    NavigationLink { GameScreen(mode: mode, practiceDifficulty: selectedDifficulty) } label: {
                        Panel {
                            HStack(spacing: 16) {
                                Image(systemName: mode.icon).font(.title).frame(width: 44).foregroundStyle(Theme.gold)
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(mode.title).font(.headline)
                                    Text("Lv.\(mastery.level) · 숙련도 \(mastery.percent)% · 정답률 \(Int(mastery.accuracy * 100))%").font(.caption).foregroundStyle(Theme.muted)
                                    ProgressView(value: Double(mastery.percent), total: 100).tint(Theme.gold)
                                    Text(mastery.personalBest == 0 ? "첫 기록을 만들어보세요" : "최고 \(mastery.personalBest.formatted()) XP · 최근 10문제 \(mastery.recentCorrect)정답")
                                        .font(.caption2).foregroundStyle(Theme.muted)
                                }
                                Spacer(); Image(systemName: "chevron.right").foregroundStyle(Theme.muted)
                            }.frame(minHeight: 88)
                        }
                    }.buttonStyle(.plain)
                }
                Text("COMING SOON").font(.caption.weight(.semibold)).tracking(2).foregroundStyle(Theme.muted).padding(.top, 10)
                ForEach(upcoming.indices, id: \.self) { index in
                    let item = upcoming[index]
                    HStack(spacing: 16) {
                        Image(systemName: item.2).frame(width: 42)
                        VStack(alignment: .leading) { Text(item.0); Text(item.1).font(.caption) }
                        Spacer(); Text("준비 중").font(.caption)
                    }.foregroundStyle(Theme.muted).padding(16).background(Theme.panel.opacity(0.55), in: RoundedRectangle(cornerRadius: 16))
                }
            }.padding(20)
        }.navigationBarHidden(true).rushBackground()
    }
}
