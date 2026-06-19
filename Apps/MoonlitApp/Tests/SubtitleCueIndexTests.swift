import XCTest
@testable import MoonlitApp

final class SubtitleCueIndexTests: XCTestCase {
    func testActiveCuesUseTimeRangeBoundaries() {
        let cues = [
            SubtitleCue(start: 1.0, end: 2.0, text: "first"),
            SubtitleCue(start: 2.0, end: 3.5, text: "second"),
            SubtitleCue(start: 4.0, end: 5.0, text: "third")
        ]
        let index = SubtitleCueIndex(cues: cues)

        XCTAssertEqual(index.activeCues(at: 0.99).map(\.text), [])
        XCTAssertEqual(index.activeCues(at: 1.0).map(\.text), ["first"])
        XCTAssertEqual(index.activeCues(at: 2.0).map(\.text), ["second"])
        XCTAssertEqual(index.activeCues(at: 3.5).map(\.text), [])
    }

    func testActiveCuesReturnOverlappingCuesWithoutScanningFutureCues() {
        let cues = [
            SubtitleCue(start: 0.0, end: 10.0, text: "long"),
            SubtitleCue(start: 2.0, end: 4.0, text: "short"),
            SubtitleCue(start: 8.0, end: 9.0, text: "future")
        ]
        let index = SubtitleCueIndex(cues: cues)

        XCTAssertEqual(index.activeCues(at: 3.0).map(\.text), ["long", "short"])
    }
}
