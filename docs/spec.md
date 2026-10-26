# AMS Manual Expenses — specification

What the app does, rule by rule, written from the code (version 1.8, 26 Oct 2026).
Change this file in the same commit as the behaviour it describes.

## 1. The main screen (`ContentView.swift`)

One list, three parts:

1. **Header** — the time (updates every minute) and the date; the place
   (from location, else the time-zone name); the **currency button**
   (`home-currency`) showing the currency in use and "· auto" when it comes from
   location.
2. **Dictation** — the microphone button (`home-dictate`; red with a stop sign while
   listening), a status line (`home-status`: "Listening…", the words heard so far, or an
   error in red — and nothing at all while idle; the hint was removed in 1.4, his ask), and a text field (`home-type-field`) with **Go**
   (`home-type-go`, disabled while the field is empty) for typing the same sentence.
3. **Today** — today's expenses, newest first (`expense-row-0`, `-1`, …), each with
   description, time (and category, since 1.3) and amount in its own currency. The section header holds "Today"
   and the total in kronor (`today-total`, §9; before 1.2 one total per currency). Empty: "No expenses yet today."
   (`today-empty`). Tap a row to change it; swipe left to delete it (no question).

Toolbar: the map (`home-map`, 1.8) opens Today on the map (§14). The globe (`home-language`) picks the dictation language — English (en-US),
Svenska (sv-SE), Deutsch (de-DE); stored as `dictationLanguage`. The chart
(`home-statistics`) opens Statistics (§10). The gear (`home-settings`) opens Settings.

## 2. Dictation (`SpeechRecognizer.swift`)

- First use asks for speech recognition, then the microphone. A refusal shows
  "… is turned off. Allow it in Settings › Expenses." in the status line.
- Recording stops by itself 1.8 s after the last new word, or after 6 s if nothing
  is heard; a second tap stops it at once.
- Nothing heard: "Nothing heard. Tap the microphone and try again."
- The sentence then goes to the parser, exactly like a typed one.

## 3. The parser (`Core/Sources/ExpenseCore/ExpenseParser.swift`)

Input: a sentence and the default currency. Output: description, amount, currency,
time, and whether currency and time were spoken.

- **Currency words** (longest match first): EUR — euros, euro, eur, €, cents, cent;
  SEK — swedish crowns, swedish kronor, kronor, kronan, krona, kronen, krone, crowns,
  crown, sek, kr, spänn, öre.
- **Amount**: the number right next to a currency word (before or after it, only
  spaces between); otherwise the largest number. "12 euros 50" and "12 euro and 50
  cents" give 12.50. Numbers: "1,234" = 1234, "12,50" = 12.5, "1,234.50" = 1234.5.
  Rounded to cents.
- **Currency**: the one next to the amount; else the first currency word; else the
  default.
- **Time ago** (1.1) wins over everything below: [for] N hours / minutes / days ago;
  för N timmar / minuter / dagar sedan (or "sen"), för en halvtimme sedan; vor N Stunden /
  Minuten / Tagen. N is a number (1.5 allowed) or a word: a, an, one … twelve, half an;
  en, ett, två … tolv, en halv; ein, eine, einer, einem, zwei … zwölf, einer halben. The
  time is now minus that. "for 3 hours" without "ago" is not a time (it stays in the
  description).
- **Time**: "at / around / klockan / kl / um / gegen" + hour[:minutes] [am/pm/Uhr], or
  hour[:minutes] + am/pm/Uhr. "yesterday / igår / i går / gestern" moves it to
  yesterday. No time said: now.
- **Description**: what is left after amount, currency and time words are removed,
  filler words stripped only at the start and end ("I paid … for lunch" → "Lunch";
  "Kaffe och bulle" stays whole), first letter capitalised. Empty → "Expense" on save.

The tests (`Core/Tests`) hold real sentences in all three languages.

## 4. Currency in use

Manual choice (stored as `manualCurrency`) wins. Otherwise automatic: the currency of
the country the iPhone is in (location, reverse geocoded, kilometre accuracy, asked
again each time the app comes to the front); without a location, from the time zone
(Europe/Stockholm → SEK, euro-zone time zones → EUR); else SEK.
The currency menu offers Automatic, SEK, EUR and the local currency if it is another.

## 5. Checking an entry (`EntryEditor`)

Opens for every new expense and when a row is tapped. From the top (1.4 order, his ask):
what was heard (`entry-heard`); Description (`entry-title`); Amount (`entry-amount`,
decimal pad, comma or point) with the Currency beside it (`entry-currency`); the date and
time on the left as two quiet labels without a heading (`entry-time`; a tap opens the
calendar with the time in its own sheet, `entry-time-picker`, Cancel / Done); what was heard is in italics; last, the category without a label
(`entry-category`, showing `entry-category-value`: the name, or "No category" in grey;
opens the chooser, §11); the very last line (1.6) the consumer pill (`entry-consumer`,
value `entry-consumer-value`; chooser `consumer-choice-0` … Martin / AMS / Others; a new
expense is Martin, earlier ones count as Martin). Since 1.7 the last line is the place
visited (`entry-place`, value `entry-place-value`: the name, or "No place" in grey; opens
the chooser, §13). A new expense's category is the one its description had last
time, else the default category (§11).
**Save** (`entry-save`) is off until the amount is a number above 0. **Cancel**
(`entry-cancel`) keeps nothing. An existing expense also has **Delete expense**
(`entry-delete`).

## 6. Settings (`SettingsScreen.swift`)

- **Categories** (`settings-categories`): §11.
- **Places** (`settings-places`, 1.7): §13.
- **Export all as CSV** (`settings-export`): every expense, oldest first, columns
  Date, Time, Description, Category (1.3), Consumer (1.6), Place visited (1.7), Amount,
  Currency, Place, Time zone, Latitude, Longitude (1.7, six decimals; empty without a fix); date and time in the
  time zone where it was logged; every field quoted.
- **What's new** (`settings-whatsnew`): `Releases.all`, newest first; the top version
  is `whatsnew-0-version`.
- **How it works** (`settings-howitworks`): `Guide.sections`.
- **Version** (`settings-version`): "version (build)", read from the app itself.
- **Done** (`settings-done`).

## 7. Data (`Expense.swift`)

SwiftData, on the iPhone only. An expense: title, amount, currency, date, time-zone id
and place at the moment it was logged, the sentence heard, created-at, category (1.3, a
name; "" = none), consumer (1.6), latitude and longitude (1.7, the GPS fix; nil = none) and
the place visited (1.7, `visitedPlace`; "" = none), and the fix's accuracy in metres (1.8,
`locationAccuracy`; nil = not known). The category list is UserDefaults `categories`, one name per line.

## 8. Test hooks

`-uiTesting`: the store is in memory and starts empty; location is never asked; no
exchange rate is fetched — one euro is always 10 kronor; `-uiTestingFix <lat>,<lon>[,<accuracy>]` (1.7;
accuracy 1.8) sets the GPS fix, and then the area is "Stockholm, Sweden"; the category list starts as a
new install's.
UI tests also pass `-manualCurrency SEK -dictationLanguage en-US -AppleLanguages (en)
-AppleLocale en_US`.

## 9. Kronor (1.2, `ExchangeRates.swift`, `Core/…/Statistics.swift`)

Every total is in kronor (his choice, 22 Oct 2026). An amount in another currency is
multiplied by the European Central Bank's rate of its day: the rate of that day, else the
last one before it (weekends, holidays, today before the rate is out), else the first one
after it. Rates come from `https://api.frankfurter.dev/v1/<start>..<end>?base=SEK&symbols=<code>`
— one request per currency, from a week before the oldest expense in that currency to
today — and are kept in UserDefaults (`exchangeRates`), so days already fetched work
offline. Fetched when the app starts or an expense is added or removed, and when
Statistics opens; at most once an hour unless a currency has no rate at all. Only dates
and currency codes are sent. An amount with no rate yet is shown apart: "SEK 45 + €12.50".
Totals are whole kronor.

## 10. Statistics (1.2, `StatisticsScreen.swift`)

- **Totals**: This week (`stats-week-total`; the week starts on the iPhone's first
  weekday — Monday in Sweden), This month (`stats-month-total`), Last month
  (`stats-lastmonth-total`); each with "… a day" (`…-perday`): the total divided by the
  days so far (today included) for this week and this month, by all its days for last month.
- **By category** (1.3): a segmented choice (`stats-category-span`) Week / Month (the
  default) / Last month / All; each category in that span with count and kronor, the
  dearest first, "No category" as one more row (`stats-category-0` …). A row opens its
  expenses (with dates) in the same list screen as a day.
- **Last 30 days** (`stats-chart`): one bar per day, today the last; 0 for a day with nothing.
- **What you spend most on** (`stats-top-0` …): the 5 descriptions used most often
  ("coffee" and "Coffee " are one), then the dearest: "Coffee · 14× · 630 kr".
- **Earlier days** (`stats-day-0` …): every day with an expense except today, newest
  first, with its total. A day opens `ExpenseListScreen`: its expenses (`list-row-0` …),
  the total (`list-total`); tap one to change it (the same check sheet as §5), swipe to
  delete it.
- Footer (`stats-rates-note`): that totals are in kronor at the bank's rate, or that some
  rates are still missing.

## 11. Categories (1.3, `CategoryViews.swift`)

Asked for on 22 Oct 2026: "coffee and café were in different statistics".

- A new install's list: Café, Groceries, Restaurant, Transport, Shopping, Home, Health,
  Leisure, Travel, Other (`Categories.defaults`).
- **Chooser** (from the check sheet): None (`category-choice-none`), each category
  (`category-choice-0` …, a check mark on the chosen one); a tap chooses and goes back.
  **New category…** (`category-new`) asks for a name (`category-new-name`; Cancel / Add):
  added at the end of the list and chosen. A name already there (any spelling) is chosen
  instead of added twice.
- **Remembered**: a new expense gets the category of the latest expense with the same
  description (trimmed, any capitals); none → the **default category** (1.4, his ask:
  Café; UserDefaults `defaultCategory`, marked "default" in Settings › Categories,
  follows a rename, cleared when that category is deleted — then no category). He can
  change it before Save.
- **Settings › Categories** (`categories-row-0` …, each with how many expenses use it):
  tap = rename (Cancel / Save; every expense with it moves along; renaming onto another
  category's name joins the two); swipe = delete (when used, asks first — "Delete
  category" / "Keep it"; its expenses keep no category, the expenses stay); Edit
  (`categories-edit`) = reorder; **Add category** (`categories-add`) at the bottom.

## 12. Shortcuts and the Action button (1.5, `Shortcuts.swift`)

`DictateExpenseIntent` ("Dictate expense", opens the app) sets `DictationRequest.pending`;
the main screen takes it when it appears or when it changes: closes an open check sheet or
Settings and, 0.4 s later, starts dictation (if not already listening). `ExpenseShortcuts`
(App Shortcuts) lists it in Shortcuts, the Action button's Shortcut choice and Siri
("Dictate an expense in Expenses", "Log an expense in Expenses"). UI tests:
`-uiTestingDictateRequest` plays the action; the microphone is not used, the request is
counted in `home-dictate`'s value ("requests 1").

## 13. GPS fix and place visited (1.7, his ask 25 Oct 2026; `LocationService.swift`, `Core/…/Places.swift`, `PlaceChooser`)

- **GPS fix**: location is asked at the best accuracy the iPhone gives, when the app comes
  to the front and when the microphone is tapped to start. A new expense keeps the latest
  fix at the moment its check sheet opens (`Draft.fix`); editing never changes it. No fix
  (location off, not yet known) = none. Expenses from before 1.7 have none.
- **Place visited**: a name, chosen on the check sheet. The list is every name already used
  (once each, any spelling; the latest spelling wins) — no separate list in Settings.
- **Chooser** (`PlaceChooser`): at the top a typing line "New place" (`place-new-name`) with
  **Add** (`place-new-add`, off while empty; Done on the keyboard does the same) — a name
  already used (any spelling) is chosen instead; no pop-up (the UI tests could not reach one).
  Then None (`place-choice-none`); **Nearby**: the places used within 1 km of this expense's
  fix, nearest first; then the other places, the latest used first (`place-choice-0` …
  counting on from Nearby).
  Without a fix the footer says so and there is no Nearby section.
- **Filled in by itself**: a new expense gets the place used nearest to its fix within 150 m
  (`Places.sameSpot`); none → "No place". He can change it before Save.
- Nothing about the position leaves the iPhone except in the CSV he exports.
- **Settings › Places** (`PlacesScreen`): every place used, A to Z, once each (any spelling),
  with how many expenses have it (`places-row-0` …; empty: `places-empty`). Tap = rename on
  its own screen (`places-rename-name`, Save `places-rename-save`, or Back): every expense with it follows;
  onto another place's name (any spelling) joins the two in that place's spelling. Swipe =
  delete, always asked first ("Delete place" `places-delete-confirm` / "Keep it"): its
  expenses keep no place, the expenses stay. No Add: a place exists while an expense has it.

## 14. Maps (1.8, his choice 26 Oct 2026 of concepts A, B and C; `MapViews.swift`)

Apple's map (MapKit). Nothing is sent anywhere by the app; Apple's map loads its own tiles.

- **A · on the check sheet**, after the place: when the draft has a fix, a small map that does
  not move (`FixPreview`, 120 pt) with the teal dot, and under it "<area> · ±<accuracy> m"
  (either part left out when unknown; neither: "Where it was logged"). The row (`entry-map`)
  opens C. Beside the place pill, while the place is still the one filled in by itself:
  "auto · N m away" (`entry-place-auto`; N = metres to the nearest earlier expense with that
  place, `Places.nearest`).
- **C · Where** (`ExpenseMapScreen`): a big map (it moves) with the dot; rows: description and
  amount, When, Place, Area, Position (`map-position`, six decimals), Accuracy (`map-accuracy`,
  when known); **Open in Maps** (`map-open`) opens `https://maps.apple.com/?ll=<lat>,<lon>&q=<place>`.
  Footer: "The position stays on this iPhone."
- **B · Today on the map** (`TodayMapScreen`): today's expenses, oldest first, numbered 1, 2 …
  only those with a fix; all on one map (fitted to them), then the list (`todaymap-row-0` …:
  number or a grey "–", description, time · place or "no position", amount) with Today's total
  in the header. A row with a fix opens C. Footer `todaymap-count`: "N of M have a position".
  None with a fix: "No expense today has a position yet." (`todaymap-empty`).
