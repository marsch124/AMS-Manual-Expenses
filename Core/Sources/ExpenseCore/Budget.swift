import Foundation

/// 1.19 (his pick): a weekly budget in kronor, set in Settings. 0 or less = no budget.
public enum Budget {
    /// What is left of the budget this week: positive = left, negative = over; nil = no budget.
    public static func left(budget: Double, spent: Double) -> Double? {
        guard budget > 0 else { return nil }
        return (budget - spent).rounded()
    }

    /// "1 500" / "1500,50" as typed in Settings; nil or junk = 0 (no budget).
    public static func parse(_ text: String) -> Double {
        let clean = text.replacingOccurrences(of: ",", with: ".").filter { !$0.isWhitespace }
        return max(0, Double(clean) ?? 0)
    }
}
