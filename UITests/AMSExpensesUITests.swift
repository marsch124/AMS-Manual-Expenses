import XCTest

/// UI tests — every control is found by its accessibilityIdentifier, never by its words
/// (Martin's standing rule, 16 Sep 2026). Two to start with; each release that touches a
/// flow adds the test for that flow, seen to fail once before it is trusted.
final class AMSExpensesUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        // -uiTesting: an empty store in memory and no location question. The rest fix what
        // the screens depend on: English, an English number format, SEK as the currency.
        app.launchArguments += ["-uiTesting",
                                "-manualCurrency", "SEK",
                                "-dictationLanguage", "en-US",
                                "-AppleLanguages", "(en)",
                                "-AppleLocale", "en_US"]
        app.launch()
        return app
    }

    /// Settings shows the version and the build, and What's new starts with exactly this version —
    /// a release that forgets its What's new entry goes red here.
    func testTheVersionHasItsWhatsNew() {
        let app = launch()
        app.buttons["home-settings"].tap()

        let version = app.staticTexts["settings-version"]
        XCTAssertTrue(version.waitForExistence(timeout: 10), "Settings shows no version")
        let text = version.label
        XCTAssertNotNil(text.range(of: #"^\d+\.\d+(\.\d+)? \(\d+\)$"#, options: .regularExpression),
                        "the version reads '\(text)', not 'version (build)'")
        let marketing = String(text.split(separator: " ")[0])

        app.buttons["settings-whatsnew"].tap()
        let top = app.staticTexts["whatsnew-0-version"]
        XCTAssertTrue(top.waitForExistence(timeout: 10), "What's new is empty")
        XCTAssertEqual(top.label, marketing, "What's new starts at \(top.label) but the app is \(marketing)")
    }

    /// A typed sentence opens for checking, read the right way, and Save puts it in today's list.
    func testATypedExpenseIsCheckedAndSaved() {
        let app = launch()
        XCTAssertTrue(app.staticTexts["today-empty"].waitForExistence(timeout: 10), "today's list is not empty at the start")

        let field = app.textFields["home-type-field"]
        field.tap()
        field.typeText("Taxi 12 euros 50")
        app.buttons["home-type-go"].tap()

        let title = app.textFields["entry-title"]
        XCTAssertTrue(title.waitForExistence(timeout: 10), "the check sheet did not open")
        XCTAssertEqual(title.value as? String, "Taxi")
        XCTAssertEqual(app.textFields["entry-amount"].value as? String, "12.50")
        app.buttons["entry-save"].tap()

        XCTAssertTrue(app.buttons["expense-row-0"].waitForExistence(timeout: 10), "the expense is not in today's list")
        XCTAssertFalse(app.staticTexts["today-empty"].exists, "the list still says it is empty")
        // Wait for the total to be drawn — never snatch a number.
        let total = app.staticTexts["today-total"]
        expectation(for: NSPredicate(format: "label CONTAINS '12.50'"), evaluatedWith: total)
        waitForExpectations(timeout: 10)
    }
}
