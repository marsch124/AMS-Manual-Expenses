import XCTest
@testable import ExpenseCore

final class RouteShapeTests: XCTestCase {
    /// 1.29: streets only for close pins and sensible ways; otherwise a bow that bends to its side.
    func testRoutesFollowStreetsWhenCloseAndBowOtherwise() {
        XCTAssertFalse(RouteShape.asksForRoad(straight: 20))      // too close
        XCTAssertTrue(RouteShape.asksForRoad(straight: 800))
        XCTAssertFalse(RouteShape.asksForRoad(straight: 2500))    // too far
        XCTAssertTrue(RouteShape.usesRoad(straight: 800, road: 1100))
        XCTAssertFalse(RouteShape.usesRoad(straight: 800, road: 2600))   // a detour
        XCTAssertFalse(RouteShape.usesRoad(straight: 800, road: nil))    // none found

        let a = Fix(latitude: 58.5900, longitude: 16.1800)
        let b = Fix(latitude: 58.5900, longitude: 16.2000)   // due east
        let left = RouteShape.bow(from: a, to: b, side: 1)
        let right = RouteShape.bow(from: a, to: b, side: -1)
        XCTAssertEqual(left.first!.latitude, a.latitude, accuracy: 1e-9)
        XCTAssertEqual(left.first!.longitude, a.longitude, accuracy: 1e-9)
        XCTAssertEqual(left.last!.latitude, b.latitude, accuracy: 1e-9)
        XCTAssertEqual(left.last!.longitude, b.longitude, accuracy: 1e-9)
        // Going east, left is north: the middle bends 10–20 % of the distance to its side.
        let distance = a.distance(to: b)
        let middleLeft = left[left.count / 2], middleRight = right[right.count / 2]
        XCTAssertGreaterThan(middleLeft.latitude, a.latitude)
        XCTAssertLessThan(middleRight.latitude, a.latitude)
        let bend = Fix(latitude: a.latitude, longitude: middleLeft.longitude).distance(to: middleLeft)
        XCTAssertGreaterThan(bend, distance * 0.10)
        XCTAssertLessThan(bend, distance * 0.20)
    }
}
