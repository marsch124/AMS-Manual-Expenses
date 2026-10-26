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
private struct FixDot: View {
    var size: CGFloat = 16
    var body: some View {
        Circle()
            .fill(Color.accentColor)
            .frame(width: size, height: size)
            .overlay(Circle().stroke(.white, lineWidth: size / 5))
            .shadow(radius: 1)
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
struct TodayMapScreen: View {
    let expenses: [Expense]
    @EnvironmentObject private var rates: ExchangeRates

    /// Oldest first; the number is only for those with a position.
    private var rows: [(expense: Expense, number: Int?)] {
        var n = 0
        return expenses.sorted { $0.date < $1.date }.map { e in
            guard e.fix != nil, false else { return (e, nil) }
            n += 1
            return (e, n)
        }
    }

    var body: some View {
        let rows = self.rows
        let onMap = rows.filter { $0.number != nil }
        List {
            Section {
                if onMap.isEmpty {
                    Text("No expense today has a position yet.")
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
                                    .background(Circle().fill(Color.accentColor))
                                    .overlay(Circle().stroke(.white, lineWidth: 2))
                            }
                            .annotationTitles(.hidden)
                        }
                    }
                    .frame(height: 380)
                    .listRowInsets(EdgeInsets())
                    .accessibilityHidden(true)
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
                    Text("Today")
                    Spacer()
                    Text(Money.text(Statistics.total(expenses.map(\.spend), rates: rates.table, calendar: .current)))
                }
            }
        }
        .navigationTitle("Today on the map")
        .navigationBarTitleDisplayMode(.inline)
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
                .background(Circle().fill(row.number == nil ? Color.secondary.opacity(0.2) : Color.accentColor))
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
        let time = e.date.formatted(.dateTime.hour().minute())
        if e.fix == nil { return time + " · no position" }
        return e.visitedPlace.isEmpty ? time : time + " · " + e.visitedPlace
    }
}
