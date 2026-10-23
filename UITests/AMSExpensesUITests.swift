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

    /// Runs first (tests run in name order). A cold simulator may fumble the first launch of a
    /// run — on GitHub on 22 Oct 2026 it timed out — so that fumble is absorbed here, not
    /// counted against a real test. The same as AMS Packing's.
    func testAAAWarmsUpTheSimulator() {
        XCTExpectFailure("a cold simulator may fumble its first launch", options: .nonStrict()) {
            let app = launch()
            _ = app.buttons["home-settings"].waitForExistence(timeout: 120)
            app.terminate()
        }
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
        XCTAssertFalse(app.staticTexts["home-status"].exists, "1.4: no hint under the microphone while idle")

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
        // Wait for the total to be drawn — never snatch a number. Since 1.2 it is in kronor:
        // the UI tests' euro is always 10 kronor, so 12.50 euros make 125.
        let total = app.staticTexts["today-total"]
        expectation(for: NSPredicate(format: "label CONTAINS '125'"), evaluatedWith: total)
        waitForExpectations(timeout: 10)
    }

    private func add(_ app: XCUIApplication, _ sentence: String) {
        let field = app.textFields["home-type-field"]
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap()
        field.typeText(sentence)
        app.buttons["home-type-go"].tap()
        let save = app.buttons["entry-save"]
        XCTAssertTrue(save.waitForExistence(timeout: 10), "the check sheet did not open for '\(sentence)'")
        save.tap()
        XCTAssertTrue(app.textFields["home-type-field"].waitForExistence(timeout: 10))
    }

    /// 1.3: a category chosen on the check sheet is what Statistics › By category counts.
    func testACategoryChosenAtEntryIsCountedByCategory() {
        let app = launch()
        let field = app.textFields["home-type-field"]
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap()
        field.typeText("Coffee 45 kronor")
        app.buttons["home-type-go"].tap()

        let category = app.buttons["entry-category"]
        XCTAssertTrue(category.waitForExistence(timeout: 10), "the check sheet has no category")
        category.tap()
        // Not the first one: since 1.4 that is Café, where a new expense already starts.
        let first = app.buttons["category-choice-1"]
        XCTAssertTrue(first.waitForExistence(timeout: 10), "the category list did not open")
        let chosen = first.label
        first.tap()
        let value = app.staticTexts["entry-category-value"]
        XCTAssertTrue(value.waitForExistence(timeout: 10))
        XCTAssertEqual(value.label, chosen, "the check sheet does not show the chosen category")
        app.buttons["entry-save"].tap()

        XCTAssertTrue(app.buttons["home-statistics"].waitForExistence(timeout: 10))
        app.buttons["home-statistics"].tap()
        let row = app.buttons["stats-category-0"]
        XCTAssertTrue(row.waitForExistence(timeout: 10), "By category is empty")
        XCTAssertTrue(row.label.contains(chosen), "the first category reads '\(row.label)', not \(chosen)")
        XCTAssertTrue(row.label.contains("45"), "the category's total reads '\(row.label)'")
    }

    /// 1.4 (his ask): a new expense whose description has no category yet starts in Café.
    func testANewExpenseStartsInTheDefaultCategory() {
        let app = launch()
        let field = app.textFields["home-type-field"]
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap()
        field.typeText("Taxi 300 kronor")
        app.buttons["home-type-go"].tap()
        let value = app.staticTexts["entry-category-value"]
        XCTAssertTrue(value.waitForExistence(timeout: 10), "the check sheet shows no category")
        XCTAssertEqual(value.label, "Café")

        // 1.4: the date and time are quiet labels; a tap opens the calendar, Cancel closes it.
        app.buttons["entry-time"].tap()
        XCTAssertTrue(app.datePickers["entry-time-picker"].waitForExistence(timeout: 10), "no calendar opened")
        app.buttons["entry-time-cancel"].tap()
        XCTAssertTrue(app.buttons["entry-save"].waitForExistence(timeout: 10))
    }

    /// 1.2: Statistics counts this week in kronor, euros at the day's rate (10 in UI tests).
    func testStatisticsCountTheWeekInKronor() {
        let app = launch()
        add(app, "Taxi 12 euros 50")
        add(app, "Coffee 45 kronor")

        app.buttons["home-statistics"].tap()
        let week = app.staticTexts["stats-week-total"]
        XCTAssertTrue(week.waitForExistence(timeout: 10), "Statistics shows no week total")
        expectation(for: NSPredicate(format: "label CONTAINS '170'"), evaluatedWith: week)
        waitForExpectations(timeout: 10)
    }
}
