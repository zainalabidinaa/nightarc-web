import SwiftUI
import UIKit
import Combine
import MoonlitCore
#if canImport(KSPlayer)
import KSPlayer
#endif
import MPVKit

/// Wrapper that delegates to either KSPlayerEngine or MPVPlayerEngine based on
/// the `moonlit.playerEngine` user default. PlayerScreen uses this single object
/// instead of referencing ksEngine directly, so all playback paths work regardless
/// of which backend is active.
@MainActor
public final class VideoPlayerEngine: ObservableObject {
    private let ksEngine = KSPlayerEngine()
    private let mpvEngine = MPVPlayerEngine()

    @AppStorage("moonlit.playerEngine") public var playerEngineChoice = "ksplayer"

    // MARK: - Display

    var displayView: UIView? {
        playerEngineChoice == "mpv" ? mpvEngine.displayView : ksEngine.displayView
    }

    var hasRenderedFrame: Bool {
        playerEngineChoice == "mpv" ? mpvEngine.hasRenderedFrame : ksEngine.hasRenderedFrame
    }

    var launchToken: Int {
        playerEngineChoice == "mpv" ? mpvEngine.launchToken : ksEngine.launchToken
    }

    // MARK: - Passthrough @Published

    @Published public var isPlaying = false
    @Published public var isLoading = true
    @Published public var isEnded = false
    @Published public var currentPosition: Double = 0
    @Published public var duration: Double = 0
    @Published public var bufferedPosition: Double = 0
    @Published public var playbackSpeed: Float = 1.0
    @Published public var availableSubtitles: [SubtitleItem] = []
    @Published public var selectedSubtitle: SubtitleItem?
    @Published public var availableAudioTracks: [String] = []
    @Published public var selectedAudioTrack: String?
    @Published public var isMuted = false
    @Published public var loadedCues: [SubtitleCue] = []
    @Published public var isFillingVideo = false
    @Published public var didEncounterError = false

    // MARK: - Passthrough Publishers

    public let positionPublisher = PassthroughSubject<Double, Never>()
    public let bufferedPositionPublisher = PassthroughSubject<Double, Never>()

    private var engineBindings: Set<AnyCancellable> = []

    public init() {
        bindEngine()
    }

    private func bindEngine() {
        // Observe changes to the player engine choice and rebind
        // For now, bind both engines and forward based on active choice.
        // When the choice changes, the @AppStorage triggers objectWillChange.
        bind(ksEngine)
        bind(mpvEngine)
    }

    private func bind(_ engine: KSPlayerEngine) {
        engine.$isPlaying
            .removeDuplicates()
            .sink { [weak self] in
                guard let self, self.playerEngineChoice == "ksplayer" else { return }
                self.isPlaying = $0
            }
            .store(in: &engineBindings)
        engine.$isLoading
            .removeDuplicates()
            .sink { [weak self] in
                guard let self, self.playerEngineChoice == "ksplayer" else { return }
                self.isLoading = $0
            }
            .store(in: &engineBindings)
        engine.$isEnded
            .removeDuplicates()
            .sink { [weak self] in
                guard let self, self.playerEngineChoice == "ksplayer" else { return }
                self.isEnded = $0
            }
            .store(in: &engineBindings)
        engine.$duration
            .removeDuplicates()
            .sink { [weak self] in
                guard let self, self.playerEngineChoice == "ksplayer" else { return }
                self.duration = $0
            }
            .store(in: &engineBindings)
        engine.$playbackSpeed
            .removeDuplicates()
            .sink { [weak self] in
                guard let self, self.playerEngineChoice == "ksplayer" else { return }
                self.playbackSpeed = $0
            }
            .store(in: &engineBindings)
        engine.$availableSubtitles
            .removeDuplicates()
            .sink { [weak self] in
                guard let self, self.playerEngineChoice == "ksplayer" else { return }
                self.availableSubtitles = $0
            }
            .store(in: &engineBindings)
        engine.$selectedSubtitle
            .removeDuplicates()
            .sink { [weak self] in
                guard let self, self.playerEngineChoice == "ksplayer" else { return }
                self.selectedSubtitle = $0
            }
            .store(in: &engineBindings)
        engine.$availableAudioTracks
            .removeDuplicates()
            .sink { [weak self] in
                guard let self, self.playerEngineChoice == "ksplayer" else { return }
                self.availableAudioTracks = $0
            }
            .store(in: &engineBindings)
        engine.$selectedAudioTrack
            .removeDuplicates()
            .sink { [weak self] in
                guard let self, self.playerEngineChoice == "ksplayer" else { return }
                self.selectedAudioTrack = $0
            }
            .store(in: &engineBindings)
        engine.$isMuted
            .removeDuplicates()
            .sink { [weak self] in
                guard let self, self.playerEngineChoice == "ksplayer" else { return }
                self.isMuted = $0
            }
            .store(in: &engineBindings)
        engine.$loadedCues
            .removeDuplicates()
            .sink { [weak self] in
                guard let self, self.playerEngineChoice == "ksplayer" else { return }
                self.loadedCues = $0
            }
            .store(in: &engineBindings)
        engine.$isFillingVideo
            .removeDuplicates()
            .sink { [weak self] in
                guard let self, self.playerEngineChoice == "ksplayer" else { return }
                self.isFillingVideo = $0
            }
            .store(in: &engineBindings)
        engine.$didEncounterError
            .removeDuplicates()
            .sink { [weak self] in
                guard let self, self.playerEngineChoice == "ksplayer" else { return }
                self.didEncounterError = $0
            }
            .store(in: &engineBindings)
        engine.$currentPosition
            .removeDuplicates()
            .throttle(for: .milliseconds(250), scheduler: RunLoop.main, latest: true)
            .sink { [weak self] in
                guard let self, self.playerEngineChoice == "ksplayer" else { return }
                self.currentPosition = $0
            }
            .store(in: &engineBindings)
        engine.$bufferedPosition
            .removeDuplicates()
            .sink { [weak self] in
                guard let self, self.playerEngineChoice == "ksplayer" else { return }
                self.bufferedPosition = $0
            }
            .store(in: &engineBindings)
    }

    private func bind(_ engine: MPVPlayerEngine) {
        engine.$isPlaying
            .removeDuplicates()
            .sink { [weak self] in
                guard let self, self.playerEngineChoice == "mpv" else { return }
                self.isPlaying = $0
            }
            .store(in: &engineBindings)
        engine.$isLoading
            .removeDuplicates()
            .sink { [weak self] in
                guard let self, self.playerEngineChoice == "mpv" else { return }
                self.isLoading = $0
            }
            .store(in: &engineBindings)
        engine.$isEnded
            .removeDuplicates()
            .sink { [weak self] in
                guard let self, self.playerEngineChoice == "mpv" else { return }
                self.isEnded = $0
            }
            .store(in: &engineBindings)
        engine.$duration
            .removeDuplicates()
            .sink { [weak self] in
                guard let self, self.playerEngineChoice == "mpv" else { return }
                self.duration = $0
            }
            .store(in: &engineBindings)
        engine.$playbackSpeed
            .removeDuplicates()
            .sink { [weak self] in
                guard let self, self.playerEngineChoice == "mpv" else { return }
                self.playbackSpeed = $0
            }
            .store(in: &engineBindings)
        engine.$availableSubtitles
            .removeDuplicates()
            .sink { [weak self] in
                guard let self, self.playerEngineChoice == "mpv" else { return }
                self.availableSubtitles = $0
            }
            .store(in: &engineBindings)
        engine.$selectedSubtitle
            .removeDuplicates()
            .sink { [weak self] in
                guard let self, self.playerEngineChoice == "mpv" else { return }
                self.selectedSubtitle = $0
            }
            .store(in: &engineBindings)
        engine.$availableAudioTracks
            .removeDuplicates()
            .sink { [weak self] in
                guard let self, self.playerEngineChoice == "mpv" else { return }
                self.availableAudioTracks = $0
            }
            .store(in: &engineBindings)
        engine.$selectedAudioTrack
            .removeDuplicates()
            .sink { [weak self] in
                guard let self, self.playerEngineChoice == "mpv" else { return }
                self.selectedAudioTrack = $0
            }
            .store(in: &engineBindings)
        engine.$isMuted
            .removeDuplicates()
            .sink { [weak self] in
                guard let self, self.playerEngineChoice == "mpv" else { return }
                self.isMuted = $0
            }
            .store(in: &engineBindings)
        engine.$loadedCues
            .removeDuplicates()
            .sink { [weak self] in
                guard let self, self.playerEngineChoice == "mpv" else { return }
                self.loadedCues = $0
            }
            .store(in: &engineBindings)
        engine.$isFillingVideo
            .removeDuplicates()
            .sink { [weak self] in
                guard let self, self.playerEngineChoice == "mpv" else { return }
                self.isFillingVideo = $0
            }
            .store(in: &engineBindings)
        engine.$didEncounterError
            .removeDuplicates()
            .sink { [weak self] in
                guard let self, self.playerEngineChoice == "mpv" else { return }
                self.didEncounterError = $0
            }
            .store(in: &engineBindings)
        engine.$currentPosition
            .removeDuplicates()
            .throttle(for: .milliseconds(250), scheduler: RunLoop.main, latest: true)
            .sink { [weak self] in
                guard let self, self.playerEngineChoice == "mpv" else { return }
                self.currentPosition = $0
            }
            .store(in: &engineBindings)
        engine.$bufferedPosition
            .removeDuplicates()
            .sink { [weak self] in
                guard let self, self.playerEngineChoice == "mpv" else { return }
                self.bufferedPosition = $0
            }
            .store(in: &engineBindings)
    }

    // MARK: - Passthrough Methods

    func launch(_ launch: PlayerLaunch) {
        if playerEngineChoice == "mpv" {
            mpvEngine.launch(launch)
        } else {
            ksEngine.launch(launch)
        }
    }

    func play() {
        if playerEngineChoice == "mpv" {
            mpvEngine.play()
        } else {
            ksEngine.play()
        }
    }

    func pause() {
        if playerEngineChoice == "mpv" {
            mpvEngine.pause()
        } else {
            ksEngine.pause()
        }
    }

    func stop() {
        if playerEngineChoice == "mpv" {
            mpvEngine.stop()
        } else {
            ksEngine.stop()
        }
    }

    func seek(to seconds: Double) {
        if playerEngineChoice == "mpv" {
            mpvEngine.seek(to: seconds)
        } else {
            ksEngine.seek(to: seconds)
        }
    }

    func setPlaybackSpeed(_ speed: Float) {
        if playerEngineChoice == "mpv" {
            mpvEngine.setPlaybackSpeed(speed)
        } else {
            ksEngine.setPlaybackSpeed(speed)
        }
    }

    func setSubtitle(_ subtitle: SubtitleItem?) {
        if playerEngineChoice == "mpv" {
            mpvEngine.setSubtitle(subtitle)
        } else {
            ksEngine.setSubtitle(subtitle)
        }
    }

    func cycleSubtitle() {
        if playerEngineChoice == "mpv" {
            mpvEngine.cycleSubtitle()
        } else {
            ksEngine.cycleSubtitle()
        }
    }

    func selectAudioTrack(named name: String) {
        if playerEngineChoice == "mpv" {
            mpvEngine.selectAudioTrack(named: name)
        } else {
            ksEngine.selectAudioTrack(named: name)
        }
    }

    func toggleMute() {
        if playerEngineChoice == "mpv" {
            mpvEngine.toggleMute()
        } else {
            ksEngine.toggleMute()
        }
    }

    func setVideoFill(_ fill: Bool) {
        if playerEngineChoice == "mpv" {
            mpvEngine.setVideoFill(fill)
        } else {
            ksEngine.setVideoFill(fill)
        }
    }

    func refreshAudioTracks() {
        if playerEngineChoice == "mpv" {
            mpvEngine.refreshAudioTracks()
        } else {
            ksEngine.refreshAudioTracks()
        }
    }

    func loadSubtitles(from subtitles: [SubtitleItem]) {
        if playerEngineChoice == "mpv" {
            mpvEngine.loadSubtitles(from: subtitles)
        } else {
            ksEngine.loadSubtitles(from: subtitles)
        }
    }

    func skipForward() {
        if playerEngineChoice == "mpv" { mpvEngine.skipForward() }
        else { ksEngine.skipForward() }
    }

    func skipBack() {
        if playerEngineChoice == "mpv" { mpvEngine.skipBack() }
        else { ksEngine.skipBack() }
    }

    func skipForward15() {
        if playerEngineChoice == "mpv" { mpvEngine.skipForward15() }
        else { ksEngine.skipForward15() }
    }

    func skipBack15() {
        if playerEngineChoice == "mpv" { mpvEngine.skipBack15() }
        else { ksEngine.skipBack15() }
    }
}
