import XCTest
@testable import ExpenseCore

final class PlacesTests: XCTestCase {
    // Stockholm: ICA by Odenplan, a café 60 m away, Gamla stan about 2.5 km south.
    let ica = Fix(latitude: 59.3430, longitude: 18.0490)
    let nextDoor = Fix(latitude: 59.3435, longitude: 18.0492)
    let gamlaStan = Fix(latitude: 59.3250, longitude: 18.0710)

    func date(_ day: Int) -> Date { Date(timeIntervalSince1970: Double(day) * 86_400) }

    func testDistanceIsInMetres() {
        let d = ica.distance(to: nextDoor)
        XCTAssertGreaterThan(d, 40)
        XCTAssertLessThan(d, 80)
        let far = ica.distance(to: gamlaStan)
        XCTAssertGreaterThan(far, 2_000)
        XCTAssertLessThan(far, 3_000)
    }

    func testTheNearestPlaceUsedOnTheSameSpotIsSuggested() {
        let history = [
            Visit(place: "ICA Odenplan", fix: ica, date: date(1)),
            Visit(place: "Café Pascal", fix: nextDoor, date: date(2)),
            Visit(place: "Gamla stan", fix: gamlaStan, date: date(3)),
        ]
        let here = Fix(latitude: 59.3431, longitude: 18.0490)   // about 10 m from ICA
        XCTAssertEqual(Places.suggestion(at: here, history: history), "ICA Odenplan")
        XCTAssertEqual(Places.suggestion(at: nextDoor, history: history), "Café Pascal")
        let near = Places.nearest(at: here, history: history)
        XCTAssertEqual(near?.place, "ICA Odenplan")
        XCTAssertEqual(near?.metres ?? -1, 11, accuracy: 2)
    }

    func testNothingIsSuggestedFarAwayOrWithoutAFix() {
        let history = [Visit(place: "ICA Odenplan", fix: ica, date: date(1))]
        XCTAssertNil(Places.suggestion(at: gamlaStan, history: history))
        XCTAssertNil(Places.suggestion(at: nil, history: history))
        XCTAssertNil(Places.suggestion(at: ica, history: [Visit(place: "Old", fix: nil, date: date(1))]))
        XCTAssertNil(Places.suggestion(at: ica, history: [Visit(place: "", fix: ica, date: date(1))]))
    }

    func testChoicesListNearbyFirstThenTheRestNewestFirst() {
        let history = [
            Visit(place: "Gamla stan", fix: gamlaStan, date: date(5)),
            Visit(place: "ICA Odenplan", fix: ica, date: date(1)),
            Visit(place: "Café Pascal", fix: nextDoor, date: date(2)),
            Visit(place: "Hotel", fix: nil, date: date(4)),
            Visit(place: "ica odenplan ", fix: nil, date: date(6)),   // the same place, spelt anew
            Visit(place: "", fix: ica, date: date(7)),
        ]
        let c = Places.choices(at: ica, history: history)
        XCTAssertEqual(c.near, ["ica odenplan", "Café Pascal"])
        XCTAssertEqual(c.other, ["Gamla stan", "Hotel"])

        let noFix = Places.choices(at: nil, history: history)
        XCTAssertEqual(noFix.near, [])
        XCTAssertEqual(noFix.other, ["ica odenplan", "Gamla stan", "Hotel", "Café Pascal"])
    }

    // 1.15: distances on the Place page, and its search.
    func testDistancesAndSearchOnThePlacePage() {
        let history = [
            Visit(place: "ICA Odenplan", fix: ica, date: date(1)),
            Visit(place: "ica odenplan", fix: gamlaStan, date: date(2)),
            Visit(place: "Gamla stan", fix: gamlaStan, date: date(3)),
            Visit(place: "Hotel", fix: nil, date: date(4)),
        ]
        let d = Places.distances(at: nextDoor, history: history)
        XCTAssertLessThan(d["ica odenplan"]!, 80)          // the nearest spot counts
        XCTAssertGreaterThan(d["gamla stan"]!, 2_000)
        XCTAssertNil(d["hotel"])                           // no GPS, no distance
        XCTAssertEqual(Places.distances(at: nil, history: history), [:])
        XCTAssertEqual(Places.distanceText(57), "60 m")
        XCTAssertEqual(Places.distanceText(3_420), "3.4 km")
        XCTAssertEqual(Places.distanceText(25_400), "25 km")
        let names = ["ICA Odenplan", "Café Pascal", "Gamla stan"]
        XCTAssertEqual(Places.matching(names, search: "  "), names)
        XCTAssertEqual(Places.matching(names, search: "ica"), ["ICA Odenplan"])
        XCTAssertEqual(Places.matching(names, search: "cafe"), ["Café Pascal"])
        XCTAssertEqual(Places.matching(names, search: "an"), ["ICA Odenplan", "Gamla stan"])
    }

    // 1.16: Nearest first.
    func testNearestFirstPutsPlacesWithoutADistanceLast() {
        let d = ["b": 900.0, "a": 50.0]
        XCTAssertEqual(Places.byDistance(["X", "B", "Y", "A"], distances: d), ["A", "B", "X", "Y"])
    }
}
