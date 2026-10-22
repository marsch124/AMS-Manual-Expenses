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
    @State private var typed = ""
    @State private var draft: Draft?
    @State private var showSettings = false

    private var autoCurrency: String {
        location.currency ?? CurrencyDefaults.currency(forTimeZone: TimeZone.current.identifier) ?? "SEK"
    }
    private var defaultCurrency: String { manualCurrency.isEmpty ? autoCurrency : manualCurrency }
    private var currencyOptions: [String] {
        ["SEK", "EUR"].contains(autoCurrency) ? ["SEK", "EUR"] : ["SEK", "EUR", autoCurrency]
    }
    private var todays: [Expense] { expenses.filter { Calendar.current.isDateInToday($0.date) } }

    var body: some View {
        NavigationStack {
            List {
                Section { header }
                Section { dictation }
                Section {
                    if todays.isEmpty {
                        Text("No expenses yet today.").foregroundStyle(.secondary)
                            .accessibilityIdentifier("today-empty")
                    }
                    ForEach(Array(todays.enumerated()), id: \.element.id) { index, expense in
                        Button { draft = Draft(editing: expense) } label: { ExpenseRow(expense: expense) }
                            .tint(.primary)
                            .accessibilityIdentifier("expense-row-\(index)")
                    }
                    .onDelete { offsets in
                        let items = offsets.map { todays[$0] }
                        for item in items { context.delete(item) }
                    }
                } header: {
                    HStack(alignment: .top) {
                        Text("Today")
                        Spacer()
                        Text(todayTotal).multilineTextAlignment(.trailing)
                            .accessibilityIdentifier("today-total")
                    }
                }
            }
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
                    onSave: save,
                    onDelete: d.expense.map { e in { context.delete(e) } }
                )
            }
        }
        .onAppear {
            speech.onFinish = { handle($0) }
            if !ExpensesApp.uiTesting { location.refresh() }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active && !ExpensesApp.uiTesting { location.refresh() }
        }
        .task(id: expenses.count) {
            await rates.update(for: expenses.map(\.spend))
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            TimelineView(.everyMinute) { context in
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.date, format: .dateTime.hour().minute())
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    Text(context.date, format: .dateTime.weekday(.wide).day().month(.wide))
                        .foregroundStyle(.secondary)
                }
            }
            HStack {
                Label(location.placeName ?? TimeZone.current.identifier, systemImage: "location")
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer()
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
                .accessibilityIdentifier("home-currency")
            }
            .font(.subheadline)
        }
    }

    private var dictation: some View {
        VStack(spacing: 12) {
            Button { speech.toggle(localeID: language) } label: {
                Image(systemName: speech.isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.white)
                    .frame(width: 96, height: 96)
                    .background(Circle().fill(speech.isRecording ? Color.red : Color.accentColor))
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(speech.isRecording ? "Stop" : "Dictate expense")
            .accessibilityIdentifier("home-dictate")

            Text(statusText)
                .font(.footnote)
                .foregroundStyle(speech.errorMessage == nil ? Color.secondary : Color.red)
                .multilineTextAlignment(.center)
                .accessibilityIdentifier("home-status")

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
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private var statusText: String {
        if let error = speech.errorMessage { return error }
        if speech.isRecording { return speech.transcript.isEmpty ? "Listening…" : speech.transcript }
        return "Tap and say e.g. “Coffee 45 kronor” or “Taxi 12 euros 50”"
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
        var lines = ["Date,Time,Description,Category,Amount,Currency,Place,Time zone"]
        for e in expenses.reversed() {
            let tz = TimeZone(identifier: e.timeZoneID) ?? .current
            dateFormat.timeZone = tz
            timeFormat.timeZone = tz
            lines.append([dateFormat.string(from: e.date), timeFormat.string(from: e.date), e.title, e.category,
                          String(format: "%.2f", e.amount), e.currency, e.place, e.timeZoneID].map(quote).joined(separator: ","))
        }
        return lines.joined(separator: "\n")
    }

    private func handle(_ text: String) {
        let sentence = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sentence.isEmpty else { return }
        let parsed = ExpenseParser.parse(sentence, defaultCurrency: defaultCurrency)
        draft = Draft(title: parsed.title, amountText: parsed.amount.map(Draft.format) ?? "",
                      currency: parsed.currency, date: parsed.date, heard: sentence,
                      category: Categories.suggestion(for: parsed.title, history: expenses.map(\.spend)) ?? "")
        typed = ""
    }

    private func save(_ d: Draft) {
        guard let amount = d.amount else { return }
        let title = d.title.trimmingCharacters(in: .whitespaces).isEmpty ? "Expense" : d.title
        if let e = d.expense {
            e.apply(d)
        } else {
            context.insert(Expense(title: title, amount: amount, currency: d.currency, date: d.date,
                                   place: location.placeName ?? "", heard: d.heard, category: d.category))
        }
    }
}

struct ExpenseRow: View {
    let expense: Expense
    var showsDate = false

    private var when: String {
        showsDate
            ? expense.date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).hour().minute())
            : expense.date.formatted(.dateTime.hour().minute())
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(expense.title)
                Text(expense.category.isEmpty ? when : when + " · " + expense.category)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(expense.amount, format: .currency(code: expense.currency))
                .bold()
                .monospacedDigit()
        }
    }
}

struct EntryEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: Draft
    private let currencies: [String]
    private let onSave: (Draft) -> Void
    private let onDelete: (() -> Void)?

    init(draft: Draft, currencies: [String], onSave: @escaping (Draft) -> Void, onDelete: (() -> Void)?) {
        _draft = State(initialValue: draft)
        self.currencies = currencies
        self.onSave = onSave
        self.onDelete = onDelete
    }

    private var options: [String] {
        currencies.contains(draft.currency) ? currencies : currencies + [draft.currency]
    }

    var body: some View {
        NavigationStack {
            Form {
                if !draft.heard.isEmpty {
                    Section("Heard") {
                        Text(draft.heard).foregroundStyle(.secondary)
                            .accessibilityIdentifier("entry-heard")
                    }
                }
                Section {
                    TextField("Description", text: $draft.title)
                        .accessibilityIdentifier("entry-title")
                    NavigationLink { CategoryChooser(selection: $draft.category) } label: {
                        HStack {
                            Text("Category")
                            Spacer()
                            Text(draft.category.isEmpty ? "None" : draft.category)
                                .foregroundStyle(.secondary)
                                .accessibilityIdentifier("entry-category-value")
                        }
                    }
                    .accessibilityIdentifier("entry-category")
                    HStack {
                        TextField("Amount", text: $draft.amountText)
                            .keyboardType(.decimalPad)
                            .accessibilityIdentifier("entry-amount")
                        Picker("Currency", selection: $draft.currency) {
                            ForEach(options, id: \.self) { Text($0).tag($0) }
                        }
                        .labelsHidden()
                        .fixedSize()
                        .accessibilityIdentifier("entry-currency")
                    }
                    DatePicker("Time", selection: $draft.date)
                        .accessibilityIdentifier("entry-time")
                }
                if let onDelete {
                    Section {
                        Button("Delete expense", role: .destructive) {
                            onDelete()
                            dismiss()
                        }
                        .accessibilityIdentifier("entry-delete")
                    }
                }
            }
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
