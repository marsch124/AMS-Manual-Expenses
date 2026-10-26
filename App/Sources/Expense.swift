import ExpenseCore
import Foundation
import SwiftData

@Model
final class Expense {
    var title: String = ""
    var amount: Double = 0
    var currency: String = "SEK"
    var date: Date = Date()
    /// Time zone the phone was in when the expense was logged.
    var timeZoneID: String = ""
    /// Place name from the phone's location, if known.
    var place: String = ""
    /// The sentence as it was dictated or typed.
    var heard: String = ""
    var createdAt: Date = Date()
    /// Since 1.3; "" = no category. A name from Settings › Categories.
    var category: String = ""
    /// Since 1.6: who the expense was for — Martin (default), AMS or Others.
    var consumer: String = Consumers.initial
    /// Since 1.7: the GPS fix when it was logged (nil: none known, or logged before 1.7).
    var latitude: Double?
    var longitude: Double?
    /// Since 1.8: how sure the iPhone was about that fix, in metres.
    var locationAccuracy: Double?
    /// Since 1.7: the place visited, a name he chose on the check sheet; "" = none.
    var visitedPlace: String = ""

    init(title: String, amount: Double, currency: String, date: Date, place: String, heard: String,
         category: String = "", consumer: String = Consumers.initial, fix: Fix? = nil, visitedPlace: String = "") {
        self.category = category
        self.consumer = consumer
        self.latitude = fix?.latitude
        self.longitude = fix?.longitude
        self.locationAccuracy = fix?.accuracy
        self.visitedPlace = visitedPlace
        self.title = title
        self.amount = amount
        self.currency = currency
        self.date = date
        self.timeZoneID = TimeZone.current.identifier
        self.place = place
        self.heard = heard
        self.createdAt = Date()
    }
}

extension Expense {
    /// What the statistics count.
    var spend: Spend { Spend(title: title, amount: amount, currency: currency, date: date, category: category) }

    var fix: Fix? {
        guard let latitude, let longitude else { return nil }
        return Fix(latitude: latitude, longitude: longitude, accuracy: locationAccuracy)
    }

    /// What the place chooser learns from.
    var visit: Visit { Visit(place: visitedPlace, fix: fix, date: date) }

    /// A checked draft's answers written onto this expense (editing an existing one).
    func apply(_ d: Draft) {
        guard let amount = d.amount else { return }
        title = d.title.trimmingCharacters(in: .whitespaces).isEmpty ? "Expense" : d.title
        self.amount = amount
        currency = d.currency
        date = d.date
        category = d.category
        consumer = d.consumer
        visitedPlace = d.visitedPlace
    }
}

/// An expense being reviewed before it is saved.
struct Draft: Identifiable {
    let id = UUID()
    var expense: Expense?
    var title: String
    var amountText: String
    var currency: String
    var date: Date
    var heard: String
    var category: String = ""
    var consumer: String = Consumers.initial
    var visitedPlace: String = ""
    /// Where it was logged: for a new expense the fix when the check sheet opened.
    var fix: Fix?
    /// The town and country it was logged in ("Stockholm, Sweden"), shown under the map (1.8).
    var area: String = ""
    /// 1.8: the place the app filled in by itself, and how far away it was used before.
    var autoPlace: String = ""
    var autoPlaceMetres: Double?

    var amount: Double? {
        let value = Double(amountText.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces))
        guard let value, value > 0 else { return nil }
        return (value * 100).rounded() / 100
    }

    static func format(_ value: Double) -> String {
        value == value.rounded() ? String(Int(value)) : String(format: "%.2f", value)
    }
}

extension Draft {
    init(editing e: Expense) {
        self.init(expense: e, title: e.title, amountText: Draft.format(e.amount),
                  currency: e.currency, date: e.date, heard: e.heard, category: e.category, consumer: e.consumer,
                  visitedPlace: e.visitedPlace, fix: e.fix, area: e.place)
    }
}

/// Who an expense was for (1.6, his three values; Martin is the default).
enum Consumers {
    static let all = ["Martin", "AMS", "Others"]
    static let initial = "Martin"
}
