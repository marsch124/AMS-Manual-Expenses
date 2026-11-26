import XCTest
@testable import ExpenseCore

final class SearchTests: XCTestCase {
    func testEveryWordMustBeFoundSomewhere() {
        let fields = ["Lunch", "Food", "Café Nero", "Eva"]
        XCTAssertTrue(ExpenseSearch.matches(query: "cafe", fields: fields))
        XCTAssertTrue(ExpenseSearch.matches(query: "LUNCH eva", fields: fields))
        XCTAssertTrue(ExpenseSearch.matches(query: "  nero   food ", fields: fields))
        XCTAssertFalse(ExpenseSearch.matches(query: "lunch pizza", fields: fields))
        XCTAssertFalse(ExpenseSearch.matches(query: "", fields: fields))
        XCTAssertFalse(ExpenseSearch.matches(query: "   ", fields: fields))
    }
}
