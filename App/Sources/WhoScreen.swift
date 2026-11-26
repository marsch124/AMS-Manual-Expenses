import ExpenseCore
import SwiftData
import SwiftUI

/// Settings › Who it was for (1.33): the three names on the buttons of the check sheet, in the
/// order and colours they have there (first blue, second yellow, third green; "Others" grey is
/// always the last and cannot be renamed). Renaming a name renames it in every expense too, so
/// the totals stay together. Cancel leaves everything as it was; Save is the full-colour button.
struct WhoScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @AppStorage(Consumers.key) private var namesText = ""
    @State private var names: [String] = []
    @State private var original: [String] = []

    private var changed: Bool { names != original }
    private var valid: Bool { WhoNames.isValid(names) }

    var body: some View {
        Form {
            Section {
                ForEach(0..<names.count, id: \.self) { i in
                    HStack(spacing: 10) {
                        Circle().fill(Looks.consumer(original[i]).fill).frame(width: 14, height: 14)
                        TextField("Name", text: $names[i])
                            .accessibilityIdentifier("who-name-\(i)")
                    }
                }
                HStack(spacing: 10) {
                    Circle().fill(Looks.consumer(WhoNames.others).fill).frame(width: 14, height: 14)
                    Text(WhoNames.others).foregroundStyle(.secondary)
                }
            } header: {
                Text("Who it was for")
            } footer: {
                Text(valid || !changed
                     ? "These are the buttons on the check sheet. A new expense starts with the first one. If you rename one, it is renamed in all your expenses too."
                     : "Every name needs some letters, no two can be the same, and “Others” is taken.")
                    .accessibilityIdentifier("who-footer")
            }
        }
        .navigationTitle("Who it was for")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
                    .accessibilityIdentifier("who-cancel")
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
                    .buttonStyle(.borderedProminent)
                    .disabled(!changed || !valid)
                    .accessibilityIdentifier("who-save")
            }
        }
        .onAppear {
            if names.isEmpty { names = Consumers.names; original = names }
        }
    }

    private func save() {
        let new = names.map { $0.trimmingCharacters(in: .whitespaces) }
        let map = WhoNames.renames(old: original, new: new)
        if !map.isEmpty, let all = try? context.fetch(FetchDescriptor<Expense>()) {
            // One look-up per expense, so two names swapped with each other stay right.
            for e in all { if let to = map[e.consumer] { e.consumer = to } }
            try? context.save()
        }
        namesText = WhoNames.encode(new)
        dismiss()
    }
}
