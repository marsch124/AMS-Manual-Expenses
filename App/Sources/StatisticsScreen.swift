import Charts
import ExpenseCore
import SwiftData
import SwiftUI

/// Statistics (1.2, Martin's four picks): week and month totals with the average per day,
/// a bar for each of the last 30 days, what he spends most on, and every earlier day.
/// Every sum is in kronor.
struct StatisticsScreen: View {
    @EnvironmentObject private var rates: ExchangeRates
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]

    private var spends: [Spend] { expenses.map(\.spend) }
    private var calendar: Calendar { .current }
    private var daily: [DayKronor] {
        Statistics.daily(spends, days: 30, now: Date(), rates: rates.table, calendar: calendar)
    }
    private var favourites: [Statistics.Favourite] {
        Statistics.favourites(spends, limit: 5, rates: rates.table, calendar: calendar)
    }
    private var earlierDays: [DayTotal] {
        Statistics.days(spends, rates: rates.table, calendar: calendar)
            .filter { !calendar.isDateInToday($0.day) }
    }
    private var ratesMissing: Bool {
        !Statistics.total(spends, rates: rates.table, calendar: calendar).unconverted.isEmpty
    }

    var body: some View {
        List {
            Section("Totals") {
                periodRow("This week", .thisWeek, id: "stats-week")
                periodRow("This month", .thisMonth, id: "stats-month")
                periodRow("Last month", .lastMonth, id: "stats-lastmonth")
            }
            Section("Last 30 days") {
                Chart(daily) { d in
                    BarMark(x: .value("Day", d.day, unit: .day), y: .value("Kronor", d.kronor))
                        .foregroundStyle(Color.accentColor)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                    }
                }
                .frame(height: 160)
                .padding(.vertical, 6)
                .accessibilityIdentifier("stats-chart")
            }
            Section("What you spend most on") {
                if favourites.isEmpty {
                    Text("Nothing yet.").foregroundStyle(.secondary)
                }
                ForEach(Array(favourites.enumerated()), id: \.element.title) { index, f in
                    HStack {
                        Text(f.title)
                        Spacer()
                        Text("\(f.count)× · \(Money.kronor(f.kronor))")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("stats-top-\(index)")
                }
            }
            Section {
                if earlierDays.isEmpty {
                    Text("No earlier days yet.").foregroundStyle(.secondary)
                }
                ForEach(Array(earlierDays.enumerated()), id: \.element.id) { index, d in
                    NavigationLink { DayScreen(day: d.day) } label: {
                        HStack {
                            Text(d.day, format: .dateTime.weekday(.abbreviated).day().month(.wide))
                            Spacer()
                            Text(Money.text(d.total))
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityIdentifier("stats-day-\(index)")
                }
            } header: {
                Text("Earlier days")
            } footer: {
                Text(ratesMissing
                     ? "Totals are in kronor. Some exchange rates are not here yet: the iPhone fetches them when it is online."
                     : "Totals are in kronor. Other currencies are counted at the European Central Bank's rate of their day.")
                    .accessibilityIdentifier("stats-rates-note")
            }
        }
        .navigationTitle("Statistics")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await rates.update(for: spends)
        }
    }

    private func periodRow(_ title: String, _ period: Statistics.Period, id: String) -> some View {
        let result = Statistics.total(spends, in: period, now: Date(), rates: rates.table, calendar: calendar)
        return HStack(alignment: .firstTextBaseline) {
            Text(title)
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(Money.text(result.total))
                    .monospacedDigit()
                    .accessibilityIdentifier("\(id)-total")
                Text("\(Money.kronor(result.perDay)) a day")
                    .font(.footnote)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("\(id)-perday")
            }
        }
    }
}

/// One earlier day: its expenses, to look at, change (tap) or delete (swipe).
struct DayScreen: View {
    let day: Date
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var rates: ExchangeRates
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @State private var draft: Draft?

    private var items: [Expense] { expenses.filter { Calendar.current.isDate($0.date, inSameDayAs: day) } }

    var body: some View {
        List {
            Section {
                if items.isEmpty {
                    Text("Nothing left on this day.").foregroundStyle(.secondary)
                }
                ForEach(Array(items.enumerated()), id: \.element.id) { index, expense in
                    Button { draft = Draft(editing: expense) } label: { ExpenseRow(expense: expense) }
                        .tint(.primary)
                        .accessibilityIdentifier("day-row-\(index)")
                }
                .onDelete { offsets in
                    let gone = offsets.map { items[$0] }
                    for item in gone { context.delete(item) }
                }
            } header: {
                HStack {
                    Text("Total")
                    Spacer()
                    Text(Money.text(Statistics.total(items.map(\.spend), rates: rates.table, calendar: .current)))
                        .accessibilityIdentifier("day-total")
                }
            }
        }
        .navigationTitle(day.formatted(.dateTime.weekday(.wide).day().month(.wide)))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $draft) { d in
            EntryEditor(
                draft: d,
                currencies: [homeCurrency, "EUR"],
                onSave: { d.expense?.apply($0) },
                onDelete: d.expense.map { e in { context.delete(e) } }
            )
        }
    }
}
