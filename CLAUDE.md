# AMS Manual Expenses — working notes

Memory for anyone (human or Claude) picking this project up. Keep it short and current.
Run the same way as AMS Packing (`../AMS Packing App`) and AMS Paragon (`../AMS PARA`);
when in doubt, do what they do.

## Owner

Martin Schabbauer — project manager, part-time retired, lives in Sweden, not
a developer. English is not his first language: short, plain sentences, common words, no
idioms, no computer talk (no error codes, API names or tool quirks in what you tell him).
Name buttons and screens exactly as the app spells them; give whole URLs. He never uses
the Terminal and does not need Xcode: you build, test, push and ship.
Don't ask him what you can find out yourself, and don't ask before doing the agreed work.

## What the app is

iPhone app (SwiftUI, iOS 17+, SwiftData, iPhone only, portrait) for logging expenses by
voice during the day. Display name "Expenses". Data only on the iPhone.
Scope agreed 22 Oct 2026: manual dictated expenses only. More features only when he asks.
The full rules: `docs/spec.md`.

## Fixed decisions

- Bundle ID `com.schabbauer.amsmanualexpenses` (his choice). Team `D24ENP83QQ`.
- Repo `marsch124/AMS-Manual-Expenses` (public — nothing private in it; `private/` is
  git-ignored). Local folder `~/Documents/01 Leisure/30 App Development/AMS Manual Expenses`.
- Branch `main`. The app was started on 22 Oct 2026 in a cloud session from his phone on
  `claude/expense-dictation-app`; the Mac session merged it into main. A later cloud session
  gets its own `claude/…` branch: merge it into main before shipping.
- Version in `project.yml` (`MARKETING_VERSION`); the build number is set by the TestFlight
  workflow (one above the highest App Store Connect has).

## Releasing (every change that should reach his phone)

1. Bump `MARKETING_VERSION` in `project.yml` (1.0 → 1.1 …) and add the entry at the top of
   `App/Sources/Releases.swift` (What's new, his words, plain). Update `Guide` in the same
   file (How it works) and `docs/spec.md` when behaviour changes.
   The UI test `testTheVersionHasItsWhatsNew` goes red if What's new does not start with
   the version.
2. A new behaviour gets its UI test (one at a time), seen to fail with a planted fault.
3. `tools/build.sh test` green locally, then commit + push to main.
4. When the push's Tests run is green, start TestFlight yourself:
   `gh workflow run testflight.yml -R marsch124/AMS-Manual-Expenses -f notes="<what is new>"`.
   It skips the suite when that commit is already green, archives, uploads and releases
   the build to the tester group "Martin" with the notes as What to Test.
5. Wait for the run to finish. Then tell him in one line: "the upload is done, Apple is
   processing it now — look for build N in TestFlight in a few minutes". Never say "it is in
   TestFlight" when the run goes green: Apple still processes it for 5–15 minutes.

## Traps already known (from his other apps)

- Builds under `~/Documents`: codesign refuses the extended attributes → `tools/build.sh`.
- TestFlight needs the ADMIN App Store Connect key (`63M2792NNV`); App Manager cannot
  cloud-sign. Every CI archive mints a "Created via API" development certificate; at about
  ten the archive fails — revoke the "Created via API" ones (standing permission), never
  the one named "Martin Schabbauer".
- A green upload does not reach his phone unless the build is released to the group —
  `tools/release-to-testers.py` does that in the workflow.
- The icon must be opaque (it is: flat teal, white microphone).
- GitHub's simulator has an on-screen keyboard; his Mac's has not. A control under the
  keyboard takes no tap on CI.
- CI's Xcode can be older than the Mac's: keep long arithmetic expressions typed and split.
- Identifiers name what a control IS (`home-type-go`), never what it says.
  Don't put an identifier on a whole screen container: its children inherit it.
