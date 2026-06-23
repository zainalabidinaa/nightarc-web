import Foundation

public enum MetadataProviderConnectionState: Equatable, Sendable {
    case missing
    case checking
    case connected
    case failed(String)

    public var label: String {
        switch self {
        case .missing:
            "Missing"
        case .checking:
            "Checking..."
        case .connected:
            "Connected"
        case .failed(let message):
            message
        }
    }

    public var isConnected: Bool {
        self == .connected
    }
}

@MainActor
public final class MetadataIntegrationStore: ObservableObject {
    public static let shared = MetadataIntegrationStore()

    @Published public private(set) var tvdbAPIKey: String
    @Published public private(set) var tmdbAPIKey: String
    @Published public private(set) var revision = 0

    private let defaults: UserDefaults
    private let tvdbKey = "moonlit.metadataIntegrations.tvdbAPIKey"
    private let tmdbKey = "moonlit.metadataIntegrations.tmdbAPIKey"
    private let traktKey = "moonlit.traktClientId"
    private let traktSecretKey = "moonlit.traktClientSecret"

    public convenience init() {
        self.init(defaults: .standard)
    }

    init(defaults: UserDefaults) {
        self.defaults = defaults
        tvdbAPIKey = defaults.string(forKey: tvdbKey)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        tmdbAPIKey = defaults.string(forKey: tmdbKey)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? MoonlitConfig.tmdbApiKey
    }

    public var effectiveTVDBAPIKey: String? {
        tvdbAPIKey.nilIfBlank
    }

    public var effectiveTMDBAPIKey: String? {
        tmdbAPIKey.nilIfBlank
    }

    public func setTVDBAPIKey(_ value: String) {
        tvdbAPIKey = value.trimmingCharacters(in: .whitespacesAndNewlines)
        defaults.set(tvdbAPIKey, forKey: tvdbKey)
        revision += 1
    }

    public func setTMDBAPIKey(_ value: String) {
        tmdbAPIKey = value.trimmingCharacters(in: .whitespacesAndNewlines)
        defaults.set(tmdbAPIKey, forKey: tmdbKey)
        revision += 1
    }

    public var traktClientId: String {
        get { defaults.string(forKey: traktKey) ?? MoonlitConfig.traktClientId ?? "" }
        set {
            defaults.set(newValue.trimmingCharacters(in: .whitespacesAndNewlines), forKey: traktKey)
            revision += 1
        }
    }

    public var traktClientSecret: String {
        get { defaults.string(forKey: traktSecretKey) ?? MoonlitConfig.traktClientSecret ?? "" }
        set {
            defaults.set(newValue.trimmingCharacters(in: .whitespacesAndNewlines), forKey: traktSecretKey)
            revision += 1
        }
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
