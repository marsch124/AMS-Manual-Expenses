# AMS Manual Expenses

A small web app for logging expenses during the day by voice.

## What it does

- **Dictate**: tap the microphone and say, for example, "Coffee 45 kronor",
  "Taxi 12 euros 50", "Lunch 129 kr at 1 pm" or "Yesterday parking 40".
  English, Swedish and German keywords are understood.
- **Time**: the current time is used unless you say one ("at 7 pm", "klockan 9.15", "um 14 Uhr").
- **Currency**: if you say a currency (kronor, kr, crowns, SEK, euro, €) that is used.
  Otherwise the default comes from the phone's time zone: Stockholm → SEK, euro-zone countries → EUR.
  Tap the currency button to override it; hold it to return to automatic.
- **Check before saving**: every entry is shown for correction before it is saved.
- Today's list with totals per currency, tap an entry to edit or delete, and CSV export of everything.

Data is stored only on the device (browser local storage). Nothing is sent anywhere.

## Run locally

    python3 -m http.server 8000

Open http://localhost:8000. Run the parser tests with `npm test`.
