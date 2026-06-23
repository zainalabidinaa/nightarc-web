import SwiftUI
import AppKit

struct MPVPlayerViewRepresentable: NSViewRepresentable {
    let playerView: NSView

    func makeNSView(context: Context) -> NSView {
        playerView
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        guard let superview = nsView.superview, nsView.frame != superview.bounds else { return }
        nsView.frame = superview.bounds
    }
}
