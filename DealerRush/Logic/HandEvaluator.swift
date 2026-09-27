import Foundation

enum HandEvaluator {
    static func best(_ cards: [Card]) -> HandValue {
        precondition(cards.count >= 5 && cards.count <= 7 && Set(cards).count == cards.count)
        var bestValue: HandValue?
        for a in 0..<(cards.count-4) {
            for b in (a+1)..<(cards.count-3) {
                for c in (b+1)..<(cards.count-2) {
                    for d in (c+1)..<(cards.count-1) {
                        for e in (d+1)..<cards.count {
                            let value = evaluate([cards[a],cards[b],cards[c],cards[d],cards[e]])
                            if bestValue == nil || value > bestValue! { bestValue = value }
                        }
                    }
                }
            }
        }
        return bestValue!
    }
    private static func evaluate(_ cards: [Card]) -> HandValue {
        let ranks = cards.map(\.rank)
        let counts = Dictionary(grouping: ranks, by: { $0 }).mapValues(\.count)
        let groups = counts.map { ($0.key, $0.value) }.sorted { $0.1 == $1.1 ? $0.0 > $1.0 : $0.1 > $1.1 }
        let flush = Set(cards.map(\.suit)).count == 1
        let distinct = Set(ranks)
        let straightHigh: Int = {
            for high in stride(from: 14, through: 5, by: -1) {
                let needed = (high-4...high).map { $0 == 1 ? 14 : $0 }
                if needed.allSatisfy({ distinct.contains($0) }) { return high }
            }
            return 0
        }()
        if flush && straightHigh > 0 { return .init(category: .straightFlush, kickers: [straightHigh]) }
        if groups[0].1 == 4 { return .init(category: .fourOfAKind, kickers: [groups[0].0, groups[1].0]) }
        if groups[0].1 == 3 && groups[1].1 == 2 { return .init(category: .fullHouse, kickers: [groups[0].0, groups[1].0]) }
        if flush { return .init(category: .flush, kickers: ranks.sorted(by: >)) }
        if straightHigh > 0 { return .init(category: .straight, kickers: [straightHigh]) }
        if groups[0].1 == 3 { return .init(category: .threeOfAKind, kickers: [groups[0].0] + groups.dropFirst().map { $0.0 }.sorted(by: >)) }
        if groups[0].1 == 2 && groups[1].1 == 2 {
            let pairs = [groups[0].0, groups[1].0].sorted(by: >)
            return .init(category: .twoPair, kickers: pairs + [groups[2].0])
        }
        if groups[0].1 == 2 { return .init(category: .onePair, kickers: [groups[0].0] + groups.dropFirst().map { $0.0 }.sorted(by: >)) }
        return .init(category: .highCard, kickers: ranks.sorted(by: >))
    }
}
