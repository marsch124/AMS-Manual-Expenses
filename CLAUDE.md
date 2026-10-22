# AMS Manual Expenses – notes for Claude

## Owner
Martin, project manager (part-time retired). Not a developer. Distributes the app to himself via TestFlight.
Wants friendly, concise answers, no filler, and never guesses: say plainly what is verified and what is not.

## What the app is
iPhone app (SwiftUI, iOS 17+, SwiftData) for logging expenses by voice during the day.
- Dictation with Apple's Speech framework (English / Svenska / Deutsch), auto-stops after a pause.
- Parser in `ExpenseCore/` turns "Taxi 12 euros 50 at 9 am" into title, amount, currency and time.
- Default currency: country from location (CoreLocation + reverse geocode), fallback to time zone,
  manual override in the app. Main currencies: SEK (Sweden) and EUR.
- Every entry opens a review sheet before saving. Today's list with totals, swipe to delete, CSV export.
- Scope agreed so far: manual dictated expenses only. More features later, only when Martin asks.

## Layout
- `App/` – app sources, asset catalog, `PrivacyInfo.xcprivacy`
- `ExpenseCore/` – Swift package with the parser; tests: `swift test --package-path ExpenseCore`
- `project.yml` – XcodeGen definition; `AMSExpenses.xcodeproj` and `App/Info.plist` are generated and git-ignored
- `.github/workflows/ios.yml` – CI on macOS: parser tests + unsigned build; TestFlight upload job runs only
  when the App Store Connect secrets exist (currently not set)

## Fixed decisions
- Bundle ID: `com.schabbauer.amsmanualexpenses` (Martin chose this)
- Display name "Expenses", version 1.0, iPhone only, portrait
- Work happens on branch `claude/expense-dictation-app`

## Status (handoff from cloud session, 2026-10-22)
- Verified on GitHub Actions (Xcode 26.6): parser tests pass (6 tests), app builds unsigned with no errors.
- NOT yet verified: running on a real iPhone (speech, microphone, location), signing, TestFlight upload.
- Martin moved to working locally on his Mac with Xcode.

## Next steps on the Mac
1. Check Xcode is installed (`xcodebuild -version`) and signed in with Martin's Apple ID
   (Xcode → Settings → Accounts).
2. Generate the project: `brew install xcodegen` (install Homebrew first if missing), then `xcodegen generate`.
   Re-run `xcodegen generate` after adding/removing files or changing `project.yml`.
3. Set the Team: add `DEVELOPMENT_TEAM: <TEAM_ID>` under the target's `settings.base` in `project.yml`,
   regenerate, open `AMSExpenses.xcodeproj`.
4. Run on the Simulator, then on Martin's iPhone.
5. In App Store Connect: make sure the app record exists with the bundle ID above.
6. Product → Archive, then Organizer → Distribute App → TestFlight & App Store. Increase the build number
   (`CURRENT_PROJECT_VERSION` in `project.yml`) for every new upload.
