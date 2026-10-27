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
                    choice(name, value: name, id: "category-choice-\(index)", icon: true)
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

    private func choice(_ label: String, value: String, id: String, icon: Bool = false) -> some View {
        Button {
            selection = value
            dismiss()
        } label: {
            HStack(spacing: 12) {
                if icon { CategoryIcon(name: value, size: 28) }
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

/// The category whose icon is being picked, as a sheet item (1.9).
private struct Picking: Identifiable {
    let id: String
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
    @AppStorage(Looks.iconsKey) private var iconsText = ""
    /// 1.9: the category whose icon is being picked.
    @State private var picking: String?

    private var names: [String] { CategoryList.decode(categoriesText) }

    var body: some View {
        List {
            Section {
                ForEach(Array(names.enumerated()), id: \.element) { index, name in
                    HStack(spacing: 12) {
                        // 1.9: the icon is its own button (tap = pick another); the rest of the row renames.
                        Button { picking = name } label: { CategoryIcon(name: name, size: 34) }
                            .buttonStyle(.borderless)
                            .accessibilityLabel("Icon for \(name)")
                            .accessibilityValue(CategoryLooks.look(for: name, custom: CategoryLooks.decode(iconsText)).symbol)
                            .accessibilityIdentifier("categories-icon-\(index)")
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
                        .buttonStyle(.borderless)
                        .accessibilityIdentifier("categories-row-\(index)")
                    }
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
                Text("The number is how many expenses have the category. Tap the icon to choose another one; tap the name to rename it. A new expense starts in the default one, unless its description had another category before.")
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
        .sheet(item: Binding(get: { picking.map(Picking.init) }, set: { picking = $0?.id })) { p in
            CategoryIconPicker(category: p.id)
        }
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
            iconsText = CategoryLooks.removed(iconsText, old)
            categoriesText = CategoryList.encode(names.filter { $0 != old })
            return
        }
        // 1.9: the icon moves with the name.
        let look = CategoryLooks.look(for: old, custom: CategoryLooks.decode(iconsText))
        iconsText = CategoryLooks.renamed(iconsText, from: old, to: name, keeping: look)
        for e in expenses where e.category == old { e.category = name }
        if defaultCategory == old { defaultCategory = name }
        categoriesText = CategoryList.encode(names.map { $0 == old ? name : $0 })
    }

    private func remove(_ name: String) {
        for e in expenses where e.category == name { e.category = "" }
        if defaultCategory == name { defaultCategory = "" }
        iconsText = CategoryLooks.removed(iconsText, name)
        categoriesText = CategoryList.encode(names.filter { $0 != name })
    }
}

/// Choosing who an expense was for (1.6): Martin, AMS, Anna (1.9) or Others, each with its
/// colour; a tap chooses and goes back.
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
                    HStack(spacing: 12) {
                        Circle().fill(Looks.consumer(name).fill).frame(width: 14, height: 14)
                            .accessibilityHidden(true)
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

/// Choosing the place visited (1.7): a line to type a new place, None, the places near this
/// expense's GPS fix (nearest first), then every other place used before (latest first).
/// No pop-up for the new name: a typing line at the top, which the UI tests can reach.
struct PlaceChooser: View {
    @Binding var selection: String
    let fix: Fix?
    let visits: [Visit]
    @Environment(\.dismiss) private var dismiss
    @State private var newName = ""

    private var lists: (near: [String], other: [String]) {
        var c = Places.choices(at: fix, history: visits)
        // A place typed on this sheet but not saved yet is still offered.
        if !selection.isEmpty, !(c.near + c.other).contains(where: { $0.lowercased() == selection.lowercased() }) {
            c.other.insert(selection, at: 0)
        }
        return c
    }

    private var trimmed: String { newName.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        let c = lists
        List {
            Section {
                HStack {
                    TextField("New place", text: $newName)
                        .submitLabel(.done)
                        .onSubmit { add(c) }
                        .accessibilityIdentifier("place-new-name")
                    Button("Add") { add(c) }
                        .buttonStyle(.borderless)
                        .disabled(trimmed.isEmpty)
                        .accessibilityIdentifier("place-new-add")
                }
                choice("None", value: "", id: "place-choice-none")
            } footer: {
                if fix == nil {
                    Text("No GPS position for this expense, so no places nearby.")
                }
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
        }
        .navigationTitle("Place")
        .navigationBarTitleDisplayMode(.inline)
    }

    /// A name already used (any spelling) is chosen, not added twice.
    private func add(_ c: (near: [String], other: [String])) {
        guard !trimmed.isEmpty else { return }
        selection = (c.near + c.other).first { $0.lowercased() == trimmed.lowercased() } ?? trimmed
        dismiss()
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

/// Settings › Places (1.7): every place used, A to Z, with how many expenses have it.
/// Tap = rename on its own screen (every expense follows; onto another place's name joins
/// the two); swipe = delete after asking (its expenses keep no place, the expenses stay).
/// There is no Add here: a place exists as long as an expense has it ("New place").
struct PlacesScreen: View {
    @Query private var expenses: [Expense]
    @State private var deleting: String?

    /// One name per place, any spelling: the spelling of its latest expense.
    private var names: [String] {
        let c = Places.choices(at: nil, history: expenses.map(\.visit))
        return (c.near + c.other).sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    private func with(_ name: String) -> [Expense] {
        expenses.filter { $0.visitedPlace.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == name.lowercased() }
    }

    var body: some View {
        List {
            Section {
                if names.isEmpty {
                    Text("No places yet. Type one under “New place” on the check sheet.")
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("places-empty")
                }
                ForEach(Array(names.enumerated()), id: \.element) { index, name in
                    NavigationLink {
                        PlaceRenameScreen(old: name) { rename(name, to: $0) }
                    } label: {
                        HStack {
                            Text(name)
                            Spacer()
                            Text("\(with(name).count)")
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityIdentifier("places-row-\(index)")
                }
                .onDelete { offsets in
                    guard let index = offsets.first else { return }
                    deleting = names[index]
                }
            } footer: {
                Text("The number is how many expenses have the place. Tap a place to rename it. Swipe to the left to delete it.")
            }
        }
        .navigationTitle("Places")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Delete this place?", isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } }),
                            titleVisibility: .visible) {
            Button("Delete place", role: .destructive) {
                if let name = deleting { for e in with(name) { e.visitedPlace = "" } }
                deleting = nil
            }
            .accessibilityIdentifier("places-delete-confirm")
            Button("Keep it", role: .cancel) { deleting = nil }
        } message: {
            Text("\(with(deleting ?? "").count) expenses will have no place. The expenses themselves stay.")
        }
    }

    private func rename(_ old: String, to new: String) {
        let name = new.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, name != old else { return }
        // Renaming onto another place's name joins the two, in that place's spelling.
        let target = names.first { $0 != old && $0.lowercased() == name.lowercased() } ?? name
        for e in with(old) { e.visitedPlace = target }
    }
}

/// Renaming one place: its name to change, Save (top right) or Back.
struct PlaceRenameScreen: View {
    let old: String
    let onSave: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""

    var body: some View {
        Form {
            Section {
                TextField("Name", text: $name)
                    .accessibilityIdentifier("places-rename-name")
            } footer: {
                Text("Every expense at this place moves with it.")
            }
        }
        .navigationTitle("Rename place")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { name = old }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    onSave(name)
                    dismiss()
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .accessibilityIdentifier("places-rename-save")
            }
        }
    }
}
