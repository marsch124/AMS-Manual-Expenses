import ExpenseCore
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @StateObject private var speech = SpeechRecognizer()
    @StateObject private var location = LocationService()
    @EnvironmentObject private var rates: ExchangeRates
    /// Empty means automatic (from location).
    @AppStorage("manualCurrency") private var manualCurrency = ""
    @AppStorage("dictationLanguage") private var language = "en-US"
    @AppStorage(CategoryList.defaultKey) private var defaultCategory = CategoryList.initialDefault
    @State private var typed = ""
    @State private var draft: Draft?
    @State private var showSettings = false
    @ObservedObject private var dictationRequest = DictationRequest.shared
    /// UI tests cannot use the microphone: there a request is only counted (`home-dictate` value).
    @State private var testRequests = 0
    /// 1.9: counts saves, for the little vibration and the "Saved" check mark.
    @State private var saves = 0
    @State private var showSaved = false
    /// 1.25: which small card is open below (one at a time); all closed when the app starts.
    @State private var openTile: DayTile.Kind?
    /// 1.19: the expense just deleted, for the Undo bar.
    @State private var deleted: DeletedExpense?
    /// 1.19: the weekly budget in kronor from Settings; 0 = none.
    @AppStorage("weeklyBudget") private var weeklyBudget = 0.0

    private var autoCurrency: String {
        location.currency ?? CurrencyDefaults.currency(forTimeZone: TimeZone.current.identifier) ?? "SEK"
    }
    private var defaultCurrency: String { manualCurrency.isEmpty ? autoCurrency : manualCurrency }
    private var currencyOptions: [String] {
        ["SEK", "EUR"].contains(autoCurrency) ? ["SEK", "EUR"] : ["SEK", "EUR", autoCurrency]
    }
    private var todays: [Expense] { expenses.filter { Calendar.current.isDateInToday($0.date) } }
    /// 1.12: yesterday's expenses, newest first, for the folded Yesterday section.
    private var yesterdays: [Expense] { expenses.filter { Calendar.current.isDateInYesterday($0.date) } }
    /// 1.19: "· SEK 766 left", or "· SEK 120 over" in orange; nothing without a budget.
    private var budgetNote: Text {
        let spent: Double = Statistics.total(thisWeeks.map(\.spend), rates: rates.table, calendar: .current).kronor
        guard let left = Budget.left(budget: weeklyBudget, spent: spent) else { return Text("") }
        return left >= 0 ? Text(" · \(Money.kronor(left)) left")
                         : Text(" · \(Money.kronor(-left)) over").foregroundColor(.orange)
    }

    /// 1.19: up to three descriptions logged at least three times — each one's latest expense.
    private var favourites: [Expense] {
        Statistics.favourites(expenses.map(\.spend), limit: 3, rates: rates.table, calendar: .current)
            .filter { $0.count >= 3 }
            .compactMap { f in
                expenses.filter { $0.title.trimmingCharacters(in: .whitespaces).lowercased() == f.title.lowercased() }
                    .max { $0.date < $1.date }
            }
    }

    /// 1.19: delete, and keep what it was for the Undo bar (6 s).
    private func remove(_ e: Expense) {
        let gone = DeletedExpense(e)
        context.delete(e)
        withAnimation { deleted = gone }
        Task {
            try? await Task.sleep(for: .seconds(ExpensesApp.uiTesting ? 20 : 6))
            if deleted?.id == gone.id { withAnimation { deleted = nil } }
        }
    }

    /// 1.18: this week's expenses, Monday to now.
    private var thisWeeks: [Expense] {
        let week = Statistics.range(.thisWeek, now: Date(), calendar: .current).interval
        return expenses.filter { $0.date >= week.start && $0.date < week.end }
    }
    /// 1.16: last week's expenses (Monday to Sunday before this week).
    private var lastWeeks: [Expense] {
        let week = Statistics.range(.lastWeek, now: Date(), calendar: .current).interval
        return expenses.filter { $0.date >= week.start && $0.date < week.end }
    }
    private var lastWeekTotal: String {
        Money.text(Statistics.total(lastWeeks.map(\.spend), rates: rates.table, calendar: .current), whole: true)
    }

    var body: some View {
        NavigationStack {
            List {
                Section { header }
                Section {
                    dictation
                    // 1.19 (his pick): the descriptions logged most often, one tap each.
                    if !favourites.isEmpty {
                        HStack(spacing: 8) {
                            ForEach(Array(favourites.enumerated()), id: \.element.id) { index, e in
                                Button(e.title) { sameAgain(e) }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                    .lineLimit(1)
                                    .accessibilityIdentifier("favourite-\(index)")
                            }
                            Spacer(minLength: 0)
                        }
                        .listRowInsets(EdgeInsets(top: 2, leading: 16, bottom: 6, trailing: 16))
                        .listRowSeparator(.hidden)
                    }
                }
                Section {
                    if todays.isEmpty {
                        Text("No expenses yet today.").foregroundStyle(.secondary)
                            .accessibilityIdentifier("today-empty")
                    } else {
                        // 1.9: the Today card — today's total, big, and how many;
                        // 1.10 (his pick B): this week's days as small bars on the right.
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(todayTotal)
                                    .font(.system(size: 34, weight: .bold, design: .rounded))
                                    .monospacedDigit()
                                    .minimumScaleFactor(0.6)
                                    .lineLimit(1)
                                    .accessibilityIdentifier("today-total")
                                Text(todays.count == 1 ? "1 expense" : "\(todays.count) expenses")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .accessibilityIdentifier("today-count")
                            }
                            Spacer(minLength: 12)
                            WeekBars(days: weekDays)
                        }
                        // 1.11 (his ask): tight — no extra space, and no "This week" line under the card.
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    }
                    ForEach(Array(todays.enumerated()), id: \.element.id) { index, expense in
                        Button { draft = Draft(editing: expense) } label: { ExpenseRow(expense: expense) }
                            .tint(.primary)
                            // 1.11 (his ask): slimmer rows.
                            .listRowInsets(EdgeInsets(top: 3, leading: 16, bottom: 3, trailing: 16))
                            .accessibilityIdentifier("expense-row-\(index)")
                            // 1.9: swipe to the right = log the same one again now.
                            .swipeActions(edge: .leading) {
                                Button { sameAgain(expense) } label: {
                                    Label("Same again", systemImage: "arrow.clockwise")
                                }
                                .tint(.accentColor)
                                .accessibilityIdentifier("row-same-again")
                            }
                            // A row with its own swipe actions loses the automatic Delete: so it is here too.
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) { remove(expense) } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                    .onDelete { offsets in
                        let items = offsets.map { todays[$0] }
                        for item in items { remove(item) }
                    }
                } header: {
                    Text("Today")
                }
                // 1.25 (his pick 2 of 3, and "keep them under today's expenses"): three small cards on
                // one line — Yesterday, This week, Last week. A tap opens that one's expenses below it,
                // one at a time; a second tap closes. (1.12–1.24: three quiet fold-open lines.)
                Section {
                    HStack(spacing: 8) {
                        DayTile(kind: .yesterday, total: Money.text(Statistics.total(yesterdays.map(\.spend), rates: rates.table, calendar: .current), whole: true),
                                count: yesterdays.count, days: nil, isOpen: openTile == .yesterday) { toggle(.yesterday) }
                        DayTile(kind: .thisWeek, total: Money.text(Statistics.total(thisWeeks.map(\.spend), rates: rates.table, calendar: .current), whole: true),
                                count: thisWeeks.count, days: weekDays, isOpen: openTile == .thisWeek) { toggle(.thisWeek) }
                        DayTile(kind: .lastWeek, total: lastWeekTotal, count: lastWeeks.count,
                                days: weekDays(containing: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()),
                                isOpen: openTile == .lastWeek) { toggle(.lastWeek) }
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 2, leading: 0, bottom: 2, trailing: 0))
                }
                if let open = openTile {
                    Section {
                        if open != .yesterday {
                            let items = open == .thisWeek ? thisWeeks : lastWeeks
                            // 1.24: the swatch explains the tinted top five; 1.19: the budget on this week.
                            HStack(spacing: 6) {
                                (Text(items.count == 1 ? "1 expense" : "\(items.count) expenses") + (open == .thisWeek ? budgetNote : Text("")))
                                    .accessibilityIdentifier("\(open.id)-count")
                                Spacer(minLength: 4)
                                if items.count > 5 { TopFiveNote(name: open.id) }
                            }
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        }
                        let rows = open == .yesterday ? yesterdays : (open == .thisWeek ? thisWeeks : lastWeeks).sorted { $0.date > $1.date }
                        // 1.23 (his ask): a week's five highest get a light teal row.
                        let top = open == .yesterday ? Set<Int>() : Statistics.highest(rows.map(\.spend), rates: rates.table, calendar: .current)
                        ForEach(Array(rows.enumerated()), id: \.element.id) { index, expense in
                            Button { draft = Draft(editing: expense) } label: {
                                // 1.20/1.21: the week lists show whole amounts and the weekday.
                                ExpenseRow(expense: expense, wholeAmount: open != .yesterday, showsWeekday: open != .yesterday)
                            }
                                .tint(.primary)
                                .listRowInsets(EdgeInsets(top: 3, leading: 16, bottom: 3, trailing: 16))
                                .topFiveTint(top.contains(index))
                                .accessibilityIdentifier("\(open.id)-row-\(index)")
                                // 1.19 (his pick): Same again on older rows too.
                                .swipeActions(edge: .leading) {
                                    Button { sameAgain(expense) } label: {
                                        Label("Same again", systemImage: "arrow.clockwise")
                                    }
                                    .tint(.accentColor)
                                }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) { remove(expense) } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
            }
            // 1.11 (his ask): less space between the parts of the screen and between rows.
            .listSectionSpacing(.compact)
            .environment(\.defaultMinListRowHeight, 34)
            .navigationTitle("Expenses")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Picker("Dictation language", selection: $language) {
                            Text("English").tag("en-US")
                            Text("Svenska").tag("sv-SE")
                            Text("Deutsch").tag("de-DE")
                        }
                    } label: {
                        Image(systemName: "globe")
                    }
                    .accessibilityIdentifier("home-language")
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    // 1.8: today's expenses on a map (concept B).
                    NavigationLink { TodayMapScreen(all: expenses) } label: {
                        Image(systemName: "map")
                    }
                    .accessibilityLabel("On the map")
                    .accessibilityIdentifier("home-map")
                    NavigationLink { StatisticsScreen() } label: {
                        Image(systemName: "chart.bar")
                    }
                    .accessibilityLabel("Statistics")
                    .accessibilityIdentifier("home-statistics")
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                    .accessibilityIdentifier("home-settings")
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsScreen(csv: csv)
            }
            .sheet(item: $draft) { d in
                EntryEditor(
                    draft: d,
                    currencies: currencyOptions,
                    visits: expenses.map(\.visit),
                    onSave: save,
                    onDelete: d.expense.map { e in { remove(e) } },
                    onSameAgain: d.expense.map { e in { sameAgain(e) } }
                )
            }
        }
        // 1.19 (his pick): Undo after a delete, a small bar at the bottom.
        .overlay(alignment: .bottom) {
            if let gone = deleted {
                HStack(spacing: 12) {
                    Text("Deleted \(gone.title)")
                        .lineLimit(1)
                        .accessibilityIdentifier("undo-text")
                    Spacer(minLength: 8)
                    Button {
                        context.insert(gone.restored())
                        withAnimation { deleted = nil }
                    } label: {
                        Text("Undo")
                            .fontWeight(.semibold)
                            .padding(.horizontal, 14)
                            .frame(minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .highPriorityGesture(TapGesture().onEnded {
                        context.insert(gone.restored())
                        withAnimation { deleted = nil }
                    })
                    .accessibilityIdentifier("undo-button")
                }
                .font(.subheadline)
                .foregroundStyle(.white)
                .padding(.leading, 16)
                .padding(.trailing, 2)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.accentColor))
                .shadow(radius: 4)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        // 1.9: a short vibration and a check mark when an expense is saved.
        .sensoryFeedback(.success, trigger: saves)
        .overlay(alignment: .top) {
            if showSaved {
                Label("Saved", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color.accentColor))
                    .shadow(radius: 4)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .accessibilityIdentifier("home-saved")
            }
        }
        .onAppear {
            speech.onFinish = { handle($0) }
            if !ExpensesApp.uiTesting { location.refresh() }
            if ExpensesApp.uiTesting && ProcessInfo.processInfo.arguments.contains("-uiTestingDictateRequest") {
                dictationRequest.pending = true
            }
            takeDictationRequest()
        }
        .onChange(of: dictationRequest.pending) { _, _ in takeDictationRequest() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active && !ExpensesApp.uiTesting { location.refresh() }
        }
        .task(id: expenses.count) {
            await rates.update(for: expenses.map(\.spend))
        }
    }

    /// 1.11 (his ask "tighten things up"): one block — the time, under it the date and the place
    /// on one grey line, the currency on the right.
    /// 1.32 (his ask): the currency sits beside the time only, so the date and place line has the
    /// whole width of the card. Before, the currency stood beside both lines and the line was cut
    /// off ("Sun, 22… · Benalm…"). The date never shrinks; only a very long place is shortened.
    private var header: some View {
        TimelineView(.everyMinute) { context in
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .center, spacing: 8) {
                    Text(context.date, format: .dateTime.hour().minute())
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    Spacer(minLength: 0)
                    currencyButton
                }
                HStack(spacing: 4) {
                    Text(context.date, format: .dateTime.weekday(.abbreviated).day().month(.abbreviated))
                        .fixedSize()
                        .accessibilityIdentifier("home-date")
                    Text("·")
                    Image(systemName: "location.fill").font(.caption2)
                    Text(location.placeName ?? TimeZone.current.identifier)
                        .truncationMode(.tail)
                        .accessibilityIdentifier("home-place")
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }
        }
        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
    }

    private var currencyButton: some View {
        Menu {
            Picker("Currency", selection: $manualCurrency) {
                Text("Automatic (\(autoCurrency))").tag("")
                ForEach(currencyOptions, id: \.self) { Text($0).tag($0) }
            }
        } label: {
            Text(manualCurrency.isEmpty ? "\(defaultCurrency) · auto" : defaultCurrency)
                .bold()
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color.accentColor.opacity(0.15)))
        }
        .font(.subheadline)
        .fixedSize()
        .accessibilityIdentifier("home-currency")
    }

    /// 1.11 (his ask "tighten things up"): the microphone on the left, the typing field beside it.
    private var dictation: some View {
        HStack(alignment: .center, spacing: 12) {
            Button {
                // 1.7: a fresh GPS fix while he speaks, for the expense he is about to log.
                if !speech.isRecording && !ExpensesApp.uiTesting { location.refresh() }
                speech.toggle(localeID: language)
            } label: {
                Image(systemName: speech.isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.white)
                    .frame(width: 64, height: 64)
                    .background(Circle().fill(speech.isRecording ? Color.red : Color.accentColor))
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(speech.isRecording ? "Stop" : "Dictate expense")
            .accessibilityIdentifier("home-dictate")
            .accessibilityValue(ExpensesApp.uiTesting ? "requests \(testRequests)" : "")

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    TextField("…or type an expense", text: $typed)
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.done)
                        .onSubmit { handle(typed) }
                        .accessibilityIdentifier("home-type-field")
                    Button("Go") { handle(typed) }
                        .buttonStyle(.borderless)
                        .disabled(typed.trimmingCharacters(in: .whitespaces).isEmpty)
                        .accessibilityIdentifier("home-type-go")
                }
                // 1.4 (his ask): no hint any more — the line is there only while listening or for an error.
                if !statusText.isEmpty {
                    Text(statusText)
                        .font(.footnote)
                        .foregroundStyle(speech.errorMessage == nil ? Color.secondary : Color.red)
                        .lineLimit(3)
                        .accessibilityIdentifier("home-status")
                }
            }
        }
        .frame(maxWidth: .infinity)
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
    }

    private var statusText: String {
        if let error = speech.errorMessage { return error }
        if speech.isRecording { return speech.transcript.isEmpty ? "Listening…" : speech.transcript }
        return ""
    }

    /// 1.10: this week, Monday (the iPhone's first weekday) to Sunday, in kronor per day.
    private var weekDays: [WeekBars.Day] { weekDays(containing: Date()) }

    /// 1.22: the seven days of the week that holds `date` (this week or last week).
    private func weekDays(containing date: Date) -> [WeekBars.Day] {
        let calendar = Calendar.current
        guard let week = calendar.dateInterval(of: .weekOfYear, for: date) else { return [] }
        let spends = expenses.map(\.spend)
        return (0..<7).compactMap { offset -> WeekBars.Day? in
            guard let day = calendar.date(byAdding: .day, value: offset, to: week.start) else { return nil }
            let inDay = spends.filter { calendar.isDate($0.date, inSameDayAs: day) }
            let kronor: Double = Statistics.total(inDay, rates: rates.table, calendar: calendar).kronor
            return WeekBars.Day(date: day, kronor: kronor,
                                isToday: calendar.isDateInToday(day), isFuture: day > Date() && !calendar.isDateInToday(day))
        }
    }

    /// 1.25: a tap on a small card opens it (closing another); a tap on the open one closes it.
    private func toggle(_ kind: DayTile.Kind) {
        withAnimation { openTile = openTile == kind ? nil : kind }
    }

    /// Today's total in kronor (1.2: other currencies at the bank's rate of their day).
    private var todayTotal: String {
        todays.isEmpty ? "" : Money.text(Statistics.total(todays.map(\.spend), rates: rates.table, calendar: .current))
    }

    private var csv: String {
        let dateFormat = DateFormatter()
        dateFormat.dateFormat = "yyyy-MM-dd"
        let timeFormat = DateFormatter()
        timeFormat.dateFormat = "HH:mm"
        func quote(_ s: String) -> String { "\"" + s.replacingOccurrences(of: "\"", with: "\"\"") + "\"" }
        func coordinate(_ value: Double?) -> String { value.map { String(format: "%.6f", $0) } ?? "" }
        var lines = ["Date,Time,Description,Category,Consumer,Place visited,Amount,Currency,Place,Time zone,Latitude,Longitude"]
        for e in expenses.reversed() {
            let tz = TimeZone(identifier: e.timeZoneID) ?? .current
            dateFormat.timeZone = tz
            timeFormat.timeZone = tz
            lines.append([dateFormat.string(from: e.date), timeFormat.string(from: e.date), e.title, e.category, e.consumer, e.visitedPlace,
                          String(format: "%.2f", e.amount), e.currency, e.place, e.timeZoneID,
                          coordinate(e.latitude), coordinate(e.longitude)].map(quote).joined(separator: ","))
        }
        return lines.joined(separator: "\n")
    }

    /// The Shortcuts action (or the Action button) asked to dictate: start listening at once.
    private func takeDictationRequest() {
        guard dictationRequest.pending else { return }
        dictationRequest.pending = false
        draft = nil
        showSettings = false
        if ExpensesApp.uiTesting {
            testRequests += 1
            return
        }
        // A moment for the app to be fully on screen after it was opened by the action.
        Task {
            try? await Task.sleep(for: .milliseconds(400))
            if !speech.isRecording { speech.toggle(localeID: language) }
        }
    }

    private func handle(_ text: String) {
        let sentence = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sentence.isEmpty else { return }
        let parsed = ExpenseParser.parse(sentence, defaultCurrency: defaultCurrency)
        let fix = location.fix
        let near = Places.nearest(at: fix, history: expenses.map(\.visit))
        draft = Draft(title: parsed.title, amountText: parsed.amount.map(Draft.format) ?? "",
                      currency: parsed.currency, date: parsed.date, heard: sentence,
                      category: Categories.initial(for: parsed.title, history: expenses.map(\.spend),
                                                   default: defaultCategory),
                      visitedPlace: near?.place ?? "",
                      fix: fix, area: location.placeName ?? "",
                      autoPlace: near?.place ?? "", autoPlaceMetres: near?.metres)
        typed = ""
    }

    /// 1.9: the same expense again, now and here — opened for checking like any new one.
    private func sameAgain(_ e: Expense) {
        let fix = location.fix
        draft = Draft(title: e.title, amountText: Draft.format(e.amount), currency: e.currency, date: Date(),
                      heard: "", category: e.category, consumer: e.consumer, visitedPlace: e.visitedPlace,
                      fix: fix, area: location.placeName ?? "")
    }

    private func save(_ d: Draft) {
        guard let amount = d.amount else { return }
        saves += 1
        withAnimation { showSaved = true }
        let shown = saves
        Task {
            // Long enough to see; in UI tests longer, so GitHub's slow simulator can catch it.
            try? await Task.sleep(for: .seconds(ExpensesApp.uiTesting ? 15 : 2.5))
            if saves == shown { withAnimation { showSaved = false } }
        }
        let title = d.title.trimmingCharacters(in: .whitespaces).isEmpty ? "Expense" : d.title
        if let e = d.expense {
            e.apply(d)
        } else {
            let e = Expense(title: title, amount: amount, currency: d.currency, date: d.date,
                            place: location.placeName ?? "", heard: d.heard, category: d.category, consumer: d.consumer,
                            fix: d.fix, visitedPlace: d.visitedPlace)
            e.photo = d.photo
            e.photoThumb = d.photoThumb
            context.insert(e)
        }
    }
}

struct ExpenseRow: View {
    let expense: Expense
    var showsDate = false
    /// 1.20 (his ask): the This week and Last week lists show €10, not €10,00.
    var wholeAmount = false
    /// 1.21 (his yes): the week lists say which day — "Wed 10:24".
    var showsWeekday = false
    @EnvironmentObject private var rates: ExchangeRates

    /// 1.9: "≈ SEK 125" under an amount in another currency, at its day's rate.
    private var kronorText: String? {
        guard expense.currency != homeCurrency,
              let kronor = rates.table.kronor(expense.spend, calendar: .current) else { return nil }
        return "≈ " + Money.kronor(kronor)
    }

    private var when: String {
        if showsDate { return expense.date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).hour().minute()) }
        if showsWeekday {
            return expense.date.formatted(.dateTime.weekday(.abbreviated)) + " " + expense.date.formatted(.dateTime.hour().minute())
        }
        return expense.date.formatted(.dateTime.hour().minute())
    }

    var body: some View {
        HStack(spacing: 10) {
            CategoryIcon(name: expense.category, size: 26)
            VStack(alignment: .leading, spacing: 1) {
                Text(expense.title)
                HStack(spacing: 6) {
                    Text(expense.category.isEmpty ? when : when + " · " + expense.category)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ConsumerTag(name: expense.consumer)
                }
            }
            Spacer()
            // 1.13: a small copy of its photo.
            if let thumb = expense.photoThumb, let image = UIImage(data: thumb) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 30, height: 30)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .accessibilityLabel("Photo")
            }
            VStack(alignment: .trailing, spacing: 0) {
                Group {
                    if wholeAmount {
                        Text(WholeAmount.rounded(expense.amount), format: .currency(code: expense.currency).precision(.fractionLength(0)))
                    } else {
                        Text(expense.amount, format: .currency(code: expense.currency))
                    }
                }
                    .bold()
                    .monospacedDigit()
                if let kronorText {
                    Text(kronorText)
                        .font(.caption)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct EntryEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: Draft
    @State private var showWhen = false
    @State private var pickedDate = Date()
    private let currencies: [String]
    private let visits: [Visit]
    private let onSave: (Draft) -> Void
    private let onDelete: (() -> Void)?
    /// 1.9: an existing expense can be logged again now (main screen only: it needs the location).
    private let onSameAgain: (() -> Void)?

    init(draft: Draft, currencies: [String], visits: [Visit], onSave: @escaping (Draft) -> Void, onDelete: (() -> Void)?,
         onSameAgain: (() -> Void)? = nil) {
        self.onSameAgain = onSameAgain
        _draft = State(initialValue: draft)
        self.currencies = currencies
        self.visits = visits
        self.onSave = onSave
        self.onDelete = onDelete
    }

    private var options: [String] {
        currencies.contains(draft.currency) ? currencies : currencies + [draft.currency]
    }

    /// A small tinted label, like the currency on the main screen (category, consumer).
    private func pill(_ text: String, filled: Bool, color: Color = .accentColor) -> some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(filled ? color : Color.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(Capsule().fill(filled ? color.opacity(0.15) : Color.secondary.opacity(0.12)))
    }

    private var mapAmount: String {
        guard let amount = draft.amount else { return draft.amountText }
        return amount.formatted(.currency(code: draft.currency))
    }

    private func whenLabel(_ text: String) -> some View {
        Text(text)
            .monospacedDigit()
            .foregroundStyle(.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(Color.secondary.opacity(0.08)))
    }

    var body: some View {
        NavigationStack {
            Form {
                if !draft.heard.isEmpty {
                    Section("Heard") {
                        // 1.4: a slim line (his ask: "the heard pill is too high").
                        Text(draft.heard).italic()
                            .foregroundStyle(.secondary)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            .accessibilityIdentifier("entry-heard")
                    }
                }
                Section {
                    TextField("Description", text: $draft.title)
                        .accessibilityIdentifier("entry-title")
                    HStack {
                        TextField("Amount", text: $draft.amountText)
                            .keyboardType(.decimalPad)
                            .font(.title3.weight(.semibold))
                            .monospacedDigit()
                            .accessibilityIdentifier("entry-amount")
                        Picker("Currency", selection: $draft.currency) {
                            ForEach(options, id: \.self) { Text($0).tag($0) }
                        }
                        .labelsHidden()
                        .fixedSize()
                        .accessibilityIdentifier("entry-currency")
                    }
                    // 1.4 (his ask): no "Time" word, the date and time on the left.
                    // 1.4: quiet labels instead of the system's grey pills (his ask); a tap
                    // opens the calendar with the time underneath.
                    Button {
                        pickedDate = draft.date
                        showWhen = true
                    } label: {
                        HStack(spacing: 8) {
                            whenLabel(draft.date.formatted(.dateTime.day().month(.abbreviated).year()))
                            whenLabel(draft.date.formatted(.dateTime.hour().minute()))
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("entry-time")
                    .sheet(isPresented: $showWhen) {
                        NavigationStack {
                            DatePicker("Time", selection: $pickedDate)
                                .datePickerStyle(.graphical)
                                .labelsHidden()
                                .padding(.horizontal)
                                .accessibilityIdentifier("entry-time-picker")
                                .navigationTitle("Date and time")
                                .navigationBarTitleDisplayMode(.inline)
                                .toolbar {
                                    ToolbarItem(placement: .cancellationAction) {
                                        Button("Cancel") { showWhen = false }
                                            .accessibilityIdentifier("entry-time-cancel")
                                    }
                                    ToolbarItem(placement: .confirmationAction) {
                                        Button("Done") {
                                            draft.date = pickedDate
                                            showWhen = false
                                        }
                                        .accessibilityIdentifier("entry-time-done")
                                    }
                                }
                        }
                        .presentationDetents([.large])
                    }
                    // 1.4 (his ask): the category last, without the word "Category".
                    NavigationLink { CategoryChooser(selection: $draft.category) } label: {
                        HStack(spacing: 10) {
                            CategoryIcon(name: draft.category, size: 28)
                            pill(draft.category.isEmpty ? "No category" : draft.category, filled: !draft.category.isEmpty)
                                .accessibilityIdentifier("entry-category-value")
                        }
                    }
                    .accessibilityIdentifier("entry-category")
                    // 1.6 (his ask): who it was for, under the category. 1.31 (his ask): four buttons on
                    // one line, one tap chooses — no list to open any more.
                    ConsumerButtons(selection: $draft.consumer)
                    // 1.7 (his ask): the place visited, a pill like the others; the places near
                    // this expense's GPS fix come first in the chooser.
                    NavigationLink { PlaceChooser(selection: $draft.visitedPlace, fix: draft.fix, visits: visits) } label: {
                        HStack {
                            pill(draft.visitedPlace.isEmpty ? "No place" : draft.visitedPlace, filled: !draft.visitedPlace.isEmpty)
                                .accessibilityIdentifier("entry-place-value")
                            Spacer()
                            // 1.8: says when the app filled the place in by itself, and how near.
                            if !draft.autoPlace.isEmpty, draft.visitedPlace == draft.autoPlace, let m = draft.autoPlaceMetres {
                                Text("auto · \(Int(m.rounded())) m away")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .accessibilityIdentifier("entry-place-auto")
                            }
                        }
                    }
                    .accessibilityIdentifier("entry-place")
                    // 1.8 (concept A): a small map of where it was logged; a tap opens the big one (C).
                    if let fix = draft.fix {
                        NavigationLink {
                            ExpenseMapScreen(title: draft.title, amount: mapAmount, date: draft.date, area: draft.area,
                                             place: draft.visitedPlace, fix: fix)
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                FixPreview(fix: fix)
                                Label([draft.area, fix.accuracyText ?? ""].filter { !$0.isEmpty }.joined(separator: " · ")
                                          .ifEmpty("Where it was logged"), systemImage: "mappin.and.ellipse")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .accessibilityIdentifier("entry-map-caption")
                            }
                            .padding(.vertical, 4)
                        }
                        .accessibilityIdentifier("entry-map")
                    }
                }
                // 1.13 (his ask): one photo — the receipt or what was bought.
                PhotoSection(photo: $draft.photo, thumb: $draft.photoThumb)
                if let onDelete {
                    Section {
                        if let onSameAgain {
                            // The new draft replaces this sheet with a fresh one.
                            Button { onSameAgain() } label: {
                                Label("Same again, now", systemImage: "arrow.clockwise")
                            }
                            .accessibilityIdentifier("entry-same-again")
                        }
                        Button("Delete expense", role: .destructive) {
                            onDelete()
                            dismiss()
                        }
                        .accessibilityIdentifier("entry-delete")
                    }
                }
            }
            // Lets the Heard line be slimmer than a normal row, and the sections sit closer.
            .environment(\.defaultMinListRowHeight, 30)
            .listSectionSpacing(.compact)
            .navigationTitle(draft.expense == nil ? "New expense" : "Edit expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityIdentifier("entry-cancel")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(draft)
                        dismiss()
                    }
                    .disabled(draft.amount == nil)
                    .accessibilityIdentifier("entry-save")
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

struct CSVExport: Transferable {
    let csv: String

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .commaSeparatedText) { item in
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("Expenses.csv")
            try item.csv.write(to: url, atomically: true, encoding: .utf8)
            return SentTransferredFile(url)
        }
    }
}

extension String {
    func ifEmpty(_ fallback: String) -> String { isEmpty ? fallback : self }
}

extension View {
    /// 1.23 (his ask): a week's five highest expenses get a light teal row, like a highlighter.
    /// The value says "Top five" so the screen tests (and VoiceOver) can find them.
    @ViewBuilder func topFiveTint(_ on: Bool) -> some View {
        if on {
            self.listRowBackground(Color.accentColor.opacity(0.14))
                .accessibilityValue("Top five")
        } else {
            self
        }
    }
}

/// 1.25 (his pick 2 of 3): one of the three small cards under today's expenses — its name in
/// its own colour, the total in whole kronor, and the count (Yesterday) or seven tiny day bars
/// (the weeks). The open one is full colour with white writing; an empty one does nothing.
struct DayTile: View {
    enum Kind: String {
        case yesterday = "Yesterday", thisWeek = "This week", lastWeek = "Last week"
        var id: String {
            switch self {
            case .yesterday: "yesterday"
            case .thisWeek: "this-week"
            case .lastWeek: "last-week"
            }
        }
        var color: Color {
            switch self {
            case .yesterday: .orange
            case .thisWeek: .accentColor
            case .lastWeek: .indigo
            }
        }
    }

    let kind: Kind
    let total: String
    let count: Int
    let days: [WeekBars.Day]?
    let isOpen: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 1) {
                Text(kind.rawValue)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(isOpen ? Color.white : kind.color)
                Text(total)
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .monospacedDigit()
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .foregroundStyle(isOpen ? Color.white : Color.primary)
                if let days {
                    MiniBars(days: days, color: isOpen ? .white : kind.color)
                } else {
                    Text(count == 1 ? "1 expense" : "\(count) expenses")
                        .font(.caption)
                        .foregroundStyle(isOpen ? Color.white.opacity(0.85) : Color.secondary)
                        .frame(height: 16, alignment: .bottomLeading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 9)
            .padding(.vertical, 7)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(isOpen ? kind.color : Color(.secondarySystemGroupedBackground)))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(count == 0)
        .opacity(count == 0 ? 0.5 : 1)
        .accessibilityLabel("\(kind.rawValue), \(total)")
        .accessibilityValue(count == 1 ? "1 expense" : "\(count) expenses")
        .accessibilityAddTraits(isOpen ? .isSelected : [])
        .accessibilityIdentifier("day-tile-\(kind.id)")
    }
}

/// 1.25: the week's seven days as tiny bars inside a small card (Monday first).
struct MiniBars: View {
    let days: [WeekBars.Day]
    let color: Color

    var body: some View {
        let top: Double = max(days.map(\.kronor).max() ?? 0, 1)
        HStack(alignment: .bottom, spacing: 3) {
            ForEach(days) { day in
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(color.opacity(day.isFuture || day.kronor == 0 ? 0.25 : 0.55))
                    .frame(width: 6, height: day.kronor > 0 ? max(3, CGFloat(day.kronor / top) * 16) : 2)
            }
        }
        .frame(height: 16, alignment: .bottom)
    }
}

/// 1.24 (his yes): "▭ = the 5 highest" — the screen says what the tinted rows are.
struct TopFiveNote: View {
    let name: String

    var body: some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.accentColor.opacity(0.14))
                .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.accentColor.opacity(0.4), lineWidth: 0.5))
                .frame(width: 16, height: 10)
            Text("= the 5 highest")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("\(name)-top-note")
    }
}

/// 1.10: the week's seven small bars on the Today card — today in full colour, earlier days
/// lighter, days still to come a grey stub; each bar's height is its day's share of the
/// week's highest day.
struct WeekBars: View {
    struct Day: Identifiable {
        let date: Date
        let kronor: Double
        let isToday: Bool
        let isFuture: Bool
        var id: Date { date }
    }

    let days: [Day]
    var label = "This week by day"
    var identifier = "today-week-bars"
    private let barHeight: CGFloat = 52

    var body: some View {
        let top: Double = max(days.map(\.kronor).max() ?? 0, 1)
        HStack(alignment: .bottom, spacing: 6) {
            ForEach(days) { day in
                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color(day))
                        .frame(width: 11, height: height(day, top: top))
                        .frame(height: barHeight, alignment: .bottom)
                    Text(day.date.formatted(.dateTime.weekday(.narrow)))
                        .font(.system(size: 10, weight: day.isToday ? .bold : .regular))
                        .foregroundStyle(day.isToday ? Color.accentColor : Color.secondary)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(days.map { "\($0.date.formatted(.dateTime.weekday(.abbreviated))) \(Money.kronor($0.kronor))" }
            .joined(separator: ", "))
        .accessibilityIdentifier(identifier)
    }

    private func height(_ day: Day, top: Double) -> CGFloat {
        guard day.kronor > 0 else { return 4 }
        let share: Double = day.kronor / top
        return max(6, CGFloat(share) * barHeight)
    }

    /// 1.23 (his ask): today's bar is as light as the other days — only its letter is marked.
    private func color(_ day: Day) -> Color {
        if day.isFuture || day.kronor == 0 { return Color.secondary.opacity(0.2) }
        return Color.accentColor.opacity(0.35)
    }
}
