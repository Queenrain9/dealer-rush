import Foundation

struct StableRandom: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed == 0 ? 0x9e3779b97f4a7c15 : seed }
    mutating func next() -> UInt64 {
        state &+= 0x9e3779b97f4a7c15
        var value = state
        value = (value ^ (value >> 30)) &* 0xbf58476d1ce4e5b9
        value = (value ^ (value >> 27)) &* 0x94d049bb133111eb
        return value ^ (value >> 31)
    }
    mutating func number(_ upper: Int) -> Int { Int(next() % UInt64(upper)) }
}

enum QuestionFactory {
    private static func shuffled<T>(_ input: [T], using rng: inout StableRandom) -> [T] {
        var items = input
        guard items.count > 1 else { return items }
        for index in stride(from: items.count - 1, through: 1, by: -1) {
            items.swapAt(index, rng.number(index + 1))
        }
        return items
    }
    static func make(mode: TrainingMode, difficulty: Difficulty, seed: UInt64) -> TrainingQuestion {
        var rng = StableRandom(seed: seed)
        switch mode {
        case .showdown:
            let cards = shuffled(Card.deck, using: &rng)
            let count = difficulty == .beginner ? 2 : (difficulty == .intermediate ? 3 : 4)
            let board = Array(cards.prefix(5))
            let players = (0..<count).map { index in ShowdownPlayer(hole: Array(cards[(5 + index*2)..<(7 + index*2)])) }
            let values = players.map { HandEvaluator.best(board + $0.hole) }
            let highest = values.max()!
            return .showdown(.init(board: board, players: players, winners: values.indices.filter { values[$0] == highest }, winningHand: highest))
        case .potCalculation:
            let count = difficulty == .beginner ? 2 : (difficulty == .intermediate ? 3 : 4)
            let low = (rng.number(8) + 2) * 5_000
            var contributions = Array(repeating: low, count: count)
            if count > 2 {
                let high = low + (rng.number(10) + 2) * 5_000
                contributions[count - 1] = high
                contributions[count - 2] = high
            }
            contributions = shuffled(contributions, using: &rng)
            return .mainPot(.init(contributions: contributions, pots: PotCalculator.calculate(contributions).pots))
        case .sidePot:
            let base = (rng.number(6) + 2) * 5_000
            let middle = base + (rng.number(6) + 2) * 5_000
            let top = middle + (rng.number(6) + 2) * 5_000
            // Matched top contributions avoid an uncalled excess in generated questions.
            var contributions = difficulty == .advanced ? [base, middle, top, top] : [base, middle, middle]
            contributions = shuffled(contributions, using: &rng)
            return .sidePot(.init(contributions: contributions, pots: PotCalculator.calculate(contributions).pots))
        }
    }
}

enum DailyChallenge {
    static func key(for date: Date = .now, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }
    static func seed(dateKey: String, index: Int) -> UInt64 {
        var hash: UInt64 = 14_695_981_039_346_656_037
        for byte in "DEALER-RUSH|\(dateKey)|\(index)".utf8 {
            hash = (hash ^ UInt64(byte)) &* 1_099_511_628_211
        }
        return hash
    }
    static func mode(at index: Int) -> TrainingMode { TrainingMode.allCases[index % 3] }
    static func difficulty(at index: Int) -> Difficulty { index < 3 ? .beginner : (index < 7 ? .intermediate : .advanced) }
    static func question(dateKey: String, index: Int) -> TrainingQuestion {
        QuestionFactory.make(mode: mode(at: index), difficulty: difficulty(at: index), seed: seed(dateKey: dateKey, index: index))
    }
    static func streak(records: [AnswerRecord], on date: Date = .now, calendar: Calendar = .current) -> Int {
        let completed = Set(Dictionary(grouping: records.compactMap { record -> (String, AnswerRecord)? in
            guard let key = record.dailyKey else { return nil }
            return (key, record)
        }, by: { $0.0 }).filter { $0.value.count >= 10 }.map { $0.key })
        var day = calendar.startOfDay(for: date)
        if !completed.contains(key(for: day, calendar: calendar)) {
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { return 0 }
            day = previous
        }
        var count = 0
        while completed.contains(key(for: day, calendar: calendar)) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return count
    }
}
