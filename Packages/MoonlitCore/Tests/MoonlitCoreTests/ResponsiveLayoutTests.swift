import XCTest
@testable import MoonlitCore

final class ResponsiveLayoutTests: XCTestCase {
    func testPhoneBreakpoints() {
        XCTAssertEqual(LayoutBreakpoint.from(width: 375), .phone)
        XCTAssertEqual(LayoutBreakpoint.from(width: 430), .phone)
        XCTAssertEqual(LayoutBreakpoint.from(width: 767), .phone)
    }

    func testTabletBreakpoints() {
        XCTAssertEqual(LayoutBreakpoint.from(width: 768), .tablet)
        XCTAssertEqual(LayoutBreakpoint.from(width: 834), .tablet)
        XCTAssertEqual(LayoutBreakpoint.from(width: 1023), .tablet)
    }

    func testLargeBreakpoints() {
        XCTAssertEqual(LayoutBreakpoint.from(width: 1024), .large)
        XCTAssertEqual(LayoutBreakpoint.from(width: 1366), .large)
        XCTAssertEqual(LayoutBreakpoint.from(width: 1439), .large)
    }

    func testXlargeBreakpoints() {
        XCTAssertEqual(LayoutBreakpoint.from(width: 1440), .xlarge)
        XCTAssertEqual(LayoutBreakpoint.from(width: 2048), .xlarge)
    }

    func testPhoneMetrics() {
        let m = ResponsiveMetrics(for: 375)
        XCTAssertEqual(m.horizontalPadding, 16)
        XCTAssertEqual(m.posterWidth, 125)
        XCTAssertEqual(m.posterHeight, 185)
        XCTAssertEqual(m.breakpoint, .phone)
    }

    func testXlargeMetrics() {
        let m = ResponsiveMetrics(for: 1440)
        XCTAssertEqual(m.horizontalPadding, 32)
        XCTAssertEqual(m.posterWidth, 185)
        XCTAssertEqual(m.posterHeight, 275)
        XCTAssertEqual(m.breakpoint, .xlarge)
    }

    func testBreakpointOrdering() {
        XCTAssertTrue(LayoutBreakpoint.phone < LayoutBreakpoint.tablet)
        XCTAssertTrue(LayoutBreakpoint.tablet < LayoutBreakpoint.large)
        XCTAssertTrue(LayoutBreakpoint.large < LayoutBreakpoint.xlarge)
    }
}
