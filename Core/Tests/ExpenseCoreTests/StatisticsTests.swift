import XCTest
@testable import ExpenseCore

final class StatisticsTests: XCTestCase {
    var calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Europe/Stockholm")!
        c.firstWeekday = 2   // Monday, as in Sweden
        return c
    }()

    func day(_ month: Int, _ day: Int, _ hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour))!
    }

    /// Thursday 22 October 2026, 15:45.
    lazy var now = calendar.date(from: DateComponents(year: 2026, month: 10, day: 22, hour: 15, minute: 45))!

    lazy var rates = RateTable(kronorPer: [
        "2026-09-30": ["EUR": 11.5],
        "2026-10-16": ["EUR": 11.0],   // a Friday
        "2026-10-19": ["EUR": 11.2],   // the Monday after
    ])

    lazy var spends = [
        Spend(title: "Coffee", amount: 45, currency: "SEK", date: day(10, 22)),
        Spend(title: "Taxi", amount: 10, currency: "EUR", date: day(10, 20)),
        Spend(title: "Lunch", amount: 120, currency: "SEK", date: day(10, 5)),
        Spend(title: "Hotel", amount: 100, currency: "EUR", date: day(9, 30)),
    ]

    func testTheRateIsTheDaysOrTheLastOneBefore() {
        XCTAssertEqual(rates.kronor(per: "EUR", on: day(10, 19), calendar: calendar), 11.2)
        XCTAssertEqual(rates.kronor(per: "EUR", on: day(10, 17), calendar: calendar), 11.0, "a Saturday takes Friday's")
        XCTAssertEqual(rates.kronor(per: "EUR", on: day(10, 22), calendar: calendar), 11.2, "today before the rate is out")
        XCTAssertEqual(rates.kronor(per: "EUR", on: day(9, 1), calendar: calendar), 11.5, "nothing earlier: the first one after")
        XCTAssertEqual(rates.kronor(per: "SEK", on: day(9, 1), calendar: calendar), 1)
        XCTAssertNil(rates.kronor(per: "USD", on: day(10, 19), calendar: calendar))
    }

    func testTheBanksAnswerIsTurnedIntoKronor() {
        var table = RateTable()
        table.merge(bankRates: ["2026-10-21": ["EUR": 0.08, "USD": 0.1]])
        XCTAssertEqual(table.kronor(per: "EUR", on: day(10, 21), calendar: calendar)!, 12.5, accuracy: 0.0001)
        XCTAssertEqual(table.kronor(per: "USD", on: day(10, 21), calendar: calendar)!, 10, accuracy: 0.0001)
    }

    func testWeekAndMonthTotalsInKronor() {
        let week = Statistics.total(spends, in: .thisWeek, now: now, rates: rates, calendar: calendar)
        XCTAssertEqual(week.total.kronor, 45 + 112, accuracy: 0.001)
        XCTAssertEqual(week.perDay, 157.0 / 4, accuracy: 0.001, "Monday to Thursday")

        let month = Statistics.total(spends, in: .thisMonth, now: now, rates: rates, calendar: calendar)
        XCTAssertEqual(month.total.kronor, 45 + 112 + 120, accuracy: 0.001)
        XCTAssertEqual(month.perDay, 277.0 / 22, accuracy: 0.001)

        let last = Statistics.total(spends, in: .lastMonth, now: now, rates: rates, calendar: calendar)
        XCTAssertEqual(last.total.kronor, 1150, accuracy: 0.001)
        XCTAssertEqual(last.perDay, 1150.0 / 30, accuracy: 0.001, "September has 30 days")
    }

    func testWhatHasNoRateIsKeptApart() {
        let t = Statistics.total([Spend(title: "Book", amount: 20, currency: "USD", date: day(10, 22)),
                                  Spend(title: "Bun", amount: 35, currency: "SEK", date: day(10, 22))],
                                 rates: rates, calendar: calendar)
        XCTAssertEqual(t.kronor, 35)
        XCTAssertEqual(t.unconverted, ["USD": 20])
        XCTAssertEqual(t.count, 2)
    }

    func testThirtyDaysEndingToday() {
        let daily = Statistics.daily(spends, days: 30, now: now, rates: rates, calendar: calendar)
        XCTAssertEqual(daily.count, 30)
        XCTAssertEqual(daily.last?.day, calendar.startOfDay(for: now))
        XCTAssertEqual(daily.first?.day, calendar.startOfDay(for: day(9, 23)))
        XCTAssertEqual(daily.last?.kronor, 45)
        XCTAssertEqual(daily[27].kronor, 112, accuracy: 0.001, "20 October")
        XCTAssertEqual(daily.filter { $0.kronor > 0 }.count, 4, "all four days, 30 September included, are inside")
    }

    func testWhatYouSpendMostOn() {
        let more = spends + [
            Spend(title: "coffee ", amount: 40, currency: "SEK", date: day(10, 21)),
            Spend(title: "Coffee", amount: 5, currency: "EUR", date: day(10, 19)),
        ]
        let top = Statistics.favourites(more, limit: 2, rates: rates, calendar: calendar)
        XCTAssertEqual(top.count, 2)
        XCTAssertEqual(top[0].title, "Coffee")
        XCTAssertEqual(top[0].count, 3)
        XCTAssertEqual(top[0].kronor, 45 + 40 + 56, accuracy: 0.001)
        XCTAssertEqual(top[1].title, "Hotel", "one each: the dearest first")
    }

    func testEarlierDaysNewestFirst() {
        let days = Statistics.days(spends, rates: rates, calendar: calendar)
        XCTAssertEqual(days.map(\.day), [day(10, 22), day(10, 20), day(10, 5), day(9, 30)].map(calendar.startOfDay(for:)))
        XCTAssertEqual(days[1].total.kronor, 112, accuracy: 0.001)
    }
}
