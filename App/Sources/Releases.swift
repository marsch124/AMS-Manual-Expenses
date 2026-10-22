/// What's new, newest first — shown in Settings › What's new.
/// Every release adds its entry here, with the same version as MARKETING_VERSION in
/// project.yml; a UI test (testTheVersionHasItsWhatsNew) holds the two together.
struct Release {
    let version: String
    let date: String
    let lines: [String]
}

enum Releases {
    static let all: [Release] = [
        Release(version: "1.1", date: "22 October 2026", lines: [
            "Say how long ago you paid: “3 hours ago”, “for 3 hours ago”, “half an hour ago”, “20 minutes ago”, “2 days ago”.",
            "The same in Swedish and German: “för 3 timmar sedan”, “för en halvtimme sen”, “vor 3 Stunden”, “vor einer halben Stunde”.",
        ]),
        Release(version: "1.0", date: "22 October 2026", lines: [
            "Say an expense — “Coffee 45 kronor”, “Taxi 12 euros 50”, “Lunch 129 kr at 1 pm” — and check it before it is saved.",
            "English, Svenska and Deutsch, chosen with the globe.",
            "The currency follows the country you are in; you can fix it by hand.",
            "Today’s expenses with a total per currency. Tap one to change it, swipe to delete.",
            "Settings: export everything as CSV, What's new, How it works and the version.",
        ]),
    ]
}

/// How it works — shown in Settings › How it works. Update it whenever behaviour changes.
enum Guide {
    struct Section {
        let title: String
        let lines: [String]
    }

    static let sections: [Section] = [
        Section(title: "Say it", lines: [
            "Tap the microphone and say what you paid, for example “Coffee 45 kronor” or “Taxi 12 euros 50”.",
            "Recording stops by itself after a short pause.",
            "You can also type the same sentence in the field under the microphone and tap Go.",
        ]),
        Section(title: "Check it", lines: [
            "Every expense opens for checking before it is saved: description, amount, currency and time.",
            "Save keeps it. Cancel throws it away.",
        ]),
        Section(title: "Time", lines: [
            "The time is now, unless you say one: “at 7 pm”, “klockan 9.15”, “um 13 Uhr”.",
            "Or say how long ago: “3 hours ago”, “half an hour ago”, “för 3 timmar sedan”, “vor einer halben Stunde”, “2 days ago”.",
            "“Yesterday”, “igår” or “gestern” moves it to yesterday.",
        ]),
        Section(title: "Currency", lines: [
            "A currency you say is used: kronor, kr, crowns, SEK, euro, €.",
            "Otherwise it is the currency of the country you are in, from your location; without a location, from the iPhone’s time zone.",
            "Tap the currency button to fix one by hand, or set it back to automatic.",
        ]),
        Section(title: "Language", lines: [
            "The globe chooses the language you dictate in: English, Svenska or Deutsch.",
        ]),
        Section(title: "Today", lines: [
            "The list shows today’s expenses with a total for each currency.",
            "Tap an expense to change it. Swipe it to the left to delete it.",
        ]),
        Section(title: "Your data", lines: [
            "Everything stays on this iPhone.",
            "Settings › Export all as CSV gives every expense as a file for Numbers or Excel.",
        ]),
    ]
}
