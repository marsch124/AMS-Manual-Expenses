import SwiftData
import SwiftUI

@main
struct ExpensesApp: App {
    /// UI tests start the app with `-uiTesting`: an empty store kept in memory only, and no
    /// location question (its system alert would sit on top of every test).
    static let uiTesting = ProcessInfo.processInfo.arguments.contains("-uiTesting")

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Expense.self, inMemory: Self.uiTesting)
    }
}
