# AMS Manual Expenses

iPhone app for logging expenses during the day by voice. Distributed via TestFlight.

## What it does

- **Dictate**: tap the microphone and say, for example, "Coffee 45 kronor", "Taxi 12 euros 50",
  "Lunch 129 kr at 1 pm" or "Yesterday parking 40". Recording stops by itself after a short pause.
  Dictation language (English, Svenska, Deutsch) is chosen with the globe button.
- **Time**: the current time is used unless you say one ("at 7 pm", "klockan 9.15", "um 13 Uhr").
- **Currency**: a spoken currency (kronor, kr, crowns, SEK, euro, €) is used. Otherwise the default is the
  currency of the country you are in (from location), falling back to the phone's time zone.
  Tap the currency button to fix it manually or set it back to automatic.
- **Check before saving**: every entry opens for correction before it is saved.
- Today's list with totals per currency; tap to edit, swipe to delete; export everything as CSV.

Data is stored only on the iPhone.

## Project layout

- `App/` – SwiftUI app (iOS 17+, SwiftData)
- `ExpenseCore/` – Swift package with the sentence parser and its tests (`swift test --package-path ExpenseCore`)
- `project.yml` – XcodeGen project definition. Run `xcodegen generate` to create `AMSExpenses.xcodeproj`.
- `.github/workflows/ios.yml` – builds and tests on every push; uploads to TestFlight when the secrets below are set.

## TestFlight setup (one time)

Repository secrets (GitHub → Settings → Secrets and variables → Actions):

| Secret | Value |
| --- | --- |
| `APPLE_TEAM_ID` | 10-character Team ID from developer.apple.com → Membership |
| `ASC_KEY_ID` | Key ID of an App Store Connect API key with the **Admin** role |
| `ASC_ISSUER_ID` | Issuer ID shown above the key list in App Store Connect |
| `ASC_KEY_P8` | Full text of the downloaded `AuthKey_XXXX.p8` file |

The app record in App Store Connect must exist with bundle ID `com.schabbauer.amsmanualexpenses`.
