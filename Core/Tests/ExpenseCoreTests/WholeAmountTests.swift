import XCTest
@testable import ExpenseCore

final class WholeAmountTests: XCTestCase {
    func testWeekListsShowWholeAmountsHalfUp() {
        XCTAssertEqual(WholeAmount.rounded(10.00), 10)
        XCTAssertEqual(WholeAmount.rounded(6.45), 6)
        XCTAssertEqual(WholeAmount.rounded(7.50), 8)
        XCTAssertEqual(WholeAmount.rounded(53.15), 53)
        XCTAssertEqual(WholeAmount.rounded(0.40), 0)
    }
}
