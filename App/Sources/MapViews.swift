import CoreLocation
import ExpenseCore
import MapKit
import SwiftUI

/// The GPS fix on a map (1.8, his choice of the 26 Oct 2026 concept: A, B and C).
extension Fix {
    var coordinate: CLLocationCoordinate2D { CLLocationCoordinate2D(latitude: latitude, longitude: longitude) }

    /// "±8 m", or nil when the iPhone did not say how sure it was.
    var accuracyText: String? { accuracy.map { "±\(Int($0.rounded())) m" } }

    /// "59.343000, 18.049000" — six decimals, as in the CSV.
    var numbers: String { String(format: "%.6f, %.6f", latitude, longitude) }
}

/// The teal dot with a white ring, drawn where the expense was logged.
struct FixDot: View {
    var size: CGFloat = 16
    var body: some View {
        Circle()
            .fill(Color.accentColor)
            .frame(width: size, height: size)
            .overlay(Circle().stroke(.white, lineWidth: size / 5))
            .shadow(radius: 1)
    }
}

/// 1.17 (his pick): the small map at the top of the Place page — a dot with its name for
/// each place still in the list, the teal dot for this expense. Tapping a name chooses it.
struct PlacesMap: View {
    let fix: Fix?
    let places: [(name: String, spot: Fix)]
    let selection: String
    let choose: (String) -> Void

    var body: some View {
        Map(initialPosition: .automatic) {
            ForEach(places, id: \.name) { p in
                Annotation("", coordinate: p.spot.coordinate) {
                    Button { choose(p.name) } label: {
                        VStack(spacing: 2) {
                            Text(p.name)
                                .font(.caption2.weight(.semibold))
                                .lineLimit(1)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(.background, in: Capsule())
                                .foregroundStyle(p.name == selection ? Color.accentColor : .primary)
                            Circle().fill(Color.accentColor.opacity(0.8)).frame(width: 8, height: 8)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            if let fix {
                Annotation("", coordinate: fix.coordinate) { FixDot(size: 14) }
            }
        }
        .frame(height: 150)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

/// A: the small map under the place on the check sheet. It does not move; a tap on its
/// row opens C.
struct FixPreview: View {
    let fix: Fix

    var body: some View {
        Map(initialPosition: .region(MKCoordinateRegion(center: fix.coordinate, latitudinalMeters: 350, longitudinalMeters: 350)),
            interactionModes: []) {
            Annotation("", coordinate: fix.coordinate) { FixDot() }
        }
        .frame(height: 120)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// C: one expense — a larger map with the dot, when, the area, the position in numbers,
/// the accuracy, and Open in Maps.
struct ExpenseMapScreen: View {
    let title: String
    let amount: String
    let date: Date
    let area: String
    let place: String
    let fix: Fix
    @Environment(\.openURL) private var openURL

    var body: some View {
        List {
            Section {
                Map(initialPosition: .region(MKCoordinateRegion(center: fix.coordinate, latitudinalMeters: 500, longitudinalMeters: 500))) {
                    Annotation(place, coordinate: fix.coordinate) { FixDot(size: 20) }
                }
                .frame(height: 300)
                .listRowInsets(EdgeInsets())
                .accessibilityHidden(true)
            }
            Section {
                row(title, amount)
                row("When", date.formatted(.dateTime.day().month(.abbreviated).year().hour().minute()))
                if !place.isEmpty { row("Place", place) }
                if !area.isEmpty { row("Area", area) }
                row("Position", fix.numbers, id: "map-position")
                if let accuracy = fix.accuracyText { row("Accuracy", accuracy, id: "map-accuracy") }
            }
            Section {
                Button {
                    var parts = URLComponents(string: "https://maps.apple.com/")!
                    parts.queryItems = [URLQueryItem(name: "ll", value: "\(fix.latitude),\(fix.longitude)"),
                                        URLQueryItem(name: "q", value: place.isEmpty ? title : place)]
                    if let url = parts.url { openURL(url) }
                } label: {
                    Label("Open in Maps", systemImage: "map")
                        .frame(maxWidth: .infinity)
                }
                .accessibilityIdentifier("map-open")
            } footer: {
                Text("The position stays on this iPhone.")
            }
        }
        .navigationTitle("Where")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(_ label: String, _ value: String, id: String? = nil) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).monospacedDigit().multilineTextAlignment(.trailing)
                .accessibilityIdentifier(id ?? "")
        }
    }
}

/// B: today's expenses on one map, numbered in the order they were paid, with the list below.
/// An expense without a position has a grey "–" and is not on the map.
/// 1.25 (his ask): it opens on Today; a row at the top switches to This week, Last week or
/// this Month — the map, the numbers and the list follow.
struct TodayMapScreen: View {
    enum Span: String, CaseIterable, Identifiable {
        case today = "Today", thisWeek = "This week", lastWeek = "Last week", month = "Month"
        var id: String { rawValue }
    }

    /// Every expense; the screen picks the span's own.
    let all: [Expense]
    @State private var span: Span = .today
    @EnvironmentObject private var rates: ExchangeRates

    private var expenses: [Expense] {
        let calendar = Calendar.current
        let now = Date()
        switch span {
        case .today: return all.filter { calendar.isDateInToday($0.date) }
        case .thisWeek: return all.filter { Statistics.range(.thisWeek, now: now, calendar: calendar).interval.contains($0.date) }
        case .lastWeek: return all.filter { Statistics.range(.lastWeek, now: now, calendar: calendar).interval.contains($0.date) }
        case .month: return all.filter { Statistics.range(.thisMonth, now: now, calendar: calendar).interval.contains($0.date) }
        }
    }

    /// Oldest first; the number is only for those with a position.
    private var rows: [(expense: Expense, number: Int?)] {
        var n = 0
        return expenses.sorted { $0.date < $1.date }.map { e in
            guard e.fix != nil else { return (e, nil) }
            n += 1
            return (e, n)
        }
    }

    var body: some View {
        let rows = self.rows
        let onMap = rows.filter { $0.number != nil }
        List {
            Picker("Show", selection: $span) {
                ForEach(Span.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 4, trailing: 0))
            .accessibilityIdentifier("map-span")
            Section {
                if onMap.isEmpty {
                    Text(span == .today ? "No expense today has a position yet." : "No expense in this time has a position yet.")
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("todaymap-empty")
                } else {
                    Map(initialPosition: .automatic) {
                        ForEach(onMap, id: \.expense.id) { row in
                            Annotation(row.expense.title, coordinate: row.expense.fix!.coordinate) {
                                Text("\(row.number!)")
                                    .font(.footnote.bold())
                                    .foregroundStyle(.white)
                                    .frame(width: 28, height: 28)
                                    .background(Circle().fill(pinColour(row.expense)))
                                    .overlay(Circle().stroke(.white, lineWidth: 2))
                            }
                            .annotationTitles(.hidden)
                        }
                    }
                    .id(span)   // a new span = the map fits its own pins
                    .frame(height: 380)
                    .listRowInsets(EdgeInsets())
                    .accessibilityHidden(true)
                    if byDay { legend(onMap.map(\.expense)) }
                }
            } footer: {
                Text("\(onMap.count) of \(rows.count) have a position")
                    .accessibilityIdentifier("todaymap-count")
            }
            Section {
                ForEach(Array(rows.enumerated()), id: \.element.expense.id) { index, row in
                    if let fix = row.expense.fix {
                        NavigationLink {
                            ExpenseMapScreen(title: row.expense.title, amount: amountText(row.expense), date: row.expense.date,
                                             area: row.expense.place, place: row.expense.visitedPlace, fix: fix)
                        } label: { label(row) }
                        .accessibilityIdentifier("todaymap-row-\(index)")
                    } else {
                        label(row)
                            .accessibilityElement(children: .combine)
                            .accessibilityIdentifier("todaymap-row-\(index)")
                    }
                }
            } header: {
                HStack {
                    Text(span.rawValue)
                    Spacer()
                    Text(Money.text(Statistics.total(expenses.map(\.spend), rates: rates.table, calendar: .current)))
                }
            }
        }
        .navigationTitle("On the map")
        .navigationBarTitleDisplayMode(.inline)
    }

    /// 1.26 (his ask): This week and Last week colour each pin, and its row's number, by its
    /// weekday (`DayColours`: Monday blue … Sunday brown). Today and Month stay teal.
    private var byDay: Bool { span == .thisWeek || span == .lastWeek }

    private func pinColour(_ e: Expense) -> Color {
        byDay ? Looks.color(DayColours.name(for: e.date, calendar: .current)) : Color.accentColor
    }

    /// The line under the map: a coloured dot and the short day name for each day with a pin,
    /// Monday first.
    private func legend(_ pinned: [Expense]) -> some View {
        let calendar = Calendar.current
        var firstOfDay: [Int: Date] = [:]
        for e in pinned {
            let i = DayColours.index(of: e.date, calendar: calendar)
            if firstOfDay[i] == nil { firstOfDay[i] = e.date }
        }
        let days = firstOfDay.keys.sorted().map { (name: firstOfDay[$0]!.formatted(.dateTime.weekday(.abbreviated)),
                                                   colour: DayColours.names[$0]) }
        return HStack(spacing: 10) {
            ForEach(days, id: \.name) { day in
                HStack(spacing: 4) {
                    Circle().fill(Looks.color(day.colour)).frame(width: 9, height: 9)
                    Text(day.name).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .lineLimit(1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Pin colours: " + days.map { "\($0.name) \($0.colour)" }.joined(separator: ", "))
        .accessibilityIdentifier("todaymap-legend")
    }

    private func amountText(_ e: Expense) -> String {
        e.amount.formatted(.currency(code: e.currency))
    }

    private func label(_ row: (expense: Expense, number: Int?)) -> some View {
        HStack(spacing: 12) {
            Text(row.number.map(String.init) ?? "–")
                .font(.caption.bold())
                .foregroundStyle(row.number == nil ? Color.secondary : Color.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(row.number == nil ? Color.secondary.opacity(0.2) : pinColour(row.expense)))
            VStack(alignment: .leading, spacing: 2) {
                Text(row.expense.title)
                Text(subtitle(row.expense))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(amountText(row.expense)).bold().monospacedDigit()
        }
    }

    private func subtitle(_ e: Expense) -> String {
        let time: String
        switch span {
        case .today: time = e.date.formatted(.dateTime.hour().minute())
        case .thisWeek, .lastWeek: time = e.date.formatted(.dateTime.weekday(.abbreviated)) + " " + e.date.formatted(.dateTime.hour().minute())
        case .month: time = e.date.formatted(.dateTime.day().month(.abbreviated)) + " · " + e.date.formatted(.dateTime.hour().minute())
        }
        if e.fix == nil { return time + " · no position" }
        return e.visitedPlace.isEmpty ? time : time + " · " + e.visitedPlace
    }
}
