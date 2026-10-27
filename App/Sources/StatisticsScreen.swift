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
    @State private var categorySpan: CategorySpan = .thisMonth
    @AppStorage(Looks.iconsKey) private var iconsText = ""

    /// The span the category totals cover (1.3).
    enum CategorySpan: String, CaseIterable, Identifiable {
        case thisWeek = "Week", thisMonth = "Month", lastMonth = "Last month", all = "All"
        var id: String { rawValue }
        var period: Statistics.Period? {
            switch self {
            case .thisWeek: .thisWeek
            case .thisMonth: .thisMonth
            case .lastMonth: .lastMonth
            case .all: nil
            }
        }
    }

    private var spends: [Spend] { expenses.map(\.spend) }
    private var categories: [CategoryTotal] {
        Statistics.byCategory(Statistics.inside(spends, categorySpan.period, now: Date(), calendar: calendar),
                              rates: rates.table, calendar: calendar)
    }
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
            Section("By category") {
                Picker("Span", selection: $categorySpan) {
                    ForEach(CategorySpan.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("stats-category-span")
                if categories.isEmpty {
                    Text("Nothing in this span.").foregroundStyle(.secondary)
                } else {
                    categoryRing
                }
                ForEach(Array(categories.enumerated()), id: \.element.id) { index, c in
                    NavigationLink {
                        ExpenseListScreen(title: c.name.isEmpty ? "No category" : c.name, showsDate: true) { e in
                            e.category == c.name && Statistics.inside([e.spend], categorySpan.period, now: Date(),
                                                                      calendar: calendar).count == 1
                        }
                    } label: {
                        HStack(spacing: 12) {
                            CategoryIcon(name: c.name, size: 28)
                            Text(c.name.isEmpty ? "No category" : c.name)
                            Spacer()
                            Text("\(c.count)× · \(Money.kronor(c.kronor))")
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityIdentifier("stats-category-\(index)")
                }
            }
            Section("Last 30 days") {
                Chart(daily) { d in
                    // 1.9: today's bar stronger than the others.
                    BarMark(x: .value("Day", d.day, unit: .day), y: .value("Kronor", d.kronor))
                        .foregroundStyle(calendar.isDateInToday(d.day) ? Color.accentColor : Color.accentColor.opacity(0.4))
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
                    NavigationLink {
                        ExpenseListScreen(title: d.day.formatted(.dateTime.weekday(.wide).day().month(.wide))) { e in
                            calendar.isDate(e.date, inSameDayAs: d.day)
                        }
                    } label: {
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

    /// 1.9: the span's categories as a ring, in their colours, the total in the middle.
    private var categoryRing: some View {
        let custom = CategoryLooks.decode(iconsText)
        let total: Double = categories.reduce(0.0) { $0 + $1.kronor }
        return Chart(categories) { c in
            SectorMark(angle: .value("Kronor", c.kronor), innerRadius: .ratio(0.62), angularInset: 1.5)
                .cornerRadius(3)
                .foregroundStyle(Looks.color(CategoryLooks.look(for: c.name, custom: custom).color))
        }
        .frame(height: 190)
        .overlay {
            VStack(spacing: 0) {
                Text(Money.kronor(total))
                    .font(.title3.bold())
                    .monospacedDigit()
                Text(categorySpan.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
        .accessibilityIdentifier("stats-category-ring")
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

/// A list of expenses — one earlier day, or one category — to look at, change (tap) or
/// delete (swipe).
struct ExpenseListScreen: View {
    let title: String
    /// A category's list spans many days, so its rows show the date too.
    var showsDate = false
    let include: (Expense) -> Bool
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var rates: ExchangeRates
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @State private var draft: Draft?

    private var items: [Expense] { expenses.filter(include) }

    var body: some View {
        List {
            Section {
                if items.isEmpty {
                    Text("Nothing left here.").foregroundStyle(.secondary)
                }
                ForEach(Array(items.enumerated()), id: \.element.id) { index, expense in
                    Button { draft = Draft(editing: expense) } label: { ExpenseRow(expense: expense, showsDate: showsDate) }
                        .tint(.primary)
                        .accessibilityIdentifier("list-row-\(index)")
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
                        .accessibilityIdentifier("list-total")
                }
            }
        }
        .navigationTitle(title)
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
