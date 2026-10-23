import SwiftData
import SwiftUI

@main
struct ExpensesApp: App {
    /// UI tests start the app with `-uiTesting`: an empty store kept in memory only, and no
    /// location question (its system alert would sit on top of every test).
    static let uiTesting = ProcessInfo.processInfo.arguments.contains("-uiTesting")

    @StateObject private var rates = ExchangeRates()

    init() {
        // The category list lives in UserDefaults, which a UI test run does not wipe:
        // every test starts from the list a new install has.
        if Self.uiTesting {
            UserDefaults.standard.removeObject(forKey: CategoryList.key)
            UserDefaults.standard.removeObject(forKey: CategoryList.defaultKey)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(rates)
        }
        .modelContainer(for: Expense.self, inMemory: Self.uiTesting)
    }
}
