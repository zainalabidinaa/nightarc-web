import SwiftUI
import LunaCore

private let defaultAvatarURLs: [String] = [
    "https://media1.tenor.com/m/BbkxgHGg-EEAAAAC/butcher-billy-butcher.gif",
    "https://i.pinimg.com/originals/29/bd/26/29bd261d201e956588ee777d37d26800.gif",
    "https://i.postimg.cc/cLnhTxnr/Rick-Grimes-v2.png",
    "https://media1.giphy.com/media/v1.Y2lkPTZjMDliOTUycDg5cGFzNm1ydWo2aGZ2Njl4NnZiOHpvdjdsbHdzaTBmcTk2bGZnYyZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/1qErVv5GVUac8uqBJU/giphy.gif",
    "https://media1.tenor.com/m/ZNyte-qzI8QAAAAC/spider-man-drink.gif"
]

struct ProfileAvatarView: View {
    let profile: LunaProfile
    var size: CGFloat = 32

    private var avatarURL: URL? {
        guard let avatarId = profile.avatarId,
              avatarId >= 0,
              avatarId < defaultAvatarURLs.count else { return nil }
        return URL(string: defaultAvatarURLs[avatarId])
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
        let color = profile.avatarColor.map { Color(hex: $0) } ?? LunaTheme.accent
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
func avatarURLs() -> [String] { defaultAvatarURLs }
