import XCTest
@testable import ExpenseCore

/// 1.34: the launch words of picture mode.
final class PictureModeTests: XCTestCase {
    func testTheLaunchWordsAreRead() {
        XCTAssertEqual(PictureMode.parse([]), PictureMode(sample: false, screen: nil))
        XCTAssertEqual(PictureMode.parse(["-uiTesting"]), PictureMode(sample: false, screen: nil))
        XCTAssertEqual(PictureMode.parse(["-pictures"]), PictureMode(sample: true, screen: nil))
        XCTAssertEqual(PictureMode.parse(["-pictures", "-show", "this-week"]), PictureMode(sample: true, screen: .thisWeek))
        XCTAssertEqual(PictureMode.parse(["-pictures", "-show", "map"]).screen, .map)
        XCTAssertNil(PictureMode.parse(["-pictures", "-show", "nonsense"]).screen)
        XCTAssertNil(PictureMode.parse(["-pictures", "-show"]).screen)
        // -show alone never turns picture mode on.
        XCTAssertEqual(PictureMode.parse(["-show", "map"]), PictureMode(sample: false, screen: nil))
    }
}
