import XCTest
@testable import ExpenseCore

final class BudgetTests: XCTestCase {
    func testTheBudgetSaysWhatIsLeftOrOver() {
        XCTAssertEqual(Budget.left(budget: 2000, spent: 1234), 766)
        XCTAssertEqual(Budget.left(budget: 2000, spent: 2120), -120)
        XCTAssertNil(Budget.left(budget: 0, spent: 50))
        XCTAssertEqual(Budget.parse(" 1 500 "), 1500)
        XCTAssertEqual(Budget.parse("1500,50"), 1500.5)
        XCTAssertEqual(Budget.parse("abc"), 0)
    }
}
