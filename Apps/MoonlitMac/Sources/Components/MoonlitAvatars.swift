import SwiftUI
import MoonlitCore

// Indices must match the iOS app exactly — profiles store avatar_id as a portable index.
let moonlitAvatarURLs: [String] = [
    "https://media1.tenor.com/m/BbkxgHGg-EEAAAAC/butcher-billy-butcher.gif",
    "https://i.pinimg.com/originals/29/bd/26/29bd261d201e956588ee777d37d26800.gif",
    "https://i.postimg.cc/cLnhTxnr/Rick-Grimes-v2.png",
    "https://media1.giphy.com/media/v1.Y2lkPTZjMDliOTUycDg5cGFzNm1ydWo2aGZ2Njl4NnZiOHpvdjdsbHdzaTBmcTk2bGZnYyZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/1qErVv5GVUac8uqBJU/giphy.gif",
    "https://media1.tenor.com/m/ZNyte-qzI8QAAAAC/spider-man-drink.gif",
    "https://hvfsntdyowapjxobtyli.supabase.co/storage/v1/object/public/avatars/Walter_White2.webp",
    "https://hvfsntdyowapjxobtyli.supabase.co/storage/v1/object/public/avatars/dexter-morgan.gif",
    "https://hvfsntdyowapjxobtyli.supabase.co/storage/v1/object/public/avatars/doakes-dexter.gif",
    "https://hvfsntdyowapjxobtyli.supabase.co/storage/v1/object/public/avatars/joker.jpeg",
    "https://hvfsntdyowapjxobtyli.supabase.co/storage/v1/object/public/avatars/360_dark_knight_0708.jpg",
    "https://hvfsntdyowapjxobtyli.supabase.co/storage/v1/object/public/avatars/butcher.gif",
    "https://hvfsntdyowapjxobtyli.supabase.co/storage/v1/object/public/avatars/Spider_Man.gif",
    "https://hvfsntdyowapjxobtyli.supabase.co/storage/v1/object/public/avatars/Spider-man_Avatar.gif",
    "https://hvfsntdyowapjxobtyli.supabase.co/storage/v1/object/public/avatars/i-am-groot.webp",
    "https://hvfsntdyowapjxobtyli.supabase.co/storage/v1/object/public/avatars/grogu-star-wars-profile-avatar.png",
    "https://hvfsntdyowapjxobtyli.supabase.co/storage/v1/object/public/avatars/mando-star-wars-profile-avatar.png",
    "https://hvfsntdyowapjxobtyli.supabase.co/storage/v1/object/public/avatars/rick_and_morty.gif",
    "https://hvfsntdyowapjxobtyli.supabase.co/storage/v1/object/public/avatars/Leo.gif",
    "https://hvfsntdyowapjxobtyli.supabase.co/storage/v1/object/public/avatars/Profile.gif",
    "https://hvfsntdyowapjxobtyli.supabase.co/storage/v1/object/public/avatars/Scott_No.gif",
    "https://hvfsntdyowapjxobtyli.supabase.co/storage/v1/object/public/avatars/B6SyssSlTgPXq.webp",
    "https://hvfsntdyowapjxobtyli.supabase.co/storage/v1/object/public/avatars/375473.jpeg",
]

struct AvatarCategory: Identifiable {
    let id = UUID()
    let name: String
    let emoji: String
    let indices: [Int]
}

let moonlitAvatarCategories: [AvatarCategory] = [
    AvatarCategory(name: "Breaking Bad",     emoji: "⚗️",  indices: [5]),
    AvatarCategory(name: "Dexter",           emoji: "🔪",  indices: [6, 7]),
    AvatarCategory(name: "The Boys",         emoji: "💥",  indices: [0, 10]),
    AvatarCategory(name: "Marvel",           emoji: "🕷️", indices: [3, 4, 11, 12, 13]),
    AvatarCategory(name: "DC Universe",      emoji: "🦇",  indices: [8, 9]),
    AvatarCategory(name: "Star Wars",        emoji: "⚔️",  indices: [14, 15]),
    AvatarCategory(name: "The Walking Dead", emoji: "🧟",  indices: [2]),
    AvatarCategory(name: "Animated",         emoji: "🎭",  indices: [16]),
    AvatarCategory(name: "Fan Favorites",    emoji: "⭐️", indices: [1, 17, 18, 19, 20, 21]),
]

struct MacProfileAvatarView: View {
    let avatarId: Int?
    let name: String
    let avatarColor: String?
    var size: CGFloat = 80

    private var url: URL? {
        guard let id = avatarId, id >= 0, id < moonlitAvatarURLs.count else { return nil }
        return URL(string: moonlitAvatarURLs[id])
    }

    var body: some View {
        if let url {
            if url.absoluteString.lowercased().hasSuffix(".gif") {
                AnimatedRemoteImage(url: url, contentMode: .resizeAspectFill)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                CachedAsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size, height: size)
                        .clipShape(Circle())
                } placeholder: {
                    fallback
                }
            }
        } else {
            fallback
        }
    }

    private var fallback: some View {
        let color = avatarColor.map { Color(hex: $0) } ?? MoonlitTheme.accent
        return Circle()
            .fill(color)
            .frame(width: size, height: size)
            .overlay(
                Text(String(name.prefix(1).uppercased()))
                    .font(.system(size: size * 0.41, weight: .bold))
                    .foregroundColor(.white)
            )
    }
}
