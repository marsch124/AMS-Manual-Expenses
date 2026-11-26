import ExpenseCore
import SwiftUI

/// 1.9: the colours and icons — categories (his choice per category, Settings › Categories)
/// and who an expense was for (his colours, 27 Oct 2026, now by place in his list: first blue,
/// second yellow, third green, Others grey).
enum Looks {
    /// UserDefaults key of his category icon choices ("name<TAB>symbol" per line).
    static let iconsKey = "categoryIcons"

    static func color(_ name: String) -> Color {
        switch name {
        case "brown": .brown
        case "green": .green
        case "orange": .orange
        case "blue": .blue
        case "pink": .pink
        case "indigo": .indigo
        case "red": .red
        case "purple": .purple
        case "teal": .teal
        case "cyan": .cyan
        case "yellow": .yellow
        case "mint": .mint
        default: .gray
        }
    }

    /// Who it was for: the label's fill, and its text colour (dark on yellow, so it can be read).
    /// By place in the list of names; a name not in the list (and Others) is grey.
    static func consumer(_ name: String) -> (fill: Color, text: Color) {
        switch Consumers.names.firstIndex(of: name) {
        case 0: (.blue, .white)
        case 1: (.yellow, .black)
        case 2: (.green, .white)
        default: (.gray, .white)
        }
    }

    /// Who it was for, as writing on a light tint of its colour: the colour itself, but a dark
    /// yellow for the second place (yellow writing cannot be read).
    static func consumerInk(_ name: String) -> Color {
        Consumers.names.firstIndex(of: name) == 1 ? Color(red: 0.6, green: 0.45, blue: 0) : consumer(name).fill
    }
}

/// A category's white icon in its coloured circle.
struct CategoryIcon: View {
    let name: String
    var size: CGFloat = 30
    @AppStorage(Looks.iconsKey) private var iconsText = ""

    var body: some View {
        let look = CategoryLooks.look(for: name, custom: CategoryLooks.decode(iconsText))
        Image(systemName: look.symbol)
            .font(.system(size: size * 0.48, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(Circle().fill(Looks.color(look.color).gradient))
            .accessibilityHidden(true)
    }
}

/// Who it was for, as a small coloured label in the lists.
struct ConsumerTag: View {
    let name: String

    var body: some View {
        let look = Looks.consumer(name)
        Text(name)
            .font(.caption2.weight(.bold))
            .foregroundStyle(look.text)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(Capsule().fill(look.fill))
            .accessibilityLabel("for \(name)")
    }
}

/// Settings › Categories: tap a category's icon to pick another one; a tap chooses and closes.
struct CategoryIconPicker: View {
    let category: String
    @Environment(\.dismiss) private var dismiss
    @AppStorage(Looks.iconsKey) private var iconsText = ""

    var body: some View {
        let current = CategoryLooks.look(for: category, custom: CategoryLooks.decode(iconsText))
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 64), spacing: 16)], spacing: 16) {
                    ForEach(Array(CategoryLooks.choices.enumerated()), id: \.offset) { index, look in
                        Button {
                            var custom = CategoryLooks.decode(iconsText)
                            custom = custom.filter { $0.key.lowercased() != category.lowercased() }
                            custom[category] = look.symbol
                            iconsText = CategoryLooks.encode(custom)
                            dismiss()
                        } label: {
                            Image(systemName: look.symbol)
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 56, height: 56)
                                .background(Circle().fill(Looks.color(look.color).gradient))
                                .overlay(Circle().stroke(Color.primary, lineWidth: look == current ? 3 : 0).padding(-4))
                        }
                        .accessibilityLabel(look.symbol)
                        .accessibilityIdentifier("icon-choice-\(index)")
                    }
                }
                .padding(20)
            }
            .navigationTitle(category)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityIdentifier("icon-cancel")
                }
            }
        }
        .presentationDetents([.medium])
    }
}

extension CategoryLooks {
    /// Renaming a category keeps its look; deleting it drops his choice (1.9).
    static func renamed(_ text: String, from old: String, to new: String, keeping look: CategoryLook) -> String {
        var custom = decode(text).filter { $0.key.lowercased() != old.lowercased() && $0.key.lowercased() != new.lowercased() }
        custom[new] = look.symbol
        return encode(custom)
    }

    static func removed(_ text: String, _ name: String) -> String {
        encode(decode(text).filter { $0.key.lowercased() != name.lowercased() })
    }
}
