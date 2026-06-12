import Foundation

@MainActor
public final class HeroPreferenceStore: ObservableObject {
    public static let shared = HeroPreferenceStore()

    @Published public private(set) var disabledRowTitles: Set<String>
    @Published public private(set) var rowOrder: [String]
    @Published public private(set) var revision = 0

    private let defaults: UserDefaults
    private let key = "luna.heroPreferences"

    private struct Stored: Codable {
        var disabledRowTitles: Set<String>
        var rowOrder: [String]
    }

    public convenience init() { self.init(defaults: .standard) }

    init(defaults: UserDefaults) {
        self.defaults = defaults
        if let data = defaults.data(forKey: key),
           let stored = try? JSONDecoder().decode(Stored.self, from: data) {
            disabledRowTitles = stored.disabledRowTitles
            rowOrder = stored.rowOrder
        } else {
            disabledRowTitles = []
            rowOrder = []
        }
    }

    public func isEnabled(rowTitle: String) -> Bool {
        !disabledRowTitles.contains(rowTitle)
    }

    public func setEnabled(_ enabled: Bool, for rowTitle: String) {
        if enabled {
            disabledRowTitles.remove(rowTitle)
            if !rowOrder.contains(rowTitle) {
                rowOrder.append(rowTitle)
            }
        } else {
            disabledRowTitles.insert(rowTitle)
        }
        save()
    }

    public func setOrder(_ order: [String]) {
        rowOrder = order
        save()
    }

    private func save() {
        let stored = Stored(disabledRowTitles: disabledRowTitles, rowOrder: rowOrder)
        if let data = try? JSONEncoder().encode(stored) {
            defaults.set(data, forKey: key)
        }
        revision += 1
    }
}
