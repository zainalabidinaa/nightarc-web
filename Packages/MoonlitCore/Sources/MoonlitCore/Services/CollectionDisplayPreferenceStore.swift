import Foundation

@MainActor
public final class CollectionDisplayPreferenceStore: ObservableObject {
    public static let shared = CollectionDisplayPreferenceStore()

    @Published public private(set) var disabledCollectionIds: Set<String>
    @Published public private(set) var expandedCollectionIds: Set<String>
    @Published public private(set) var hiddenFolderIds: Set<String>
    @Published public private(set) var revision = 0

    private let defaults: UserDefaults
    private let key = "moonlit.collectionDisplayPreferences"

    private struct StoredPreferences: Codable {
        var disabledCollectionIds: Set<String>
        var expandedCollectionIds: Set<String>
        var hiddenFolderIds: Set<String>
    }

    public convenience init() {
        self.init(defaults: .standard)
    }

    init(defaults: UserDefaults) {
        self.defaults = defaults
        if let data = defaults.data(forKey: key),
           let stored = try? JSONDecoder().decode(StoredPreferences.self, from: data) {
            disabledCollectionIds = stored.disabledCollectionIds
            expandedCollectionIds = stored.expandedCollectionIds
            hiddenFolderIds = stored.hiddenFolderIds
        } else {
            disabledCollectionIds = []
            expandedCollectionIds = []
            hiddenFolderIds = []
        }
    }

    public func preferences(for collections: [DBCollection]) -> CollectionDisplayPreferences {
        let collectionIds = Set(collections.map(\.id))
        return CollectionDisplayPreferences(
            enabledCollectionIds: collectionIds.subtracting(disabledCollectionIds),
            expandedCollectionIds: expandedCollectionIds,
            hiddenFolderIds: hiddenFolderIds
        )
    }

    public func isCollectionEnabled(_ collection: DBCollection) -> Bool {
        !disabledCollectionIds.contains(collection.id)
    }

    public func isCollectionExpanded(_ collection: DBCollection) -> Bool {
        expandedCollectionIds.contains(collection.id)
    }

    public func isFolderHidden(_ folder: DBFolder) -> Bool {
        hiddenFolderIds.contains(folder.id)
    }

    public func setCollection(_ collection: DBCollection, enabled: Bool) {
        if enabled {
            disabledCollectionIds.remove(collection.id)
        } else {
            disabledCollectionIds.insert(collection.id)
        }
        save()
    }

    public func setCollection(_ collection: DBCollection, expanded: Bool) {
        if expanded {
            expandedCollectionIds.insert(collection.id)
        } else {
            expandedCollectionIds.remove(collection.id)
        }
        save()
    }

    public func setFolder(_ folder: DBFolder, hidden: Bool) {
        if hidden {
            hiddenFolderIds.insert(folder.id)
        } else {
            hiddenFolderIds.remove(folder.id)
        }
        save()
    }

    private func save() {
        let stored = StoredPreferences(
            disabledCollectionIds: disabledCollectionIds,
            expandedCollectionIds: expandedCollectionIds,
            hiddenFolderIds: hiddenFolderIds
        )
        if let data = try? JSONEncoder().encode(stored) {
            defaults.set(data, forKey: key)
        }
        revision += 1
    }
}
