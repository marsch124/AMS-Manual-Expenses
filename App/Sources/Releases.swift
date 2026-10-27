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
        Release(version: "1.11", date: "27 October 2026", lines: [
            "The “This week” line under the Today card is gone. The small bars on the right stay.",
            "The main screen is tighter: the time is smaller, with the date and place on one line under it; the microphone sits on the left with the typing field beside it; less space around the Today card and between the parts; slimmer expense rows.",
        ]),
        Release(version: "1.10", date: "27 October 2026", lines: [
            "The Today card shows this week on the right: a small bar for each day, Monday to Sunday. Today’s bar is the strong one; days still to come are grey.",
            "Under it, “This week” with the week’s total in kronor.",
        ]),
        Release(version: "1.9", date: "27 October 2026", lines: [
            "Every category has its own icon and colour: in the lists, on the check sheet and in Statistics. Change one in Settings › Categories: tap its icon.",
            "Who it was for, in colour on every expense: Martin blue, AMS yellow, Anna green, Others grey. Anna is new under “For whom”.",
            "Statistics › By category: a ring in the category colours, with the total in the middle. In Last 30 days, today’s bar is the strong one.",
            "The Today card: today’s total in large numbers, and how many expenses.",
            "An amount in euros has its kronor under it, for example “≈ SEK 125”.",
            "Same again: swipe an expense to the right, or open it and tap “Same again, now”, to log it again now. It opens for checking; tap Save.",
            "A short vibration and “Saved” when you save.",
            "The app icon has a dark and a tinted look, for dark and tinted home screens.",
        ]),
        Release(version: "1.8", date: "26 October 2026", lines: [
            "The check sheet shows a small map of where the expense was logged, with the town and how exact the position is (for example ±8 m). Tap it for a big map.",
            "The big map: the time, the place, the town, the position in numbers, how exact it is, and Open in Maps.",
            "Today on the map: the new map button at the top of the main screen. Today’s expenses are numbered in the order you paid; one without a position has a grey “–”.",
            "When the app fills in the place by itself, the check sheet says so: “auto · 12 m away”.",
        ]),
        Release(version: "1.7", date: "26 October 2026", lines: [
            "Every new expense keeps its GPS position.",
            "The place you visited: a new label under “For whom” on the check sheet. Tap it and choose a place, or type a new one on the top line and tap Add.",
            "The places near you are listed first, under Nearby. The next time you log an expense at the same spot, its place is filled in by itself.",
            "Settings › Places: every place with how many expenses have it. Tap one to rename it (every expense follows), swipe to delete it.",
            "The CSV export has the columns Place visited, Latitude and Longitude.",
        ]),
        Release(version: "1.6", date: "24 October 2026", lines: [
            "Who it was for: the last line of the check sheet is a small label — Martin (always first), AMS or Others. Tap it to change.",
            "The CSV export has a Consumer column. Earlier expenses count as Martin.",
        ]),
        Release(version: "1.5", date: "23 October 2026", lines: [
            "“Dictate expense” in the Shortcuts app: it opens Expenses and starts listening straight away.",
            "Put it on the Action button: iPhone Settings › Action Button › Shortcut › Expenses › Dictate expense.",
            "Siri knows it too: “Dictate an expense in Expenses”.",
        ]),
        Release(version: "1.4", date: "23 October 2026", lines: [
            "The hint under the microphone is gone.",
            "A new expense starts in Café, unless its description had another category before.",
            "The check sheet: the category is the last line, a small coloured label; the date and time sit on the left as quiet labels (tap them to change: Cancel or Done); the words “Category” and “Time” are gone; what was heard is in italics; the amount is bold.",
        ]),
        Release(version: "1.3", date: "22 October 2026", lines: [
            "Categories: choose one on the check sheet (Category), or later by tapping the expense. “New category…” adds one right there.",
            "The app remembers: the next time you say the same description, its category is filled in by itself.",
            "Statistics › By category: totals in kronor for this week, this month, last month or all time. Tap a category to see its expenses.",
            "Settings › Categories: add, rename (every expense follows), delete and reorder.",
            "The CSV export has a Category column.",
        ]),
        Release(version: "1.2", date: "22 October 2026", lines: [
            "Statistics — the chart button at the top: this week, this month and last month with the average per day; a bar for each of the last 30 days; what you spend most on; and every earlier day.",
            "Earlier days: open a day to see its expenses, tap one to change it, swipe to delete it.",
            "Every total is in kronor. Euros are counted at the European Central Bank's rate of their day — Today's total too.",
        ]),
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
        Section(title: "Action button and Shortcuts", lines: [
            "“Dictate expense” opens the app and starts listening at once.",
            "Action button: iPhone Settings › Action Button, swipe to Shortcut, choose Expenses › Dictate expense.",
            "It is also in the Shortcuts app under Expenses, and Siri knows “Dictate an expense in Expenses”.",
        ]),
        Section(title: "Check it", lines: [
            "Every expense opens for checking before it is saved: description, amount and currency, the date and time, the category, for whom and the place visited.",
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
            "The list shows today’s expenses and their total in kronor.",
            "The card at the top shows today’s total in large numbers and how many expenses, and on the right this week as small bars (today in strong colour).",
            "An amount in euros has its kronor under it (≈ SEK 125), at the bank’s rate of its day.",
            "Tap an expense to change it. Swipe it to the left to delete it. Swipe it to the right (or open it and tap “Same again, now”) for the same expense again, now, opened for checking.",
            "Save gives a short vibration and shows “Saved”.",
        ]),
        Section(title: "Categories", lines: [
            "The last line of the check sheet is the category: tap it and choose one, or “New category…” to add one.",
            "A new expense starts in Café (the default, marked in Settings › Categories).",
            "The next time you say the same description (“Coffee”), its last category is filled in by itself.",
            "To change it later, tap the expense — today, or in Statistics under a day or a category.",
            "Settings › Categories: tap one to rename it (every expense moves with it), swipe to delete it (its expenses keep no category), Edit to change the order, Add category at the bottom.",
            "Every category has an icon and a colour. Tap the icon in Settings › Categories to choose another one. A new category starts with a grey tag.",
        ]),
        Section(title: "For whom", lines: [
            "Under the category, the check sheet says who the expense was for: Martin, AMS, Anna or Others. A new one is Martin; tap the label to change it.",
            "Every expense in the lists shows it in colour: Martin blue, AMS yellow, Anna green, Others grey.",
        ]),
        Section(title: "Place visited", lines: [
            "The last line of the check sheet is the place you visited, for example “ICA Odenplan”. Tap it and choose a place, or type a new one on the top line (“New place”) and tap Add.",
            "Every new expense keeps its GPS position. The places you used near it are listed first, under Nearby; the others follow, the latest first.",
            "At the same spot again (within about 150 metres), the place is filled in by itself. You can change it before Save.",
            "Without a position (location turned off, or an expense from before 1.7) there is no Nearby list; the places are all still there.",
            "When the place was filled in by itself, “auto · 12 m away” beside it says how far away you used it before.",
            "Settings › Places: tap a place to rename it (every expense moves with it; a name that is already there joins the two), swipe it to the left to delete it (its expenses keep no place, the expenses stay).",
        ]),
        Section(title: "Maps", lines: [
            "Under the place, the check sheet shows a small map of where the expense was logged, the town, and how exact the position is (±8 m). Tap it for the big map.",
            "The big map shows the time, the place, the town, the position in numbers and how exact it is. Open in Maps opens Apple Maps at that spot.",
            "The map button at the top of the main screen shows today’s expenses on one map, numbered in the order you paid. One without a position has a grey “–” and is not on the map.",
            "An expense without a position (location turned off, or from before 1.7) has no map.",
        ]),
        Section(title: "Statistics", lines: [
            "The chart button at the top opens Statistics.",
            "Totals: this week (from Monday), this month and last month, each with the average per day.",
            "Last 30 days: one bar per day.",
            "By category: a ring in the category colours, then each category with how many and its total, for the week, the month, last month or all time. Tap one to see its expenses.",
            "What you spend most on: the descriptions you use most often, how many times, and their total.",
            "Earlier days: tap a day to see its expenses; tap one to change it, swipe to delete it.",
        ]),
        Section(title: "Kronor", lines: [
            "Every total is in kronor. An amount in euros is counted at the European Central Bank’s rate of its day; on a weekend or a holiday, the last rate before it.",
            "The rates are fetched over the internet and kept on the iPhone. Only dates and currency names are sent, never an expense.",
            "Without a rate yet (offline), that amount is shown apart, for example “+ €12.50”, until the iPhone is online.",
        ]),
        Section(title: "Your data", lines: [
            "Your expenses stay on this iPhone.",
            "Settings › Export all as CSV gives every expense, with its category, place and GPS position, as a file for Numbers or Excel.",
            "The GPS position is used only on this iPhone and in the CSV file. It is never sent anywhere.",
        ]),
    ]
}
