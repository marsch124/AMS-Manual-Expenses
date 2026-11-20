import XCTest
@testable import ExpenseCore

final class HighestTests: XCTestCase {
    let calendar = Calendar(identifier: .gregorian)
    let date = Date(timeIntervalSince1970: 1_790_000_000)
    let rates = RateTable(kronorPer: ["2026-09-01": ["EUR": 11]])

    func spend(_ amount: Double, _ currency: String = "SEK") -> Spend {
        Spend(title: "x", amount: amount, currency: currency, date: date)
    }

    // 1.23: the five highest in kronor (€10 = 110 kr beats 100 kr), ties to the earlier row;
    // five or fewer expenses → nothing is picked.
    func testTheFiveHighestOfAWeek() {
        let week = [spend(60), spend(10, "EUR"), spend(100), spend(5), spend(60), spend(60), spend(60), spend(1)]
        XCTAssertEqual(Statistics.highest(week, rates: rates, calendar: calendar), [0, 1, 2, 4, 5])
        XCTAssertEqual(Statistics.highest(Array(week.prefix(5)), rates: rates, calendar: calendar), [])
    }
}
