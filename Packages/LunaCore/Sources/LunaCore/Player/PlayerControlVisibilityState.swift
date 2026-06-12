import Foundation

public struct PlayerControlVisibilityState: Equatable {
    public private(set) var controlsVisible: Bool
    public private(set) var isPlaying: Bool

    public init(controlsVisible: Bool = true, isPlaying: Bool = false) {
        self.controlsVisible = controlsVisible
        self.isPlaying = isPlaying
    }

    public var shouldScheduleAutoHide: Bool {
        controlsVisible && isPlaying
    }

    public mutating func setPlayback(isPlaying: Bool) {
        self.isPlaying = isPlaying
        if !isPlaying {
            controlsVisible = true
        }
    }

    public mutating func registerInteraction() {
        controlsVisible = true
    }

    public mutating func hideAfterInactivityIfAllowed() {
        guard isPlaying else { return }
        controlsVisible = false
    }
}
