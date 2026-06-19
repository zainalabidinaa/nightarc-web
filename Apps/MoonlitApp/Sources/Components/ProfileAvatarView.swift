import SwiftUI
import MoonlitCore

// Indices 0-4 are existing entries — must never be reordered (profiles store avatar_id as an index).
// New avatars are appended starting at index 5.
let moonlitAvatarURLs: [String] = [
    // ── Existing (indices 0-4) ──────────────────────────────────────────────
    "https://media1.tenor.com/m/BbkxgHGg-EEAAAAC/butcher-billy-butcher.gif",          // 0  Billy Butcher
    "https://i.pinimg.com/originals/29/bd/26/29bd261d201e956588ee777d37d26800.gif",   // 1  Fan Fav
    "https://i.postimg.cc/cLnhTxnr/Rick-Grimes-v2.png",                               // 2  Rick Grimes
    "https://media1.giphy.com/media/v1.Y2lkPTZjMDliOTUycDg5cGFzNm1ydWo2aGZ2Njl4NnZiOHpvdjdsbHdzaTBmcTk2bGZnYyZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/1qErVv5GVUac8uqBJU/giphy.gif", // 3 Spider-Man
    "https://media1.tenor.com/m/ZNyte-qzI8QAAAAC/spider-man-drink.gif",               // 4  Spider-Man
    // ── New (indices 5-21) ─────────────────────────────────────────────────
    "https://hvfsntdyowapjxobtyli.supabase.co/storage/v1/object/public/avatars/Walter_White2.webp",               // 5  Walter White
    "https://hvfsntdyowapjxobtyli.supabase.co/storage/v1/object/public/avatars/dexter-morgan.gif",               // 6  Dexter Morgan
    "https://hvfsntdyowapjxobtyli.supabase.co/storage/v1/object/public/avatars/doakes-dexter.gif",               // 7  Doakes
    "https://hvfsntdyowapjxobtyli.supabase.co/storage/v1/object/public/avatars/joker.jpeg",                      // 8  Joker
    "https://hvfsntdyowapjxobtyli.supabase.co/storage/v1/object/public/avatars/360_dark_knight_0708.jpg",        // 9  Dark Knight
    "https://hvfsntdyowapjxobtyli.supabase.co/storage/v1/object/public/avatars/butcher.gif",                     // 10 Billy Butcher
    "https://hvfsntdyowapjxobtyli.supabase.co/storage/v1/object/public/avatars/Spider_Man.gif",                  // 11 Spider-Man
    "https://hvfsntdyowapjxobtyli.supabase.co/storage/v1/object/public/avatars/Spider-man_Avatar.gif",           // 12 Spider-Man
    "https://hvfsntdyowapjxobtyli.supabase.co/storage/v1/object/public/avatars/i-am-groot.webp",                 // 13 Groot
    "https://hvfsntdyowapjxobtyli.supabase.co/storage/v1/object/public/avatars/grogu-star-wars-profile-avatar.png",  // 14 Grogu
    "https://hvfsntdyowapjxobtyli.supabase.co/storage/v1/object/public/avatars/mando-star-wars-profile-avatar.png",  // 15 Mando
    "https://hvfsntdyowapjxobtyli.supabase.co/storage/v1/object/public/avatars/rick_and_morty.gif",              // 16 Rick & Morty
    "https://hvfsntdyowapjxobtyli.supabase.co/storage/v1/object/public/avatars/Leo.gif",                         // 17 Leo
    "https://hvfsntdyowapjxobtyli.supabase.co/storage/v1/object/public/avatars/Profile.gif",                     // 18
    "https://hvfsntdyowapjxobtyli.supabase.co/storage/v1/object/public/avatars/Scott_No.gif",                    // 19 Scott Pilgrim
    "https://hvfsntdyowapjxobtyli.supabase.co/storage/v1/object/public/avatars/B6SyssSlTgPXq.webp",              // 20
    "https://hvfsntdyowapjxobtyli.supabase.co/storage/v1/object/public/avatars/375473.jpeg",                     // 21
]

struct AvatarCategory: Identifiable {
    let id = UUID()
    let name: String
    let emoji: String
    let indices: [Int]
}

let moonlitAvatarCategories: [AvatarCategory] = [
    AvatarCategory(name: "Breaking Bad",    emoji: "⚗️",  indices: [5]),
    AvatarCategory(name: "Dexter",          emoji: "🔪",  indices: [6, 7]),
    AvatarCategory(name: "The Boys",        emoji: "💥",  indices: [0, 10]),
    AvatarCategory(name: "Marvel",          emoji: "🕷️", indices: [3, 4, 11, 12, 13]),
    AvatarCategory(name: "DC Universe",     emoji: "🦇",  indices: [8, 9]),
    AvatarCategory(name: "Star Wars",       emoji: "⚔️",  indices: [14, 15]),
    AvatarCategory(name: "The Walking Dead",emoji: "🧟",  indices: [2]),
    AvatarCategory(name: "Animated",        emoji: "🎭",  indices: [16]),
    AvatarCategory(name: "Fan Favorites",   emoji: "⭐️", indices: [1, 17, 18, 19, 20, 21]),
]

struct ProfileAvatarView: View {
    let profile: MoonlitProfile
    var size: CGFloat = 32

    private var avatarURL: URL? {
        guard let avatarId = profile.avatarId,
              avatarId >= 0,
              avatarId < moonlitAvatarURLs.count else { return nil }
        return URL(string: moonlitAvatarURLs[avatarId])
    }

    private var isGif: Bool {
        avatarURL?.pathExtension.lowercased() == "gif"
    }

    private var gifAnimationDisabled: Bool {
        UserDefaults.standard.bool(forKey: "avatar_gif_still_\(profile.id)")
    }

    var body: some View {
        if let url = avatarURL {
            if isGif && !gifAnimationDisabled {
                AnimatedRemoteImage(url: url, contentMode: .scaleAspectFill)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                CachedAsyncImage(url: url) { phase in
                    if case .success(let image) = phase {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: size, height: size)
                            .clipShape(Circle())
                    } else {
                        fallbackAvatar
                    }
                }
            }
        } else {
            fallbackAvatar
        }
    }

    @ViewBuilder private var fallbackAvatar: some View {
        let color = profile.avatarColor.map { Color(hex: $0) } ?? MoonlitTheme.accent
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .overlay(
                Text(String(profile.name.prefix(1).uppercased()))
                    .font(.system(size: size * 0.41, weight: .bold))
                    .foregroundColor(.white)
            )
    }
}

/// Returns the list of avatar URLs — used by EditProfileSheet
func avatarURLs() -> [String] { moonlitAvatarURLs }
