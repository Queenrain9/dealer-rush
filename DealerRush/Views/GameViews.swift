import SwiftUI
import SwiftData

struct PlayingCardView: View {
    let card: Card
    var compact = false
    var body: some View {
        VStack(spacing: 0) {
            Text(card.label).font(.system(size: compact ? 17 : 20, weight: .bold, design: .serif))
            Text(card.suit.symbol).font(.system(size: compact ? 19 : 24))
        }
        .foregroundStyle(card.suit.red ? Theme.red : .black)
        .frame(maxWidth: .infinity).frame(height: compact ? 48 : 64)
        .background(Theme.ivory, in: RoundedRectangle(cornerRadius: 5))
        .accessibilityLabel("\(card.label) \(card.suit.symbol)")
    }
}

struct PotTableView: View {
    let contributions: [Int]
    private func status(for index: Int) -> String {
        let high = contributions.max() ?? 0
        if contributions[index] < high { return "All-in" }
        let firstHigh = contributions.firstIndex(of: high) ?? index
        return index == firstHigh ? "Bet" : "Call"
    }
    private func point(_ index: Int, size: CGSize) -> CGPoint {
        switch contributions.count {
        case 2: return index == 0 ? CGPoint(x: size.width / 2, y: 34) : CGPoint(x: size.width / 2, y: size.height - 34)
        case 3:
            return [CGPoint(x: size.width / 2, y: 32), CGPoint(x: 58, y: size.height / 2),
                    CGPoint(x: size.width - 58, y: size.height / 2)][index]
        default:
            return [CGPoint(x: size.width / 2, y: 32), CGPoint(x: 58, y: size.height / 2),
                    CGPoint(x: size.width - 58, y: size.height / 2), CGPoint(x: size.width / 2, y: size.height - 32)][index]
        }
    }
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Ellipse().fill(Theme.forest.gradient)
                    .overlay(Ellipse().stroke(Theme.gold.opacity(0.45), lineWidth: 2))
                    .padding(.horizontal, 20).padding(.vertical, 15)
                VStack(spacing: 2) {
                    Text("POT").font(.caption2.weight(.bold)).tracking(1).foregroundStyle(Theme.muted)
                    Text("?").font(.title2.weight(.bold)).foregroundStyle(Theme.ivory)
                }.frame(width: 66, height: 66).background(Theme.background, in: Circle())
                ForEach(contributions.indices, id: \.self) { index in
                    VStack(spacing: 2) {
                        Text("P\(index + 1) · \(status(for: index))").font(.caption2.weight(.semibold))
                            .foregroundStyle(status(for: index) == "All-in" ? Theme.gold : Theme.ivory)
                        Text(contributions[index].formatted()).font(.caption.weight(.bold)).monospacedDigit()
                    }
                    .lineLimit(1).minimumScaleFactor(0.75)
                    .frame(width: 104, height: 49)
                    .background(Theme.panel, in: RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(.white.opacity(0.10)))
                    .position(point(index, size: geometry.size))
                    .accessibilityLabel("Player \(index + 1), \(status(for: index)), \(contributions[index]) chips")
                }
            }
        }
        .frame(height: 238)
        .accessibilityElement(children: .contain)
    }
}

struct GameScreen: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query private var records: [AnswerRecord]
    @State private var session: TrainingSession
    @StateObject private var gameCenter = GameCenterManager.shared
    @State private var showingExplanation = false
    @FocusState private var amountFocused: Bool
    init(mode: TrainingMode? = nil, dailyKey: String? = nil, practiceDifficulty: Difficulty? = nil) {
        _session = State(initialValue: TrainingSession(mode: mode, dailyKey: dailyKey, practiceDifficulty: practiceDifficulty))
    }
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 18) {
                    if session.finished { completed.id("handTop") }
                    else if let question = session.question {
                        trainingHeader.id("handTop")
                        Group {
                            switch question {
                            case let .showdown(q): showdown(q)
                            case let .mainPot(q): mainPot(q)
                            case let .sidePot(q): sidePot(q)
                            }
                        }.disabled(session.outcome != nil)
                        if let error = session.error { Text(error).font(.footnote).foregroundStyle(.red) }
                    }
                }.padding(20).frame(maxWidth: 560).frame(maxWidth: .infinity)
            }
            .onChange(of: session.index) { _, _ in proxy.scrollTo("handTop", anchor: .top) }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !session.finished, session.question != nil {
                VStack(spacing: 10) {
                    if let outcome = session.outcome { feedback(outcome) }
                    PrimaryButton(title: session.outcome == nil ? actionTitle : session.index == 9 ? "근무 평가 보기" : "다음 핸드  →",
                                  enabled: session.outcome != nil || canSubmit) {
                        amountFocused = false
                        if session.outcome == nil { submit() } else { nextHand() }
                    }
                }.padding(.horizontal, 20).padding(.vertical, 12)
                    .frame(maxWidth: 560).frame(maxWidth: .infinity)
                    .background(Theme.background)
            }
        }
        .navigationTitle(session.isDaily ? "오늘의 근무" : session.mode.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .onAppear { session.start(context: context) }
        .scrollDismissesKeyboard(.interactively)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("완료") { amountFocused = false }
            }
        }
        .sheet(isPresented: $showingExplanation) {
            NavigationStack {
                ScrollView {
                    if let outcome = session.outcome { result(outcome).padding(20) }
                }
                .navigationTitle("판정 확인").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("닫기") { showingExplanation = false } } }
                .rushBackground()
            }.presentationDetents([.medium, .large])
        }
        .rushBackground()
    }
    private var actionTitle: String {
        switch session.mode {
        case .showdown: "팟 지급 확정"
        case .potCalculation: "메인 팟 확정"
        case .sidePot: "팟 분리 확정"
        }
    }
    private var successfulHands: Int {
        records.filter { record in
            let belongsToShift = session.dailyKey.map { record.dailyKey == $0 } ?? (record.sessionID == session.sessionID)
            return belongsToShift && record.correct
        }.count
    }
    private var trainingHeader: some View {
        VStack(spacing: 10) {
            HStack {
                Text("HAND \(session.index + 1) / 10").foregroundStyle(Theme.gold)
                Spacer()
                Text(session.difficulty.title).foregroundStyle(Theme.muted)
            }.font(.caption.weight(.semibold)).monospacedDigit()
            ProgressView(value: Double(session.answeredCount), total: 10).tint(Theme.gold)
            HStack(spacing: 0) {
                TimelineView(.periodic(from: .now, by: 0.1)) { timeline in
                    miniMetric(String(format: "%.2f초", session.elapsedSeconds(at: timeline.date)), "시간")
                }
                miniMetric("×\(session.combo)", "연속 성공")
                miniMetric(session.sessionScore.formatted(), "SCORE")
            }.padding(.vertical, 10).background(Theme.panel, in: RoundedRectangle(cornerRadius: 12))
            HStack {
                Label(successfulHands >= 8 ? "목표 달성" : "정확한 판정 · 목표 8", systemImage: successfulHands >= 8 ? "checkmark.seal.fill" : "flag.checkered")
                Spacer()
                Text("\(successfulHands) / 10").monospacedDigit()
            }.font(.caption.weight(.medium)).foregroundStyle(successfulHands >= 8 ? Theme.gold : Theme.muted)
        }
    }
    private func feedback(_ outcome: AnswerOutcome) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Label(outcome.correct ? "NICE DEAL" : "판정 오류", systemImage: outcome.correct ? "checkmark.circle.fill" : "arrow.uturn.backward.circle")
                    .font(.subheadline.bold()).foregroundStyle(outcome.correct ? Color.green : Theme.ivory)
                Spacer()
                Text(outcome.correct ? "+\(outcome.points) XP" : "콤보 리셋")
                    .font(.subheadline.bold()).foregroundStyle(Theme.gold).monospacedDigit()
            }
            Button { showingExplanation = true } label: {
                HStack(alignment: .top, spacing: 8) {
                    Text(outcome.explanation).lineLimit(2).multilineTextAlignment(.leading)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                }.font(.caption).foregroundStyle(Theme.muted).frame(minHeight: 44)
            }.buttonStyle(.plain).accessibilityLabel("판정 해설: \(outcome.explanation)")
        }
        .accessibilityElement(children: .contain)
    }
    private func nextHand() {
        session.next()
        if session.finished {
            Feedback.complete()
            if let key = session.dailyKey, let records = try? context.fetch(FetchDescriptor<AnswerRecord>()) {
                gameCenter.publishDaily(records.filter { $0.dailyKey == key }.reduce(0) { $0 + $1.points })
            }
        }
    }
    private func miniMetric(_ value: String, _ label: String) -> some View {
        VStack(spacing: 4) {
            Text(label).font(.caption2).foregroundStyle(Theme.muted)
            Text(value).font(.subheadline.weight(.semibold)).monospacedDigit().lineLimit(1).minimumScaleFactor(0.7)
                .contentTransition(.numericText())
                .animation(reduceMotion || label == "시간" ? nil : .easeOut(duration: 0.18), value: value)
        }.frame(maxWidth: .infinity)
    }
    private var canSubmit: Bool {
        guard let question = session.question else { return false }
        switch question {
        case .showdown: return session.selectedPlayer != nil
        case .mainPot, .sidePot: return !session.amountEntries.isEmpty && session.amountEntries.allSatisfy { Int($0.filter(\.isNumber)) != nil }
        }
    }
    private func submit() {
        session.submit(context: context)
        if session.outcome != nil, let records = try? context.fetch(FetchDescriptor<AnswerRecord>()) {
            gameCenter.publishRating(TrainingStats(records: records).rating)
        }
    }
    private func showdown(_ question: ShowdownQuestion) -> some View {
        VStack(spacing: 20) {
            Panel {
                VStack(spacing: 16) {
                    Text("BOARD").font(.caption.weight(.semibold)).tracking(2).foregroundStyle(Theme.gold)
                    HStack(spacing: 5) { ForEach(question.board) { PlayingCardView(card: $0) } }
                }
            }
            Text("팟을 받을 플레이어는?").font(.title2.weight(.semibold))
            ForEach(question.players.indices, id: \.self) { index in
                Button {
                    session.selectedPlayer = index; Feedback.tap()
                } label: {
                    HStack(spacing: 8) {
                        Text("Player \(index + 1)").font(.subheadline.weight(.medium)).frame(width: 75, alignment: .leading)
                        ForEach(question.players[index].hole) { PlayingCardView(card: $0, compact: true).frame(maxWidth: 44) }
                        Spacer(minLength: 2)
                        Image(systemName: session.selectedPlayer == index ? "largecircle.fill.circle" : "circle").foregroundStyle(session.selectedPlayer == index ? Theme.gold : Theme.muted)
                    }.padding(10).background(session.selectedPlayer == index ? Theme.forest : Theme.panel, in: RoundedRectangle(cornerRadius: 14))
                }.buttonStyle(.plain).disabled(session.outcome != nil)
            }
            Button {
                session.selectedPlayer = -1; Feedback.tap()
            } label: {
                HStack { Text("Tie / Chop"); Spacer(); Image(systemName: session.selectedPlayer == -1 ? "largecircle.fill.circle" : "circle") }
                    .padding(15).background(session.selectedPlayer == -1 ? Theme.forest : Theme.panel, in: RoundedRectangle(cornerRadius: 14))
            }.buttonStyle(.plain).disabled(session.outcome != nil)
        }
    }
    private func contributionList(_ amounts: [Int]) -> some View {
        Panel {
            VStack(alignment: .leading, spacing: 15) {
                Text("PLAYER CONTRIBUTIONS").font(.caption.weight(.semibold)).tracking(1).foregroundStyle(Theme.gold)
                ForEach(amounts.indices, id: \.self) { index in
                    let maximum = amounts.max() ?? 0
                    let action = amounts[index] < maximum ? "All-in" : index == (amounts.firstIndex(of: maximum) ?? index) ? "Bet" : "Call"
                    HStack {
                        Text("P\(index + 1)").font(.caption.weight(.bold)).frame(width: 30, height: 30).background(Theme.forest, in: Circle())
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Player \(index + 1)")
                            Text(action).font(.caption2).foregroundStyle(Theme.gold)
                        }
                        Spacer()
                        Text(amounts[index].formatted()).monospacedDigit().foregroundStyle(Theme.ivory)
                    }.font(.subheadline)
                }
            }
        }
    }
    private func mainPot(_ question: PotQuestion) -> some View {
        VStack(spacing: 22) {
            Text("메인 팟을 정리하세요").font(.title3.weight(.semibold)).multilineTextAlignment(.center)
            PotTableView(contributions: question.contributions)
            let right = question.pots[0].amount
            let choices = Array(Set([right, right + 10_000, max(5_000, right - 10_000), question.contributions.reduce(0,+)])).sorted()
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(choices, id: \.self) { choice in
                    Button { session.amountEntries[0] = String(choice); Feedback.tap() } label: {
                        Text(choice.formatted()).font(.headline.monospacedDigit()).frame(maxWidth: .infinity).frame(minHeight: 54)
                            .background(session.amountEntries[0] == String(choice) ? Theme.forest : Theme.panel, in: RoundedRectangle(cornerRadius: 14))
                    }.buttonStyle(.plain)
                }
            }
            TextField("금액 직접 입력", text: $session.amountEntries[0])
                .keyboardType(.numberPad).focused($amountFocused).padding(16).background(Theme.panel, in: RoundedRectangle(cornerRadius: 14))
                .disabled(session.outcome != nil)
        }
    }
    private func sidePot(_ question: PotQuestion) -> some View {
        VStack(spacing: 20) {
            Text("메인 팟과 사이드 팟을 분리하세요").font(.title3.weight(.semibold))
            contributionList(question.contributions)
            ForEach(question.pots.indices, id: \.self) { index in
                Panel {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(index == 0 ? "Main Pot" : "Side Pot \(index)").font(.headline)
                        Text("참가 가능: \(question.pots[index].eligible.map { "P\($0 + 1)" }.joined(separator: ", "))")
                            .font(.caption).foregroundStyle(Theme.muted)
                        TextField("금액 입력", text: $session.amountEntries[index])
                            .keyboardType(.numberPad).focused($amountFocused).padding(12).background(Theme.background, in: RoundedRectangle(cornerRadius: 10))
                            .disabled(session.outcome != nil)
                    }
                }
            }
        }
    }
    private func result(_ outcome: AnswerOutcome) -> some View {
        VStack(spacing: 20) {
            Image(systemName: outcome.correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 50)).foregroundStyle(outcome.correct ? .green : Theme.red)
            Text(outcome.correct ? "정확한 판정!" : "올바른 판정을 확인하세요").font(.title2.bold())
            Text(outcome.explanation).font(.subheadline).multilineTextAlignment(.center).foregroundStyle(Theme.ivory)
            HStack {
                metric("+\(outcome.points) XP", "획득 점수")
                metric(String(format: "%.2f초", outcome.seconds), "TIME")
                metric("×\(outcome.combo)", "COMBO")
            }
            Panel {
                VStack(alignment: .leading, spacing: 10) {
                    Text("DEALER RATING").font(.caption.weight(.semibold)).tracking(1).foregroundStyle(Theme.gold)
                    HStack(alignment: .firstTextBaseline) {
                        Text(outcome.ratingBefore.formatted()).foregroundStyle(Theme.muted)
                        Image(systemName: "arrow.right").font(.caption).foregroundStyle(Theme.muted)
                        Text(outcome.ratingAfter.formatted()).font(.title2.bold()).foregroundStyle(Theme.ivory)
                        Spacer()
                        let delta = outcome.ratingAfter - outcome.ratingBefore
                        Text(delta >= 0 ? "+\(delta)" : "\(delta)").foregroundStyle(delta >= 0 ? Theme.gold : Theme.muted)
                    }.monospacedDigit()
                    Text("세션 점수 \(outcome.sessionScore.formatted())").font(.subheadline).foregroundStyle(Theme.muted)
                }
            }

        }.padding(.top, 30).frame(maxWidth: .infinity)
    }
    private func metric(_ value: String, _ title: String) -> some View {
        VStack(spacing: 4) { Text(value).font(.subheadline.bold()).minimumScaleFactor(0.7).lineLimit(1); Text(title).font(.caption2).foregroundStyle(Theme.muted) }
            .frame(maxWidth: .infinity)
    }
    private var completed: some View {
        VStack(spacing: 22) {
            Image(systemName: "checkmark.seal.fill").font(.system(size: 58)).foregroundStyle(Theme.gold)
            Text(session.isDaily ? "오늘의 근무 종료" : "테이블 마감").font(.title2.bold())
            CompletionSummary(dailyKey: session.dailyKey, sessionID: session.sessionID)
            PrimaryButton(title: "근무 마치기") { dismiss() }
        }.padding(.top, 50)
    }
}

private struct CompletionSummary: View {
    @Query private var records: [AnswerRecord]
    let dailyKey: String?
    let sessionID: UUID
    private var selected: [AnswerRecord] {
        if let dailyKey { return records.filter { $0.dailyKey == dailyKey } }
        return records.filter { $0.sessionID == sessionID }
    }
    private var stats: TrainingStats { TrainingStats(records: selected) }
    private var ratingDelta: Int? { ScoreCalculator.shiftRatingDelta(selected) }
    var body: some View {
        Panel {
            VStack(spacing: 16) {
                Text(stats.correct == 10 ? "PERFECT SHIFT" : stats.correct >= 8 ? "근무 목표 달성" : "다음 근무에서 다시 도전")
                    .font(.headline).foregroundStyle(Theme.gold).multilineTextAlignment(.center)
                Text("\(selected.reduce(0) { $0 + $1.points }.formatted())")
                    .font(.system(size: 44, weight: .bold, design: .rounded)).foregroundStyle(Theme.ivory)
                Text("SHIFT SCORE").font(.caption.weight(.semibold)).tracking(2).foregroundStyle(Theme.muted)
                HStack { Text("정확한 판정"); Spacer(); Text("\(stats.correct) / 10") }
                HStack { Text("총 시간"); Spacer(); Text(String(format: "%.1f초", selected.map(\.responseSeconds).reduce(0,+))) }
                HStack { Text("최고 콤보"); Spacer(); Text("×\(stats.bestCombo)") }
                if let delta = ratingDelta {
                    Divider()
                    HStack {
                        Text("Dealer Rating")
                        Spacer()
                        Text(delta >= 0 ? "+\(delta)" : "\(delta)").fontWeight(.bold).foregroundStyle(Theme.gold)
                    }
                }
                Text("정확한 판정 8회가 근무 목표입니다.\n기록은 커리어에 저장됐어요.")
                    .font(.caption).foregroundStyle(Theme.muted).multilineTextAlignment(.center)
            }.monospacedDigit()
        }
    }
}
