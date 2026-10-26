import ExpenseCore
import SwiftData
import SwiftUI

/// His categories, in his order, kept in UserDefaults one per line (1.3).
enum CategoryList {
    static let key = "categories"
    static let initial = encode(Categories.defaults)
    /// The category a new expense starts in when its description has none yet (1.4: Café).
    /// It follows a rename and is cleared when that category is deleted.
    static let defaultKey = "defaultCategory"
    static let initialDefault = Categories.initialDefault

    static func decode(_ text: String) -> [String] {
        text.split(separator: "\n").map(String.init)
    }

    static func encode(_ names: [String]) -> String {
        names.joined(separator: "\n")
    }

    /// A name worth adding: trimmed, not empty, not already there (any spelling).
    static func cleaned(_ name: String, in names: [String]) -> String? {
        let n = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !n.isEmpty, !names.contains(where: { $0.lowercased() == n.lowercased() }) else { return nil }
        return n
    }
}

/// Choosing an expense's category on the check sheet: tap one and it is chosen;
/// "New category…" adds one to the list and chooses it.
struct CategoryChooser: View {
    @Binding var selection: String
    @Environment(\.dismiss) private var dismiss
    @AppStorage(CategoryList.key) private var categoriesText = CategoryList.initial
    @State private var adding = false
    @State private var newName = ""

    private var names: [String] { CategoryList.decode(categoriesText) }

    var body: some View {
        List {
            Section {
                choice("None", value: "", id: "category-choice-none")
                ForEach(Array(names.enumerated()), id: \.element) { index, name in
                    choice(name, value: name, id: "category-choice-\(index)")
                }
            }
            Section {
                Button("New category…") {
                    newName = ""
                    adding = true
                }
                .accessibilityIdentifier("category-new")
            }
        }
        .navigationTitle("Category")
        .navigationBarTitleDisplayMode(.inline)
        .alert("New category", isPresented: $adding) {
            TextField("Name", text: $newName)
                .accessibilityIdentifier("category-new-name")
            Button("Cancel", role: .cancel) {}
                .accessibilityIdentifier("category-new-cancel")
            Button("Add") {
                if let name = CategoryList.cleaned(newName, in: names) {
                    categoriesText = CategoryList.encode(names + [name])
                    selection = name
                    dismiss()
                } else if let existing = names.first(where: { $0.lowercased() == newName.trimmingCharacters(in: .whitespaces).lowercased() }) {
                    selection = existing
                    dismiss()
                }
            }
            .accessibilityIdentifier("category-new-add")
        }
    }

    private func choice(_ label: String, value: String, id: String) -> some View {
        Button {
            selection = value
            dismiss()
        } label: {
            HStack {
                Text(label)
                Spacer()
                if selection == value {
                    Image(systemName: "checkmark").foregroundStyle(Color.accentColor)
                }
            }
        }
        .tint(.primary)
        .accessibilityIdentifier(id)
        .accessibilityAddTraits(selection == value ? .isSelected : [])
    }
}

/// Settings › Categories: add (at the bottom), rename (tap; every expense follows), delete
/// (swipe; its expenses keep no category, after asking when some use it), reorder (Edit).
struct CategoriesScreen: View {
    @Environment(\.modelContext) private var context
    @AppStorage(CategoryList.key) private var categoriesText = CategoryList.initial
    @AppStorage(CategoryList.defaultKey) private var defaultCategory = CategoryList.initialDefault
    @Query private var expenses: [Expense]
    @State private var renaming: String?
    @State private var adding = false
    @State private var editedName = ""
    @State private var deleting: String?

    private var names: [String] { CategoryList.decode(categoriesText) }

    var body: some View {
        List {
            Section {
                ForEach(Array(names.enumerated()), id: \.element) { index, name in
                    Button {
                        editedName = name
                        renaming = name
                    } label: {
                        HStack {
                            Text(name)
                            if name == defaultCategory {
                                Text("default")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .accessibilityIdentifier("categories-default")
                            }
                            Spacer()
                            Text("\(used(name))")
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tint(.primary)
                    .accessibilityIdentifier("categories-row-\(index)")
                }
                .onDelete { offsets in
                    guard let index = offsets.first else { return }
                    let name = names[index]
                    if used(name) > 0 { deleting = name } else { remove(name) }
                }
                .onMove { from, to in
                    var list = names
                    list.move(fromOffsets: from, toOffset: to)
                    categoriesText = CategoryList.encode(list)
                }
            } footer: {
                Text("The number is how many expenses have the category. Tap a category to rename it. A new expense starts in the default one, unless its description had another category before.")
            }
            Section {
                Button("Add category") {
                    editedName = ""
                    adding = true
                }
                .accessibilityIdentifier("categories-add")
            }
        }
        .navigationTitle("Categories")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            EditButton().accessibilityIdentifier("categories-edit")
        }
        .alert("Rename category", isPresented: Binding(get: { renaming != nil }, set: { if !$0 { renaming = nil } })) {
            TextField("Name", text: $editedName)
                .accessibilityIdentifier("categories-rename-name")
            Button("Cancel", role: .cancel) { renaming = nil }
            Button("Save") {
                if let old = renaming { rename(old, to: editedName) }
                renaming = nil
            }
            .accessibilityIdentifier("categories-rename-save")
        } message: {
            Text("Every expense in this category moves with it.")
        }
        .alert("New category", isPresented: $adding) {
            TextField("Name", text: $editedName)
                .accessibilityIdentifier("categories-new-name")
            Button("Cancel", role: .cancel) {}
            Button("Add") {
                if let name = CategoryList.cleaned(editedName, in: names) {
                    categoriesText = CategoryList.encode(names + [name])
                }
            }
            .accessibilityIdentifier("categories-new-add")
        }
        .confirmationDialog("Delete this category?", isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } }),
                            titleVisibility: .visible) {
            Button("Delete category", role: .destructive) {
                if let name = deleting { remove(name) }
                deleting = nil
            }
            .accessibilityIdentifier("categories-delete-confirm")
            Button("Keep it", role: .cancel) { deleting = nil }
        } message: {
            Text("\(used(deleting ?? "")) expenses will have no category. The expenses themselves stay.")
        }
    }

    private func used(_ name: String) -> Int {
        expenses.filter { $0.category == name }.count
    }

    private func rename(_ old: String, to new: String) {
        let name = new.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, name != old else { return }
        if name.lowercased() != old.lowercased(), names.contains(where: { $0.lowercased() == name.lowercased() }) {
            // Renaming onto another category joins the two: its expenses move there.
            let target = names.first { $0.lowercased() == name.lowercased() }!
            for e in expenses where e.category == old { e.category = target }
            if defaultCategory == old { defaultCategory = target }
            categoriesText = CategoryList.encode(names.filter { $0 != old })
            return
        }
        for e in expenses where e.category == old { e.category = name }
        if defaultCategory == old { defaultCategory = name }
        categoriesText = CategoryList.encode(names.map { $0 == old ? name : $0 })
    }

    private func remove(_ name: String) {
        for e in expenses where e.category == name { e.category = "" }
        if defaultCategory == name { defaultCategory = "" }
        categoriesText = CategoryList.encode(names.filter { $0 != name })
    }
}

/// Choosing who an expense was for (1.6): Martin, AMS or Others; a tap chooses and goes back.
struct ConsumerChooser: View {
    @Binding var selection: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            ForEach(Array(Consumers.all.enumerated()), id: \.element) { index, name in
                Button {
                    selection = name
                    dismiss()
                } label: {
                    HStack {
                        Text(name)
                        Spacer()
                        if selection == name {
                            Image(systemName: "checkmark").foregroundStyle(Color.accentColor)
                        }
                    }
                }
                .tint(.primary)
                .accessibilityIdentifier("consumer-choice-\(index)")
            }
        }
        .navigationTitle("For whom")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Choosing the place visited (1.7): None, the places near this expense's GPS fix (nearest
/// first), then every other place used before (latest first); "New place…" types a new one.
struct PlaceChooser: View {
    @Binding var selection: String
    let fix: Fix?
    let visits: [Visit]
    @Environment(\.dismiss) private var dismiss
    @State private var adding = false
    @State private var newName = ""

    private var lists: (near: [String], other: [String]) {
        var c = Places.choices(at: fix, history: visits)
        // A place typed on this sheet but not saved yet is still offered.
        if !selection.isEmpty, !(c.near + c.other).contains(where: { $0.lowercased() == selection.lowercased() }) {
            c.other.insert(selection, at: 0)
        }
        return c
    }

    var body: some View {
        let c = lists
        List {
            Section {
                choice("None", value: "", id: "place-choice-none")
            }
            if !c.near.isEmpty {
                Section("Nearby") {
                    ForEach(Array(c.near.enumerated()), id: \.element) { index, name in
                        choice(name, value: name, id: "place-choice-\(index)")
                    }
                }
            }
            if !c.other.isEmpty {
                Section(c.near.isEmpty ? "Places" : "Other places") {
                    ForEach(Array(c.other.enumerated()), id: \.element) { index, name in
                        choice(name, value: name, id: "place-choice-\(c.near.count + index)")
                    }
                }
            }
            Section {
                Button("New place…") {
                    newName = ""
                    adding = true
                }
                .accessibilityIdentifier("place-new")
            } footer: {
                if fix == nil {
                    Text("No GPS position for this expense, so no places nearby.")
                }
            }
        }
        .navigationTitle("Place")
        .navigationBarTitleDisplayMode(.inline)
        .alert("New place", isPresented: $adding) {
            TextField("Name", text: $newName)
                .accessibilityIdentifier("place-new-name")
            Button("Cancel", role: .cancel) {}
                .accessibilityIdentifier("place-new-cancel")
            Button("Add") {
                let name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !name.isEmpty else { return }
                // A name already there (any spelling) is chosen, not added twice.
                selection = (c.near + c.other).first { $0.lowercased() == name.lowercased() } ?? name
                dismiss()
            }
            .accessibilityIdentifier("place-new-add")
        }
    }

    private func choice(_ label: String, value: String, id: String) -> some View {
        Button {
            selection = value
            dismiss()
        } label: {
            HStack {
                Text(label)
                Spacer()
                if selection == value {
                    Image(systemName: "checkmark").foregroundStyle(Color.accentColor)
                }
            }
        }
        .tint(.primary)
        .accessibilityIdentifier(id)
        .accessibilityAddTraits(selection == value ? .isSelected : [])
    }
}
