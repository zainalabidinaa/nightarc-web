import SwiftUI

@MainActor
public final class ThemeManager: ObservableObject {
    public static let shared = ThemeManager()
    private let storage = ThemeSettingsStorage.shared

    @Published public private(set) var selectedTheme: AppTheme = .violet
    @Published public private(set) var isAmoledEnabled: Bool = false

    public var palette: ThemeColorPalette { selectedTheme.palette(amoled: isAmoledEnabled) }
    public var accent: Color { palette.primary }
    public var background: Color { palette.background }
    public var surface: Color { palette.surface }
    public var surfaceElevated: Color { palette.surfaceElevated }
    public var surfaceContainer: Color { palette.surfaceContainer }
    public var textPrimary: Color { .white }
    public var textSecondary: Color { .white.opacity(0.7) }
    public var textTertiary: Color { .white.opacity(0.5) }
    public var outline: Color { .white.opacity(0.08) }
    public var focusRing: Color { palette.focusRing }
    public var focusBackground: Color { palette.focusBackground }

    private init() { loadFromDisk() }

    public func loadFromDisk() {
        selectedTheme = storage.loadTheme()
        isAmoledEnabled = storage.loadAmoled()
    }
    public func setTheme(_ theme: AppTheme) {
        selectedTheme = theme
        storage.saveTheme(theme)
    }
    public func setAmoled(_ enabled: Bool) {
        isAmoledEnabled = enabled
        storage.saveAmoled(enabled)
    }
}
