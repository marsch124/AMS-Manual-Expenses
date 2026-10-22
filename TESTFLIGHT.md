# Getting AMS Manual Expenses onto the iPhone (TestFlight)

The same pipeline as AMS Packing, for the iPhone only.

## Once

1. **App Store Connect app record** — My Apps → "+" → New App: platform **iOS**, name
   **AMS Manual Expenses**, bundle ID **com.schabbauer.amsmanualexpenses** (already
   registered), SKU `AMSManualExpenses`, Full Access.
2. **Tester group** — TestFlight → Internal Testing → "+" → group **Martin**, with
   Martin in it. (Can also be made over the API: `POST /v1/betaGroups`, then a new
   betaTester tied to that group — an existing tester id from another app answers 409.)
3. **Secrets** (all set 22 Oct 2026): `ASC_KEY_ID` = `63M2792NNV` (the ADMIN key),
   `ASC_ISSUER_ID`, `ASC_KEY_P8` (the .p8's text), `ASC_TEAM_ID` = `D24ENP83QQ`,
   `TESTER_GROUP` = `Martin`.

## Every release

**Actions → TestFlight → Run workflow** (Claude starts it once the Tests run is green):
<https://github.com/marsch124/AMS-Manual-Expenses/actions/workflows/testflight.yml>.
It runs the suite first unless that commit is already green, archives for the iPhone,
uploads, and releases the build to the group with the **notes** as What to Test.
Apple then processes it for a few minutes before the TestFlight app offers it.

## Crash reports

A crash a tester shares from TestFlight ("… crashed. Share?") is fetched by
**Actions → Crash reports → Run workflow** — read only.
