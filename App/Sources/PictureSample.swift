import ExpenseCore
import Foundation
import SwiftData

/// 1.34: picture mode (`-pictures`). Invented expenses, kept in an in-memory store only, so
/// screenshots can be made without real data. Nothing here is ever written to the device:
/// the three names are held in memory (`Consumers.pictureNames`), not in the settings.
enum PictureSample {
    static let names = ["Sam", "Alex", "Robin"]

    // title, amount in kronor, category, who, days ago, hour, place, latitude, longitude
    // Places and positions are invented, in central Stockholm.
    private static let rows: [(String, Double, String, String, Int, Double, String, Double?, Double?)] = [
        ("Coffee", 45, "Café", "Sam", 0, 8.2, "Corner Café", 59.3326, 18.0649),
        ("Croissant", 32, "Café", "Sam", 0, 8.3, "Corner Café", 59.3326, 18.0649),
        ("Train ticket", 62, "Transport", "Sam", 0, 9.1, "Central Station", 59.3303, 18.0586),
        ("Museum", 150, "Leisure", "Alex", 0, 10.9, "Harbour Museum", 59.3270, 18.0910),
        ("Lunch", 129, "Restaurant", "Sam", 0, 12.6, "Market Kitchen", 59.3380, 18.0700),
        ("Pharmacy", 89, "Health", "Alex", 0, 13.4, "Linden Pharmacy", 59.3345, 18.0632),
        ("Groceries", 245, "Groceries", "Sam", 1, 17.8, "Market Hall", 59.3380, 18.0700),
        ("Coffee", 45, "Café", "Sam", 1, 9.0, "Corner Café", 59.3326, 18.0649),
        ("Dinner", 386, "Restaurant", "Alex", 1, 19.7, "Garden Inn", 59.3408, 18.0550),
        ("Tram", 39, "Transport", "Sam", 1, 8.4, "", nil, nil),
        ("Bookshop", 199, "Shopping", "Alex", 2, 15.3, "Old Town Books", 59.3250, 18.0710),
        ("Coffee", 45, "Café", "Sam", 2, 8.9, "Corner Café", 59.3326, 18.0649),
        ("Groceries", 312, "Groceries", "Sam", 3, 18.2, "Market Hall", 59.3380, 18.0700),
        ("Lunch", 115, "Restaurant", "Sam", 3, 12.5, "Market Kitchen", 59.3380, 18.0700),
        ("Park entry", 60, "Leisure", "Alex", 4, 14.0, "River Park", 59.3440, 18.0900),
        ("Coffee", 45, "Café", "Sam", 5, 9.1, "Corner Café", 59.3326, 18.0649),
        ("Train ticket", 274, "Travel", "Sam", 6, 7.5, "Central Station", 59.3303, 18.0586),
        ("Lunch", 132, "Restaurant", "Alex", 7, 12.7, "Market Kitchen", 59.3380, 18.0700),
        ("Groceries", 421, "Groceries", "Sam", 8, 17.5, "Market Hall", 59.3380, 18.0700),
        ("Cinema", 110, "Leisure", "Robin", 9, 20.0, "Cinema Rex", 59.3360, 18.0480),
        ("Coffee", 45, "Café", "Sam", 10, 8.8, "Corner Café", 59.3326, 18.0649),
        ("Pharmacy", 153, "Health", "Sam", 11, 11.2, "Linden Pharmacy", 59.3345, 18.0632),
        ("Dinner", 468, "Restaurant", "Alex", 12, 19.5, "Garden Inn", 59.3408, 18.0550),
        ("Shoes", 790, "Shopping", "Robin", 13, 16.0, "", nil, nil),
    ]

    /// Puts the sample into a store that lives in memory only.
    static func fill(_ context: ModelContext, now: Date = Date()) {
        let cal = Calendar.current
        let startOfToday = cal.startOfDay(for: now)
        for (index, r) in rows.enumerated() {
            let day = cal.date(byAdding: .day, value: -r.4, to: startOfToday) ?? startOfToday
            var date = day.addingTimeInterval(r.5 * 3600)
            if r.4 == 0, date > now {
                // Today's rows never lie in the future, and stay today.
                date = max(startOfToday, now.addingTimeInterval(-Double(rows.count - index) * 60))
            }
            let fix: Fix? = (r.7 != nil && r.8 != nil) ? Fix(latitude: r.7 ?? 0, longitude: r.8 ?? 0, accuracy: 10) : nil
            context.insert(Expense(title: r.0, amount: r.1, currency: "SEK", date: date, place: "Stockholm, Sweden",
                                   heard: "\(r.0) \(Int(r.1)) kronor", category: r.2, consumer: r.3, fix: fix,
                                   visitedPlace: r.6))
        }
        try? context.save()
    }
}
