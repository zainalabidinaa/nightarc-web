import Foundation

public struct RecommendationRow: Codable, Identifiable, Sendable {
    public let rowType: String
    public let rowTitle: String
    public let coverImage: String?
    public let sortOrder: Int
    public let items: [MetaPreview]

    public var id: String { "\(rowType)_\(rowTitle)" }

    public init(rowType: String, rowTitle: String, coverImage: String?, sortOrder: Int, items: [MetaPreview]) {
        self.rowType = rowType
        self.rowTitle = rowTitle
        self.coverImage = coverImage
        self.sortOrder = sortOrder
        self.items = items
    }

    enum CodingKeys: String, CodingKey {
        case rowType = "row_type"
        case rowTitle = "row_title"
        case coverImage = "cover_image"
        case sortOrder = "sort_order"
        case items
    }
}

public struct RecommendationsResponse: Codable, Sendable {
    public let generatedAt: String
    public let rows: [RecommendationRow]

    enum CodingKeys: String, CodingKey {
        case generatedAt = "generated_at"
        case rows
    }
}

@MainActor
public final class RecommendationsService: ObservableObject {
    public static let shared = RecommendationsService()

    @Published public var rows: [RecommendationRow] = []
    @Published public var isLoading = false
    @Published public var generatedAt: String?

    private let client = SupabaseClient.shared
    private let generateURL = "https://moonlit-web-zainalabidinaas-projects.vercel.app/api/recommendations/generate"
    private var didAutoGenerate = false

    private init() {}

    public func load(profileId: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let dbRows: [DBRecommendationRow] = try await client.select(
                from: "profile_recommendations",
                where: ["profile_id": profileId],
                order: "sort_order"
            )

            if dbRows.isEmpty {
                rows = []
                generatedAt = nil
                // Auto-trigger generation if never done for this profile
                if !didAutoGenerate {
                    didAutoGenerate = true
                    Task { _ = await triggerRegeneration(profileId: profileId) }
                }
                return
            }

            generatedAt = dbRows.first?.generatedAt

            rows = dbRows.map { db in
                RecommendationRow(
                    rowType: db.rowType,
                    rowTitle: db.rowTitle,
                    coverImage: db.coverImage,
                    sortOrder: db.sortOrder,
                    items: db.items
                )
            }
        } catch {
            print("[RecommendationsService] load failed: \(error)")
        }
    }

    public func triggerRegeneration(profileId: String) async -> Bool {
        guard let url = URL(string: generateURL) else { return false }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(["profile_id": profileId])

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            return json?["success"] as? Bool ?? false
        } catch {
            print("[RecommendationsService] generate failed: \(error)")
            return false
        }
    }

    public func clear() {
        rows = []
        generatedAt = nil
    }
}

private struct DBRecommendationRow: Codable, Sendable {
    let id: String
    let profileId: String
    let rowType: String
    let rowTitle: String
    let coverImage: String?
    let items: [MetaPreview]
    let sortOrder: Int
    let generatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case profileId = "profile_id"
        case rowType = "row_type"
        case rowTitle = "row_title"
        case coverImage = "cover_image"
        case items
        case sortOrder = "sort_order"
        case generatedAt = "generated_at"
    }
}
