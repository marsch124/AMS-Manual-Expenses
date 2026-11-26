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
    /// Since 1.6: who the expense was for — one of the owner's own names (see `Consumers`) or Others.
    var consumer: String = ""
    /// Since 1.7: the GPS fix when it was logged (nil: none known, or logged before 1.7).
    var latitude: Double?
    var longitude: Double?
    /// Since 1.8: how sure the iPhone was about that fix, in metres.
    var locationAccuracy: Double?
    /// Since 1.7: the place visited, a name he chose on the check sheet; "" = none.
    var visitedPlace: String = ""
    /// Since 1.13: one photo (receipt or what was bought), JPEG, kept beside the store on the iPhone.
    @Attribute(.externalStorage) var photo: Data?
    /// Since 1.13: a small copy of the photo for the list rows.
    var photoThumb: Data?

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
        photo = d.photo
        photoThumb = d.photoThumb
    }
}

/// 1.19: everything a deleted expense had, so Undo can bring it back exactly.
struct DeletedExpense {
    let id = UUID()
    let title: String, amount: Double, currency: String, date: Date, timeZoneID: String
    let place: String, heard: String, createdAt: Date, category: String, consumer: String
    let fix: Fix?, visitedPlace: String, photo: Data?, photoThumb: Data?

    init(_ e: Expense) {
        title = e.title; amount = e.amount; currency = e.currency; date = e.date; timeZoneID = e.timeZoneID
        place = e.place; heard = e.heard; createdAt = e.createdAt; category = e.category; consumer = e.consumer
        fix = e.fix; visitedPlace = e.visitedPlace; photo = e.photo; photoThumb = e.photoThumb
    }

    func restored() -> Expense {
        let e = Expense(title: title, amount: amount, currency: currency, date: date, place: place, heard: heard,
                        category: category, consumer: consumer, fix: fix, visitedPlace: visitedPlace)
        e.timeZoneID = timeZoneID
        e.createdAt = createdAt
        e.photo = photo
        e.photoThumb = photoThumb
        return e
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
    /// 1.13: the photo and its small copy (see `Photos`).
    var photo: Data?
    var photoThumb: Data?

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
                  visitedPlace: e.visitedPlace, fix: e.fix, area: e.place, photo: e.photo, photoThumb: e.photoThumb)
    }
}

/// Who an expense was for. 1.33: the three names are the owner's own list, kept in the app's
/// settings on the device (`consumerNames`), not in the code; "Others" is always the fourth.
/// The first name is the one a new expense starts with. The value stored with an expense stays
/// the plain name.
enum Consumers {
    static let key = "consumerNames"
    /// 1.34: in picture mode the three invented names, held in memory only (never stored).
    static var pictureNames: [String]?

    /// The three names (the defaults of a new install until the list has been filled).
    static var names: [String] {
        if let pictureNames { return pictureNames }
        return WhoNames.decode(UserDefaults.standard.string(forKey: key) ?? "") ?? WhoNames.defaults
    }
    static var all: [String] { names + [WhoNames.others] }
    static var initial: String { names[0] }

    /// First start after the update: fill the list once from the stored expenses (oldest first).
    static func seedIfNeeded(from expenses: [Expense]) {
        guard WhoNames.decode(UserDefaults.standard.string(forKey: key) ?? "") == nil else { return }
        let seeded = WhoNames.seed(from: expenses.map(\.consumer))
        UserDefaults.standard.set(WhoNames.encode(seeded), forKey: key)
    }
}
