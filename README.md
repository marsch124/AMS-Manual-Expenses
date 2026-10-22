# AMS Manual Expenses — say what you paid

An iPhone app for logging expenses during the day by voice: "Coffee 45 kronor",
"Taxi 12 euros 50", "Lunch 129 kr at 1 pm". Every entry is checked before it is
saved. Data stays on the iPhone. Distributed to Martin through TestFlight.

Organised and run like AMS Packing and AMS Paragon: XcodeGen project, the logic in
a Swift package of its own (`Core/`), UI tests by identifier in CI on every push,
What's new and How it works inside the app, and a TestFlight workflow that releases
every build to his tester group.

## Layout

- `App/Sources` — the SwiftUI app (iOS 17+, SwiftData, iPhone only, portrait)
- `App/Resources` — asset catalogue (icon, accent colour), privacy manifest
- `App/Config/Info.plist` — generated from `project.yml`; committed
- `Core/` — Swift package `ExpenseCore`: the sentence parser and the time-zone currency
  fallback, with its own tests
- `UITests/` — XCUITest, every control found by `accessibilityIdentifier`
- `project.yml` — XcodeGen spec; `AMSExpenses.xcodeproj` is generated from it and committed
- `docs/spec.md` — what the app does, rule by rule, written from the code
- `tools/` — `build.sh`, `test-core.sh`, `release-to-testers.py`
- `.github/workflows/` — `tests.yml` (every push), `testflight.yml` (a release),
  `crash-reports.yml` (TestFlight crash reports, read only)

## Where it stands

- ✅ The app: dictation (English, Svenska, Deutsch), the parser, the check before
  saving, today's list with totals per currency, CSV export, Settings with What's new,
  How it works and the version.
- ✅ Tests: 6 parser tests and 2 UI tests (the version has its What's new; a typed
  expense is checked and saved). Both UI tests were seen to fail with a planted fault.
- ✅ CI on every push; TestFlight workflow; all five secrets set.
- ⏳ App Store Connect app record and the tester group (once, in the browser).
- ⏳ Not yet tried on a real iPhone: the microphone, speech, location.

## Building

`tools/build.sh [build|test]` (its own simulator, "Expenses iPhone 18 Pro") and
`tools/test-core.sh` (the parser's tests alone, a few seconds). Anything under
`~/Documents` collects extended attributes that `codesign` refuses ("detritus not
allowed"); the scripts clear them (never inside `.git`) and keep every build folder
outside `~/Documents`.

## Tests

Martin's standing rule: UI tests in CI on every push, every control found by its
`accessibilityIdentifier` and never by its words, starting with two and growing one
at a time. A red run blocks a release. Every test is SEEN TO FAIL before it is
trusted: plant the fault it guards against, watch it go red, remove the fault.

UI tests start the app with `-uiTesting` (an empty store in memory, no location
question) and fix the language, number format and currency with launch arguments.
