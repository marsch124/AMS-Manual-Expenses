import Foundation

/// 1.20 (his ask): the This week and Last week lists show whole amounts — €10 instead of €10,00.
public enum WholeAmount {
    /// Rounded to whole units, .50 up (away from zero): 6.45 → 6, 7.50 → 8, 53.15 → 53.
    public static func rounded(_ amount: Double) -> Double {
        amount.rounded(.toNearestOrAwayFromZero)
    }
}
