import Foundation

extension Statistics {
    /// 1.23 (his ask, 20 Nov 2026): which rows of a week list are its `count` highest
    /// expenses, compared in kronor at each expense's own day's rate. Nothing is picked when
    /// the list has `count` expenses or fewer (all would be). Ties: the earlier row wins.
    public static func highest(_ items: [Spend], count: Int = 5, rates: RateTable, calendar: Calendar) -> Set<Int> {
        guard items.count > count else { return [] }
        let kronor: [Double] = items.map { spend in
            rates.kronor(spend, calendar: calendar) ?? (spend.currency == homeCurrency ? spend.amount : 0)
        }
        let order = items.indices.sorted { a, b in
            kronor[a] != kronor[b] ? kronor[a] > kronor[b] : a < b
        }
        return Set(order.prefix(count))
    }
}
