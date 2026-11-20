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

    /// The colour name of the date's weekday.
    public static func name(for date: Date, calendar: Calendar) -> String {
        names[index(of: date, calendar: calendar)]
    }
}
