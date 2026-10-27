import Foundation

/// A category's icon and colour (1.9, his ask 27 Oct 2026: "visual improvements with colour
/// icons"). `symbol` is an SF Symbol name; `color` one of a few names the app turns into colours.
public struct CategoryLook: Equatable, Sendable {
    public var symbol: String
    public var color: String

    public init(_ symbol: String, _ color: String) {
        self.symbol = symbol
        self.color = color
    }
}

public enum CategoryLooks {
    /// What he can choose from in Settings › Categories, in this order.
    public static let choices: [CategoryLook] = [
        CategoryLook("cup.and.saucer.fill", "brown"),
        CategoryLook("cart.fill", "green"),
        CategoryLook("fork.knife", "orange"),
        CategoryLook("car.fill", "blue"),
        CategoryLook("bag.fill", "pink"),
        CategoryLook("house.fill", "indigo"),
        CategoryLook("heart.fill", "red"),
        CategoryLook("theatermasks.fill", "purple"),
        CategoryLook("airplane", "teal"),
        CategoryLook("square.grid.2x2.fill", "gray"),
        CategoryLook("tram.fill", "cyan"),
        CategoryLook("fuelpump.fill", "yellow"),
        CategoryLook("gift.fill", "mint"),
        CategoryLook("book.fill", "brown"),
        CategoryLook("wineglass.fill", "purple"),
        CategoryLook("briefcase.fill", "indigo"),
        CategoryLook("tag.fill", "gray"),
    ]

    /// A new install's categories (`Categories.defaults`) each start with their own look.
    public static let defaults: [String: CategoryLook] = [
        "café": choices[0], "groceries": choices[1], "restaurant": choices[2], "transport": choices[3],
        "shopping": choices[4], "home": choices[5], "health": choices[6], "leisure": choices[7],
        "travel": choices[8], "other": choices[9],
    ]

    /// Any other category, until he picks a look for it.
    public static let fallback = CategoryLook("tag.fill", "gray")
    /// "No category".
    public static let none = CategoryLook("questionmark", "gray")

    /// The look of `name`: his own choice (`custom`, name → symbol) first, then the default.
    public static func look(for name: String, custom: [String: String]) -> CategoryLook {
        let key = name.trimmingCharacters(in: .whitespaces).lowercased()
        guard !key.isEmpty else { return none }
        if let symbol = custom.first(where: { $0.key.lowercased() == key })?.value,
           let chosen = choices.first(where: { $0.symbol == symbol }) {
            return chosen
        }
        return defaults[key] ?? fallback
    }

    /// His choices are kept as text, one "name<TAB>symbol" per line.
    public static func decode(_ text: String) -> [String: String] {
        var result: [String: String] = [:]
        for line in text.split(separator: "\n") {
            let parts = line.split(separator: "\t", maxSplits: 1).map(String.init)
            if parts.count == 2 { result[parts[0]] = parts[1] }
        }
        return result
    }

    public static func encode(_ custom: [String: String]) -> String {
        custom.sorted { $0.key < $1.key }.map { "\($0.key)\t\($0.value)" }.joined(separator: "\n")
    }
}
