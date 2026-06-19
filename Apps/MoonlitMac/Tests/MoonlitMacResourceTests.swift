import XCTest

final class MoonlitMacResourceTests: XCTestCase {
    func testHomeOrganizerAndLoadingAnimationAreBundledAndDecodable() throws {
        let bundle = Bundle.main

        let organizerURL = try XCTUnwrap(bundle.url(forResource: "home-organizer", withExtension: "json"))
        let organizerData = try Data(contentsOf: organizerURL)
        XCTAssertNoThrow(try JSONSerialization.jsonObject(with: organizerData))

        let animationURL = try XCTUnwrap(bundle.url(
            forResource: "loading-animation-gradient-line-2-colors-1",
            withExtension: "json"
        ))
        let animationData = try Data(contentsOf: animationURL)
        let animationObject = try XCTUnwrap(try JSONSerialization.jsonObject(with: animationData) as? [String: Any])
        XCTAssertEqual(animationObject["v"] as? String, "4.8.0")
    }
}
