import Foundation

enum PotCalculator {
    static func calculate(_ contributions: [Int]) -> PotResult {
        precondition(contributions.count >= 2 && contributions.allSatisfy { $0 >= 0 })
        let levels = Array(Set(contributions.filter { $0 > 0 })).sorted()
        var prior = 0
        var pots: [Pot] = []
        var refund = 0
        for level in levels {
            let eligible = contributions.indices.filter { contributions[$0] >= level }
            let amount = (level - prior) * eligible.count
            if eligible.count >= 2 { pots.append(Pot(amount: amount, eligible: eligible)) }
            else { refund += amount }
            prior = level
        }
        return PotResult(pots: pots, refund: refund)
    }
}
