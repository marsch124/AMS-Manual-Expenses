import Foundation

/// 1.19: "Search all expenses" — every word typed must be found in at least one field.
public enum ExpenseSearch {
    public static func matches(query: String, fields: [String]) -> Bool {
        let words = query.split(whereSeparator: { $0.isWhitespace }).map(String.init)
        guard !words.isEmpty else { return false }
        return words.allSatisfy { word in
            fields.contains { $0.range(of: word, options: [.caseInsensitive, .diacriticInsensitive]) != nil }
        }
    }
}
