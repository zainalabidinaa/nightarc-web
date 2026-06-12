import SwiftUI
import LunaCore

struct PlayerFeedbackPill: View {
    let mode: PlayerGestureMode
    let value: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "sun.max.fill")
                .font(.system(size: 16))
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(Circle().fill(LunaTheme.accent.opacity(0.6)))

            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Capsule().fill(Color.black.opacity(0.75)))
        .opacity(mode == .none ? 0 : 1)
    }
}
