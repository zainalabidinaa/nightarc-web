import SwiftUI
import UIKit

struct MPVPlayerViewRepresentable: UIViewRepresentable {
    let playerView: UIView

    func makeUIView(context: Context) -> UIView {
        playerView
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let superview = uiView.superview, uiView.frame != superview.bounds else { return }
        uiView.frame = superview.bounds
    }
}
