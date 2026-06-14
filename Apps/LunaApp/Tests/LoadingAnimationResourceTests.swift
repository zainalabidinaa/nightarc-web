import XCTest

final class LoadingAnimationResourceTests: XCTestCase {
    func testOriginalLottieLoadingAnimationIsBundledAndDecodable() throws {
        let resourceURL = try XCTUnwrap(
            Bundle.main.url(forResource: "loading-animation-gradient-line-2-colors-1", withExtension: "json"),
            "Expected original Lottie loading animation JSON to be bundled with the app target."
        )

        let data = try Data(contentsOf: resourceURL)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertEqual(json?["nm"] as? String, "Loading animation v1")
        XCTAssertNotNil(json?["layers"] as? [[String: Any]])
    }
}
