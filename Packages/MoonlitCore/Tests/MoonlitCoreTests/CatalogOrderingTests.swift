import XCTest
@testable import MoonlitCore

/// Covers the deterministic merge ordering for the "Coming Soon" rails.
/// The non-determinism bug came from merging concurrent source fetches in
/// completion order; these helpers replace that with a stable, sorted order.
final class CatalogOrderingTests: XCTestCase {

    private func meta(_ id: String, _ rawReleaseDate: String?) -> MetaPreview {
        MetaPreview(id: id, type: .movie, name: id, rawReleaseDate: rawReleaseDate)
    }

    func testSortsSoonestReleaseFirst() {
        let input = [
            meta("trakt-2027", "2027"),
            meta("mdblist-jun", "2026-06-19"),
            meta("undated", nil),
            meta("mdblist-dec", "2026-12-18"),
            meta("trakt-2027b", "2027"),
        ]
        let sorted = CatalogRepository.sortedByReleaseDateAscending(input)
        XCTAssertEqual(
            sorted.map(\.id),
            ["mdblist-jun", "mdblist-dec", "trakt-2027", "trakt-2027b", "undated"]
        )
    }

    func testUndatedItemsGoLast() {
        let input = [meta("undated-a", nil), meta("dated", "2026-01-01"), meta("undated-b", "")]
        let sorted = CatalogRepository.sortedByReleaseDateAscending(input)
        XCTAssertEqual(sorted.first?.id, "dated")
        XCTAssertEqual(Set(sorted.suffix(2).map(\.id)), ["undated-a", "undated-b"])
    }

    func testTiesKeepSourceOrderMdblistBeforeTrakt() {
        // Input arrives in source order (mdblist bucket merged before trakt bucket).
        // A stable same-date tiebreak must keep mdblist ahead.
        let input = [meta("mdblist", "2026-06-19"), meta("trakt", "2026-06-19")]
        let sorted = CatalogRepository.sortedByReleaseDateAscending(input)
        XCTAssertEqual(sorted.map(\.id), ["mdblist", "trakt"])
    }

    func testOrderingIsDeterministicAcrossRuns() {
        let input = [
            meta("c", "2027"), meta("a", "2025-03-01"), meta("b", "2026-08-08"), meta("d", nil),
        ]
        let first = CatalogRepository.sortedByReleaseDateAscending(input).map(\.id)
        for _ in 0..<25 {
            XCTAssertEqual(CatalogRepository.sortedByReleaseDateAscending(input).map(\.id), first)
        }
        XCTAssertEqual(first, ["a", "b", "c", "d"])
    }

    func testDeduplicatesByIdPreservingFirstSeenOrder() {
        let input = [meta("a", "2026"), meta("b", "2025"), meta("a", "2024"), meta("c", "2027")]
        XCTAssertEqual(CatalogRepository.deduplicated(input).map(\.id), ["a", "b", "c"])
    }
}
