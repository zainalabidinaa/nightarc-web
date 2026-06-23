import Foundation

public enum SessionStore {
    private static let defaultsKey = "com.moonlit.session"

    public static func save(_ session: UserSession) {
        let data: Data
        do {
            data = try JSONEncoder().encode(session)
        } catch {
            print("[SessionStore] Failed to encode session: \(error)")
            return
        }
        UserDefaults.standard.set(data, forKey: defaultsKey)
    }

    public static func load() -> UserSession? {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey) else {
            return nil
        }
        do {
            return try JSONDecoder().decode(UserSession.self, from: data)
        } catch {
            print("[SessionStore] Failed to decode session: \(error)")
            clear()
            return nil
        }
    }

    public static func clear() {
        UserDefaults.standard.removeObject(forKey: defaultsKey)
    }
}
