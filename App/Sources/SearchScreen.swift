import ExpenseCore
import SwiftData
import SwiftUI

/// 1.19: search every expense by what it was, a place, a category or who it was for.
struct ExpenseSearchScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var rates: ExchangeRates
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @State private var query = ""
    @State private var draft: Draft?

    private var found: [Expense] {
        expenses.filter {
            ExpenseSearch.matches(query: query,
                                  fields: [$0.title, $0.category, $0.visitedPlace, $0.place, $0.consumer, $0.heard])
        }
    }

    private var isBlank: Bool { query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var body: some View {
        let results = found
        List {
            if isBlank {
                Text("Type a word: what it was, a place, a category or who it was for.")
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("search-hint")
            } else if results.isEmpty {
                Text("Nothing found.")
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("search-empty")
            } else {
                Section {
                    ForEach(Array(results.enumerated()), id: \.element.id) { index, expense in
                        Button { draft = Draft(editing: expense) } label: { ExpenseRow(expense: expense, showsDate: true) }
                            .tint(.primary)
                            .accessibilityIdentifier("search-row-\(index)")
                    }
                } header: {
                    let total = Money.text(Statistics.total(results.map(\.spend), rates: rates.table, calendar: .current))
                    Text("\(results.count) \(results.count == 1 ? "expense" : "expenses") · \(total)")
                        .font(.footnote)
                        .textCase(nil)
                        .accessibilityIdentifier("search-summary")
                }
            }
        }
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search expenses")
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $draft) { d in
            EntryEditor(
                draft: d,
                currencies: [homeCurrency, "EUR"],
                visits: expenses.map(\.visit),
                onSave: { d.expense?.apply($0) },
                onDelete: d.expense.map { e in { context.delete(e) } }
            )
        }
    }
}
