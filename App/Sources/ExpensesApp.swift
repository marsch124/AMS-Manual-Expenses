import ExpenseCore
import SwiftData
import SwiftUI

@main
struct ExpensesApp: App {
    /// UI tests start the app with `-uiTesting`: an empty store kept in memory only, and no
    /// location question (its system alert would sit on top of every test).
    static let uiTesting = ProcessInfo.processInfo.arguments.contains("-uiTesting")

    @StateObject private var rates = ExchangeRates()
    private let container: ModelContainer?

    init() {
        // The category list lives in UserDefaults, which a UI test run does not wipe:
        // every test starts from the list a new install has.
        if Self.uiTesting {
            UserDefaults.standard.removeObject(forKey: CategoryList.key)
            UserDefaults.standard.removeObject(forKey: CategoryList.defaultKey)
            UserDefaults.standard.removeObject(forKey: Looks.iconsKey)
            UserDefaults.standard.removeObject(forKey: Consumers.key)
        }
        // 1.33: the "who was it for" names are filled once from the stored expenses, before any
        // screen shows (a screen's own query may not have loaded yet and would see no expenses).
        let made = try? ModelContainer(for: Expense.self,
                                       configurations: ModelConfiguration(isStoredInMemoryOnly: Self.uiTesting))
        container = made
        if let made, let all = try? ModelContext(made).fetch(FetchDescriptor<Expense>(sortBy: [SortDescriptor(\.date)])) {
            Consumers.seedIfNeeded(from: all)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(rates)
        }
        .modelContainer(container ?? (try! ModelContainer(for: Expense.self)))
    }
}
