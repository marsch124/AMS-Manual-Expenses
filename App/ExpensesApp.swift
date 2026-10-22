import SwiftData
import SwiftUI

@main
struct ExpensesApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Expense.self)
    }
}
