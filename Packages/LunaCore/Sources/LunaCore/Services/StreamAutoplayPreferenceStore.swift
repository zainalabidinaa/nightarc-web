import Foundation

public enum StreamAutoplayMode: String, Codable, Sendable, CaseIterable {
    case manual
    case automatic
}

@MainActor
public final class StreamAutoplayPreferenceStore {
    public static let shared = StreamAutoplayPreferenceStore()

    private let defaults: UserDefaults
    private let modePrefix = "luna.streamAutoplay.mode"
    private let automaticAddonUrlsPrefix = "luna.streamAutoplay.automaticAddonUrls"
    private let timeoutSecondsPrefix = "luna.streamAutoplay.timeoutSeconds"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func mode(profileId: String) -> StreamAutoplayMode {
        guard let rawValue = defaults.string(forKey: modeKey(profileId: profileId)),
              let mode = StreamAutoplayMode(rawValue: rawValue) else {
            return .manual
        }
        return mode
    }

    public func setMode(_ mode: StreamAutoplayMode, profileId: String) {
        defaults.set(mode.rawValue, forKey: modeKey(profileId: profileId))
    }

    public func automaticAddonUrls(profileId: String) -> [String] {
        defaults.stringArray(forKey: automaticAddonUrlsKey(profileId: profileId)) ?? []
    }

    public func setAutomaticAddonUrls(_ urls: [String], profileId: String) {
        defaults.set(Array(dictOrderedSet: urls), forKey: automaticAddonUrlsKey(profileId: profileId))
    }

    public func timeoutSeconds(profileId: String) -> Int? {
        let key = timeoutSecondsKey(profileId: profileId)
        guard defaults.object(forKey: key) != nil else { return nil }
        return defaults.integer(forKey: key)
    }

    public func setTimeoutSeconds(_ seconds: Int?, profileId: String) {
        let key = timeoutSecondsKey(profileId: profileId)
        if let seconds {
            defaults.set(seconds, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }

    public nonisolated static func automaticAddons(from managedAddons: [ManagedAddon], selectedUrls: [String]) -> [AddonManifest] {
        let enabledStreamAddons = managedAddons
            .filter { $0.enabled && $0.manifest.hasResource("stream") }

        guard !selectedUrls.isEmpty else {
            return enabledStreamAddons.map(\.manifest)
        }

        let selected = Set(selectedUrls)
        return enabledStreamAddons
            .filter { selected.contains($0.manifestUrl) }
            .map(\.manifest)
    }

    private func modeKey(profileId: String) -> String {
        "\(modePrefix).\(profileId)"
    }

    private func automaticAddonUrlsKey(profileId: String) -> String {
        "\(automaticAddonUrlsPrefix).\(profileId)"
    }

    private func timeoutSecondsKey(profileId: String) -> String {
        "\(timeoutSecondsPrefix).\(profileId)"
    }
}

private extension Array where Element == String {
    init(dictOrderedSet values: [String]) {
        var seen = Set<String>()
        self = values.filter { seen.insert($0).inserted }
    }
}
