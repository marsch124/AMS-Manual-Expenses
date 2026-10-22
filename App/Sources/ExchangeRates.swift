import ExpenseCore
import Foundation

/// The European Central Bank's daily rates, fetched from frankfurter.dev (free, no key) and
/// kept on the iPhone, so totals in kronor work offline for every day already fetched.
/// Only dates and currency codes are sent — never an expense.
@MainActor
final class ExchangeRates: ObservableObject {
    @Published private(set) var table: RateTable
    private var lastFetch: Date?
    private static let storeKey = "exchangeRates"

    init() {
        if ExpensesApp.uiTesting {
            // UI tests never touch the internet: one euro is always 10 kronor there.
            table = .fixed(["EUR": 10])
            return
        }
        if let data = UserDefaults.standard.data(forKey: Self.storeKey),
           let saved = try? JSONDecoder().decode(RateTable.self, from: data) {
            table = saved
        } else {
            table = RateTable()
        }
    }

    /// Fetches what the expenses need: from a week before the oldest one in another currency
    /// up to today, one request per currency (a currency the bank does not know cannot spoil
    /// the others). At most once an hour, unless a currency is still missing altogether.
    func update(for spends: [Spend]) async {
        guard !ExpensesApp.uiTesting else { return }
        let foreign = spends.filter { $0.currency != homeCurrency }
        guard let oldest = foreign.map(\.date).min() else { return }
        let codes = Set(foreign.map(\.currency)).sorted()
        let calendar = Calendar.current
        let known = Set(table.kronorPer.values.flatMap(\.keys))
        if let lastFetch, Date().timeIntervalSince(lastFetch) < 3600, codes.allSatisfy(known.contains) { return }
        lastFetch = Date()

        let start = RateTable.dayKey(calendar.date(byAdding: .day, value: -7, to: oldest) ?? oldest, calendar: calendar)
        let end = RateTable.dayKey(Date(), calendar: calendar)
        struct Answer: Decodable { let rates: [String: [String: Double]] }
        var updated = table
        for code in codes {
            guard let url = URL(string: "https://api.frankfurter.dev/v1/\(start)..\(end)?base=\(homeCurrency)&symbols=\(code)"),
                  let (data, response) = try? await URLSession.shared.data(from: url),
                  (response as? HTTPURLResponse)?.statusCode == 200,
                  let answer = try? JSONDecoder().decode(Answer.self, from: data) else { continue }
            updated.merge(bankRates: answer.rates)
        }
        guard updated != table else { return }
        table = updated
        if let data = try? JSONEncoder().encode(updated) {
            UserDefaults.standard.set(data, forKey: Self.storeKey)
        }
    }
}

/// How money is written: totals in whole kronor, then whatever has no rate yet.
enum Money {
    static func kronor(_ value: Double) -> String {
        value.formatted(.currency(code: homeCurrency).precision(.fractionLength(0)))
    }

    static func text(_ total: KronorTotal) -> String {
        var parts = [kronor(total.kronor)]
        for (code, amount) in total.unconverted.sorted(by: { $0.key < $1.key }) {
            parts.append("+ " + amount.formatted(.currency(code: code)))
        }
        return parts.joined(separator: " ")
    }
}
