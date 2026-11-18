import Foundation

/// 1.19: everything the monthly PDF report shows, worked out without any screen.
public struct MonthReport: Equatable, Sendable {
    public var interval: DateInterval
    public var count: Int
    public var total: KronorTotal
    /// The dearest category first.
    public var categories: [CategoryTotal]
    /// Only days with expenses, oldest first.
    public var days: [DayTotal]
    /// Oldest first.
    public var items: [Spend]

    public static func make(_ items: [Spend], period: Statistics.Period, now: Date, rates: RateTable,
                            calendar: Calendar) -> MonthReport {
        let interval = Statistics.range(period, now: now, calendar: calendar).interval
        let inside = Statistics.inside(items, period, now: now, calendar: calendar)
            .sorted { $0.date < $1.date }
        let days = Statistics.days(inside, rates: rates, calendar: calendar).sorted { $0.day < $1.day }
        return MonthReport(
            interval: interval,
            count: inside.count,
            total: Statistics.total(inside, rates: rates, calendar: calendar),
            categories: Statistics.byCategory(inside, rates: rates, calendar: calendar),
            days: days,
            items: inside)
    }
}
