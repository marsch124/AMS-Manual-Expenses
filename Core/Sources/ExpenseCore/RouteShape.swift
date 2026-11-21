import Foundation

/// 1.29 (his ask, 21 Nov 2026: "more organic and hand written … dotted … follow some roads, if not too
/// far"): how the route between two pins on the map is shaped. Close pins follow the streets on foot
/// (when Apple Maps finds a sensible way); everything else is a gentle hand-drawn bow.
public enum RouteShape {
    /// Pins at most this far apart (straight, metres) follow the streets.
    public static let roadReach: Double = 2000
    /// Pins closer than this need no street way.
    public static let nearest: Double = 30
    /// A street way longer than this many times the straight line is a detour: bow instead.
    public static let longestDetour: Double = 3

    /// Worth asking Apple Maps for the way on foot between two pins this far apart?
    public static func asksForRoad(straight: Double) -> Bool {
        straight > nearest && straight <= roadReach
    }

    /// Draw the street way (`road` = its length in metres, nil = none found)?
    public static func usesRoad(straight: Double, road: Double?) -> Bool {
        guard let road, asksForRoad(straight: straight) else { return false }
        return road <= straight * longestDetour
    }

    /// A gentle hand-drawn bow from `a` to `b`: its middle bends 15 % of the distance to `side`
    /// (+1 left, −1 right, seen from `a`), with a small wobble so it is not a perfect arc.
    /// First point = `a`, last = `b`.
    public static func bow(from a: Fix, to b: Fix, side: Int, steps: Int = 24) -> [Fix] {
        // Flat x/y in "latitude degrees", longitude shrunk by cos(latitude) so bends look round.
        let k = cos((a.latitude + b.latitude) / 2 * .pi / 180)
        let ax = a.longitude * k, ay = a.latitude
        let bx = b.longitude * k, by = b.latitude
        let dx = bx - ax, dy = by - ay
        // Left-hand normal; its length equals the distance.
        let nx = -dy, ny = dx
        let s = Double(side < 0 ? -1 : 1)
        // Control point: the middle pushed sideways (a quadratic's peak is half its control offset).
        let cx = (ax + bx) / 2 + nx * 0.30 * s
        let cy = (ay + by) / 2 + ny * 0.30 * s
        let n = max(steps, 2)
        return (0...n).map { i in
            let t = Double(i) / Double(n)
            let u = 1 - t
            var x = u * u * ax + 2 * u * t * cx + t * t * bx
            var y = u * u * ay + 2 * u * t * cy + t * t * by
            // The hand's wobble: small, zero at both ends.
            let w = 0.02 * sin(t * .pi * 3) * sin(t * .pi)
            x += nx * w
            y += ny * w
            return Fix(latitude: y, longitude: x / k)
        }
    }
}
