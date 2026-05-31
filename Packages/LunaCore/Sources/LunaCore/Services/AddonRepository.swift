import Foundation

@MainActor
public class AddonRepository: ObservableObject {
    public static let shared = AddonRepository()

    @Published public var managedAddons: [ManagedAddon] = []
    @Published public var isLoading = false
    @Published public var errorMessage: String?

    private let syncService = SyncService()
    private var currentProfileId: String?

    private init() {}

    public func loadAddons(profileId: String) async {
        self.currentProfileId = profileId
        isLoading = true
        defer { isLoading = false }

        do {
            let remoteUrls = try await syncService.pullAddons(profileId: profileId)
            if !remoteUrls.isEmpty {
                await refreshFromUrls(remoteUrls)
            } else {
                await refreshFromUrls(LunaConfig.defaultAddons)
            }
        } catch {
            await refreshFromUrls(LunaConfig.defaultAddons)
        }
    }

    public func refreshFromUrls(_ urls: [String]) async {
        var addons: [ManagedAddon] = []
        let existing = managedAddons

        await withTaskGroup(of: ManagedAddon?.self) { group in
            for (index, url) in urls.enumerated() {
                group.addTask {
                    do {
                        let manifest = try await self.fetchManifest(url: url)
                        return ManagedAddon(
                            manifest: manifest,
                            manifestUrl: url,
                            enabled: true,
                            sortOrder: index
                        )
                    } catch {
                        if let found = existing.first(where: { $0.manifestUrl == url }) {
                            var copy = found
                            copy.errorMessage = error.localizedDescription
                            return copy
                        }
                        return nil
                    }
                }
            }

            for await addon in group {
                if let addon = addon {
                    addons.append(addon)
                }
            }
        }

        addons.sort { $0.sortOrder < $1.sortOrder }
        self.managedAddons = addons
    }

    private func fetchManifest(url: String) async throws -> AddonManifest {
        let text = try await StremioHTTPClient.shared.getText(url: url + (url.contains("?") ? "&" : "?") + "t=\(Date().timeIntervalSince1970)")
        return try AddonManifestParser.parse(json: text, manifestUrl: url)
    }

    public func installAddon(url: String) async {
        guard !managedAddons.contains(where: { $0.manifestUrl == url }) else { return }
        do {
            let manifest = try await fetchManifest(url: url)
            let addon = ManagedAddon(
                manifest: manifest,
                manifestUrl: url,
                enabled: true,
                sortOrder: managedAddons.count
            )
            managedAddons.append(addon)
            await persistAddons()
        } catch {
            errorMessage = "Failed to install addon: \(error.localizedDescription)"
        }
    }

    public func removeAddon(url: String) {
        managedAddons.removeAll { $0.manifestUrl == url }
        Task { await persistAddons() }
    }

    public func toggleAddon(url: String) {
        if let index = managedAddons.firstIndex(where: { $0.manifestUrl == url }) {
            managedAddons[index].enabled.toggle()
            Task { await persistAddons() }
        }
    }

    public func reorderAddons(from source: IndexSet, to destination: Int) {
        managedAddons.move(fromOffsets: source, toOffset: destination)
        for i in managedAddons.indices {
            managedAddons[i].sortOrder = i
        }
        Task { await persistAddons() }
    }

    private func persistAddons() async {
        guard let profileId = currentProfileId else { return }
        let urls = managedAddons.map { $0.manifestUrl }
        try? await syncService.pushAddons(profileId: profileId, addonUrls: urls)
    }

    public var enabledAddons: [AddonManifest] {
        managedAddons.filter { $0.enabled }.map { $0.manifest }
    }

    public var enabledAddonsForType: [MediaType: [AddonManifest]] {
        var result: [MediaType: [AddonManifest]] = [:]
        for addon in enabledAddons {
            guard let types = addon.types else { continue }
            for typeStr in types {
                if let mediaType = MediaType(rawValue: typeStr) {
                    result[mediaType, default: []].append(addon)
                }
            }
        }
        return result
    }

    public func addonForCatalog(catalogId: String) -> AddonManifest? {
        for addon in managedAddons where addon.enabled {
            if let catalogs = addon.manifest.catalogs {
                if catalogs.contains(where: { $0.id == catalogId }) {
                    return addon.manifest
                }
            }
        }
        return nil
    }

    public func findAddonWithMetaResource(type: String?) -> [AddonManifest] {
        enabledAddons.filter { addon in
            guard addon.hasResource("meta") else { return false }
            if let type = type, let types = addon.types {
                return types.contains(type)
            }
            return true
        }
    }
}
