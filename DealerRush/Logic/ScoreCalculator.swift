import Foundation

struct DealerTier: Identifiable {
    let name: String
    let minimum: Int
    var id: String { name }
}

struct TierProgress {
    let name: String
    let nextName: String?
    let nextThreshold: Int?
    let remaining: Int
    let fraction: Double
}

struct ModeMastery {
    let level: Int
    let percent: Int
    let accuracy: Double
    let personalBest: Int
    let recentCorrect: Int
}
struct ProgressComparison {
    let olderRating: Int
    let recentRating: Int
    let olderAccuracy: Double
    let recentAccuracy: Double
    let olderAverageSeconds: Double
    let recentAverageSeconds: Double
}

enum ScoreCalculator {
    static let tiers = [
        DealerTier(name: "Trainee", minimum: 1_000),
        DealerTier(name: "Dealer", minimum: 1_200),
        DealerTier(name: "Skilled Dealer", minimum: 1_450),
        DealerTier(name: "Senior Dealer", minimum: 1_750),
        DealerTier(name: "Elite Dealer", minimum: 2_200)
    ]
    static func points(correct: Bool, seconds: Double, combo: Int, difficulty: Difficulty) -> Int {
        guard correct else { return 0 }
        let speed = max(0, 60 - Int(max(0, seconds) * 6))
        return (80 + speed + min(combo, 10) * 5) * difficulty.rawValue
    }
    static func rating(_ records: [AnswerRecord]) -> Int {
        max(0, 1_000 + records.reduce(0) { $0 + ($1.correct ? max(1, $1.points / 12) : -12) })
    }
    static func tier(_ rating: Int) -> String {
        tierProgress(rating).name
    }
    static func tierProgress(_ rating: Int) -> TierProgress {
        let currentIndex = tiers.lastIndex { rating >= $0.minimum } ?? 0
        let current = tiers[currentIndex]
        guard currentIndex + 1 < tiers.count else {
            return TierProgress(name: current.name, nextName: nil, nextThreshold: nil, remaining: 0, fraction: 1)
        }
        let next = tiers[currentIndex + 1]
        let range = max(1, next.minimum - current.minimum)
        return TierProgress(name: current.name, nextName: next.name, nextThreshold: next.minimum,
                            remaining: max(0, next.minimum - rating),
                            fraction: min(1, max(0, Double(rating - current.minimum) / Double(range))))
    }
}

struct TrainingStats {
    let records: [AnswerRecord]
    var total: Int { records.count }
    var correct: Int { records.filter(\.correct).count }
    var accuracy: Double { total == 0 ? 0 : Double(correct) / Double(total) }
    var averageSeconds: Double { total == 0 ? 0 : records.map(\.responseSeconds).reduce(0,+) / Double(total) }
    var bestCombo: Int { records.map(\.combo).max() ?? 0 }
    var rating: Int { ScoreCalculator.rating(records) }
    func forMode(_ mode: TrainingMode) -> TrainingStats { TrainingStats(records: records.filter { $0.mode == mode.rawValue }) }
    func mastery(for mode: TrainingMode) -> ModeMastery {
        let modeRecords = records.filter { $0.mode == mode.rawValue }
        let ordered = modeRecords.sorted { $0.answeredAt > $1.answeredAt }
        let recent = Array(ordered.prefix(20))
        let accuracy = recent.isEmpty ? 0 : Double(recent.filter(\.correct).count) / Double(recent.count)
        let confidence = min(1, Double(recent.count) / 10)
        let grouped = Dictionary(grouping: modeRecords.compactMap { record -> (UUID, AnswerRecord)? in
            guard let id = record.sessionID else { return nil }
            return (id, record)
        }, by: { $0.0 })
        let best = grouped.values.map { group in group.reduce(0) { $0 + $1.1.points } }.max()
            ?? modeRecords.map(\.points).max() ?? 0
        return ModeMastery(level: min(10, 1 + modeRecords.count / 20),
                           percent: Int((accuracy * confidence * 100).rounded()),
                           accuracy: accuracy, personalBest: best,
                           recentCorrect: recent.prefix(10).filter(\.correct).count)
    }
    var ratingHistory: [(Date, Int)] {
        let ordered = records.sorted { $0.answeredAt < $1.answeredAt }
        var rawValue = 1_000
        return ordered.map { record in
            rawValue += record.correct ? max(1, record.points / 12) : -12
            return (record.answeredAt, max(0, rawValue))
        }
    }
    var ratingChange: Int {
        let history = ratingHistory
        guard history.count >= 2 else { return 0 }
        return history.last!.1 - history[max(0, history.count - 11)].1
    }
    var comparison: ProgressComparison? {
        let ordered = records.sorted { $0.answeredAt < $1.answeredAt }
        guard ordered.count >= 20 else { return nil }
        let older = Array(ordered.dropLast(10).suffix(10))
        let recent = Array(ordered.suffix(10))
        let history = ratingHistory
        return ProgressComparison(olderRating: history[history.count - 11].1,
                                  recentRating: history.last!.1,
                                  olderAccuracy: TrainingStats(records: older).accuracy,
                                  recentAccuracy: TrainingStats(records: recent).accuracy,
                                  olderAverageSeconds: TrainingStats(records: older).averageSeconds,
                                  recentAverageSeconds: TrainingStats(records: recent).averageSeconds)
    }
    var improvement: Int {
        guard records.count >= 20 else { return 0 }
        let sorted = records.sorted { $0.answeredAt < $1.answeredAt }
        let recent = sorted.suffix(10).filter(\.correct).count
        let earlier = sorted.dropLast(10).suffix(10).filter(\.correct).count
        return recent - earlier
    }
}
