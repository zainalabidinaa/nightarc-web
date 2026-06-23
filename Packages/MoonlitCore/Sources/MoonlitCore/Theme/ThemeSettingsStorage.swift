import Foundation

@MainActor
public final class ThemeSettingsStorage {
    public static let shared = ThemeSettingsStorage()
    private let defaults = UserDefaults.standard
    private let themeKey = "moonlit_selected_theme"
    private let amoledKey = "moonlit_amoled_enabled"
    private init() {}

    public func loadTheme() -> AppTheme {
        guard let raw = defaults.string(forKey: themeKey),
              let theme = AppTheme(rawValue: raw) else { return .white }
        return theme
    }
    public func saveTheme(_ theme: AppTheme) {
        defaults.set(theme.rawValue, forKey: themeKey)
    }
    public func loadAmoled() -> Bool {
        defaults.bool(forKey: amoledKey)
    }
    public func saveAmoled(_ enabled: Bool) {
        defaults.set(enabled, forKey: amoledKey)
    }
}
