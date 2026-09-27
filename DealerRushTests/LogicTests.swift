import XCTest
import SwiftData
@testable import DealerRush

final class LogicTests: XCTestCase {
    func testWheelAndKickerAndBoardPlay() {
        let wheel = HandEvaluator.best([.init(14, .spades), .init(2, .hearts), .init(3, .clubs), .init(4, .diamonds), .init(5, .spades), .init(11, .hearts), .init(12, .clubs)])
        let six = HandEvaluator.best([.init(2, .spades), .init(3, .hearts), .init(4, .clubs), .init(5, .diamonds), .init(6, .spades), .init(11, .hearts), .init(12, .clubs)])
        XCTAssertEqual(wheel.category, .straight)
        XCTAssertTrue(six > wheel)
        let board = [Card(14, .spades), Card(13, .spades), Card(12, .spades), Card(11, .spades), Card(10, .spades)]
        let a = HandEvaluator.best(board + [Card(2, .clubs), Card(3, .diamonds)])
        let b = HandEvaluator.best(board + [Card(9, .hearts), Card(8, .clubs)])
        XCTAssertEqual(a, b)
        let pairA = HandEvaluator.best([Card(14, .clubs), Card(14, .diamonds), Card(13, .hearts), Card(10, .clubs), Card(7, .spades), Card(2, .hearts), Card(3, .clubs)])
        let pairB = HandEvaluator.best([Card(14, .spades), Card(14, .hearts), Card(12, .hearts), Card(10, .diamonds), Card(7, .clubs), Card(2, .diamonds), Card(3, .spades)])
        XCTAssertTrue(pairA > pairB)
    }

    func testHandCategoriesAndTie() {
        let straightFlush = HandEvaluator.best([Card(9,.hearts),Card(10,.hearts),Card(11,.hearts),Card(12,.hearts),Card(13,.hearts),Card(14,.clubs),Card(2,.diamonds)])
        let quads = HandEvaluator.best([Card(8,.hearts),Card(8,.clubs),Card(8,.diamonds),Card(8,.spades),Card(14,.hearts),Card(3,.clubs),Card(2,.diamonds)])
        XCTAssertTrue(straightFlush > quads)
        XCTAssertEqual(quads.category, .fourOfAKind)
        let fullHouse = HandEvaluator.best([Card(12,.hearts),Card(12,.clubs),Card(12,.diamonds),Card(5,.spades),Card(5,.hearts),Card(2,.clubs),Card(3,.diamonds)])
        XCTAssertEqual(fullHouse.category, .fullHouse)
        let flushBoard = [Card(2,.clubs),Card(5,.clubs),Card(8,.clubs),Card(11,.clubs),Card(13,.clubs)]
        XCTAssertEqual(HandEvaluator.best(flushBoard + [Card(4,.hearts),Card(3,.diamonds)]),
                       HandEvaluator.best(flushBoard + [Card(6,.spades),Card(7,.diamonds)]))
    }

    func testLayeredPotsReturnUncalledChips() {
        let pots = PotCalculator.calculate([20_000, 50_000, 50_000, 120_000])
        XCTAssertEqual(pots.map(\.amount), [80_000, 90_000])
        XCTAssertEqual(pots.map(\.eligible), [[0,1,2,3], [1,2,3]])
        XCTAssertEqual(pots.refund, 70_000)
        XCTAssertEqual(PotCalculator.calculate([25_000,25_000,70_000,70_000]).first?.amount, 100_000)
        XCTAssertEqual(PotCalculator.calculate([10,20,30,30]).map(\.amount), [40,30,20])
        XCTAssertEqual(PotCalculator.calculate([0,0]).pots, [])
        for a in stride(from: 5, through: 100, by: 5) {
            let inputs = [a, a + 10, a + 20, a + 20]
            let result = PotCalculator.calculate(inputs)
            XCTAssertEqual(result.pots.map(\.amount).reduce(0,+) + result.refund, inputs.reduce(0,+))
        }
    }

    func testGeneratedQuestionsAreValidAndRepeatable() {
        for mode in TrainingMode.allCases {
            for index in 0..<100 {
                let a = QuestionFactory.make(mode: mode, difficulty: .advanced, seed: UInt64(index + 19))
                let b = QuestionFactory.make(mode: mode, difficulty: .advanced, seed: UInt64(index + 19))
                XCTAssertEqual(a, b)
                if case let .showdown(q) = a {
                    let cards = q.board + q.players.flatMap(\.hole)
                    XCTAssertEqual(Set(cards).count, cards.count)
                    XCTAssertFalse(q.winners.isEmpty)
                }
                if case let .sidePot(q) = a {
                    XCTAssertGreaterThanOrEqual(q.pots.count, 2)
                    XCTAssertTrue(q.pots.allSatisfy { $0.eligible.count >= 2 })
                }
                if case let .mainPot(q) = a {
                    XCTAssertEqual(q.pots.first?.amount, q.contributions.min()! * q.contributions.count)
                }
            }
        }
    }

    func testDailySeedStableAndChangesByDate() {
        XCTAssertEqual(DailyChallenge.seed(dateKey: "2026-09-28", index: 5), DailyChallenge.seed(dateKey: "2026-09-28", index: 5))
        XCTAssertNotEqual(DailyChallenge.seed(dateKey: "2026-09-28", index: 5), DailyChallenge.seed(dateKey: "2026-09-29", index: 5))
    }

    func testTierProgressAndModeMasteryUseActualRecords() {
        XCTAssertEqual(ScoreCalculator.tierProgress(1_000).name, "Trainee")
        XCTAssertEqual(ScoreCalculator.tierProgress(1_000).remaining, 200)
        XCTAssertEqual(ScoreCalculator.tierProgress(1_200).name, "Dealer")
        let empty = TrainingStats(records: [])
        XCTAssertEqual(empty.mastery(for: .showdown).percent, 0)
        XCTAssertEqual(empty.mastery(for: .showdown).level, 1)
        let answers = (0..<10).map { index in
            AnswerRecord(mode: .showdown, difficulty: .beginner, correct: index != 0,
                         responseSeconds: 2, points: index == 0 ? 0 : 100, combo: index,
                         dailyKey: nil, questionIndex: index)
        }
        XCTAssertEqual(TrainingStats(records: answers).mastery(for: .showdown).percent, 90)
        XCTAssertEqual(TrainingStats(records: answers).forMode(.sidePot).total, 0)
    }

    func testRatingAfterAnswerUsesSameSavedRecordFormula() {
        let first = AnswerRecord(mode: .showdown, difficulty: .beginner, correct: true,
                                 responseSeconds: 1.5, points: 120, combo: 1,
                                 dailyKey: "2026-09-28", questionIndex: 0)
        XCTAssertEqual(ScoreCalculator.rating([]), 1_000)
        XCTAssertEqual(ScoreCalculator.rating([first]), 1_010)
        XCTAssertEqual(ScoreCalculator.rating([first]) - ScoreCalculator.rating([]), 10)
        let history = TrainingStats(records: Array(repeating: first, count: 1)).ratingHistory
        XCTAssertEqual(history.last?.1, ScoreCalculator.rating([first]))
    }

    func testDailyStreakCountsOnlyCompletedConsecutiveDays() {
        let calendar = Calendar(identifier: .gregorian)
        let date = calendar.date(from: DateComponents(year: 2026, month: 9, day: 28))!
        let yesterday = (0..<10).map { index in
            AnswerRecord(mode: .showdown, difficulty: .beginner, correct: true,
                         responseSeconds: 2, points: 100, combo: index + 1,
                         dailyKey: "2026-09-27", questionIndex: index)
        }
        XCTAssertEqual(DailyChallenge.streak(records: yesterday, on: date, calendar: calendar), 1)
        XCTAssertEqual(DailyChallenge.streak(records: [], on: date, calendar: calendar), 0)
    }

    @MainActor func testDailyAnswerPersistsAndResumesWithUpdatedRating() throws {
        let container = try ModelContainer(for: AnswerRecord.self,
                                           configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext
        let key = "2026-09-28"
        let first = TrainingSession(dailyKey: key)
        first.start(context: context)
        guard case let .some(.showdown(question)) = first.question else { return XCTFail("Expected showdown") }
        first.selectedPlayer = question.winners.count > 1 ? -1 : question.winners[0]
        first.submit(context: context)
        XCTAssertTrue(first.outcome?.correct == true)
        XCTAssertEqual(first.outcome?.ratingBefore, 1_000)
        XCTAssertGreaterThan(first.outcome?.ratingAfter ?? 0, 1_000)
        let restored = TrainingSession(dailyKey: key)
        restored.start(context: context)
        XCTAssertEqual(restored.index, 1)
        XCTAssertEqual(restored.sessionScore, first.outcome?.sessionScore)
        XCTAssertEqual(try context.fetch(FetchDescriptor<AnswerRecord>()).count, 1)
    }
}
