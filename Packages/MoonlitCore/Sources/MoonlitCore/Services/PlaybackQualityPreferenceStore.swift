import Foundation

@MainActor
public final class PlaybackQualityPreferenceStore {
    public static let shared = PlaybackQualityPreferenceStore()

    private let defaults: UserDefaults
    private let prefix = "moonlit.playbackQuality.prefer4K"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func prefers4K(profileId: String) -> Bool {
        defaults.bool(forKey: key(profileId: profileId))
    }

    public func setPrefers4K(_ value: Bool, profileId: String) {
        defaults.set(value, forKey: key(profileId: profileId))
    }

    private func key(profileId: String) -> String {
        "\(prefix).\(profileId)"
    }
}
