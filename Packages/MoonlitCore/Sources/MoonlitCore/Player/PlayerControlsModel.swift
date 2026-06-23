import Foundation

public enum PlayerResizeMode: String, CaseIterable {
    case fit
    case fill
    case stretch
}

public enum PlayerSkipDirection {
    case forward
    case back
}

@MainActor
public class PlayerControlsState: ObservableObject {
    @Published public var showControls = true
    @Published public var resizeMode: PlayerResizeMode = .fit
    @Published public var subtitleOffset: Double = 0
    @Published public var audioDelay: Double = 0

    private var hideTimer: Timer?

    public init() {}

    public func showTemporarily() {
        showControls = true
        hideTimer?.invalidate()
        hideTimer = Timer.scheduledTimer(withTimeInterval: 4, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.showControls = false
            }
        }
    }

    public func toggleControls() {
        if showControls {
            showControls = false
            hideTimer?.invalidate()
        } else {
            showTemporarily()
        }
    }
}
