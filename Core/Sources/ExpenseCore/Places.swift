import Foundation

/// A GPS position: where the phone was when an expense was logged (1.7).
public struct Fix: Equatable, Sendable {
    public var latitude: Double
    public var longitude: Double
    /// How sure the iPhone was, in metres (1.8); nil = not known.
    public var accuracy: Double?

    public init(latitude: Double, longitude: Double, accuracy: Double? = nil) {
        self.latitude = latitude
        self.longitude = longitude
        self.accuracy = accuracy
    }

    /// Metres between two positions, on a round Earth (more than close enough for a shop).
    public func distance(to other: Fix) -> Double {
        let r = 6_371_000.0
        let lat1: Double = latitude * .pi / 180
        let lat2: Double = other.latitude * .pi / 180
        let dLat: Double = lat2 - lat1
        let dLon: Double = (other.longitude - longitude) * .pi / 180
        let a: Double = sin(dLat / 2) * sin(dLat / 2) + cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2)
        let c: Double = 2 * atan2(sqrt(a), sqrt(1 - a))
        return r * c
    }
}

/// An earlier expense's place visited, with where it was logged and when.
public struct Visit: Equatable, Sendable {
    public var place: String
    public var fix: Fix?
    public var date: Date

    public init(place: String, fix: Fix?, date: Date) {
        self.place = place
        self.fix = fix
        self.date = date
    }
}

/// The place visited (1.7, his ask 25 Oct 2026): a name he chooses on the check sheet.
/// The list is the names already used; the ones near the GPS fix come first.
public enum Places {
    /// A new expense gets the place used nearest to it, when that is this close.
    public static let sameSpot: Double = 150
    /// Places this close are listed first in the chooser, as "Nearby".
    public static let nearby: Double = 1_000

    /// The place for a new expense logged at `fix`: the one used nearest to it within
    /// `sameSpot` metres; nil without a fix or with nothing that close.
    public static func suggestion(at fix: Fix?, history: [Visit]) -> String? {
        nearest(at: fix, history: history)?.place
    }

    /// The same, with how far away that earlier expense was logged (1.8: "auto · 12 m away").
    public static func nearest(at fix: Fix?, history: [Visit]) -> (place: String, metres: Double)? {
        guard let fix else { return nil }
        var best: (place: String, metres: Double)?
        for v in history where !v.place.isEmpty {
            guard let f = v.fix else { continue }
            let d = fix.distance(to: f)
            if d <= sameSpot, best == nil || d < best!.metres { best = (v.place, d) }
        }
        return best
    }

    /// Every place used, once each (the latest spelling), split into those within `nearby`
    /// metres of `fix` (nearest first) and the rest (most recently used first).
    public static func choices(at fix: Fix?, history: [Visit]) -> (near: [String], other: [String]) {
        var latest: [String: (name: String, date: Date)] = [:]
        var closest: [String: Double] = [:]
        for v in history {
            let name = v.place.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { continue }
            let key = name.lowercased()
            if latest[key] == nil || v.date > latest[key]!.date { latest[key] = (name, v.date) }
            if let fix, let f = v.fix {
                let d = fix.distance(to: f)
                if d <= nearby, closest[key] == nil || d < closest[key]! { closest[key] = d }
            }
        }
        let near = closest.sorted { $0.value < $1.value }.map { latest[$0.key]!.name }
        let other = latest.filter { closest[$0.key] == nil }
            .sorted { $0.value.date > $1.value.date }
            .map(\.value.name)
        return (near, other)
    }
}
