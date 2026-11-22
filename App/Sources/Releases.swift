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
        Release(version: "1.32", date: "22 November 2026", lines: [
            "Date and place in full: on the main screen, the grey line under the time now shows the whole date and the whole place, for example “Sun, 22 Nov · Benalmádena, Spain”. Before (1.31), the line was cut off, for example “Sun, 22… · Benalm…”, although there was free space.",
            "Why: the currency button (“EUR · auto”) now stands beside the big time only, not beside both lines. So the line under it can use the whole width of the card. The button works as before.",
            "Only a very long place name is still shortened at its end, with “…”. The date is never shortened.",
        ]),
        Release(version: "1.31", date: "22 November 2026", lines: [
            "Who it was for, with one tap: on the check sheet (New expense and Edit expense), under the category, there are now four buttons on one line: Martin, AMS, Anna and Others. Tap one and it is chosen at once; you stay on the sheet. Before (1.30), there was one label, for example “Martin”, and to change it you had to tap it, choose in a list and come back.",
            "Which one is chosen: the chosen button is full colour (Martin blue, AMS yellow, Anna green, Others grey). The other three are light, in their own colour. Only one is chosen at a time.",
            "Unchanged: a new expense still starts with Martin chosen. “Same again” and the favourites row keep the person of the expense. The coloured tags on the rows in the lists are as before.",
            "Guide: How it works (For whom) and “Signs in this app” now describe the four buttons.",
        ]),
        Release(version: "1.30", date: "21 November 2026", lines: [
            "Route length under the map: on the “On the map” screen, in the small grey lines under the map (where “N of M have a position” is), there is now a new line that says how long the drawn route is: “Route: about 850 m” or “Route: about 2.4 km”. Before (1.29) there was no length anywhere. The number is rounded like the place distances: whole 10 metres below 1 km (850 m), one decimal from 1 km to 10 km (2.4 km), whole kilometres from 10 km up (12 km). A very short route says “Route: under 50 m”.",
            "Several days add up: in “This week” and “Last week”, when the map shows the routes of several days, the line adds them up and says “Routes: about 5.3 km in all”. When you choose one day with the day buttons, only that day’s route is counted (“Route: about 1.2 km”). Tap the day again and the whole week is back.",
            "How it is measured: the number is the length of the dotted line as it is drawn: along the streets where it follows them, along the gentle bow everywhere else. So it is the way as drawn, not a measured walk; the app keeps no GPS track. While the street ways are still being looked up, the number can change a little when they arrive.",
            "When the line is shown: only when a route is drawn, that is two or more pins with a position. With one pin or none there is no line. Month has no route, so it has no length line either.",
            "Direction arrows: on every dotted route there is now a small hand-drawn arrowhead (a chevron with round ends) halfway along each stretch from one pin to the next. It points the way you went, from the older pin to the newer one. It has the colour of its route (teal in Today, the day’s colour in This week and Last week) with a thin white edge, so you see it on any map. Before (1.29) only the numbers told the order. Now you see it on the line itself.",
            "The map no longer turns or tilts: so that the arrows always point the right way, rotating the map with two fingers and tilting it are switched off. Before (1.29) you could turn the map. You can still move it with one finger and zoom with two fingers or a double tap.",
            "Unchanged: the dots, the streets and bows, the pins, their numbers and colours, the day buttons and the lists.",
            "Guide: How it works (the map) now tells about the route length line, the arrows and that the map does not turn, and “Signs in this app” has a new sign: a small arrowhead on the dotted line means the way you went, from the older pin to the newer.",
        ]),
        Release(version: "1.29", date: "21 November 2026", lines: [
            "Dotted routes: on the “On the map” screen the route lines are now a row of small round dots, like a path drawn by hand. Before (1.28) a route was a thin solid line, 3 points wide, straight from pin to pin like a ruler. Now the dots are 4 points wide, in the same colours: teal in Today, the day’s colour for each day in This week and Last week. Month still has no line.",
            "Along the streets when the pins are close: between two pins that are not more than 2 km apart (in a straight line), the dots now follow the streets, the way on foot that Apple Maps finds between the two places. Before, the line cut straight across houses and water. The street way is used only when Apple Maps finds one and it is not more than three times as long as the straight line, so you never get a strange long detour. Pins closer than 30 metres to each other get no street way.",
            "A gentle bow everywhere else: when the pins are farther than 2 km apart, when Apple Maps finds no way, when there is no internet, or when the pins are very close, the dots go in a soft hand-drawn bow from pin to pin instead of a ruler-straight line. One bow after the other bends to the other side, with a small natural wobble, so a route looks like a hand-drawn path.",
            "Internet: the street ways need the internet. They are looked up when the map opens and remembered while the screen stays open. Until they arrive, or without internet, you see the bows; then the street ways replace them. The order is still oldest first, pin 1 to 2 to 3, and a route still needs two or more pins with a position that day. Pins, numbers, colours and day buttons are unchanged.",
            "Your data: to ask for a way, the app sends only the two pin positions to Apple Maps. Nothing else leaves the iPhone.",
            "Guide: How it works (the map) and “Signs in this app” now say that the line between pins is dotted, in the day’s colour (teal in Today), and that it follows the streets when the pins are close and is a gentle bow otherwise.",
        ]),
        Release(version: "1.28", date: "21 November 2026", lines: [
            "A route on Today too: on the “On the map” screen, in “Today”, a thin teal line now joins today’s pins in the order you paid (oldest first, pin 1 to 2 to 3), so you see the way you went today. It is drawn when two or more of today’s expenses have a position; with one pin or none there is no line. Before (1.27) Today showed only the pins, without a line. The line is as thin as the week routes.",
            "“This week” and “Last week” are unchanged (a thin line per day in the day’s colour, two or more pins); “Month” still has no line, because a month has too many days for one line.",
            "Guide: How it works (the map) and “Signs in this app” now say that Today has a teal route and the week maps have one line per day in the day’s colour; Month has none.",
        ]),
        Release(version: "1.27", date: "20 November 2026", lines: [
            "Day buttons under the map: in “This week” and “Last week” on the “On the map” screen, the colour line under the map is now a row of small day buttons. Before (1.26) it was a line of coloured dots with the short day name (“● Mon ● Tue …”) that you could only look at. Now each day that has a pin is a small button with the short day name (“Mon”, “Fri”) in its day colour on a light background of that colour; the dots are gone, the colour of the button is the sign.",
            "Tap a day to see only that day: the map shows only that day’s pins and zooms to them, the list below shows only that day’s expenses, the button turns full colour with white writing, the line “N of M have a position” counts only that day, and the list header shows the day and its total (“This week · Fri”). Tap the same day again, or switch between Today, This week, Last week and Month, and the whole week is back. Before, the colours were only a picture and nothing happened when you tapped.",
            "The numbers stay the week’s numbers: when only Friday shows, a pin that was number 5 in the week is still 5, so the numbers never change under you.",
            "A hint under the map: a small grey line says what the buttons do: “Tap a day to show only that day.” and, when a day is chosen, “Only Fri · tap it again for the whole week.” Before, nothing said that the colours could be tapped.",
            "Route lines: new, for each day with two or more pins a thin line in that day’s colour joins its pins in the order you paid (oldest first), so you see the way you went that day. A day with one pin has no line. Before, the pins stood alone. In Today and Month there are no lines.",
            "Today and Month are unchanged: pins and numbers stay teal, numbered oldest first, with no day buttons and no lines.",
            "Guide: How it works (the map) now tells about the day buttons and the route lines, and “Signs in this app” describes the buttons (a full-colour button = that day shown alone) and the thin coloured line between pins.",
        ]),
        Release(version: "1.26", date: "20 November 2026", lines: [
            "Map pins by day: in “This week” and “Last week” on the “On the map” screen, every numbered pin now has the colour of its weekday: Monday blue, Tuesday green, Wednesday orange, Thursday purple, Friday pink, Saturday red, Sunday brown. Before (1.25) all pins were teal, so you could not see which day a pin belonged to. Now you see at a glance where you were on which day.",
            "Matching numbers in the list: the round number at the left of each row below the map has the same day colour as its pin, so a row and its pin match. Before, all the numbers were teal. A row without a position still has the grey “–”. The numbers still count oldest first across the whole week.",
            "A colour line under the map: new, directly under the map, a small line explains the colours: a small coloured dot and the short day name (“● Mon ● Tue …”), Monday first, and only for the days that have a pin. Before, there was no such line. In Today and Month it is not shown.",
            "Today and Month are unchanged: pins and numbers stay teal, numbered oldest first, and there is no colour line.",
            "Guide: How it works (the map) now tells about the day colours and the colour line, and “Signs in this app” says that the numbered circle takes the colour of its day in This week and Last week.",
        ]),
        Release(version: "1.25", date: "20 November 2026", lines: [
            "Three small cards under Today: before, “Yesterday ›”, “This week · 901 kr · 13 expenses ›” and “Last week · … ›” were three quiet grey lines, one under the other. Now they are three small cards on one line. Each card has its name in its own colour (Yesterday amber, This week teal, Last week indigo), the total in large, bold whole kronor (“901 kr”) and, underneath, for Yesterday how many expenses (“3 expenses”), for This week and Last week seven tiny bars, Monday to Sunday.",
            "Tap a card: it turns full colour with white writing and its expenses open right below it. Tap it again and it closes. Only one is open at a time: tap another card and it switches. All three are closed when the app opens. Before, each line folded open on its own and several could be open together. A card with no expenses shows “0 kr” and does nothing when you tap it; before, an empty line was simply not there.",
            "Below an opened This week or Last week there is now a small line with how many expenses (“13 expenses”). With more than five expenses it also shows the light teal square and “= the 5 highest”; the five highest rows are still tinted light teal, as in 1.23. The big card that used to open first (large total and bars, 1.22) is gone, because the small card now carries the total and the bars.",
            "Yesterday: before, the opened Yesterday started with a summary card (1.15). Now the total and the number of expenses are on the small card itself, and below it you see only yesterday’s expenses.",
            "The weekly budget: before, “· SEK 766 left” (or “· SEK 120 over” in orange) stood at the end of the grey This week line. Now the weekly budget’s left/over shows on the opened This week, in the line with the number of expenses.",
            "Rows behave as before: tap to change, swipe to delete or “Same again”, whole amounts, weekday and time on the week rows.",
            "The map shows more than today: the map button at the top still opens on Today, but a switch at the top now chooses Today, This week, Last week or Month (this calendar month). The pins, their numbers (oldest first), the line “N of M have a position” and the list below all follow your choice, and the list header shows the name of the choice and its total. In This week and Last week each row shows the weekday and time (“Fri 10:24”); in Month the date and time (“20 Nov · 10:24”). The title is now “On the map”; before it was “Today on the map” and it showed only today.",
            "Guide: How it works is updated (the three cards, the budget, the map), and “Signs in this app” has a new sign for the card colours: amber is Yesterday, teal is This week, indigo is Last week, and a full-colour card is the open one. The sign about the small arrow › after those lines is gone, because the arrow is gone.",
        ]),
        Release(version: "1.24", date: "20 November 2026", lines: [
            "Today is marked the same way everywhere: in Statistics › “Last 30 days”, today’s bar is no longer full teal. It is now light teal, like the other days, and a small bold teal word “Today” stands above it, so you still see at once which bar is today. The bars of the other days are a little lighter than before as well. Before (1.9 to 1.23), today’s bar was full teal and the other days a bit darker, with no word. Now the whole app agrees: a light bar, and a teal mark for today (the bold day letter under the small week bars, the word “Today” in the 30-day chart).",
            "The screen explains the coloured rows: when an opened “This week” or “Last week” card has more than five expenses, a small line under “13 expenses” shows a little light teal square and the words “= the 5 highest”. So you no longer have to guess why some rows have a teal background. With five or fewer expenses the line is not shown, because no row is coloured then. Before (1.23), the coloured rows had no explanation on the screen itself, only in How it works.",
            "Guide: How it works is updated for both changes (Statistics, “This week” and “Last week”), and in “Signs in this app” the today sign now covers the 30-day chart too, and the light teal row sign mentions the new little square.",
        ]),
        Release(version: "1.23", date: "20 November 2026", lines: [
            "The five highest expenses are highlighted: in the opened “This week” and the opened “Last week” lists, the five most expensive expenses of that week now have a light teal background on their row, like a highlighter, so you see at once where the money went. What counts is the amount in kronor (an expense in euros is counted at the bank’s rate of its own day). It only happens when the week has more than five expenses; with five or fewer nothing is coloured, because all of them would be. If two cost the same, the one higher in the list wins. Before (1.17 to 1.22), all rows in these two lists looked the same. Today’s and Yesterday’s lists are unchanged.",
            "Today’s bar is no longer strong: in the seven small bars (on the Today card and in the opened “This week” and “Last week” cards), today’s bar is now the same light teal as the days that have passed. Only the little day letter under the bars is still bold teal, so you still see which day is today. Before, today’s bar was full teal and its letter bold teal. Days still to come are still a small grey stub, and the bar heights are as they were.",
            "Guide: How it works is updated for both changes (the bars and the “This week” and “Last week” lists), and in “Signs in this app” the week-bars sign is changed and a new sign is added: a light teal row behind an expense means it is one of that week’s five highest.",
        ]),
        Release(version: "1.22", date: "20 November 2026", lines: [
            "A total card inside “This week”: tap the small grey “This week · SEK 901 · 13 expenses ›” line. The first thing under it is now a card like Today’s: this week’s total big in whole kronor (“901 kr”), under it how many (“13 expenses”), and on the right seven small bars, Monday to Sunday. Today’s bar is full teal, earlier days are light teal, days still to come are a small grey stub. Each bar’s height is that day’s share of the week’s highest day. Then the expenses, as before. Before (1.17 to 1.21), opening it showed only the list, with no total card and no bars. The weekly budget note stays on the grey line, not in the card.",
            "A total card inside “Last week”: tap “Last week · … ›” and the first thing under it is a card with last week’s total big in whole kronor, how many expenses, and seven bars, Monday to Sunday of last week. All days are light teal, because today is not in last week; a day with nothing is a small grey stub. Before, only the list showed. Today’s card and Yesterday’s card are unchanged.",
        ]),
        Release(version: "1.21", date: "20 November 2026", lines: [
            "Which day on the week rows: a row in the opened “This week” and “Last week” lists now starts with the short weekday and then the time, for example “Wed 10:24 · Café”. Before, it showed only “10:24 · Café”, so you could not tell which day it was. Today’s and Yesterday’s rows are unchanged: they show only the time, because the day is clear there.",
            "Whole “+ €8” on the week lines: the small grey “This week · …” and “Last week · …” lines already showed the kronor total in whole kronor (“SEK 901”). When an expense has no exchange rate yet (for example no internet), the line adds it separately, for example “+ €7.50”. That part is now whole too: “+ €8” (half rounds up). Before, it showed the cents. Statistics and everywhere else keep the cents for this part.",
        ]),
        Release(version: "1.20", date: "20 November 2026", lines: [
            "“This week” now folds open: the small grey line “This week · SEK 901 · 13 expenses” (with “· SEK 766 left” or “· SEK 120 over” when you have a weekly budget) has a small arrow ›, like “Yesterday” and “Last week”. Tap it and all of this week’s expenses, Monday to now, show under it, newest first — today’s and yesterday’s too. Tap again to fold them away. It starts folded every time you open the app. Tap an expense to change it, swipe it to the left to delete it (the Undo bar comes), swipe it to the right for “Same again”. Before (1.18 and 1.19), the line was only something to read, not a button.",
            "Whole amounts in the “This week” and “Last week” lists: a row there now shows its amount rounded to whole units, for example “€10” instead of “€10,00”, “€6” instead of “€6,45”, “€53” instead of “€53,15”; half rounds up (“€7,50” becomes “€8”). Only the display in these two folded lists changes. The saved amount, Today’s rows, Yesterday’s rows, the totals and the check sheet keep their cents. The grey “≈ 111 kr” under an amount stays as it was. Before, these rows showed the cents too.",
            "Photo buttons with words: in the new or changed expense, the Photo row now has two small buttons with a picture and a word: “Take photo” (camera, full teal) and “Choose photo” (picture, light teal). Before (1.14 to 1.19), they were two small round icons with no words.",
            "How it works has a new section, “Signs in this app”: every mark and colour that means something — the small arrow ›, the blue, yellow, green and grey tags for who it was for, the orange “over”, the teal dot on the place map, the round category icons, the small photo square, the grey “≈ … kr” line, the week bars, the “EUR · auto” button, the Undo bar and more — each with its meaning in a few plain words. Before, there was no such list.",
        ]),
        Release(version: "1.19", date: "18 November 2026", lines: [
            "Order under Today: the small grey “This week” line now sits under “Yesterday ›” and above “Last week”. Before, it was above Yesterday. When Yesterday is open, its expenses now show directly under it; before, they showed below the Last week line.",
            "Same again on older rows: swipe a row under “Yesterday ›” or “Last week” to the right and tap “Same again”. The same expense is logged again now, today. Before, only Today’s rows had this.",
            "Weekly budget: in Settings, “Weekly budget”, type an amount in kronor. The small grey “This week” line then ends with “· SEK 766 left”, or with “· SEK 120 over” in orange when this week is above the budget. Leave it empty or 0 for no budget; then the line is as before.",
            "Search all expenses: in Statistics, tap “Search expenses”. Type one or more words and you see every expense where the description, category, place, town, who it was for, or the sentence you said contains all the words. Capitals and accents do not matter. Above the list: how many and their total, for example “3 expenses · SEK 245”. The newest is first; tap one to change it. Before, there was no search for expenses.",
            "Place totals: in Settings › Places, each place now shows its total in kronor next to the number of expenses, for example “SEK 1 450 · 12”. Before, it showed only the number.",
            "Photo zoom: in the big photo, pinch with two fingers to zoom in (up to 5 times) and drag to move around. Double-tap zooms to 2.5 times, and again to go back. Before, the photo could not be zoomed.",
            "Monthly report: in Statistics, tap “Monthly report”. Choose “This month” or “Last month” and see the total, the number of expenses and the total for each category. Tap the “Share PDF” button to save or send a PDF (A4) with the total, the categories and every expense of the month: date, time, description, category, who for, place and amount. If nothing was logged, it says “Nothing was logged in this month.”",
            "Favourites row: on the main screen, under the microphone and the typing line, there are up to three small buttons with the descriptions you log most, for example “Coffee”, “Lunch”, “Bus”. One tap opens the check sheet with that expense filled in for now: its latest amount, currency, category, who it was for and place — the same as “Same again”. Check it and tap Save. A description appears only after you logged it at least 3 times. Before, there was no such row.",
            "Undo after delete: when you delete an expense on the main screen (Today, Yesterday or Last week), a small bar appears at the bottom for 6 seconds, for example “Deleted Coffee”, with an “Undo” button. Undo brings the expense back exactly as it was, with its photo. Before, a delete could not be taken back.",
        ]),
        Release(version: "1.18", date: "18 November 2026", lines: [
            "Main screen: a new small grey line just above “Yesterday ›”, for example “This week · SEK 1 234 · 12 expenses” — this week’s total in kronor and how many, Monday to today. It is only a line to read. It is hidden when nothing was logged this week. The Today card with its small week bars stays as it is.",
        ]),
        Release(version: "1.17", date: "18 November 2026", lines: [
            "Last week now folds open like Yesterday: tap the small grey “Last week · …” line and last week’s expenses show under it, newest first. Tap it again to fold them away. It starts folded every time you open the app. Tap an expense to change it; swipe it to the left to delete it.",
            "The Place page has a small map at the bottom, under the list. Each place with a GPS position shows as a small dot with its name, where you used it last; the teal dot is where this expense was logged. Tap a name on the map to choose that place. The map follows the search: only the places still in the list are on it.",
        ]),
        Release(version: "1.16", date: "18 November 2026", lines: [
            "Place page: a new button at the top right, “Nearest first”. Tap it and all places show in one list, the nearest at the top; places without a distance come last. The button then says “Usual order” and brings back Nearby and Other places. The app remembers your choice. The search works in both orders.",
            "Main screen: under the small grey “Yesterday ›” there is now a second small grey line, for example “Last week · SEK 1 234 · 12 expenses” — last week’s total in kronor and how many, Monday to Sunday. It is only there when something was logged last week.",
        ]),
        Release(version: "1.15", date: "18 November 2026", lines: [
            "Yesterday has a summary now, like Today: open the small grey “Yesterday ›” and the first thing you see is yesterday’s total in kronor in large numbers, with how many expenses under it. The “Yesterday ›” line itself stays small and quiet.",
            "The Place page has a search field at the top, “Search places”. Type a few letters and only the places with those letters stay in the list; capitals and accents do not matter. Clear it to see all again.",
            "Every place on the Place page shows how far away it is, in grey on the right: for example “80 m”, “3.4 km” or “25 km”. It is measured from where this expense was logged to the nearest spot where you used that place before. A place without a GPS position shows no distance.",
            "A photo you take with the camera in the app is now also saved in Apple Photos. The first time, the iPhone asks if the app may add photos. A photo you choose from your library is not saved a second time. If you say no, the photo still stays with the expense.",
        ]),
        Release(version: "1.14", date: "4 November 2026", lines: [
            "Yesterday is now almost invisible: a small grey “Yesterday ›” under Today, with no count, no sum and no card behind it. Tap it to fold yesterday’s expenses open, tap again to fold them away.",
            "The photo buttons on the check sheet are small round icons, no words: the camera (filled) takes a photo, the picture (light) chooses one from your photo library. Both icons are hand-drawn, in the style of your other apps.",
        ]),
        Release(version: "1.13", date: "4 November 2026", lines: [
            "A photo with each expense: on the check sheet, tap “Take photo” for the camera or “Choose photo” for your photo library — for example the receipt, or what you bought.",
            "The photo shows small on the expense’s row in the list. Open the expense and tap the photo to see it big; Done closes it.",
            "“Remove photo” on the check sheet takes it away again. One photo per expense; the photos stay on this iPhone only.",
            "The first time you take a photo, the iPhone asks if the app may use the camera.",
        ]),
        Release(version: "1.12", date: "4 November 2026", lines: [
            "Yesterday: a new line under Today with yesterday’s number of expenses and their total in kronor. Tap it and yesterday’s expenses fold open, so you can quickly check that everything was entered. Tap it again to fold them away.",
            "It starts folded every time you open the app.",
            "Tap one of yesterday’s expenses to change it; swipe it to the left to delete it.",
        ]),
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
            "Tap the currency button beside the time at the top (for example “EUR · auto”) to fix one by hand, or set it back to automatic. Under the time, a grey line shows the date and the place you are in.",
        ]),
        Section(title: "Language", lines: [
            "The globe chooses the language you dictate in: English, Svenska or Deutsch.",
        ]),
        Section(title: "Today", lines: [
            "The list shows today’s expenses and their total in kronor.",
            "The card at the top shows today’s total in large numbers and how many expenses, and on the right this week as small bars, all in light teal; only today’s day letter is bold.",
            "An amount in euros has its kronor under it (≈ SEK 125), at the bank’s rate of its day.",
            "Tap an expense to change it. Swipe it to the left to delete it. Swipe it to the right (or open it and tap “Same again, now”) for the same expense again, now, opened for checking. Rows in the opened Yesterday, This week and Last week cards have it too: swipe to the right and tap “Same again”; the same expense is logged again today, now.",
            "Save gives a short vibration and shows “Saved”.",
            "Under the microphone and the typing line there are up to three small buttons with the descriptions you log most often, for example “Coffee”, “Lunch”, “Bus”. One tap opens the check sheet with that expense filled in for now: its latest amount, currency, category, who it was for and place — the same as “Same again”. Check it and tap Save. A description is there only after it was logged at least 3 times.",
            "When you delete an expense here (Today, Yesterday or Last week), a small bar appears at the bottom for 6 seconds: “Deleted Coffee” and “Undo”. Tap Undo and the expense comes back exactly as it was, with its photo.",
            "Settings › Weekly budget: type an amount in kronor. When the This week card is open, the line with the number of expenses then also says “· SEK 766 left”, or “· SEK 120 over” in orange when this week is above the budget. Empty or 0 means no budget, and the line is as before.",
            "In the big photo, pinch with two fingers to zoom in (up to 5 times) and drag to move around. Double-tap zooms to 2.5 times and back.",
            "A photo with an expense: on the check sheet, in the Photo row, tap “Take photo” (camera) to take one or “Choose photo” (picture) to choose one from your photo library. It shows small on the row; open the expense and tap it to see it big. “Remove photo” takes it away. One photo per expense, kept with the expense on this iPhone.",
            "A photo you take with the camera in the app is also saved to Apple Photos (your photo library). The first time, the iPhone asks if the app may add photos. A photo you choose from the library is not saved again. If you say no, the photo still stays with the expense.",
            "Under the Today card are three small cards on one line: “Yesterday” (amber), “This week” (teal) and “Last week” (indigo). Each shows its name in its own colour and its total in large, bold whole kronor. Under the total, Yesterday shows how many expenses (“3 expenses”); This week and Last week show seven tiny bars, Monday to Sunday (days with nothing or still to come are a small grey stub, each bar as tall as that day’s share of the week’s highest day). A card with no expenses shows “0 kr” and does nothing when tapped. Before 1.25 these were three quiet grey lines with an arrow ›.",
            "Tap a card and it turns full colour, with white writing, and its expenses open under it, the newest first; tap it again to close it. Only one card is open at a time: tapping another one switches. All are closed every time the app opens. Tap an expense to change it, swipe it to the left to delete it, swipe it to the right for “Same again”. In This week and Last week each row starts with the short weekday and the time (“Wed 10:24 · Café”), and the amounts are rounded to whole units (€10 instead of €10,00; an amount with no exchange rate yet is added to the card’s total separately, whole too, “+ €8”).",
            "Below an opened This week or Last week there is a small line with how many expenses (“13 expenses”) and, with the This week card, the weekly budget’s left/over now shows in that line. When the week has more than five expenses, the line also shows a light teal square and “= the 5 highest”: the five highest (in kronor, at each day’s rate) have a light teal background on their row; ties go to the one higher in the list. With five or fewer nothing is tinted. Below an opened Yesterday there are only yesterday’s expenses; the total and the count are on the card itself.",
            "This week is Monday to today; Last week is the week before it, Monday to Sunday; Yesterday is the day before today. The big week card with the large total and the bars (1.22) and Yesterday’s summary card (1.15) are gone: the small card carries the total and the bars.",
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
            "Under the category, the check sheet has four buttons on one line: Martin, AMS, Anna and Others. They say who the expense was for. Tap one to choose it; the chosen one is full colour, the others are light. A new expense starts with Martin.",
            "Every expense in the lists shows it in colour: Martin blue, AMS yellow, Anna green, Others grey.",
        ]),
        Section(title: "Place visited", lines: [
            "The last line of the check sheet is the place you visited, for example “ICA Odenplan”. Tap it and choose a place, or type a new one on the top line (“New place”) and tap Add.",
            "At the top of the place page is a search field, “Search places”. Type some letters and the Nearby and Other places lists show only the names that contain them (capitals do not matter). Clear the field to see all places again. “New place” and None stay.",
            "Each place shows on the right, in grey, how far away it is: for example “80 m” (under 1 km, rounded to 10 m), “3.4 km” (under 10 km) or “25 km” (10 km and more). It is the distance from where this expense was logged to the nearest spot where you used that place before. A place with no position, or an expense without a position, shows no distance.",
            "At the top right of the place page is a button, “Nearest first”. Tap it and all places show in one list, “By distance”, the nearest first; places without a distance come last, in their usual order. The button then reads “Usual order” and brings back Nearby and Other places. The app remembers your choice for next time. Search works in both orders. Without a GPS position for the expense, the button is not shown. At the bottom, under the list, is a small map: a small dot with its name for each place that has a GPS position (at the spot where you used it last), and a teal dot for where this expense was logged. Tap a place’s name on the map to choose it, the same as tapping it in the list. The map follows the search: only the places still in the list are shown. If no place and no expense has a GPS position, there is no map.",
            "Every new expense keeps its GPS position. The places you used near it are listed first, under Nearby; the others follow, the latest first.",
            "At the same spot again (within about 150 metres), the place is filled in by itself. You can change it before Save.",
            "Without a position (location turned off, or an expense from before 1.7) there is no Nearby list; the places are all still there.",
            "When the place was filled in by itself, “auto · 12 m away” beside it says how far away you used it before.",
            "Settings › Places: each place shows its total in kronor and the number of expenses, for example “SEK 1 450 · 12”. Tap a place to rename it (every expense moves with it; a name that is already there joins the two), swipe it to the left to delete it (its expenses keep no place, the expenses stay).",
        ]),
        Section(title: "Maps", lines: [
            "Under the place, the check sheet shows a small map of where the expense was logged, the town, and how exact the position is (±8 m). Tap it for the big map.",
            "The big map shows the time, the place, the town, the position in numbers and how exact it is. Open in Maps opens Apple Maps at that spot.",
            "The map button at the top of the main screen opens “On the map”. It starts on Today, and a switch at the top chooses Today, This week, Last week or Month (this calendar month). The pins (numbered in the order you paid, oldest first), the line “N of M have a position” and the list below follow the choice; the list header shows the choice’s name and its total. In This week and Last week a row shows the weekday and time (“Fri 10:24”); in Month the date and time (“20 Nov · 10:24”). One without a position has a grey “–” and is not on the map. In This week and Last week each pin and its number in the list have the colour of their weekday (Monday blue, Tuesday green, Wednesday orange, Thursday purple, Friday pink, Saturday red, Sunday brown), and under the map a row of small day buttons shows which colour is which day (the short day name in its colour). Tap a day to show only that day: the map zooms to its pins, the list shows only its expenses and total, and the button turns full colour; tap it again, or change the switch, for the whole week. The pin numbers stay the week’s numbers. For each day with two or more pins a dotted line in the day’s colour joins them in the order you paid, so you see the way you went. In Today a dotted teal line joins today’s pins in the order you paid when two or more have a position. Between pins that are not more than 2 km apart the dots follow the streets (the way on foot that Apple Maps finds, which needs the internet); farther apart, or without a way or internet, they go in a gentle hand-drawn bow. Until the street ways arrive you see the bows. The app sends only the two pin positions to Apple Maps. Month has no buttons and no lines. A small arrowhead halfway along each stretch from one pin to the next points the way you went, from the older pin to the newer one; so that the arrows stay right, the map does not turn or tilt (you can still move and zoom it). Under the map, among the small grey lines, “Route: about 850 m” (or “about 2.4 km”, “under 50 m”) tells how long the drawn route is; with several days in This week or Last week it says “Routes: about 5.3 km in all”, and with one day chosen only that day’s route. It is the length of the dotted line as drawn (along the streets where it follows them, along the bow elsewhere), not a measured walk, and it can change a little when the street ways arrive. It shows only when a route is drawn; Month has none.",
            "An expense without a position (location turned off, or from before 1.7) has no map.",
        ]),
        Section(title: "Statistics", lines: [
            "The chart button at the top opens Statistics.",
            "Totals: this week (from Monday), this month and last month, each with the average per day.",
            "Last 30 days: one bar per day, light teal, today the last. A small bold teal word “Today” stands above today’s bar; days with nothing are a thin stub.",
            "By category: a ring in the category colours, then each category with how many and its total, for the week, the month, last month or all time. Tap one to see its expenses.",
            "What you spend most on: the descriptions you use most often, how many times, and their total.",
            "Search expenses: type one or more words; every expense whose description, category, place, town, who it was for or dictated sentence contains all of them is listed, the newest first, with “3 expenses · SEK 245” above. Capitals and accents do not matter. Tap one to change it.",
            "Monthly report: choose This month or Last month to see the total, how many expenses and the total for each category. “Share PDF” makes an A4 PDF with the total, the categories and every expense of the month, to save or send.",
            "Earlier days: tap a day to see its expenses; tap one to change it, swipe to delete it.",
        ]),
        Section(title: "Kronor", lines: [
            "Every total is in kronor. An amount in euros is counted at the European Central Bank’s rate of its day; on a weekend or a holiday, the last rate before it.",
            "The rates are fetched over the internet and kept on the iPhone. Only dates and currency names are sent, never an expense.",
            "Without a rate yet (offline), that amount is shown apart, for example “+ €12.50”, until the iPhone is online.",
        ]),
        Section(title: "Signs in this app", lines: [
            "A small card under Today in its own colour: amber is Yesterday, teal is This week, indigo is Last week. A card in full colour with white writing is the open one; tap it again to close it.",
            "Blue tag “Martin”, yellow tag “AMS”, green tag “Anna”, grey tag “Others”: who the expense was for. The tag is on every row.",
            "The four buttons Martin, AMS, Anna and Others on the check sheet: the one in full colour is chosen; the light ones are not. One tap chooses another.",
            "Orange “· SEK 120 over” in the line with the number of expenses under the opened This week card: this week is above your weekly budget. Without orange, “· SEK 766 left” is what is left of it.",
            "A round coloured icon at the left of a row: the category. Each category has its own icon and colour; a new one starts grey.",
            "A small square picture on the right of a row: the expense has a photo. Open the expense and tap it to see it big.",
            "A grey “≈ SEK 125” under an amount: what an amount in another currency is in kronor, at the bank’s rate of that day.",
            "Amounts like “€10” in the opened “This week” and “Last week” lists: rounded to whole units, only there. The same goes for the “+ €8” beside the total of the “This week” and “Last week” cards (an amount with no exchange rate yet). Everywhere else the amount shows its cents.",
            "The small bars on the Today card and on the This week and Last week cards: one per day, Monday to Sunday. The bold teal letter under a bar is today (only on Today and This week); the bars are light for today and for days that have passed; a short grey bar is a day with nothing spent or a day still to come. In Statistics › Last 30 days the same mark is the small bold teal word “Today” above today’s bar; that bar is light teal too, never full teal.",
            "A light teal background behind an expense in the opened “This week” or “Last week” list: it is one of that week’s five highest expenses (in kronor). Only when the week has more than five expenses; then the small line with the count shows the same light teal square and “= the 5 highest”.",
            "A button like “EUR · auto”: the currency is chosen by itself. When you fix one by hand, “auto” is gone.",
            "“auto · 12 m away” beside a place: the place was filled in by itself, because you used it that far from here before.",
            "A small teal dot with a white ring on the place map: where this expense was logged. A small dot with a name: a place you used before. Tap the name to choose the place.",
            "A numbered teal circle on the map: the order you paid in. In This week and Last week the circle has the colour of its day (Monday blue … Sunday brown); the day buttons under the map show which colour is which day, and a full-colour button means that day is shown alone. A grey “–” means that expense has no position and is not on the map.",
            "A dotted line in a colour between pins on the map: the way you went that day, from pin to pin in the order you paid (In Today teal, with two or more pins; in This week and Last week the day’s colour, days with two or more pins). Between close pins (up to 2 km) the dots follow the streets; otherwise they go in a gentle bow. It is a picture of the way, not a measured track.",
            "A small arrowhead on the dotted line: the way you went, from the older pin to the newer one. It sits halfway along each stretch between two pins, in the route’s colour with a thin white edge.",
            "“Route: about 850 m” under the map: the length of the dotted line as drawn (“Routes: … in all” for several days). It is a picture of the way, not a measured walk.",
            "A red microphone or stop square: the app is listening now. Red text under the microphone: something went wrong, for example no microphone permission.",
            "The bar at the bottom with “Undo”: you just deleted an expense; tap Undo within 6 seconds to bring it back.",
            "A full teal button is the main action (for example Save, Take photo). A light teal button is the second choice (for example Choose photo).",
        ]),
        Section(title: "Your data", lines: [
            "Your expenses stay on this iPhone.",
            "Settings › Export all as CSV gives every expense, with its category, place and GPS position, as a file for Numbers or Excel.",
            "The GPS position is used only on this iPhone and in the CSV file. It is never sent anywhere.",
        ]),
    ]
}
