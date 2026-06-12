import SwiftUI

public enum AppTheme: String, CaseIterable, Codable, Sendable {
    case crimson, ocean, violet, emerald, amber, rose, white

    public var displayName: String {
        switch self {
        case .crimson: return "Crimson"
        case .ocean: return "Ocean"
        case .violet: return "Violet"
        case .emerald: return "Emerald"
        case .amber: return "Amber"
        case .rose: return "Rose"
        case .white: return "White"
        }
    }
}

public struct ThemeColorPalette: Sendable {
    public let primary: Color
    public let primaryVariant: Color
    public let focusRing: Color
    public let focusBackground: Color
    public let onPrimary: Color
    public let onPrimaryVariant: Color
    public let background: Color
    public let surface: Color
    public let surfaceElevated: Color
    public let surfaceContainer: Color

    public init(primary: Color, primaryVariant: Color, focusRing: Color,
                focusBackground: Color, onPrimary: Color, onPrimaryVariant: Color,
                background: Color, surface: Color, surfaceElevated: Color,
                surfaceContainer: Color) {
        self.primary = primary; self.primaryVariant = primaryVariant
        self.focusRing = focusRing; self.focusBackground = focusBackground
        self.onPrimary = onPrimary; self.onPrimaryVariant = onPrimaryVariant
        self.background = background; self.surface = surface
        self.surfaceElevated = surfaceElevated; self.surfaceContainer = surfaceContainer
    }
}

public extension AppTheme {
    func palette(amoled: Bool = false) -> ThemeColorPalette {
        let bg = amoled ? Color(hex: "000000") : Color(hex: "0D0D0D")
        let s = Color(hex: "1A1A1A")
        let se = Color(hex: "242424")
        switch self {
        case .crimson:
            return ThemeColorPalette(
                primary: Color(hex: "E53935"), primaryVariant: Color(hex: "C62828"),
                focusRing: Color(hex: "EF5350"), focusBackground: Color(hex: "3D1A1A"),
                onPrimary: .white, onPrimaryVariant: .white,
                background: bg, surface: s, surfaceElevated: se,
                surfaceContainer: Color(hex: "241A1A"))
        case .ocean:
            return ThemeColorPalette(
                primary: Color(hex: "1E88E5"), primaryVariant: Color(hex: "1565C0"),
                focusRing: Color(hex: "42A5F5"), focusBackground: Color(hex: "1A2D3D"),
                onPrimary: .white, onPrimaryVariant: .white,
                background: bg, surface: s, surfaceElevated: se,
                surfaceContainer: Color(hex: "1A1F24"))
        case .violet:
            return ThemeColorPalette(
                primary: Color(hex: "8E24AA"), primaryVariant: Color(hex: "6A1B9A"),
                focusRing: Color(hex: "AB47BC"), focusBackground: Color(hex: "2D1A3D"),
                onPrimary: .white, onPrimaryVariant: .white,
                background: bg, surface: s, surfaceElevated: se,
                surfaceContainer: Color(hex: "1F1A24"))
        case .emerald:
            return ThemeColorPalette(
                primary: Color(hex: "43A047"), primaryVariant: Color(hex: "2E7D32"),
                focusRing: Color(hex: "66BB6A"), focusBackground: Color(hex: "1A3D1E"),
                onPrimary: .white, onPrimaryVariant: .white,
                background: bg, surface: s, surfaceElevated: se,
                surfaceContainer: Color(hex: "1A241A"))
        case .amber:
            return ThemeColorPalette(
                primary: Color(hex: "FB8C00"), primaryVariant: Color(hex: "EF6C00"),
                focusRing: Color(hex: "FFA726"), focusBackground: Color(hex: "3D2D1A"),
                onPrimary: .white, onPrimaryVariant: .white,
                background: bg, surface: s, surfaceElevated: se,
                surfaceContainer: Color(hex: "24201A"))
        case .rose:
            return ThemeColorPalette(
                primary: Color(hex: "D81B60"), primaryVariant: Color(hex: "C2185B"),
                focusRing: Color(hex: "EC407A"), focusBackground: Color(hex: "3D1A2D"),
                onPrimary: .white, onPrimaryVariant: .white,
                background: bg, surface: s, surfaceElevated: se,
                surfaceContainer: Color(hex: "241A1F"))
        case .white:
            return ThemeColorPalette(
                primary: Color(hex: "C8C8C8"), primaryVariant: Color(hex: "A0A0A0"),
                focusRing: Color(hex: "FFFFFF"), focusBackground: Color(hex: "303030"),
                onPrimary: Color(hex: "111111"), onPrimaryVariant: Color(hex: "111111"),
                background: bg, surface: s, surfaceElevated: se,
                surfaceContainer: Color(hex: "222222"))
        }
    }
}
