import Foundation

/// 1.33: the "who was it for" buttons are the owner's own list, kept on the device — three
/// names plus "Others" — not names written in the code. This is the rule that fills the list
/// once, from the people already found in the stored expenses, and the checks for renaming.
public enum WhoNames {
    /// The last button; always there, never renamed.
    public static let others = "Others"
    /// What a new install starts with, and what fills a place the data has no name for.
    public static let defaults = ["Me", "Work", "Partner"]
    public static let count = 3

    /// First start after the update: the distinct "who" values of the stored expenses in the
    /// order they first appear by date (`whos` is oldest first), "Others" and empty ones left
    /// out, at most three. A place the data does not fill takes the default of that place
    /// (the next unused default when that name is already taken).
    public static func seed(from whos: [String]) -> [String] {
        var names: [String] = []
        for who in whos {
            let name = who.trimmingCharacters(in: .whitespaces)
            if name.isEmpty || name == others || names.contains(name) { continue }
            names.append(name)
            if names.count == count { return names }
        }
        while names.count < count {
            let wanted = defaults[names.count]
            let pick = names.contains(wanted) ? defaults.first { !names.contains($0) } : wanted
            names.append(pick ?? "Person \(names.count + 1)")
        }
        return names
    }

    /// One name per line, like the category list.
    public static func encode(_ names: [String]) -> String { names.joined(separator: "\n") }

    /// nil when nothing is stored yet (the list has not been filled).
    public static func decode(_ text: String) -> [String]? {
        let names = text.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }
        return names.count == count && !names.contains("") ? names : nil
    }

    /// A list can be saved when every name is filled, none is "Others", none is used twice.
    public static func isValid(_ names: [String]) -> Bool {
        let trimmed = names.map { $0.trimmingCharacters(in: .whitespaces) }
        guard trimmed.count == count, !trimmed.contains("") else { return false }
        let lower = trimmed.map { $0.lowercased() }
        return Set(lower).count == count && !lower.contains(others.lowercased())
    }

    /// old name → new name, only for the places that changed. A swap works too: the caller
    /// looks each expense up once.
    public static func renames(old: [String], new: [String]) -> [String: String] {
        var map: [String: String] = [:]
        for (o, n) in zip(old, new) where o != n.trimmingCharacters(in: .whitespaces) {
            map[o] = n.trimmingCharacters(in: .whitespaces)
        }
        return map
    }
}
