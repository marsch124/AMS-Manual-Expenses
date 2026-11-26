import XCTest
@testable import ExpenseCore

/// 1.33: the "who was it for" list is filled once from the stored expenses.
final class WhoNamesTests: XCTestCase {
    func testTheListIsSeededFromTheStoredExpenses() {
        // Oldest first; "Others" never takes one of the three; a fourth name is left out.
        XCTAssertEqual(WhoNames.seed(from: ["Sam", "Sam", "Others", "Work", "Eva", "Kim"]), ["Sam", "Work", "Eva"])
        // Fewer than three names: the places the data leaves empty get the neutral defaults.
        XCTAssertEqual(WhoNames.seed(from: ["Sam", "Others"]), ["Sam", "Work", "Partner"])
        XCTAssertEqual(WhoNames.seed(from: ["Work"]), ["Work", "Me", "Partner"])
        // No expenses at all (a new install): the defaults.
        XCTAssertEqual(WhoNames.seed(from: []), ["Me", "Work", "Partner"])
    }

    func testRenamingKeepsTheTotalsTogether() {
        XCTAssertTrue(WhoNames.isValid(["Sam", "Work", "Eva"]))
        XCTAssertFalse(WhoNames.isValid(["Sam", "sam", "Eva"]), "two the same")
        XCTAssertFalse(WhoNames.isValid(["Sam", "", "Eva"]), "an empty name")
        XCTAssertFalse(WhoNames.isValid(["Sam", "Others", "Eva"]), "Others is the last button")
        XCTAssertEqual(WhoNames.renames(old: ["Sam", "Work", "Eva"], new: ["Sam", "Firm", " Eva "]), ["Work": "Firm"])
        XCTAssertEqual(WhoNames.decode(WhoNames.encode(["Sam", "Work", "Eva"])), ["Sam", "Work", "Eva"])
        XCTAssertNil(WhoNames.decode(""))
    }
}
