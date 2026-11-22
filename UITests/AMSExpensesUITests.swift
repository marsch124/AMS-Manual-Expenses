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

    /// 1.10 (his pick B): the Today card shows this week as bars, with today's in it; 1.11: and no week sum.
    func testTheTodayCardShowsTheWeek() {
        let app = launch()
        add(app, "Taxi 12 euros 50")
        let bars = app.descendants(matching: .any)["today-week-bars"].firstMatch
        XCTAssertTrue(bars.waitForExistence(timeout: 10), "no week bars on the Today card")
        // Seven days, and today's 125 kronor (the UI tests' euro is 10 kronor) among them.
        let value = bars.value as? String ?? ""
        XCTAssertEqual(value.components(separatedBy: ", ").count, 7, "the bars read '\(value)'")
        XCTAssertTrue(value.contains("125"), "today is not in the bars: '\(value)'")
        // 1.11 (his ask): no This week sum under the card.
        XCTAssertFalse(app.staticTexts["today-week-total"].exists, "the This week line is still there")
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
    /// (1.31: the four people are buttons on the check sheet itself.)
    func testTheConsumerStartsAsMartinAndIsKept() {
        let app = launch()
        let field = app.textFields["home-type-field"]
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap()
        field.typeText("Paper 89 kronor")
        app.buttons["home-type-go"].tap()

        let martin = app.buttons["consumer-choice-0"]
        reveal(app, martin)
        XCTAssertEqual(martin.value as? String, "Chosen", "a new expense is not for Martin")
        let ams = app.buttons["consumer-choice-1"]
        ams.tap()
        XCTAssertEqual(ams.value as? String, "Chosen")
        app.buttons["entry-save"].tap()

        // Open it again: the choice was saved, not just shown.
        let row = app.buttons["expense-row-0"]
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        row.tap()
        let saved = app.buttons["consumer-choice-1"]
        reveal(app, saved)
        XCTAssertEqual(saved.value as? String, "Chosen", "AMS was not kept")
    }

    /// 1.31 (his ask): who it was for is four buttons on one line of the check sheet — Martin,
    /// AMS, Anna, Others. One tap chooses; no list opens; only one is chosen at a time.
    func testWhoItWasForIsOneTapOnOneLine() {
        let app = launch()
        let field = app.textFields["home-type-field"]
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap()
        field.typeText("Stamps 30 kronor")
        app.buttons["home-type-go"].tap()

        let buttons = (0..<4).map { app.buttons["consumer-choice-\($0)"] }
        reveal(app, buttons[3])
        let width: CGFloat = app.windows.firstMatch.frame.width
        let line: CGFloat = buttons[0].frame.midY
        let half: CGFloat = buttons[0].frame.height / 2
        for (i, b) in buttons.enumerated() {
            XCTAssertTrue(b.exists && b.isHittable, "person button \(i) is not on the sheet")
            XCTAssertEqual(b.frame.midY, line, accuracy: half, "person button \(i) is not on the same line")
            XCTAssertLessThanOrEqual(b.frame.maxX, width, "person button \(i) runs off the screen")
        }

        buttons[2].tap()
        // Still on the check sheet: the tap chose, it did not open a list.
        XCTAssertTrue(app.buttons["entry-save"].exists, "a tap on Anna left the check sheet")
        XCTAssertEqual(buttons[2].value as? String, "Chosen", "Anna is not chosen after one tap")
        XCTAssertNotEqual(buttons[0].value as? String, "Chosen", "Martin is still chosen too")
        buttons[3].tap()
        XCTAssertEqual(buttons[3].value as? String, "Chosen", "Others is not chosen after one tap")
        XCTAssertNotEqual(buttons[2].value as? String, "Chosen", "Anna is still chosen too")
    }

    /// 1.9: the row says who it was for (his colours), and Anna is a choice.
    func testTheRowShowsWhoItWasFor() {
        let app = launch()
        let field = app.textFields["home-type-field"]
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap()
        field.typeText("Flowers 120 kronor")
        app.buttons["home-type-go"].tap()
        let anna = app.buttons["consumer-choice-2"]
        reveal(app, anna)
        anna.tap()
        XCTAssertEqual(anna.value as? String, "Chosen")
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
        // 1.15: with its distance; 1.16: Nearest first keeps it on top and flips the button.
        XCTAssertTrue(first.label.contains("0 m"), "no distance on the place: '\(first.label)'")
        // 1.17: the small map is at the bottom.
        app.swipeUp()
        XCTAssertTrue(app.descendants(matching: .any)["place-map"].firstMatch.waitForExistence(timeout: 5), "no map on the Place page")
        app.swipeDown()
        let sort = app.buttons["place-sort"]
        XCTAssertTrue(sort.waitForExistence(timeout: 10), "no Nearest first button")
        sort.tap()
        XCTAssertEqual(sort.label, "Usual order")
        XCTAssertTrue(app.buttons["place-choice-0"].label.contains("ICA Odenplan"))
        sort.tap()
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
        // 1.25 (his ask): the map switches to This week, Last week and Month.
        let span = app.segmentedControls["map-span"]
        XCTAssertTrue(span.exists, "no Today / This week / Last week / Month switch on the map")
        // 1.26 (his ask): This week colours the pins by day and says which colour is which day.
        span.buttons["This week"].tap()
        let today = Date().formatted(.dateTime.weekday(.abbreviated))
        let dayButton = app.buttons["todaymap-day-\(today)"]
        XCTAssertTrue(dayButton.waitForExistence(timeout: 10), "no \(today) button under the week map")
        // 1.27 (his yes): tap a day = only that day; tap again = the whole week.
        let hint = app.staticTexts["todaymap-day-hint"]
        XCTAssertTrue(hint.exists, "the screen does not say what the day buttons do")
        dayButton.tap()
        XCTAssertTrue(hint.label.hasPrefix("Only"), "after the tap the hint reads '\(hint.label)'")
        XCTAssertTrue(app.buttons["todaymap-row-0"].exists, "today's coffee is gone when only today shows")
        dayButton.tap()
        XCTAssertTrue(hint.label.hasPrefix("Tap"), "the whole week did not come back: '\(hint.label)'")
        span.buttons["Last week"].tap()
        XCTAssertTrue(app.staticTexts["todaymap-empty"].waitForExistence(timeout: 10), "today's coffee shows under Last week")
        span.buttons["Month"].tap()
        XCTAssertTrue(app.buttons["todaymap-row-0"].waitForExistence(timeout: 10), "today's coffee is missing from Month")
    }

    /// 1.30 (his yes): with two pins on the map, a line under it says how long the route is.
    func testTheRouteSaysHowLong() {
        let app = launch(fix: "59.3430,18.0490,8")
        add(app, "Coffee 45 kronor")
        add(app, "Bread 30 kronor")

        app.buttons["home-map"].tap()
        let length = app.staticTexts["todaymap-route-length"]
        XCTAssertTrue(length.waitForExistence(timeout: 10), "no route length under the map")
        XCTAssertTrue(length.label.hasPrefix("Route: "), "the length line reads '\(length.label)'")
    }

    /// 1.20 (his ask): This week folds open with all of this week's expenses, in whole euros.
    func testThisWeekFoldsOpenInWholeEuros() {
        let app = launch()
        add(app, "Coffee 7 euros 50")

        // 1.25 (his pick): a small card instead of the line.
        let toggle = app.buttons["day-tile-this-week"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 10), "there is no This week card")
        XCTAssertFalse(app.buttons["this-week-row-0"].exists, "this week is not folded at the start")
        toggle.tap()
        let row = app.buttons["this-week-row-0"]
        XCTAssertTrue(row.waitForExistence(timeout: 10), "a tap did not open this week")
        XCTAssertTrue(row.label.contains("Coffee"), "the row reads '\(row.label)'")
        // 1.25: the card carries the total; opened, a line says how many.
        XCTAssertTrue(toggle.label.hasPrefix("This week, ") && toggle.label.contains("75"), "the card reads '\(toggle.label)'")
        XCTAssertEqual(app.staticTexts["this-week-count"].label, "1 expense")
        XCTAssertFalse(app.descendants(matching: .any)["this-week-top-note"].exists, "a top-five line with one expense")
        XCTAssertTrue(row.label.contains("8") && !row.label.contains("7.5") && !row.label.contains("7,5"),
                      "not a whole euro: '\(row.label)'")
        // 1.21 (his yes): the row says which day, e.g. "Fri 11:49".
        let day = Date().formatted(.dateTime.weekday(.abbreviated))
        XCTAssertTrue(row.label.contains(day), "no weekday '\(day)' in '\(row.label)'")
        toggle.tap()
        expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: row)
        waitForExpectations(timeout: 10)
    }

    /// 1.23 (his ask): an opened week tints its five highest expenses; the sixth stays plain.
    func testTheWeeksFiveHighestAreTinted() {
        let app = launch()
        for line in ["Tea 5 kronor", "Lunch 120 kronor", "Taxi 90 kronor", "Book 80 kronor", "Cake 60 kronor", "Bus 40 kronor"] {
            add(app, line)
        }
        // 1.25 (his pick): a small card instead of the line.
        let toggle = app.buttons["day-tile-this-week"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 10), "there is no This week card")
        toggle.tap()
        let top = app.buttons["this-week-row-0"]       // Bus, newest
        XCTAssertTrue(top.waitForExistence(timeout: 10), "a tap did not open this week")
        XCTAssertEqual(top.value as? String, "Top five", "Bus 40 kr is one of the five highest")
        // 1.24 (his yes): the card says what the tint means.
        XCTAssertTrue(app.descendants(matching: .any)["this-week-top-note"].exists, "no '= the 5 highest' line")
        let tea = app.buttons["this-week-row-5"]       // Tea, oldest and smallest
        app.swipeUp()
        XCTAssertTrue(tea.waitForExistence(timeout: 10), "no sixth row")
        XCTAssertNotEqual(tea.value as? String, "Top five", "Tea 5 kr is not one of the five highest")
    }

    /// 1.12 (his ask): yesterday's expenses sit folded under Today; a tap opens them, another folds them.
    func testYesterdayFoldsOpenUnderToday() {
        let app = launch()
        add(app, "Taxi 300 kronor yesterday")

        // 1.25 (his pick): a small card with yesterday's total and count.
        let toggle = app.buttons["day-tile-yesterday"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 10), "there is no Yesterday card")
        XCTAssertTrue(toggle.label.contains("300"), "the Yesterday card reads '\(toggle.label)'")
        XCTAssertEqual(toggle.value as? String, "1 expense")
        XCTAssertFalse(app.buttons["yesterday-row-0"].exists, "yesterday is not folded at the start")
        // 1.18: the quiet This week line (yesterday's taxi counts unless today is the first day
        // of the week: Sunday in the tests' en_US, Monday on his phone).
        let firstDay = Calendar.current.component(.weekday, from: Date()) == Calendar.current.firstWeekday
        if !firstDay {
            XCTAssertEqual(app.buttons["day-tile-this-week"].value as? String, "1 expense", "no This week card")
        }
        XCTAssertTrue(app.staticTexts["today-empty"].exists, "yesterday's taxi was counted as today")

        toggle.tap()
        let row = app.buttons["yesterday-row-0"]
        XCTAssertTrue(row.waitForExistence(timeout: 10), "a tap did not open yesterday")
        XCTAssertTrue(row.label.contains("Taxi"), "the row reads '\(row.label)'")
        // 1.25: one card open at a time — Last week (empty) does nothing, a second tap closes.
        // On the first day of the week yesterday's taxi is in Last week (red on Sunday 22 Nov 2026).
        let lastWeek = app.buttons["day-tile-last-week"]
        if firstDay {
            XCTAssertEqual(lastWeek.value as? String, "1 expense", "yesterday's taxi is not in Last week")
        } else {
            XCTAssertFalse(lastWeek.isEnabled, "an empty Last week card can be tapped")
        }
        toggle.tap()
        expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: row)
        waitForExpectations(timeout: 10)
    }

    /// 1.13 (his ask): a photo on the check sheet is kept with the expense, shown small on its row
    /// and big when tapped. (UI tests cannot use the camera or the photo library: there
    /// "Choose photo" puts in a made-up picture.)
    func testAPhotoIsKeptWithTheExpense() {
        let app = launch()
        let field = app.textFields["home-type-field"]
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap()
        field.typeText("Lunch 120 kronor")
        app.buttons["home-type-go"].tap()

        let choose = app.buttons["entry-photo-choose"]
        reveal(app, choose)
        choose.tap()
        XCTAssertTrue(app.buttons["entry-photo"].waitForExistence(timeout: 10), "the check sheet shows no photo")
        app.buttons["entry-save"].tap()

        let row = app.buttons["expense-row-0"]
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        XCTAssertTrue(row.label.contains("Photo"), "the row shows no photo: '\(row.label)'")

        row.tap()
        let photo = app.buttons["entry-photo"]
        reveal(app, photo)
        photo.tap()
        XCTAssertTrue(app.images["photo-viewer-image"].waitForExistence(timeout: 10), "the big photo did not open")
        app.buttons["photo-viewer-done"].tap()
        XCTAssertTrue(app.buttons["entry-photo-remove"].waitForExistence(timeout: 10))
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

    /// 1.19: search finds an expense, the monthly report offers its PDF, and a delete can be undone.
    func testSearchReportAndUndo() {
        let app = launch()
        add(app, "Coffee 45 kronor")
        add(app, "Taxi 300 kronor")

        app.buttons["home-statistics"].tap()
        XCTAssertTrue(app.buttons["stats-search"].waitForExistence(timeout: 10), "no Search expenses in Statistics")
        app.buttons["stats-search"].tap()
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 10), "the Search page has no search field")
        search.tap()
        search.typeText("taxi")
        let found = app.buttons["search-row-0"]
        XCTAssertTrue(found.waitForExistence(timeout: 10), "the search found nothing")
        XCTAssertTrue(found.label.contains("Taxi"), "the search found '\(found.label)'")
        XCTAssertFalse(app.buttons["search-row-1"].exists, "the search found too much")
        // The search bar's own close button: "Close" on iOS 26+, "Cancel" before.
        for name in ["Close", "Cancel"] where app.buttons[name].exists { app.buttons[name].tap(); break }
        XCTAssertTrue(app.buttons["BackButton"].firstMatch.waitForExistence(timeout: 10), "no way back from Search")
        app.buttons["BackButton"].firstMatch.tap()

        XCTAssertTrue(app.buttons["stats-report"].waitForExistence(timeout: 10), "no Monthly report in Statistics")
        app.buttons["stats-report"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["report-share"].firstMatch.waitForExistence(timeout: 10),
                      "the report has no Share PDF button")
        app.buttons["BackButton"].firstMatch.tap()
        XCTAssertTrue(app.buttons["stats-search"].waitForExistence(timeout: 10))
        app.buttons["BackButton"].firstMatch.tap()   // Statistics is pushed from the main screen

        // Undo: swipe the first row away, then bring it back.
        let row = app.buttons["expense-row-0"]
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        row.swipeLeft()
        app.buttons["Delete"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["today-count"].label.contains("1 expense"), "the delete did not delete")
        let undo = app.buttons["undo-button"]
        XCTAssertTrue(undo.waitForExistence(timeout: 10), "no Undo after a delete")
        undo.tap()
        // The simulator can swallow the first touch after a swipe-delete; a second tap then takes.
        sleep(1)
        if undo.exists { undo.tap() }
        expectation(for: NSPredicate(format: "label == '2 expenses'"), evaluatedWith: app.staticTexts["today-count"])
        waitForExpectations(timeout: 10)
    }
}
