import Foundation
import Observation
import SwiftData

struct AnswerOutcome {
    let correct: Bool
    let explanation: String
    let seconds: Double
    let points: Int
    let combo: Int
    let sessionScore: Int
    let ratingBefore: Int
    let ratingAfter: Int
}

@Observable final class TrainingSession {
    let requestedMode: TrainingMode?
    let dailyKey: String?
    let practiceDifficulty: Difficulty?
    var index = 0
    var question: TrainingQuestion?
    var outcome: AnswerOutcome?
    var selectedPlayer: Int?
    var amountEntries: [String] = []
    var error: String?
    var sessionScore = 0
    var answeredCount = 0
    private(set) var combo = 0
    private(set) var sessionID = UUID()
    private var startedAt = Date()
    private let sessionSeed = UInt64.random(in: 1...UInt64.max)
    init(mode: TrainingMode? = nil, dailyKey: String? = nil, practiceDifficulty: Difficulty? = nil) {
        requestedMode = mode; self.dailyKey = dailyKey; self.practiceDifficulty = practiceDifficulty
    }
    var isDaily: Bool { dailyKey != nil }
    var mode: TrainingMode { requestedMode ?? DailyChallenge.mode(at: index) }
    var difficulty: Difficulty { isDaily ? DailyChallenge.difficulty(at: index) : (practiceDifficulty ?? (index < 3 ? .beginner : index < 7 ? .intermediate : .advanced)) }
    var finished: Bool { index >= 10 }
    func elapsedSeconds(at date: Date = .now) -> Double {
        // Feedback stays on the table; its clock must match the saved answer.
        outcome?.seconds ?? max(0, date.timeIntervalSince(startedAt))
    }

    func start(context: ModelContext) {
        guard question == nil else { return }
        if let dailyKey {
            if let allRecords = try? context.fetch(FetchDescriptor<AnswerRecord>()) {
                let sorted = allRecords.filter { $0.dailyKey == dailyKey }.sorted { $0.questionIndex < $1.questionIndex }
                index = min(10, sorted.count)
                combo = sorted.reversed().prefix(while: { $0.correct }).count
                answeredCount = sorted.count
                sessionScore = sorted.reduce(0) { $0 + $1.points }
                if let existingID = sorted.first?.sessionID { sessionID = existingID }
            }
        }
        prepare()
    }
    private func prepare() {
        guard !finished else { question = nil; return }
        let seed = dailyKey.map { DailyChallenge.seed(dateKey: $0, index: index) }
            ?? (sessionSeed &+ UInt64(index) &* 0x9e3779b97f4a7c15)
        question = QuestionFactory.make(mode: mode, difficulty: difficulty, seed: seed)
        selectedPlayer = nil
        amountEntries = question.map { q in
            switch q { case .showdown: []; case .mainPot: [""]; case let .sidePot(p): Array(repeating: "", count: p.pots.count) }
        } ?? []
        outcome = nil; error = nil; startedAt = .now
    }
    func submit(context: ModelContext) {
        guard let question, outcome == nil else { return }
        let correct: Bool
        let explanation: String
        switch question {
        case let .showdown(q):
            guard let selectedPlayer else { return }
            correct = q.winners.count > 1 ? selectedPlayer == -1 : selectedPlayer == q.winners[0]
            let winners = q.winners.map { "Player \($0 + 1)" }.joined(separator: " & ")
            let boardPlays = q.winners.count == q.players.count && HandEvaluator.best(q.board) == q.winningHand
            explanation = "\(winners) · \(q.winningHand.category.title) (\(q.winningHand.detail))" + (boardPlays ? " · Board plays" : q.winners.count > 1 ? " · Chop" : "")
        case let .mainPot(q):
            guard let amount = Int(amountEntries[0].filter(\.isNumber)) else { return }
            correct = amount == q.pots[0].amount
            explanation = "Main Pot · \(q.pots[0].amount.formatted()) chips. 최저 기여액을 참여 인원에 곱합니다."
        case let .sidePot(q):
            let amounts = amountEntries.map { Int($0.filter(\.isNumber)) }
            guard amounts.allSatisfy({ $0 != nil }) else { return }
            correct = amounts.compactMap { $0 } == q.pots.map(\.amount)
            explanation = q.pots.enumerated().map { i, pot in
                "\(i == 0 ? "Main" : "Side \(i)") \(pot.amount.formatted()) · P\(pot.eligible.map { String($0 + 1) }.joined(separator: ", P"))"
            }.joined(separator: "\n")
        }
        let seconds = max(0, Date().timeIntervalSince(startedAt))
        let newCombo = correct ? combo + 1 : 0
        let points = ScoreCalculator.points(correct: correct, seconds: seconds, combo: newCombo, difficulty: difficulty)
        let previousRecords: [AnswerRecord]
        do { previousRecords = try context.fetch(FetchDescriptor<AnswerRecord>()) }
        catch { self.error = "기록을 읽지 못했습니다. 다시 시도해 주세요."; return }
        let ratingBefore = ScoreCalculator.rating(previousRecords)
        let record = AnswerRecord(mode: mode, difficulty: difficulty, correct: correct, responseSeconds: seconds, points: points, combo: newCombo, dailyKey: dailyKey, questionIndex: index)
        record.sessionID = sessionID
        record.ratingBefore = ratingBefore
        record.ratingAfter = ScoreCalculator.rating(previousRecords + [record])
        context.insert(record)
        do { try context.save() }
        catch { context.rollback(); self.error = "기록을 저장하지 못했습니다. 다시 시도해 주세요."; return }
        combo = newCombo
        sessionScore += points
        answeredCount += 1
        outcome = AnswerOutcome(correct: correct, explanation: explanation, seconds: seconds,
                                points: points, combo: newCombo, sessionScore: sessionScore,
                                ratingBefore: ratingBefore, ratingAfter: record.ratingAfter ?? ratingBefore)
        Feedback.answer(correct: correct, combo: newCombo)
    }
    func next() { guard outcome != nil else { return }; index += 1; prepare() }
}
