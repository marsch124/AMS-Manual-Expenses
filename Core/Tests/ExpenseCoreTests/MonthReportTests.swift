import XCTest
@testable import ExpenseCore

final class MonthReportTests: XCTestCase {
    var calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Europe/Stockholm")!
        c.firstWeekday = 2
        return c
    }()

    func day(_ month: Int, _ day: Int, _ hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour))!
    }

    func testTheReportCoversOnlyItsMonth() {
        let now = day(11, 18)
        let items = [
            Spend(title: "Late", amount: 30, currency: "SEK", date: day(10, 31, 23), category: "Café"),
            Spend(title: "B", amount: 20, currency: "SEK", date: day(11, 10), category: "Café"),
            Spend(title: "A", amount: 50, currency: "SEK", date: day(11, 2), category: "Home"),
            Spend(title: "Next", amount: 70, currency: "SEK", date: day(12, 1, 0)),
        ]
        let r = MonthReport.make(items, period: .thisMonth, now: now, rates: RateTable(), calendar: calendar)
        XCTAssertEqual(r.count, 2)
        XCTAssertEqual(r.total.kronor, 70)
        XCTAssertEqual(r.items.map(\.title), ["A", "B"])
        XCTAssertEqual(r.days.map(\.day), [calendar.startOfDay(for: day(11, 2)), calendar.startOfDay(for: day(11, 10))])
        XCTAssertEqual(r.categories.map(\.name), ["Home", "Café"])
        let last = MonthReport.make(items, period: .lastMonth, now: now, rates: RateTable(), calendar: calendar)
        XCTAssertEqual(last.items.map(\.title), ["Late"])
    }
}
