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
}
