# AMS Manual Expenses — specification

What the app does, rule by rule, written from the code (version 1.1, 22 Oct 2026).
Change this file in the same commit as the behaviour it describes.

## 1. The main screen (`ContentView.swift`)

One list, three parts:

1. **Header** — the time (updates every minute) and the date; the place
   (from location, else the time-zone name); the **currency button**
   (`home-currency`) showing the currency in use and "· auto" when it comes from
   location.
2. **Dictation** — the microphone button (`home-dictate`; red with a stop sign while
   listening), a status line (`home-status`: the hint, "Listening…", the words heard
   so far, or an error in red), and a text field (`home-type-field`) with **Go**
   (`home-type-go`, disabled while the field is empty) for typing the same sentence.
3. **Today** — today's expenses, newest first (`expense-row-0`, `-1`, …), each with
   description, time and amount. The section header holds "Today" and one total per
   currency, sorted by code (`today-total`). Empty: "No expenses yet today."
   (`today-empty`). Tap a row to change it; swipe left to delete it (no question).

Toolbar: the globe (`home-language`) picks the dictation language — English (en-US),
Svenska (sv-SE), Deutsch (de-DE); stored as `dictationLanguage`. The gear
(`home-settings`) opens Settings.

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

Opens for every new expense and when a row is tapped. Shows what was heard
(`entry-heard`), Description (`entry-title`), Amount (`entry-amount`, decimal pad,
comma or point), Currency (`entry-currency`), Time (`entry-time`, date and time).
**Save** (`entry-save`) is off until the amount is a number above 0. **Cancel**
(`entry-cancel`) keeps nothing. An existing expense also has **Delete expense**
(`entry-delete`).

## 6. Settings (`SettingsScreen.swift`)

- **Export all as CSV** (`settings-export`): every expense, oldest first, columns
  Date, Time, Description, Amount, Currency, Place, Time zone; date and time in the
  time zone where it was logged; every field quoted.
- **What's new** (`settings-whatsnew`): `Releases.all`, newest first; the top version
  is `whatsnew-0-version`.
- **How it works** (`settings-howitworks`): `Guide.sections`.
- **Version** (`settings-version`): "version (build)", read from the app itself.
- **Done** (`settings-done`).

## 7. Data (`Expense.swift`)

SwiftData, on the iPhone only. An expense: title, amount, currency, date, time-zone id
and place at the moment it was logged, the sentence heard, created-at.

## 8. Test hooks

`-uiTesting`: the store is in memory and starts empty; location is never asked.
UI tests also pass `-manualCurrency SEK -dictationLanguage en-US -AppleLanguages (en)
-AppleLocale en_US`.
