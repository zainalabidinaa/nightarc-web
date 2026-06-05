import SwiftUI
import XCTest
@testable import LunaCore

@MainActor
final class ThemeTests: XCTestCase {
    func testAllThemesHaveValidPalettes() {
        for theme in AppTheme.allCases {
            let p = theme.palette()
            XCTAssertFalse(p.primary.description.isEmpty)
            XCTAssertFalse(p.surface.description.isEmpty)
        }
    }

    func testAmoledBackgroundIsPureBlack() {
        let pureBlack = Color(hex: "000000")
        for theme in AppTheme.allCases {
            XCTAssertEqual(theme.palette(amoled: true).background.description, pureBlack.description)
            XCTAssertNotEqual(
                theme.palette(amoled: true).background.description,
                theme.palette(amoled: false).background.description
            )
        }
    }

    func testAmoledDoesNotChangeSurfaces() {
        let a = AppTheme.crimson.palette(amoled: true)
        let n = AppTheme.crimson.palette(amoled: false)
        XCTAssertEqual(a.surface.description, n.surface.description)
        XCTAssertEqual(a.surfaceElevated.description, n.surfaceElevated.description)
    }

    func testWhiteThemeHasDarkTextOnAccent() {
        let p = AppTheme.white.palette()
        XCTAssertEqual(p.onPrimary.description, Color(hex: "111111").description)
    }

    func testNonWhiteThemesHaveWhiteOnPrimary() {
        for theme in AppTheme.allCases where theme != .white {
            XCTAssertEqual(theme.palette().onPrimary.description, Color.white.description)
        }
    }

    func testPersistenceRoundTrip() {
        let storage = ThemeSettingsStorage.shared
        for theme in AppTheme.allCases {
            storage.saveTheme(theme)
            XCTAssertEqual(storage.loadTheme(), theme)
        }
    }

    func testAmoledPersistenceRoundTrip() {
        let storage = ThemeSettingsStorage.shared
        storage.saveAmoled(true)
        XCTAssertTrue(storage.loadAmoled())
        storage.saveAmoled(false)
        XCTAssertFalse(storage.loadAmoled())
    }

    func testDefaultThemeIsViolet() {
        UserDefaults.standard.removeObject(forKey: "luna_selected_theme")
        XCTAssertEqual(ThemeSettingsStorage.shared.loadTheme(), .violet)
    }
}
