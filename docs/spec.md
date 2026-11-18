# AMS Manual Expenses — specification

What the app does, rule by rule, written from the code (version 1.11, 27 Oct 2026).
Change this file in the same commit as the behaviour it describes.

## 1. The main screen (`ContentView.swift`)

One list, three parts:

1. **Header** (one block since 1.11, §15) — the time (updates every minute) and the date; the place
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
4. **Yesterday** (1.12, his ask: a quick look back when he logs the day's first expense) — its own
   section under Today. First row `yesterday-toggle`: "Yesterday" (headline), "1 expense" / "N expenses"
   (secondary), yesterday's total in kronor on the right (§9, only when there is one) and an accent
   chevron that turns down when open. A tap folds open / shut (animated). Folded at every start
   (plain view state, not remembered). Open: yesterday's expenses newest first (`yesterday-row-0` …,
   the same `ExpenseRow` as Today); a tap opens the editor, swipe left deletes. Open with none:
   "Nothing was logged yesterday." (`yesterday-empty`). Test: `testYesterdayFoldsOpenUnderToday`.

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
value `entry-consumer-value`; chooser `consumer-choice-0` … Martin / AMS / Anna (1.9) / Others; a new
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

## 15. Colours and icons (1.9, his ask 27 Oct 2026: "implement all of them"; `Looks.swift`, `Core/…/Looks.swift`)

- **Category look**: an SF Symbol in a coloured circle (`CategoryIcon`). A new install's ten
  categories each have one (`CategoryLooks.defaults`: Café cup/brown, Groceries cart/green,
  Restaurant fork and knife/orange, Transport car/blue, Shopping bag/pink, Home house/indigo,
  Health heart/red, Leisure masks/purple, Travel airplane/teal, Other grid/grey); any other
  category a grey tag; no category a grey question mark. Shown in every expense row, the
  category chooser, the check sheet (beside the category pill) and Statistics › By category.
- **Settings › Categories**: the icon (`categories-icon-0` …, value = the symbol) is its own
  button; it opens the 17 choices (`icon-choice-0` …; Cancel `icon-cancel`); a tap chooses and
  closes. Kept in UserDefaults `categoryIcons`, "name<TAB>symbol" per line. Renaming keeps the
  look (onto another category: that one's look stays); deleting drops the choice.
- **For whom** (his colours): Martin blue, AMS yellow (dark text), Anna green (new in 1.9,
  `consumer-choice-2`; Others is now `consumer-choice-3`), Others grey. Each row shows the name
  in a small coloured label (`ConsumerTag`, read aloud "for <name>"); the check sheet's pill and
  the chooser use the same colours.
- **Rows** (`ExpenseRow`): icon · description over "time · category" and the For-whom label ·
  amount, and under an amount in another currency "≈ SEK N" at its day's rate (none while the
  rate is missing).
- **Today card**: the first row of Today when there is something: the total (`today-total`,
  34 pt bold) and "1 expense" / "N expenses" (`today-count`). The section header is just "Today".
  1.10 (his pick B of the 27 Oct concept): on its right `WeekBars` (`today-week-bars`; value
  "Mon SEK 0, Tue SEK 125, …"): this week from the iPhone's first weekday, one bar per day,
  height = its kronor over the week's highest day (4 pt stub for none), today full accent colour,
  earlier days lighter, days to come grey; narrow weekday letters under them, today's bold. (1.10
  also had a "This week" sum under the card; 1.11 removed it, his ask: only the small bars.)
  1.11 (his ask "take away all extra space"): the main list has compact section spacing and a
  34 pt minimum row height; the card's row insets are 4 pt top and bottom, each expense row's 3 pt;
  rows use a 26 pt category icon and no gap between their lines. The header is one block: the
  time (32 pt) and under it "Tue 27 Oct · <place>" in grey, the currency button on the right.
  Dictation is one row: the microphone (64 pt) on the left, the typing field and Go beside it,
  the status line under the field.
- **Same again**: swipe a Today row to the right (`row-same-again`; a full swipe runs it at once),
  or open an expense from the main screen and tap **Same again, now** (`entry-same-again`, above
  Delete expense; not in Statistics' lists, which have no location): a new draft with the same
  description, amount, currency, category, For whom and place, the time now, the GPS fix and
  area now, no "Heard"; it opens for checking like any new expense.
- **Saved**: every Save (new or changed) gives the success vibration and shows "Saved"
  (`home-saved`) at the top for 2.5 s (15 s under `-uiTesting`, so the slow CI simulator sees it).
- **Statistics**: above By category's rows a ring (`stats-category-ring`) of the span's
  categories in their colours, the total and the span in the middle. Last 30 days: today's bar
  full colour, the others lighter.
- **App icon**: dark (light teal microphone on near-black) and tinted (white on black, the
  iPhone tints it) versions, both opaque like the main one.

## 1.13 · A photo per expense (his ask, 4 Nov 2026)

- Data: `Expense.photo` (JPEG, longest side 1600 px, quality 0.7, `.externalStorage`) and
  `Expense.photoThumb` (120 px) — both optional, so older expenses simply have none. Draft carries
  both; Save (new or edited) writes them. Never leaves the iPhone (not in the CSV).
- Check sheet, own section after the main one (`PhotoSection` in `PhotoViews.swift`):
  none → "Take photo" (`entry-photo-camera`, filled, only where there is a camera; opens the camera
  full screen) and "Choose photo" (`entry-photo-choose`, bordered; opens the photo library, images
  only; in UI tests it puts in a plain teal test picture instead). With one → the photo 160 pt high,
  full width (`entry-photo`, tap → `PhotoViewer` sheet: the photo fitted, `photo-viewer-image`,
  Done `photo-viewer-done`) and "Remove photo" (`entry-photo-remove`, red, no question; the change
  counts only on Save, Cancel keeps the old one).
- List row (`ExpenseRow`, Today, Yesterday, Statistics' day lists): the small copy 30×30, rounded,
  left of the amount; accessibility label "Photo".
- Camera permission text: "The camera takes a photo of a receipt or of what you bought, kept with
  the expense on this iPhone only."
- Test: `testAPhotoIsKeptWithTheExpense`.

## 1.14 · Quieter Yesterday, icon photo buttons (his asks, 4 Nov 2026)

- `yesterday-toggle` (replaces §4's 1.12 look): "Yesterday" + a small chevron (turns down when
  open), footnote, secondary colour, no row background (`listRowBackground(.clear)`), no count and no
  total — his words: "almost invisible". Behaviour unchanged.
- Photo row (replaces 1.13's two wide buttons): "Photo" in grey on the left; on the right two 40 pt
  circles without words — `entry-photo-camera` (accent fill, white camera) and `entry-photo-choose`
  (light accent, accent picture); accessibility labels "Take photo" / "Choose photo".
- Icons: `LineIcon` draws on the AMS Icon Library grid (24 pt, 1.9 stroke, round ends, no fill).
  `CameraGlyph` = the library's camera; `PictureGlyph` is new (frame, two hills, sun) and not yet
  in the library.


## 1.15 · Yesterday summary, place search and distance, photos to Apple Photos

- **Yesterday card** (adds to §4 and 1.14; the grey `yesterday-toggle` line stays as it is). When open,
  the first row under it is a summary card like Today's but without the week bars: yesterday's total
  in kronor in large numbers (`yesterday-total`, §9, same look as the Today card) and under it the
  count as "1 expense" / "N expenses" (`yesterday-count`). Then yesterday's expenses
  (`yesterday-row-0` …) as before. Nothing logged yesterday: no card, only "Nothing was logged
  yesterday." (`yesterday-empty`). Folded: no card.
- **Place search** (adds to §13, `PlaceChooser`): the system search bar at the top of the place page,
  prompt "Search places". Typing filters the Nearby and Other places lists to the names that contain
  the typed letters, ignoring capitals (a contains match, not only the start). Empty field = all
  places again. The "New place" line (`place-new-name`, `place-new-add`) and None
  (`place-choice-none`) are never filtered. A name that does not match is not shown, and the numbering
  `place-choice-N` follows the shown list.
- **Place distance** (adds to §13): each place row shows its distance on the right, in grey, identifier
  `place-distance-N` on the distance of choice N (the same N as `place-choice-N`). Value = metres from
  this expense's fix to the nearest earlier spot where that place was used (the nearest expense with
  that place and a fix; `Places.nearest`). Format: under 1 km: metres rounded to 10 m ("80 m");
  from 1 km to under 10 km: one decimal ("3.4 km"); from 10 km: whole kilometres ("25 km"). A
  place with no expense that has a position, or an expense (draft) without a fix: no distance, and no
  `place-distance-N` element. None and "New place" have no distance.
- **Photos to Apple Photos** (adds to 1.13): a photo taken with the in-app camera is also saved to the
  photo library (add-only access, `PHPhotoLibrary` `.addOnly`). The first save makes iOS ask for
  permission. A photo chosen from the library is never saved again. If permission is refused, or the
  save fails, nothing is shown and the photo stays with the expense as before. The saved copy is
  independent: removing the photo from the expense, or deleting the expense, does not remove it from
  Apple Photos.
- Permission text, `NSPhotoLibraryAddUsageDescription`: "Photos you take in the app are also saved to
  your photo library."
- Guide (How it works): the Today, Place visited and photo lines are updated for all four changes.

## 1.16 · Nearest first on the place page, Last week line

- **Nearest first** (adds to §13 and 1.15, `PlaceChooser`): a button at the top right of the place page,
  identifier `place-sort`, reading "Nearest first". Tap it and all places show in one list, in a
  section titled "By distance", the nearest first (smallest distance, the 1.15 distance, first). Places
  without a distance come last, in their usual order (the "Other places" order: latest used first). The
  Nearby and Other places lists are not shown in this order. The button then reads "Usual order"; tap it
  and Nearby and Other places come back.
- The choice is remembered: the next time the place page opens, it is in the order you left it. It is
  kept on this iPhone only.
- Without a GPS position for the expense (location turned off, or an expense from before 1.7, or a
  draft without a fix) there is no distance to sort by, so the button is not shown, and the page
  is in the usual order whatever was chosen before.
- The search ("Search places", 1.15) works in both orders: only names that contain the typed letters
  are shown, and the order of what is shown stays as chosen. "New place" and None are never filtered
  and stay in both orders. `place-choice-N` and `place-distance-N` number the places in the shown order.
- **Last week line** (adds to §1 and 1.15): under the small grey "Yesterday ›" line on the main screen
  there is a second small grey line, identifier `last-week-summary`, for example
  "Last week · SEK 1 234 · 12 expenses" (1 expense: "1 expense"). Last week = the week before this
  one, Monday to Sunday. The total is in kronor (euro expenses at their kronor value, as everywhere).
  It is just a line to read: not a button, it does not open or fold anything. Same small grey look as
  "Yesterday ›". Nothing logged last week: the line is not shown.
- Guide (How it works): the Place visited and Today lines are updated for both changes.

## 1.17 · Last week folds open, map on the place page

- **Last week is a button** (changes 1.16, §1): the small grey "Last week · SEK 1 234 · 12 expenses" line
  under "Yesterday ›" is now a button, identifier `last-week-toggle`, with a small arrow like
  "Yesterday ›". Same small grey look and same text as before.
- Tap it and last week's expenses fold open under it, the newest first. Rows are numbered
  `last-week-row-N` in the shown order. Tap it again and they fold away.
- It starts folded every time the app opens. The open or folded state is not remembered.
- Tap an expense to change it (the same check sheet as for Today). Swipe it to the left to delete it.
  Last week = the week before this one, Monday to Sunday, as in 1.16.
- Nothing logged last week: the button is not shown, as before.
- **Map on the place page** (adds to §13, §14, 1.15 and 1.16, `PlaceChooser`): at the bottom of the place
  page, after the place lists, there is a small map, about 150 points high, identifier `place-map`.
- For each place that has a GPS position the map shows a small dot with the place's name. The dot is at
  the spot where that place was used most recently. A teal dot shows where this expense was logged.
- Tap a place's name on the map to choose that place: the same as tapping it in the list (the page
  closes with that place chosen).
- The map follows the search ("Search places", 1.15): only the places still in the list are shown on
  the map. Clear the field and all places with a position are back. The sort order (1.16) does not
  change the map.
- No map when no place and no expense has a GPS position (for example location turned off and no
  place ever used with a position). If only the expense has a position, the map shows just the teal dot;
  if only places have one, just their dots.
- Guide (How it works): the Today line (Last week) and the Place visited line (map) are updated.
