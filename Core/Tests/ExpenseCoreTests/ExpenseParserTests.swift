import XCTest
@testable import ExpenseCore

final class ExpenseParserTests: XCTestCase {
    var calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Europe/Stockholm")!
        return c
    }()
    lazy var now = calendar.date(from: DateComponents(year: 2026, month: 10, day: 22, hour: 15, minute: 45))!

    func parse(_ s: String, _ currency: String = "SEK") -> ParsedExpense {
        ExpenseParser.parse(s, defaultCurrency: currency, now: now, calendar: calendar)
    }

    func testSentences() {
        let cases: [(String, String, Double, String)] = [
            ("Coffee 45 kronor", "Coffee", 45, "SEK"),
            ("Lunch 12,50 euro", "Lunch", 12.5, "EUR"),
            ("Taxi 12 euros 50", "Taxi", 12.5, "EUR"),
            ("Taxi 12 euro and 50 cents", "Taxi", 12.5, "EUR"),
            ("I paid 129 kr for lunch at Max", "Lunch at Max", 129, "SEK"),
            ("€8.90 sandwich", "Sandwich", 8.9, "EUR"),
            ("Groceries 1,234 Swedish crowns", "Groceries", 1234, "SEK"),
            ("Parking 40", "Parking", 40, "SEK"),
            ("Kaffe och bulle 65 kronor", "Kaffe och bulle", 65, "SEK"),
            ("Zugticket 23,40 Euro", "Zugticket", 23.4, "EUR"),
            ("Lunch for 2 people 340 kronor", "Lunch for 2 people", 340, "SEK"),
            ("Dinner 85 euros at 7 pm", "Dinner", 85, "EUR"),
            ("Bensin 650 kr klockan 9.15", "Bensin", 650, "SEK"),
            ("Coffee 45 kronor 2 cups", "Coffee 2 cups", 45, "SEK"),
            ("Hotel 1,234.50 euro", "Hotel", 1234.5, "EUR"),
        ]
        for (input, title, amount, currency) in cases {
            let r = parse(input)
            XCTAssertEqual(r.title, title, input)
            XCTAssertEqual(r.amount, amount, input)
            XCTAssertEqual(r.currency, currency, input)
        }
    }

    func testTimeIsNowWhenNotSpoken() {
        let r = parse("Coffee 45 kr")
        XCTAssertEqual(r.date, now)
        XCTAssertFalse(r.timeGiven)
    }

    func testSpokenTimes() {
        XCTAssertEqual(calendar.component(.hour, from: parse("Dinner 85 euros at 7 pm").date), 19)
        let r = parse("Bensin 650 kr klockan 9.15")
        XCTAssertEqual(calendar.dateComponents([.hour, .minute], from: r.date), DateComponents(hour: 9, minute: 15))
        XCTAssertEqual(calendar.component(.hour, from: parse("Essen 20 Euro um 13 Uhr").date), 13)
    }

    func testYesterday() {
        let r = parse("Yesterday taxi 300 kronor")
        XCTAssertEqual(calendar.component(.day, from: r.date), 21)
        XCTAssertEqual(r.title, "Taxi")
    }

    /// "for 3 hours ago" was not understood in 1.0 (Martin, 22 Oct 2026).
    func testTimeAgo() {
        func minutesBack(_ s: String) -> Int { Int(now.timeIntervalSince(parse(s).date) / 60) }
        XCTAssertEqual(minutesBack("Coffee 45 kronor for 3 hours ago"), 180)
        XCTAssertEqual(minutesBack("Taxi 12 euros 50 2 hours ago"), 120)
        XCTAssertEqual(minutesBack("Lunch 129 kr half an hour ago"), 30)
        XCTAssertEqual(minutesBack("Parking 40 an hour ago"), 60)
        XCTAssertEqual(minutesBack("Bun 35 kr 20 minutes ago"), 20)
        XCTAssertEqual(minutesBack("Hotel 120 euros 2 days ago"), 2 * 24 * 60)
        XCTAssertEqual(minutesBack("Kaffe 45 kronor för 3 timmar sedan"), 180)
        XCTAssertEqual(minutesBack("Kaffe 45 kronor för en halvtimme sen"), 30)
        XCTAssertEqual(minutesBack("Glass 30 kr för två timmar sedan"), 120)
        XCTAssertEqual(minutesBack("Kaffee 4 Euro vor 3 Stunden"), 180)
        XCTAssertEqual(minutesBack("Kaffee 4 Euro vor einer halben Stunde"), 30)

        // The time's own number is never taken as the amount or left in the description.
        let r = parse("Coffee 45 kronor for 3 hours ago")
        XCTAssertEqual(r.title, "Coffee")
        XCTAssertEqual(r.amount, 45)
        XCTAssertTrue(r.timeGiven)
        let first = parse("3 hours ago parking 40")
        XCTAssertEqual(first.title, "Parking")
        XCTAssertEqual(first.amount, 40)

        // "for 3 hours" without "ago" is how long, not when: the time stays now.
        let p = parse("Parking for 3 hours 40 kronor")
        XCTAssertFalse(p.timeGiven)
        XCTAssertEqual(p.amount, 40)
        XCTAssertEqual(p.title, "Parking for 3 hours")
    }

    func testNoAmountUsesDefaultCurrency() {
        let r = parse("Coffee", "EUR")
        XCTAssertNil(r.amount)
        XCTAssertEqual(r.currency, "EUR")
        XCTAssertFalse(r.currencySpoken)
    }

    func testTimeZoneCurrency() {
        XCTAssertEqual(CurrencyDefaults.currency(forTimeZone: "Europe/Stockholm"), "SEK")
        XCTAssertEqual(CurrencyDefaults.currency(forTimeZone: "Europe/Vienna"), "EUR")
        XCTAssertNil(CurrencyDefaults.currency(forTimeZone: "America/New_York"))
    }
}
