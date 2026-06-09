// Packages/LunaCore/Sources/LunaCore/Services/SubtitleAppearanceStore.swift
import Foundation

public enum SubtitlePreset: String, Codable, Sendable, CaseIterable {
    case standard = "standard"
    case boxed    = "boxed"
    case classic  = "classic"
    case minimal  = "minimal"

    public var displayName: String {
        switch self {
        case .standard: return "Standard"
        case .boxed:    return "Boxed"
        case .classic:  return "Classic"
        case .minimal:  return "Minimal"
        }
    }

    public var description: String {
        switch self {
        case .standard: return "White text with black outline"
        case .boxed:    return "White text with dark background"
        case .classic:  return "Yellow text, cinema style"
        case .minimal:  return "Clean, subtle shadow only"
        }
    }
}

public enum SubtitleAlignment: String, Codable, Sendable {
    case left   = "left"
    case center = "center"
    case right  = "right"
}

@MainActor
public final class SubtitleAppearanceStore: ObservableObject {
    public static let shared = SubtitleAppearanceStore()

    private let defaults: UserDefaults
    private let prefix = "luna.subtitles"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public var preset: SubtitlePreset {
        get { SubtitlePreset(rawValue: defaults.string(forKey: "\(prefix).preset") ?? "") ?? .standard }
        set { defaults.set(newValue.rawValue, forKey: "\(prefix).preset") }
    }

    public var fontSize: Double {
        get { defaults.object(forKey: "\(prefix).fontSize") as? Double ?? 32 }
        set { defaults.set(newValue, forKey: "\(prefix).fontSize") }
    }

    public var scale: Double {
        get { defaults.object(forKey: "\(prefix).scale") as? Double ?? 1.0 }
        set { defaults.set(newValue, forKey: "\(prefix).scale") }
    }

    public var isBold: Bool {
        get { defaults.object(forKey: "\(prefix).bold") as? Bool ?? false }
        set { defaults.set(newValue, forKey: "\(prefix).bold") }
    }

    public var isItalic: Bool {
        get { defaults.object(forKey: "\(prefix).italic") as? Bool ?? false }
        set { defaults.set(newValue, forKey: "\(prefix).italic") }
    }

    // Colors stored as hex strings
    public var textColorHex: String {
        get { defaults.string(forKey: "\(prefix).textColor") ?? "#FFFFFF" }
        set { defaults.set(newValue, forKey: "\(prefix).textColor") }
    }

    public var outlineColorHex: String {
        get { defaults.string(forKey: "\(prefix).outlineColor") ?? "#000000" }
        set { defaults.set(newValue, forKey: "\(prefix).outlineColor") }
    }

    public var backgroundColorHex: String {
        get { defaults.string(forKey: "\(prefix).backgroundColor") ?? "#000000" }
        set { defaults.set(newValue, forKey: "\(prefix).backgroundColor") }
    }

    public var backgroundOpacity: Double {
        get { defaults.object(forKey: "\(prefix).backgroundOpacity") as? Double ?? 0.0 }
        set { defaults.set(newValue, forKey: "\(prefix).backgroundOpacity") }
    }

    public var verticalPosition: Double {
        get { defaults.object(forKey: "\(prefix).verticalPosition") as? Double ?? 100 }
        set { defaults.set(newValue, forKey: "\(prefix).verticalPosition") }
    }

    public var horizontalAlignment: SubtitleAlignment {
        get { SubtitleAlignment(rawValue: defaults.string(forKey: "\(prefix).hAlignment") ?? "") ?? .center }
        set { defaults.set(newValue.rawValue, forKey: "\(prefix).hAlignment") }
    }

    public var horizontalMargin: Double {
        get { defaults.object(forKey: "\(prefix).hMargin") as? Double ?? 19 }
        set { defaults.set(newValue, forKey: "\(prefix).hMargin") }
    }

    public var textBlur: Double {
        get { defaults.object(forKey: "\(prefix).textBlur") as? Double ?? 0.0 }
        set { defaults.set(newValue, forKey: "\(prefix).textBlur") }
    }

    public var scaleWithWindowSize: Bool {
        get { defaults.object(forKey: "\(prefix).scaleWithWindow") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "\(prefix).scaleWithWindow") }
    }

    public func resetToDefaults() {
        let keys = ["preset","fontSize","scale","bold","italic","textColor","outlineColor",
                    "backgroundColor","backgroundOpacity","verticalPosition","hAlignment",
                    "hMargin","textBlur","scaleWithWindow"]
        keys.forEach { defaults.removeObject(forKey: "\(prefix).\($0)") }
    }
}
