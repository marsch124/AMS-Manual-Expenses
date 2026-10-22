import SwiftData
import SwiftUI

@main
struct ExpensesApp: App {
    /// UI tests start the app with `-uiTesting`: an empty store kept in memory only, and no
    /// location question (its system alert would sit on top of every test).
    static let uiTesting = ProcessInfo.processInfo.arguments.contains("-uiTesting")

    @StateObject private var rates = ExchangeRates()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(rates)
        }
        .modelContainer(for: Expense.self, inMemory: Self.uiTesting)
    }
}
