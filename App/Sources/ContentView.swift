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
                    } else {
                        // 1.9: the Today card — today's total, big, and how many.
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
                        .padding(.vertical, 6)
                    }
                    ForEach(Array(todays.enumerated()), id: \.element.id) { index, expense in
                        Button { draft = Draft(editing: expense) } label: { ExpenseRow(expense: expense) }
                            .tint(.primary)
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
                                Button(role: .destructive) { context.delete(expense) } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                    .onDelete { offsets in
                        let items = offsets.map { todays[$0] }
                        for item in items { context.delete(item) }
                    }
                } header: {
                    Text("Today")
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
                    // 1.8: today's expenses on a map (concept B).
                    NavigationLink { TodayMapScreen(expenses: todays) } label: {
                        Image(systemName: "map")
                    }
                    .accessibilityLabel("Today on the map")
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
                    onDelete: d.expense.map { e in { context.delete(e) } }
                )
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
            Button {
                // 1.7: a fresh GPS fix while he speaks, for the expense he is about to log.
                if !speech.isRecording && !ExpensesApp.uiTesting { location.refresh() }
                speech.toggle(localeID: language)
            } label: {
                Image(systemName: speech.isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.white)
                    .frame(width: 96, height: 96)
                    .background(Circle().fill(speech.isRecording ? Color.red : Color.accentColor))
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(speech.isRecording ? "Stop" : "Dictate expense")
            .accessibilityIdentifier("home-dictate")
            .accessibilityValue(ExpensesApp.uiTesting ? "requests \(testRequests)" : "")

            // 1.4 (his ask): no hint any more — the line is there only while listening or for an error.
            if !statusText.isEmpty {
                Text(statusText)
                    .font(.footnote)
                    .foregroundStyle(speech.errorMessage == nil ? Color.secondary : Color.red)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("home-status")
            }

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
        return ""
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
            try? await Task.sleep(for: .seconds(1.6))
            if saves == shown { withAnimation { showSaved = false } }
        }
        let title = d.title.trimmingCharacters(in: .whitespaces).isEmpty ? "Expense" : d.title
        if let e = d.expense {
            e.apply(d)
        } else {
            context.insert(Expense(title: title, amount: amount, currency: d.currency, date: d.date,
                                   place: location.placeName ?? "", heard: d.heard, category: d.category, consumer: d.consumer,
                                   fix: d.fix, visitedPlace: d.visitedPlace))
        }
    }
}

struct ExpenseRow: View {
    let expense: Expense
    var showsDate = false
    @EnvironmentObject private var rates: ExchangeRates

    /// 1.9: "≈ SEK 125" under an amount in another currency, at its day's rate.
    private var kronorText: String? {
        guard expense.currency != homeCurrency,
              let kronor = rates.table.kronor(expense.spend, calendar: .current) else { return nil }
        return "≈ " + Money.kronor(kronor)
    }

    private var when: String {
        showsDate
            ? expense.date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).hour().minute())
            : expense.date.formatted(.dateTime.hour().minute())
    }

    var body: some View {
        HStack(spacing: 12) {
            CategoryIcon(name: expense.category)
            VStack(alignment: .leading, spacing: 3) {
                Text(expense.title)
                HStack(spacing: 6) {
                    Text(expense.category.isEmpty ? when : when + " · " + expense.category)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ConsumerTag(name: expense.consumer)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(expense.amount, format: .currency(code: expense.currency))
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

    init(draft: Draft, currencies: [String], visits: [Visit], onSave: @escaping (Draft) -> Void, onDelete: (() -> Void)?) {
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
                    // 1.6 (his ask): who it was for, the very last line, a pill like the category.
                    NavigationLink { ConsumerChooser(selection: $draft.consumer) } label: {
                        // 1.9: in his colour for that person (yellow is too light for text: dark then).
                        pill(draft.consumer, filled: true,
                             color: draft.consumer == "AMS" ? Color(red: 0.6, green: 0.45, blue: 0) : Looks.consumer(draft.consumer).fill)
                            .accessibilityIdentifier("entry-consumer-value")
                    }
                    .accessibilityIdentifier("entry-consumer")
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
