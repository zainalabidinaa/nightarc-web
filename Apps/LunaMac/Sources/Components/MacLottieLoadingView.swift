import SwiftUI
import Lottie

struct MacLottieLoadingView: View {
    var size: CGFloat = 44

    var body: some View {
        LottieAnimationPlayer(animationName: "loading-animation-gradient-line-2-colors-1")
            .frame(width: size, height: size)
    }
}

private struct LottieAnimationPlayer: NSViewRepresentable {
    let animationName: String

    func makeNSView(context: Context) -> NSView {
        let container = NSView()
        let animationView = LottieAnimationView(name: animationName, bundle: .main)
        animationView.loopMode = .loop
        animationView.contentMode = .scaleAspectFit
        animationView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(animationView)
        NSLayoutConstraint.activate([
            animationView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            animationView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            animationView.topAnchor.constraint(equalTo: container.topAnchor),
            animationView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        animationView.play()
        return container
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        guard let animationView = nsView.subviews.first as? LottieAnimationView else { return }
        if !animationView.isAnimationPlaying {
            animationView.play()
        }
    }
}
