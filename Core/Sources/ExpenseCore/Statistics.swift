import Foundation

/// Every total is counted in kronor (Martin's choice, 22 Oct 2026): an amount in another
/// currency is converted with the European Central Bank's rate of its day.
public let homeCurrency = "SEK"

/// One expense as the statistics see it — no SwiftData in here, so it can be tested.
public struct Spend: Equatable, Sendable {
    public var title: String
    public var amount: Double
    public var currency: String
    public var date: Date

    public init(title: String, amount: Double, currency: String, date: Date) {
        self.title = title
        self.amount = amount
        self.currency = currency
        self.date = date
    }
}

/// Kronor per unit of a currency, by day ("2026-10-21" → ["EUR": 11.10]).
/// The bank publishes on working days only, so a weekend, a holiday or today before the
/// day's rate is out uses the nearest earlier day; with none earlier, the nearest later one.
public struct RateTable: Equatable, Sendable, Codable {
    public var kronorPer: [String: [String: Double]]

    public init(kronorPer: [String: [String: Double]] = [:]) {
        self.kronorPer = kronorPer
    }

    /// The same rate on every day — the UI tests use it, so they never need the internet.
    public static func fixed(_ rates: [String: Double]) -> RateTable {
        RateTable(kronorPer: ["0000-01-01": rates])
    }

    public static func dayKey(_ date: Date, calendar: Calendar) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    /// Kronor for one unit of `currency` on `date`; nil when no rate is known at all.
    public func kronor(per currency: String, on date: Date, calendar: Calendar) -> Double? {
        if currency == homeCurrency { return 1 }
        let key = Self.dayKey(date, calendar: calendar)
        let days = kronorPer.keys.filter { kronorPer[$0]?[currency] != nil }.sorted()
        guard let day = days.last(where: { $0 <= key }) ?? days.first else { return nil }
        return kronorPer[day]?[currency]
    }

    public func kronor(_ spend: Spend, calendar: Calendar) -> Double? {
        kronor(per: spend.currency, on: spend.date, calendar: calendar).map { spend.amount * $0 }
    }

    /// Adds what the bank answered (`base=SEK`: units of each currency for ONE krona).
    public mutating func merge(bankRates: [String: [String: Double]]) {
        for (day, rates) in bankRates {
            var row = kronorPer[day] ?? [:]
            for (code, perKrona) in rates where perKrona > 0 {
                row[code] = 1 / perKrona
            }
            kronorPer[day] = row
        }
    }
}

/// A sum in kronor, plus whatever could not be converted (no rate known yet), per currency.
public struct KronorTotal: Equatable, Sendable {
    public var kronor: Double = 0
    public var unconverted: [String: Double] = [:]
    public var count = 0

    public init() {}
}

/// One day's sum in kronor (the chart's bars).
public struct DayKronor: Identifiable, Equatable, Sendable {
    public var day: Date
    public var kronor: Double
    public var id: Date { day }
}

/// One day with everything spent on it (the list of earlier days).
public struct DayTotal: Identifiable, Equatable, Sendable {
    public var day: Date
    public var total: KronorTotal
    public var id: Date { day }
}

public enum Statistics {
    public static func total(_ items: [Spend], rates: RateTable, calendar: Calendar) -> KronorTotal {
        var t = KronorTotal()
        for s in items {
            t.count += 1
            if let k = rates.kronor(s, calendar: calendar) {
                t.kronor += k
            } else {
                t.unconverted[s.currency, default: 0] += s.amount
            }
        }
        return t
    }

    public enum Period: String, CaseIterable, Sendable {
        case thisWeek, thisMonth, lastMonth
    }

    /// The period's days, and how many of them count for "a day" — so far for this week and
    /// this month (today included), all of them for last month.
    public static func range(_ period: Period, now: Date, calendar: Calendar) -> (interval: DateInterval, days: Int) {
        let today = calendar.startOfDay(for: now)
        switch period {
        case .thisWeek:
            let week = calendar.dateInterval(of: .weekOfYear, for: now)!
            let days = (calendar.dateComponents([.day], from: week.start, to: today).day ?? 0) + 1
            return (week, days)
        case .thisMonth:
            let month = calendar.dateInterval(of: .month, for: now)!
            return (month, calendar.component(.day, from: now))
        case .lastMonth:
            let thisMonth = calendar.dateInterval(of: .month, for: now)!
            let last = calendar.dateInterval(of: .month, for: thisMonth.start.addingTimeInterval(-1))!
            let days = calendar.range(of: .day, in: .month, for: last.start)?.count ?? 30
            return (last, days)
        }
    }

    public static func total(_ items: [Spend], in period: Period, now: Date, rates: RateTable,
                             calendar: Calendar) -> (total: KronorTotal, perDay: Double) {
        let (interval, days) = range(period, now: now, calendar: calendar)
        let inside = items.filter { $0.date >= interval.start && $0.date < interval.end }
        let t = total(inside, rates: rates, calendar: calendar)
        return (t, days > 0 ? t.kronor / Double(days) : 0)
    }

    /// One entry per day, oldest first, for the last `days` days with today the last one;
    /// a day with nothing is there with 0.
    public static func daily(_ items: [Spend], days: Int, now: Date, rates: RateTable,
                             calendar: Calendar) -> [DayKronor] {
        let today = calendar.startOfDay(for: now)
        return (0..<days).reversed().compactMap { back in
            guard let day = calendar.date(byAdding: .day, value: -back, to: today) else { return nil }
            let inside = items.filter { calendar.isDate($0.date, inSameDayAs: day) }
            return DayKronor(day: day, kronor: total(inside, rates: rates, calendar: calendar).kronor)
        }
    }

    public struct Favourite: Equatable, Sendable {
        public var title: String
        public var count: Int
        public var kronor: Double
    }

    /// The descriptions used most often ("coffee" and "Coffee " are one), then the dearest.
    public static func favourites(_ items: [Spend], limit: Int, rates: RateTable,
                                  calendar: Calendar) -> [Favourite] {
        var groups: [String: Favourite] = [:]
        for s in items {
            let title = s.title.trimmingCharacters(in: .whitespaces)
            guard !title.isEmpty else { continue }
            let key = title.lowercased()
            var f = groups[key] ?? Favourite(title: title, count: 0, kronor: 0)
            f.count += 1
            f.kronor += rates.kronor(s, calendar: calendar) ?? 0
            groups[key] = f
        }
        return groups.values
            .sorted { ($0.count, $0.kronor, $1.title) > ($1.count, $1.kronor, $0.title) }
            .prefix(limit)
            .map { $0 }
    }

    /// Every day that has an expense, newest first, with its total.
    public static func days(_ items: [Spend], rates: RateTable,
                            calendar: Calendar) -> [DayTotal] {
        let grouped = Dictionary(grouping: items) { calendar.startOfDay(for: $0.date) }
        return grouped.keys.sorted(by: >).map { day in
            DayTotal(day: day, total: total(grouped[day] ?? [], rates: rates, calendar: calendar))
        }
    }
}
