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

    init(title: String, amount: Double, currency: String, date: Date, place: String, heard: String) {
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
    var spend: Spend { Spend(title: title, amount: amount, currency: currency, date: date) }

    /// A checked draft's answers written onto this expense (editing an existing one).
    func apply(_ d: Draft) {
        guard let amount = d.amount else { return }
        title = d.title.trimmingCharacters(in: .whitespaces).isEmpty ? "Expense" : d.title
        self.amount = amount
        currency = d.currency
        date = d.date
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
                  currency: e.currency, date: e.date, heard: e.heard)
    }
}
