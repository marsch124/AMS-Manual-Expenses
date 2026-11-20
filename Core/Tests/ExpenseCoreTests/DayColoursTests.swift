import XCTest
@testable import ExpenseCore

final class DayColoursTests: XCTestCase {
    /// 1.26: Monday blue … Sunday brown, seven different colours, also with a Sunday-first calendar.
    func testEachWeekdayHasItsOwnColour() {
        XCTAssertEqual(Set(DayColours.names).count, 7)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Stockholm")!
        for firstWeekday in [1, 2] {
            calendar.firstWeekday = firstWeekday
            let monday = calendar.date(from: DateComponents(year: 2026, month: 11, day: 16, hour: 12))!
            let sunday = calendar.date(from: DateComponents(year: 2026, month: 11, day: 22, hour: 12))!
            XCTAssertEqual(DayColours.name(for: monday, calendar: calendar), "blue")
            XCTAssertEqual(DayColours.name(for: sunday, calendar: calendar), "brown")
            let week = (0..<7).map { DayColours.name(for: calendar.date(byAdding: .day, value: $0, to: monday)!, calendar: calendar) }
            XCTAssertEqual(week, DayColours.names)
        }
    }
}
