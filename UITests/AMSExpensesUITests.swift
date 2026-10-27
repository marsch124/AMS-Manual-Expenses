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

    /// 1.9: Save shows "Saved"; the Today card counts; an amount in euros has its kronor under it;
    /// "Same again" (swipe right) opens the same expense for checking, now.
    func testTheTodayCardAndSameAgain() {
        let app = launch()
        let field = app.textFields["home-type-field"]
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap()
        field.typeText("Taxi 12 euros 50")
        app.buttons["home-type-go"].tap()
        XCTAssertTrue(app.buttons["entry-save"].waitForExistence(timeout: 10))
        app.buttons["entry-save"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["home-saved"].firstMatch.waitForExistence(timeout: 5),
                      "no Saved check mark")

        let count = app.staticTexts["today-count"]
        XCTAssertTrue(count.waitForExistence(timeout: 10), "no Today card")
        XCTAssertEqual(count.label, "1 expense")
        let row = app.buttons["expense-row-0"]
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        // The UI tests' euro is 10 kronor: 12.50 euros show "≈ SEK 125" under them.
        expectation(for: NSPredicate(format: "label CONTAINS '≈' AND label CONTAINS '125'"), evaluatedWith: row)
        waitForExpectations(timeout: 10)

        // Same again from the expense's check sheet (the swipe to the right does the same; GitHub's
        // simulator does not show swipe buttons reliably, so the test uses the sheet).
        row.tap()
        let again = app.buttons["entry-same-again"]
        reveal(app, again)
        again.tap()
        let title = app.textFields["entry-title"]
        XCTAssertTrue(title.waitForExistence(timeout: 10), "Same again did not open the check sheet")
        XCTAssertEqual(title.value as? String, "Taxi")
        XCTAssertEqual(app.textFields["entry-amount"].value as? String, "12.50")
        app.buttons["entry-save"].tap()
        expectation(for: NSPredicate(format: "label == '2 expenses'"), evaluatedWith: count)
        waitForExpectations(timeout: 10)
    }

    /// 1.10 (his pick B): the Today card shows this week as bars, today's in it, and the week's total.
    func testTheTodayCardShowsTheWeek() {
        let app = launch()
        add(app, "Taxi 12 euros 50")
        let bars = app.descendants(matching: .any)["today-week-bars"].firstMatch
        XCTAssertTrue(bars.waitForExistence(timeout: 10), "no week bars on the Today card")
        // Seven days, and today's 125 kronor (the UI tests' euro is 10 kronor) among them.
        let value = bars.value as? String ?? ""
        XCTAssertEqual(value.components(separatedBy: ", ").count, 7, "the bars read '\(value)'")
        XCTAssertTrue(value.contains("125"), "today is not in the bars: '\(value)'")
        let week = app.staticTexts["today-week-total"]
        XCTAssertTrue(week.waitForExistence(timeout: 10), "no This week line")
        XCTAssertTrue(week.label.contains("125"), "This week reads '\(week.label)'")
    }

    /// 1.9: Settings › Categories: tap a category's icon and pick another; it is kept.
    func testACategoryIconCanBeChanged() {
        let app = launch()
        app.buttons["home-settings"].tap()
        app.buttons["settings-categories"].tap()
        let icon = app.buttons["categories-icon-0"]
        XCTAssertTrue(icon.waitForExistence(timeout: 10), "the categories have no icons")
        XCTAssertEqual(icon.value as? String, "cup.and.saucer.fill", "Café does not start with the cup")
        icon.tap()
        let gift = app.buttons["icon-choice-12"]
        XCTAssertTrue(gift.waitForExistence(timeout: 10), "the icons to choose from did not open")
        gift.tap()
        expectation(for: NSPredicate(format: "value == 'gift.fill'"), evaluatedWith: icon)
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
        // 1.9: and the span is drawn as a ring above the list.
        XCTAssertTrue(app.descendants(matching: .any)["stats-category-ring"].firstMatch.exists, "no ring chart")
    }

    /// 1.6 (his ask): a new expense is for Martin; choosing AMS is kept when it is saved.
    func testTheConsumerStartsAsMartinAndIsKept() {
        let app = launch()
        let field = app.textFields["home-type-field"]
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap()
        field.typeText("Paper 89 kronor")
        app.buttons["home-type-go"].tap()

        let value = app.staticTexts["entry-consumer-value"]
        XCTAssertTrue(value.waitForExistence(timeout: 10), "the check sheet has no consumer")
        XCTAssertEqual(value.label, "Martin")
        app.buttons["entry-consumer"].tap()
        let ams = app.buttons["consumer-choice-1"]
        XCTAssertTrue(ams.waitForExistence(timeout: 10))
        ams.tap()
        XCTAssertTrue(value.waitForExistence(timeout: 10))
        XCTAssertEqual(value.label, "AMS")
        app.buttons["entry-save"].tap()

        // Open it again: the choice was saved, not just shown.
        let row = app.buttons["expense-row-0"]
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        row.tap()
        XCTAssertTrue(app.staticTexts["entry-consumer-value"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["entry-consumer-value"].label, "AMS")
    }

    /// 1.9: the row says who it was for (his colours), and Anna is a choice.
    func testTheRowShowsWhoItWasFor() {
        let app = launch()
        let field = app.textFields["home-type-field"]
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap()
        field.typeText("Flowers 120 kronor")
        app.buttons["home-type-go"].tap()
        let consumer = app.buttons["entry-consumer"]
        XCTAssertTrue(consumer.waitForExistence(timeout: 10))
        consumer.tap()
        let anna = app.buttons["consumer-choice-2"]
        XCTAssertTrue(anna.waitForExistence(timeout: 10), "no third choice under For whom")
        anna.tap()
        XCTAssertTrue(app.staticTexts["entry-consumer-value"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["entry-consumer-value"].label, "Anna")
        app.buttons["entry-save"].tap()

        let row = app.buttons["expense-row-0"]
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        XCTAssertTrue(row.label.contains("for Anna"), "the row reads '\(row.label)'")
    }

    /// 1.7 (his ask): a new place typed on the check sheet is kept, and the next expense at the
    /// same GPS fix starts there (the fix is set with -uiTestingFix: no location in UI tests).
    func testAPlaceIsKeptAndOfferedAtTheSameSpot() {
        let app = XCUIApplication()
        app.launchArguments += ["-uiTesting", "-uiTestingFix", "59.3430,18.0490",
                                "-manualCurrency", "SEK", "-dictationLanguage", "en-US",
                                "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()

        let field = app.textFields["home-type-field"]
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap()
        field.typeText("Milk 25 kronor")
        app.buttons["home-type-go"].tap()

        let value = app.staticTexts["entry-place-value"]
        XCTAssertTrue(value.waitForExistence(timeout: 10), "the check sheet has no place")
        XCTAssertEqual(value.label, "No place", "a first expense has no place yet")
        app.buttons["entry-place"].tap()
        let name = app.textFields["place-new-name"]
        XCTAssertTrue(name.waitForExistence(timeout: 10), "the place list has no line for a new place")
        name.tap()
        name.typeText("ICA Odenplan")
        app.buttons["place-new-add"].tap()
        XCTAssertTrue(value.waitForExistence(timeout: 10))
        XCTAssertEqual(value.label, "ICA Odenplan")
        app.buttons["entry-save"].tap()

        // The second expense, on the same spot: the place is already there.
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap()
        field.typeText("Bread 30 kronor")
        app.buttons["home-type-go"].tap()
        XCTAssertTrue(app.staticTexts["entry-place-value"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["entry-place-value"].label, "ICA Odenplan",
                       "the place used at this GPS fix was not offered")
        // 1.8: and the sheet says it was filled in by itself, from the same spot.
        let auto = app.staticTexts["entry-place-auto"]
        XCTAssertTrue(auto.waitForExistence(timeout: 10), "no 'auto' note beside the place")
        XCTAssertEqual(auto.label, "auto · 0 m away")

        // And it is listed under Nearby, first.
        app.buttons["entry-place"].tap()
        let first = app.buttons["place-choice-0"]
        XCTAssertTrue(first.waitForExistence(timeout: 10), "the place list has no places")
        XCTAssertTrue(first.label.contains("ICA Odenplan"), "the first place reads '\(first.label)'")
    }

    /// 1.7 (his ask): Settings › Places renames a place, and the expense moves with it.
    func testRenamingAPlaceMovesItsExpenses() {
        let app = launch()
        let field = app.textFields["home-type-field"]
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap()
        field.typeText("Milk 25 kronor")
        app.buttons["home-type-go"].tap()
        let place = app.buttons["entry-place"]
        XCTAssertTrue(place.waitForExistence(timeout: 10), "the check sheet has no place")
        place.tap()
        let name = app.textFields["place-new-name"]
        XCTAssertTrue(name.waitForExistence(timeout: 10))
        name.tap()
        name.typeText("Ica")
        app.buttons["place-new-add"].tap()
        XCTAssertTrue(app.buttons["entry-save"].waitForExistence(timeout: 10))
        app.buttons["entry-save"].tap()

        XCTAssertTrue(app.buttons["home-settings"].waitForExistence(timeout: 10))
        app.buttons["home-settings"].tap()
        app.buttons["settings-places"].tap()
        let row = app.buttons["places-row-0"]
        XCTAssertTrue(row.waitForExistence(timeout: 10), "Settings › Places is empty")
        XCTAssertTrue(row.label.contains("Ica"), "the place reads '\(row.label)'")
        row.tap()
        let rename = app.textFields["places-rename-name"]
        XCTAssertTrue(rename.waitForExistence(timeout: 10), "no field to rename the place")
        rename.tap()
        // The cursor goes to the end of the short name: deletes clear it, extra ones do nothing.
        rename.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 6) + "Ica Odenplan")
        app.buttons["places-rename-save"].tap()
        let renamed = app.buttons["places-row-0"]
        XCTAssertTrue(renamed.waitForExistence(timeout: 10))
        expectation(for: NSPredicate(format: "label CONTAINS 'Ica Odenplan'"), evaluatedWith: renamed)
        waitForExpectations(timeout: 10)

        // The expense itself moved: its check sheet shows the new name.
        app.navigationBars.buttons.firstMatch.tap()
        app.buttons["settings-done"].tap()
        let expense = app.buttons["expense-row-0"]
        XCTAssertTrue(expense.waitForExistence(timeout: 10))
        expense.tap()
        let value = app.staticTexts["entry-place-value"]
        XCTAssertTrue(value.waitForExistence(timeout: 10))
        XCTAssertEqual(value.label, "Ica Odenplan")
    }

    private func launch(fix: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-uiTesting", "-uiTestingFix", fix,
                                "-manualCurrency", "SEK", "-dictationLanguage", "en-US",
                                "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        return app
    }

    /// The check sheet's lower rows sit below a half-high sheet and are only made when scrolled
    /// to: swipe up until the element is there and can be tapped.
    private func reveal(_ app: XCUIApplication, _ element: XCUIElement) {
        XCTAssertTrue(app.buttons["entry-save"].waitForExistence(timeout: 10), "the check sheet did not open")
        for _ in 0..<4 where !(element.exists && element.isHittable) {
            app.swipeUp()
            _ = element.waitForExistence(timeout: 2)
        }
        XCTAssertTrue(element.exists, "\(element) is not on the check sheet")
    }

    /// 1.8 (concepts A and C): a saved expense keeps its GPS fix and its accuracy; the small map
    /// on the check sheet opens the big one with the position in numbers.
    func testTheCheckSheetShowsWhereItWasLogged() {
        let app = launch(fix: "59.3430,18.0490,8")
        add(app, "Milk 25 kronor")

        let row = app.buttons["expense-row-0"]
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        row.tap()
        // Found by its identifier whatever kind of element the map row turns into.
        let map = app.descendants(matching: .any)["entry-map"].firstMatch
        reveal(app, map)
        map.tap()

        let position = app.staticTexts["map-position"]
        XCTAssertTrue(position.waitForExistence(timeout: 10), "the big map shows no position")
        XCTAssertEqual(position.label, "59.343000, 18.049000")
        let accuracy = app.staticTexts["map-accuracy"]
        XCTAssertTrue(accuracy.waitForExistence(timeout: 10), "the accuracy was not kept with the expense")
        XCTAssertEqual(accuracy.label, "±8 m")
        XCTAssertTrue(app.buttons["map-open"].exists, "no Open in Maps")
    }

    /// 1.8 (concept B): Today on the map counts the expenses with a position and lists them.
    func testTodayIsShownOnTheMap() {
        let app = launch(fix: "59.3430,18.0490,8")
        add(app, "Coffee 45 kronor")

        app.buttons["home-map"].tap()
        let count = app.staticTexts["todaymap-count"]
        XCTAssertTrue(count.waitForExistence(timeout: 10), "Today on the map did not open")
        XCTAssertEqual(count.label, "1 of 1 have a position")
        let first = app.buttons["todaymap-row-0"]
        XCTAssertTrue(first.waitForExistence(timeout: 10), "the expense is not listed under the map")
        XCTAssertTrue(first.label.contains("Coffee"), "the row reads '\(first.label)'")
    }

    /// 1.5: the Shortcuts action's request reaches the main screen and starts dictation once
    /// (in UI tests the microphone is not used: the request is counted on `home-dictate`).
    func testTheShortcutsActionStartsDictation() {
        let app = XCUIApplication()
        app.launchArguments += ["-uiTesting", "-uiTestingDictateRequest", "-manualCurrency", "SEK",
                                "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        let mic = app.buttons["home-dictate"]
        XCTAssertTrue(mic.waitForExistence(timeout: 10))
        expectation(for: NSPredicate(format: "value == 'requests 1'"), evaluatedWith: mic)
        waitForExpectations(timeout: 10)
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
