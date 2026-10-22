import Foundation

/// The result of reading one dictated sentence.
public struct ParsedExpense: Equatable, Sendable {
    public var title: String
    public var amount: Double?
    public var currency: String
    /// True when the currency was said out loud rather than taken from the default.
    public var currencySpoken: Bool
    public var date: Date
    /// True when a time or "yesterday" was said.
    public var timeGiven: Bool
    public var original: String
}

/// Turns a sentence such as "Taxi 12 euros 50 at 9 am" into an expense.
/// Understands English, Swedish and German keywords.
public enum ExpenseParser {
    static let currencyWords: [(code: String, word: String)] = {
        let map: [String: [String]] = [
            "EUR": ["euros", "euro", "eur", "€", "cents", "cent"],
            "SEK": ["swedish crowns", "swedish kronor", "kronor", "kronan", "krona", "kronen", "krone",
                    "crowns", "crown", "sek", "kr", "spänn", "öre"],
        ]
        // Longest first so "swedish crowns" wins over "crowns".
        return map.flatMap { code, words in words.map { (code: code, word: $0) } }
            .sorted { $0.word.count > $1.word.count }
    }()

    /// Words that carry no meaning for the description.
    static let filler = [
        "i spent", "i paid", "spent", "paid", "cost", "costs", "for", "on", "at", "a", "an", "the",
        "and", "och", "und", "jag betalade", "betalade", "kostade", "för", "på", "ich habe", "bezahlt",
        "für", "ausgegeben", "today", "idag", "heute",
    ]

    static let currencyAlt = currencyWords.map { NSRegularExpression.escapedPattern(for: $0.word) }.joined(separator: "|")
    static let currencyRe = regex(#"(^|[^\p{L}])("# + currencyAlt + #")(?=$|[^\p{L}])"#)
    static let dayRe = regex(#"(^|[^\p{L}])(yesterday|igår|i går|gestern)(?=$|[^\p{L}])"#)
    static let timeRe = regex(#"(?:\b(?:at|around|klockan|kl\.?|um|gegen)\s+(\d{1,2})(?:[:.](\d{2}))?\s*(a\.?m\.?|p\.?m\.?|uhr)?)|(?:\b(\d{1,2})(?:[:.](\d{2}))?\s*(a\.?m\.?|p\.?m\.?|uhr)(?!\p{L}))"#)
    static let numberRe = regex(#"\d{1,3}(?:[ .,]\d{3})+(?:[.,]\d{1,2})?|\d+(?:[.,]\d{1,2})?"#)
    // "12 euros 50", "12 euro and 50 cents", "45 kronor och 50 öre"
    static let centsTailRe = regex(#"^\s*(?:"# + currencyAlt + #")\s*(?:(?:and|och|und)\s*)?(?:(\d{2})(?!\d)|(\d{1,2})\s*(?:cents?|öre))(?=$|[^\p{L}\d])"#)
    static let edgeFillerRe: NSRegularExpression = {
        let alt = filler.sorted { $0.count > $1.count }.map(NSRegularExpression.escapedPattern(for:)).joined(separator: "|")
        return regex(#"^(?:(?:"# + alt + #")\s+)+|(?:\s+(?:"# + alt + #"))+$"#)
    }()

    public static func parse(_ input: String, defaultCurrency: String, now: Date = Date(), calendar: Calendar = .current) -> ParsedExpense {
        let original = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let (date, timeGiven, rest) = extractTime(original, now: now, calendar: calendar)
        let ns = rest as NSString

        struct Num { let value: Double; let range: NSRange }
        struct Cur { let code: String; let word: String; let range: NSRange }

        let nums: [Num] = numberRe.matches(in: rest, range: fullRange(rest)).compactMap { m in
            toNumber(ns.substring(with: m.range)).map { Num(value: $0, range: m.range) }
        }
        let curs: [Cur] = currencyRe.matches(in: rest, range: fullRange(rest)).map { m in
            let r = m.range(at: 2)
            let word = ns.substring(with: r).lowercased()
            return Cur(code: currencyWords.first { $0.word == word }?.code ?? defaultCurrency, word: word, range: r)
        }
        func onlySpaceBetween(_ a: Int, _ b: Int) -> Bool {
            b >= a && ns.substring(with: NSRange(location: a, length: b - a)).trimmingCharacters(in: .whitespaces).isEmpty
        }

        // Pick the number right next to a currency word; otherwise the largest number.
        var amountNum: Num?
        var currency: String?
        for c in curs where !["cents", "cent", "öre"].contains(c.word) {
            let before = nums.last { NSMaxRange($0.range) <= c.range.location && onlySpaceBetween(NSMaxRange($0.range), c.range.location) }
            let after = nums.first { $0.range.location >= NSMaxRange(c.range) && onlySpaceBetween(NSMaxRange(c.range), $0.range.location) }
            if let n = before ?? after {
                amountNum = n
                currency = c.code
                break
            }
        }
        if amountNum == nil { amountNum = nums.max { $0.value < $1.value } }
        if currency == nil { currency = curs.first?.code }

        var amount = amountNum?.value
        var removals: [NSRange] = []
        if let n = amountNum, let whole = amount {
            removals.append(n.range)
            if whole == whole.rounded() {
                let start = NSMaxRange(n.range)
                if let m = centsTailRe.firstMatch(in: rest, range: NSRange(location: start, length: ns.length - start)) {
                    let cents = Double(group(m, 1, in: rest) ?? group(m, 2, in: rest) ?? "0") ?? 0
                    amount = whole + cents / 100
                    removals.append(m.range)
                }
            }
        }

        // Build the description from what is left.
        var text = rest as NSString
        for r in removals.sorted(by: { $0.location > $1.location }) {
            text = text.replacingCharacters(in: r, with: " ") as NSString
        }
        var title = text as String
        title = currencyRe.stringByReplacingMatches(in: title, range: fullRange(title), withTemplate: "$1 ")
        title = dayRe.stringByReplacingMatches(in: title, range: fullRange(title), withTemplate: "$1 ")
        title = title.replacingOccurrences(of: #"[,.;:!?]+"#, with: " ", options: .regularExpression)
        title = title.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
        // Strip filler words only at the start and end, so "coffee and cake" stays intact.
        var previous: String
        repeat {
            previous = title
            title = edgeFillerRe.stringByReplacingMatches(in: title, range: fullRange(title), withTemplate: "")
                .trimmingCharacters(in: .whitespaces)
        } while title != previous
        if filler.contains(title.lowercased()) { title = "" }
        if let first = title.first { title = first.uppercased() + title.dropFirst() }

        return ParsedExpense(
            title: title,
            amount: amount.map { ($0 * 100).rounded() / 100 },
            currency: currency ?? defaultCurrency,
            currencySpoken: currency != nil,
            date: date,
            timeGiven: timeGiven,
            original: original
        )
    }

    static func extractTime(_ text: String, now: Date, calendar: Calendar) -> (Date, Bool, String) {
        var date = now
        var found = false
        var rest = text

        if dayRe.firstMatch(in: rest, range: fullRange(rest)) != nil {
            date = calendar.date(byAdding: .day, value: -1, to: date) ?? date
            found = true
        }
        if let m = timeRe.firstMatch(in: rest, range: fullRange(rest)) {
            var hour = Int(group(m, 1, in: rest) ?? group(m, 4, in: rest) ?? "") ?? -1
            let minute = Int(group(m, 2, in: rest) ?? group(m, 5, in: rest) ?? "0") ?? 0
            let suffix = (group(m, 3, in: rest) ?? group(m, 6, in: rest) ?? "")
                .lowercased().replacingOccurrences(of: ".", with: "")
            if suffix == "pm" && hour < 12 { hour += 12 }
            if suffix == "am" && hour == 12 { hour = 0 }
            if (0...23).contains(hour), (0...59).contains(minute),
               let d = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date) {
                date = d
                found = true
                rest = (rest as NSString).replacingCharacters(in: m.range, with: " ")
            }
        }
        return (date, found, rest)
    }

    /// "1,234" -> 1234, "12,50" -> 12.5, "1,234.50" -> 1234.5
    static func toNumber(_ raw: String) -> Double? {
        let s = raw.replacingOccurrences(of: " ", with: "")
        if s.range(of: #"^\d{1,3}([.,]\d{3})+$"#, options: .regularExpression) != nil {
            return Double(s.filter(\.isNumber))
        }
        if let sep = s.lastIndex(where: { $0 == "." || $0 == "," }) {
            let whole = s[..<sep].filter(\.isNumber)
            return Double("\(whole).\(s[s.index(after: sep)...])")
        }
        return Double(s)
    }

    static func regex(_ pattern: String) -> NSRegularExpression {
        // swiftlint:disable:next force_try
        try! NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
    }

    static func fullRange(_ s: String) -> NSRange { NSRange(location: 0, length: (s as NSString).length) }

    static func group(_ m: NSTextCheckingResult, _ i: Int, in s: String) -> String? {
        let r = m.range(at: i)
        return r.location == NSNotFound ? nil : (s as NSString).substring(with: r)
    }
}

/// Fallback currency when the location is unknown: taken from the phone's time zone.
public enum CurrencyDefaults {
    static let euroZones: Set<String> = [
        "Europe/Vienna", "Europe/Berlin", "Europe/Busingen", "Europe/Paris", "Europe/Madrid", "Europe/Rome",
        "Europe/Amsterdam", "Europe/Brussels", "Europe/Lisbon", "Europe/Dublin", "Europe/Helsinki",
        "Europe/Mariehamn", "Europe/Athens", "Europe/Luxembourg", "Europe/Monaco", "Europe/Tallinn",
        "Europe/Riga", "Europe/Vilnius", "Europe/Bratislava", "Europe/Ljubljana", "Europe/Malta",
        "Asia/Nicosia", "Asia/Famagusta", "Europe/Nicosia", "Europe/Zagreb", "Europe/Andorra",
        "Europe/San_Marino", "Europe/Vatican", "Europe/Podgorica", "Atlantic/Madeira", "Atlantic/Azores",
        "Atlantic/Canary", "Africa/Ceuta",
    ]

    public static func currency(forTimeZone id: String) -> String? {
        if id == "Europe/Stockholm" { return "SEK" }
        return euroZones.contains(id) ? "EUR" : nil
    }
}
