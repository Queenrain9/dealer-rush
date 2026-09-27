import Foundation
import SwiftData

enum Suit: Int, CaseIterable, Codable, Hashable { case spades, hearts, diamonds, clubs
    var symbol: String { ["♠", "♥", "♦", "♣"][rawValue] }
    var red: Bool { self == .hearts || self == .diamonds }
}
struct Card: Hashable, Codable, Identifiable {
    let rank: Int
    let suit: Suit
    init(_ rank: Int, _ suit: Suit) { self.rank = rank; self.suit = suit }
    var id: String { "\(rank)-\(suit.rawValue)" }
    var label: String { [11:"J",12:"Q",13:"K",14:"A"][rank] ?? String(rank) }
    static let deck: [Card] = Suit.allCases.flatMap { suit in (2...14).map { Card($0, suit) } }
}

enum TrainingMode: String, CaseIterable, Codable, Identifiable {
    case showdown, potCalculation, sidePot
    var id: String { rawValue }
    var title: String {
        switch self { case .showdown: return "Showdown"; case .potCalculation: return "Pot Calculation"; case .sidePot: return "Side Pot" }
    }
    var subtitle: String {
        switch self { case .showdown: return "승리 판정"; case .potCalculation: return "메인 팟 계산"; case .sidePot: return "사이드 팟" }
    }
    var icon: String {
        switch self { case .showdown: return "suit.spade.fill"; case .potCalculation: return "circle.grid.2x2.fill"; case .sidePot: return "square.stack.3d.up.fill" }
    }
}
enum Difficulty: Int, CaseIterable, Codable, Identifiable {
    case beginner = 1, intermediate, advanced
    var id: Int { rawValue }
    var title: String { switch self { case .beginner: return "Beginner"; case .intermediate: return "Intermediate"; case .advanced: return "Advanced" } }
}

enum HandCategory: Int, CaseIterable, Codable {
    case highCard, onePair, twoPair, threeOfAKind, straight, flush, fullHouse, fourOfAKind, straightFlush
    var title: String { ["High Card", "One Pair", "Two Pair", "Three of a Kind", "Straight", "Flush", "Full House", "Four of a Kind", "Straight Flush"][rawValue] }
}
struct HandValue: Equatable, Comparable {
    let category: HandCategory
    let kickers: [Int]
    var detail: String {
        func name(_ rank: Int) -> String { [11:"J",12:"Q",13:"K",14:"A"][rank] ?? String(rank) }
        switch category {
        case .onePair: return "\(name(kickers[0])) pair · \(name(kickers[1])) kicker"
        case .twoPair: return "\(name(kickers[0])) / \(name(kickers[1])) pairs"
        case .threeOfAKind: return "three \(name(kickers[0]))s"
        case .straight, .straightFlush: return "\(name(kickers[0])) high"
        case .flush, .highCard: return "\(name(kickers[0])) high"
        case .fullHouse: return "\(name(kickers[0]))s full of \(name(kickers[1]))s"
        case .fourOfAKind: return "four \(name(kickers[0]))s"
        }
    }
    static func < (lhs: Self, rhs: Self) -> Bool {
        if lhs.category != rhs.category { return lhs.category.rawValue < rhs.category.rawValue }
        return lhs.kickers.lexicographicallyPrecedes(rhs.kickers)
    }
}
struct ShowdownPlayer: Equatable { let hole: [Card] }
struct ShowdownQuestion: Equatable { let board: [Card]; let players: [ShowdownPlayer]; let winners: [Int]; let winningHand: HandValue }
struct Pot: Equatable { let amount: Int; let eligible: [Int] }
struct PotResult: Equatable {
    let pots: [Pot]
    let refund: Int
    var first: Pot? { pots.first }
    func map<T>(_ transform: (Pot) -> T) -> [T] { pots.map(transform) }
}
struct PotQuestion: Equatable { let contributions: [Int]; let pots: [Pot] }
enum TrainingQuestion: Equatable { case showdown(ShowdownQuestion), mainPot(PotQuestion), sidePot(PotQuestion) }

@Model final class AnswerRecord {
    var id: UUID
    var mode: String
    var difficulty: Int
    var answeredAt: Date
    var correct: Bool
    var responseSeconds: Double
    var points: Int
    var combo: Int
    var dailyKey: String?
    var questionIndex: Int
    // Optional fields allow records saved by the first project version to remain readable.
    var sessionID: UUID?
    var ratingBefore: Int?
    var ratingAfter: Int?
    init(mode: TrainingMode, difficulty: Difficulty, correct: Bool, responseSeconds: Double, points: Int, combo: Int, dailyKey: String?, questionIndex: Int) {
        self.id = UUID(); self.mode = mode.rawValue; self.difficulty = difficulty.rawValue
        self.answeredAt = .now; self.correct = correct; self.responseSeconds = responseSeconds
        self.points = points; self.combo = combo; self.dailyKey = dailyKey; self.questionIndex = questionIndex
        self.sessionID = nil; self.ratingBefore = nil; self.ratingAfter = nil
    }
}
