import CoreLocation
import ExpenseCore
import MapKit
import SwiftUI

/// The GPS fix on a map (1.8, his choice of the 26 Oct 2026 concept: A, B and C).
extension MKMultiPoint {
    /// All the points of a line from Apple Maps.
    var allCoordinates: [CLLocationCoordinate2D] {
        var points = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: pointCount)
        getCoordinates(&points, range: NSRange(location: 0, length: pointCount))
        return points
    }
}

/// 1.29 (his ask): the way on foot between two close pins, asked from Apple Maps one pair at a
/// time and kept while the map screen is open. Empty = no sensible way (the bow is drawn).
@MainActor
final class RoadWays: ObservableObject {
    @Published private(set) var found: [String: [CLLocationCoordinate2D]] = [:]
    private var asked: Set<String> = []
    private var waiting: [(key: String, a: Fix, b: Fix)] = []
    private var running = false

    static func key(_ a: Fix, _ b: Fix) -> String {
        String(format: "%.5f,%.5f>%.5f,%.5f", a.latitude, a.longitude, b.latitude, b.longitude)
    }

    func ask(_ pairs: [(Fix, Fix)]) {
        guard !ExpensesApp.isolated else { return }
        for (a, b) in pairs where RouteShape.asksForRoad(straight: a.distance(to: b)) {
            let key = Self.key(a, b)
            if asked.insert(key).inserted { waiting.append((key, a, b)) }
        }
        guard !running, !waiting.isEmpty else { return }
        running = true
        Task { await work() }
    }

    private func work() async {
        while !waiting.isEmpty {
            let next = waiting.removeFirst()
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: next.a.coordinate))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: next.b.coordinate))
            request.transportType = .walking
            var way: [CLLocationCoordinate2D] = []
            if let route = try? await MKDirections(request: request).calculate().routes.first,
               RouteShape.usesRoad(straight: next.a.distance(to: next.b), road: route.distance) {
                way = route.polyline.allCoordinates
            }
            found[next.key] = way
        }
        running = false
    }

    /// 1.30: one stretch per pair of pins, oldest first: the street way where known, a bow elsewhere.
    func legs(through fixes: [Fix]) -> [[Fix]] {
        fixes.indices.dropFirst().map { i in
            let a = fixes[i - 1], b = fixes[i]
            if let way = found[Self.key(a, b)], !way.isEmpty {
                return [a] + way.map { Fix(latitude: $0.latitude, longitude: $0.longitude) } + [b]
            }
            return RouteShape.bow(from: a, to: b, side: i % 2 == 0 ? -1 : 1)
        }
    }

    /// The whole dotted route through the pins.
    static func path(_ legs: [[Fix]]) -> [CLLocationCoordinate2D] {
        legs.enumerated().flatMap { i, leg in (i == 0 ? leg[...] : leg.dropFirst()).map(\.coordinate) }
    }
}

/// 1.30 (his yes): the small hand-drawn arrowhead halfway along a stretch — the way he went.
struct RouteArrow: View {
    let colour: Color
    let bearing: Double

    var body: some View {
        let chevron = Path { p in
            p.move(to: CGPoint(x: 2, y: 10))
            p.addLine(to: CGPoint(x: 8, y: 3))
            p.addLine(to: CGPoint(x: 14, y: 10))
        }
        ZStack {
            chevron.stroke(.white, style: StrokeStyle(lineWidth: 5.5, lineCap: .round, lineJoin: .round))
            chevron.stroke(colour, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
        }
        .frame(width: 16, height: 13)
        .rotationEffect(.degrees(bearing))
    }
}

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
    /// 1.27 (his yes): in This week / Last week, the one day shown alone (0 = Monday), or nil.
    @State private var day: Int?
    @EnvironmentObject private var rates: ExchangeRates
    @StateObject private var roads = RoadWays()

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
        let weekRows = self.rows
        let weekOnMap = weekRows.filter { $0.number != nil }
        // 1.27: a chosen day shows alone; its numbers stay the week's.
        let chosen = byDay ? day : nil
        let rows = chosen.map { d in weekRows.filter { DayColours.index(of: $0.expense.date, calendar: .current) == d } } ?? weekRows
        let onMap = rows.filter { $0.number != nil }
        // 1.28 (his yes): Today gets one teal route (index -1); Month none.
        let routes = (byDay ? DayColours.byDay(onMap, date: { $0.expense.date }, calendar: .current)
                      : span == .today ? [(index: -1, items: onMap)] : []).filter { $0.items.count > 1 }
        // 1.30: each route's stretches (streets or bows) and colour, drawn and measured the same.
        let drawn = routes.map { route in
            (index: route.index,
             legs: roads.legs(through: route.items.map { $0.expense.fix! }),
             colour: route.index < 0 ? Color.accentColor : Looks.color(DayColours.names[route.index]))
        }
        let routeLength = drawn.flatMap(\.legs).reduce(0) { $0 + RouteShape.length($1) }
        let shown = rows.map(\.expense)
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
                    // 1.30: no turning or tilting, so the arrows always point the right way.
                    Map(initialPosition: .automatic, interactionModes: [.pan, .zoom]) {
                        // 1.27 (his yes): the way he went each day, in the order paid.
                        // 1.29 (his ask): dotted, along streets when close, else a hand-drawn bow.
                        ForEach(drawn, id: \.index) { route in
                            MapPolyline(coordinates: RoadWays.path(route.legs))
                                .stroke(route.colour.opacity(0.85),
                                        style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round, dash: [0.1, 8]))
                        }
                        // 1.30 (his yes): an arrow halfway along each stretch, older pin to newer.
                        ForEach(drawn, id: \.index) { route in
                            ForEach(Array(route.legs.enumerated()), id: \.offset) { _, leg in
                                if let arrow = RouteShape.halfway(of: leg) {
                                    Annotation("", coordinate: arrow.point.coordinate) {
                                        RouteArrow(colour: route.colour, bearing: arrow.bearing)
                                    }
                                    .annotationTitles(.hidden)
                                }
                            }
                        }
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
                    .id("\(span.rawValue)-\(chosen ?? -1)")   // a new span or day = the map fits its own pins
                    .task(id: "\(span.rawValue)-\(chosen ?? -1)-\(onMap.count)") {
                        roads.ask(routes.flatMap { route in
                            zip(route.items.dropLast(), route.items.dropFirst()).map { ($0.expense.fix!, $1.expense.fix!) }
                        })
                    }
                    .frame(height: 380)
                    .listRowInsets(EdgeInsets())
                    .accessibilityHidden(true)
                    if byDay { dayButtons(weekOnMap.map(\.expense)) }
                }
            } footer: {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(onMap.count) of \(rows.count) have a position")
                        .accessibilityIdentifier("todaymap-count")
                    if !drawn.isEmpty {
                        Text(drawn.count == 1 ? "Route: \(RouteShape.lengthText(routeLength))"
                                              : "Routes: \(RouteShape.lengthText(routeLength)) in all")
                            .accessibilityIdentifier("todaymap-route-length")
                    }
                    if byDay && !weekOnMap.isEmpty {
                        Text(chosen.map { "Only \(dayName($0, in: weekRows)) · tap it again for the whole week." } ?? "Tap a day to show only that day.")
                            .accessibilityIdentifier("todaymap-day-hint")
                    }
                }
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
                    Text(chosen.map { "\(span.rawValue) · \(dayName($0, in: weekRows))" } ?? span.rawValue)
                    Spacer()
                    Text(Money.text(Statistics.total(shown.map(\.spend), rates: rates.table, calendar: .current)))
                }
            }
        }
        .onChange(of: span) { day = nil }
        .navigationTitle("On the map")
        .navigationBarTitleDisplayMode(.inline)
    }

    /// 1.26 (his ask): This week and Last week colour each pin, and its row's number, by its
    /// weekday (`DayColours`: Monday blue … Sunday brown). Today and Month stay teal.
    private var byDay: Bool { span == .thisWeek || span == .lastWeek }

    private func pinColour(_ e: Expense) -> Color {
        byDay ? Looks.color(DayColours.name(for: e.date, calendar: .current)) : Color.accentColor
    }

    /// "Fri" — the short name of a weekday (0 = Monday) that has rows.
    private func dayName(_ index: Int, in rows: [(expense: Expense, number: Int?)]) -> String {
        rows.first { DayColours.index(of: $0.expense.date, calendar: .current) == index }?
            .expense.date.formatted(.dateTime.weekday(.abbreviated)) ?? ""
    }

    /// The line under the map (1.26 colours, 1.27 buttons): one small button per day with a pin,
    /// Monday first, in the day's colour. Tap = only that day; tap again = the whole week.
    private func dayButtons(_ pinned: [Expense]) -> some View {
        let days = DayColours.byDay(pinned, date: \.date, calendar: .current).map {
            (index: $0.index, name: $0.items[0].date.formatted(.dateTime.weekday(.abbreviated)),
             colour: Looks.color(DayColours.names[$0.index]))
        }
        return HStack(spacing: 6) {
            ForEach(days, id: \.index) { d in
                let on = day == d.index
                Button {
                    day = on ? nil : d.index
                } label: {
                    Text(d.name)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(on ? Color.white : d.colour)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(on ? d.colour : d.colour.opacity(0.18)))
                }
                .buttonStyle(.borderless)
                .accessibilityValue(on ? "Shown alone" : "")
                .accessibilityIdentifier("todaymap-day-\(d.name)")
            }
            Spacer(minLength: 0)
        }
        .lineLimit(1)
        .accessibilityElement(children: .contain)
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
