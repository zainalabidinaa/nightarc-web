import Foundation

public enum AddonManifestParser {
    private static let decoder = JSONDecoder()

    public static func parse(json: String, manifestUrl: String) throws -> AddonManifest {
        guard let data = json.data(using: .utf8) else {
            throw StremioError.invalidManifest
        }

        struct RawManifest: Codable {
            let id: String?
            let name: String?
            let version: String?
            let description: String?
            let types: [String]?
            let resources: [RawResource]?
            let catalogs: [RawCatalog]?
            let behaviorHints: RawBehaviorHints?
            let transportUrl: String?
            let logo: String?
            let background: String?
        }
        struct RawResource: Codable {
            let name: String?
            let types: [String]?
            let idPrefixes: [String]?
        }
        struct RawCatalog: Codable {
            let type: String?
            let id: String?
            let name: String?
            let extra: [RawExtra]?
        }
        struct RawExtra: Codable {
            let name: String?
            let isRequired: Bool?
            let options: [String]?
            let optionsLimit: Int?
        }
        struct RawBehaviorHints: Codable {
            let adult: Bool?
            let configurable: Bool?
            let configurationRequired: Bool?
        }

        let raw = try decoder.decode(RawManifest.self, from: data)

        let manifestId = raw.id ?? URL(string: manifestUrl)?.host ?? manifestUrl
        let base = resolveBaseURL(manifestUrl: manifestUrl, transportUrl: raw.transportUrl)

        return AddonManifest(
            id: manifestId,
            name: raw.name ?? manifestId,
            version: raw.version ?? "0.0.0",
            description: raw.description,
            types: raw.types,
            resources: raw.resources?.map {
                AddonResource(
                    name: $0.name ?? "",
                    types: $0.types,
                    idPrefixes: $0.idPrefixes
                )
            },
            catalogs: raw.catalogs?.map {
                AddonCatalog(
                    type: $0.type ?? "",
                    id: $0.id ?? "",
                    name: $0.name,
                    extra: $0.extra?.map {
                        AddonCatalogExtra(
                            name: $0.name ?? "",
                            isRequired: $0.isRequired,
                            options: $0.options,
                            optionsLimit: $0.optionsLimit
                        )
                    }
                )
            },
            behaviorHints: raw.behaviorHints.map {
                AddonBehaviorHints(
                    adult: $0.adult,
                    configurable: $0.configurable,
                    configurationRequired: $0.configurationRequired
                )
            },
            transportUrl: base,
            logo: raw.logo.flatMap { resolveURL($0, base: base) },
            background: raw.background.flatMap { resolveURL($0, base: base) }
        )
    }

    private static func resolveBaseURL(manifestUrl: String, transportUrl: String?) -> String {
        if let transportUrl = transportUrl, !transportUrl.isEmpty {
            return transportUrl.hasSuffix("/") ? String(transportUrl.dropLast()) : transportUrl
        }
        let url = manifestUrl
        if url.hasSuffix("/manifest.json") {
            return String(url.dropLast("/manifest.json".count))
        }
        if let lastSlash = url.lastIndex(of: "/") {
            return String(url[..<lastSlash])
        }
        return url
    }

    private static func resolveURL(_ path: String, base: String) -> String {
        if path.hasPrefix("http://") || path.hasPrefix("https://") {
            return path
        }
        if path.hasPrefix("/") {
            return base + path
        }
        return base + "/" + path
    }
}
