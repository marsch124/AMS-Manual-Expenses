import AppIntents
import SwiftUI

/// 1.5 (his ask): "Dictate expense" for the Shortcuts app and the Action button — opens the
/// app and starts listening at once.
struct DictateExpenseIntent: AppIntent {
    static var title: LocalizedStringResource = "Dictate expense"
    static var description = IntentDescription("Opens Expenses and starts listening straight away.")
    static var openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        DictationRequest.shared.pending = true
        return .result()
    }
}

/// Puts the action in Shortcuts and in Settings › Action Button › Shortcut by itself.
struct ExpenseShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: DictateExpenseIntent(),
                    phrases: ["Dictate an expense in \(.applicationName)",
                              "Log an expense in \(.applicationName)"],
                    shortTitle: "Dictate expense",
                    systemImageName: "mic.fill")
    }
}

/// The bridge from the action to the screen: set by the action, taken by the main screen
/// as soon as it is on show (also when the app was not running yet).
@MainActor
final class DictationRequest: ObservableObject {
    static let shared = DictationRequest()
    @Published var pending = false
}
