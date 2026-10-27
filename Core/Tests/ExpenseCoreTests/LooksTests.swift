import XCTest
@testable import ExpenseCore

final class LooksTests: XCTestCase {
    func testEveryNewInstallCategoryHasItsOwnLook() {
        for name in Categories.defaults {
            XCTAssertNotEqual(CategoryLooks.look(for: name, custom: [:]), CategoryLooks.fallback, name)
        }
        XCTAssertEqual(CategoryLooks.look(for: "Café", custom: [:]).symbol, "cup.and.saucer.fill")
        XCTAssertEqual(CategoryLooks.look(for: " groceries ", custom: [:]).color, "green")
    }

    func testHisChoiceWinsAndUnknownsFallBack() {
        let custom = ["Café": "gift.fill", "Boat": "airplane"]
        XCTAssertEqual(CategoryLooks.look(for: "café", custom: custom), CategoryLook("gift.fill", "mint"))
        XCTAssertEqual(CategoryLooks.look(for: "Boat", custom: custom).color, "teal")
        XCTAssertEqual(CategoryLooks.look(for: "Dog", custom: custom), CategoryLooks.fallback)
        XCTAssertEqual(CategoryLooks.look(for: "", custom: custom), CategoryLooks.none)
        // A symbol that is not a choice (any more) is ignored.
        XCTAssertEqual(CategoryLooks.look(for: "Café", custom: ["Café": "nonsense"]).symbol, "cup.and.saucer.fill")
    }

    func testChoicesSurviveTheirText() {
        let custom = ["Café": "gift.fill", "Boat house": "house.fill"]
        XCTAssertEqual(CategoryLooks.decode(CategoryLooks.encode(custom)), custom)
        XCTAssertEqual(CategoryLooks.decode(""), [:])
    }
}
