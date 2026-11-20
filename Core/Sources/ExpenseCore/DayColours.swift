import Foundation

/// 1.26 (his ask, 20 Nov 2026): on the map, This week and Last week colour each pin by its
/// weekday. One colour per day, Monday first; the app turns the names into colours.
public enum DayColours {
    /// Monday … Sunday.
    public static let names = ["blue", "green", "orange", "purple", "pink", "red", "brown"]

    /// 0 = Monday … 6 = Sunday, whatever the calendar's first day of the week is.
    public static func index(of date: Date, calendar: Calendar) -> Int {
        (calendar.component(.weekday, from: date) + 5) % 7
    }

    /// 1.27: things grouped by weekday, Monday first, each day's things oldest first — the day
    /// buttons under the week map and the route line of each day.
    public static func byDay<T>(_ items: [T], date: (T) -> Date, calendar: Calendar) -> [(index: Int, items: [T])] {
        Dictionary(grouping: items) { index(of: date($0), calendar: calendar) }
            .map { (index: $0.key, items: $0.value.sorted { date($0) < date($1) }) }
            .sorted { $0.index < $1.index }
    }

    /// The colour name of the date's weekday.
    public static func name(for date: Date, calendar: Calendar) -> String {
        names[index(of: date, calendar: calendar)]
    }
}
