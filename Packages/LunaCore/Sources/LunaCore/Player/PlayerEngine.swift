import Foundation
import SwiftUI
import AVFoundation
#if canImport(UIKit)
import UIKit
#endif

public enum PlayerEngineMode {
    case avplayer
    case custom
}

@MainActor
public class PlayerEngine: ObservableObject {
    public static let shared = PlayerEngine()

    @Published public var player: AVPlayer?
    @Published public var isPlaying = false
    @Published public var isLoading = true
    @Published public var isEnded = false
    @Published public var currentPosition: Double = 0
    @Published public var duration: Double = 0
    @Published public var bufferedPosition: Double = 0
    @Published public var playbackSpeed: Float = 1.0
    @Published public var currentLaunch: PlayerLaunch?
    @Published public var availableSubtitles: [SubtitleItem] = []
    @Published public var selectedSubtitle: SubtitleItem?
    @Published public var availableAudioTracks: [String] = []
    @Published public var selectedAudioTrack: String?
    @Published public var isMuted = false
    @Published public var engineMode: PlayerEngineMode = .avplayer

    #if canImport(UIKit)
    public var customDisplayView: UIView?
    #endif
    public var onCustomPlay: (() -> Void)?
    public var onCustomPause: (() -> Void)?
    public var onCustomSeek: ((Double) -> Void)?
    public var onCustomSetSpeed: ((Float) -> Void)?
    public var onCustomSkipForward: (() -> Void)?
    public var onCustomSkipBack: (() -> Void)?
    public var onCustomSkipForward15: (() -> Void)?
    public var onCustomSkipBack15: (() -> Void)?
    public var onCustomToggleMute: (() -> Void)?
    public var onCustomCycleSubtitle: (() -> Void)?
    public var onCustomSetSubtitle: ((SubtitleItem?) -> Void)?
    public var onCustomStop: (() -> Void)?

    private var timeObserver: Any?
    private var progressTimer: Timer?

    private init() {}

    public func launch(_ launch: PlayerLaunch) {
        cleanup()

        let compat = classifyStream(url: launch.sourceUrl, sourceType: .url)

        if compat == .enhanced || compat == .unsupported {
            engineMode = .custom
            currentLaunch = launch
            isLoading = true
            return
        }

        engineMode = .avplayer

        guard let sourceURL = URL(string: launch.sourceUrl) else {
            self.isLoading = false
            return
        }

        self.currentLaunch = launch
        self.isLoading = true
        self.isPlaying = false
        self.isEnded = false

        let asset: AVURLAsset
        if let headers = launch.sourceHeaders, !headers.isEmpty {
            let options = ["AVURLAssetHTTPHeaderFieldsKey": headers]
            asset = AVURLAsset(url: sourceURL, options: options)
        } else {
            asset = AVURLAsset(url: sourceURL)
        }

        let playerItem = AVPlayerItem(asset: asset)
        let player = AVPlayer(playerItem: playerItem)

        if let seekMs = launch.initialPositionMs, seekMs > 0 {
            let seekTime = CMTime(seconds: seekMs / 1000, preferredTimescale: 600)
            playerItem.seek(to: seekTime, completionHandler: nil)
        }

        self.player = player

        if let subs = launch.subtitles, !subs.isEmpty {
            self.availableSubtitles = subs
            self.selectedSubtitle = subs.first
        }

        addTimeObserver()
        startProgressTimer()
        setupNotifications(playerItem: playerItem)
    }

    public func play() {
        if engineMode == .custom { onCustomPlay?(); return }
        player?.play()
        isPlaying = true
        isEnded = false
    }

    public func pause() {
        if engineMode == .custom { onCustomPause?(); return }
        player?.pause()
        isPlaying = false
    }

    public func togglePlayPause() {
        if isPlaying { pause() } else { play() }
    }

    public func seek(to seconds: Double) {
        if engineMode == .custom { onCustomSeek?(seconds); return }
        let time = CMTime(seconds: seconds, preferredTimescale: 600)
        player?.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
        currentPosition = seconds
    }

    public func seekBy(_ seconds: Double) {
        let newPosition = min(max(currentPosition + seconds, 0), duration)
        seek(to: newPosition)
    }

    public func setPlaybackSpeed(_ speed: Float) {
        if engineMode == .custom { onCustomSetSpeed?(speed); return }
        playbackSpeed = speed
        player?.rate = speed
    }

    public func skipForward() {
        if engineMode == .custom { onCustomSkipForward?(); return }
        seekBy(30)
    }

    public func skipBack() {
        if engineMode == .custom { onCustomSkipBack?(); return }
        seekBy(-15)
    }

    public func skipForward15() {
        if engineMode == .custom { onCustomSkipForward15?(); return }
        seekBy(15)
    }

    public func skipBack15() {
        if engineMode == .custom { onCustomSkipBack15?(); return }
        seekBy(-15)
    }

    public func toggleMute() {
        if engineMode == .custom { onCustomToggleMute?(); return }
        isMuted.toggle()
        player?.isMuted = isMuted
    }

    public func loadSubtitles(from subtitles: [SubtitleItem]) {
        availableSubtitles = subtitles
        if selectedSubtitle == nil {
            selectedSubtitle = subtitles.first
        }
    }

    public func cycleSubtitle() {
        if engineMode == .custom { onCustomCycleSubtitle?(); return }
        guard !availableSubtitles.isEmpty else { return }
        if let current = selectedSubtitle,
           let idx = availableSubtitles.firstIndex(where: { $0.id == current.id }) {
            let next = (idx + 1) % availableSubtitles.count
            selectedSubtitle = availableSubtitles[next]
        } else {
            selectedSubtitle = availableSubtitles.first
        }
    }

    public func setSubtitle(_ subtitle: SubtitleItem?) {
        if engineMode == .custom { onCustomSetSubtitle?(subtitle); return }
        selectedSubtitle = subtitle
    }

    public func stop() {
        if engineMode == .custom { onCustomStop?(); resetState(); return }
        cleanup()
    }

    public func addExternalSubtitle(_ subtitle: SubtitleItem) {
        selectedSubtitle = subtitle
    }

    public func resetState() {
        cleanup()
        engineMode = .avplayer
        #if canImport(UIKit)
        customDisplayView = nil
        #endif
        clearCustomCallbacks()
    }

    public func clearCustomCallbacks() {
        onCustomPlay = nil
        onCustomPause = nil
        onCustomSeek = nil
        onCustomSetSpeed = nil
        onCustomSkipForward = nil
        onCustomSkipBack = nil
        onCustomSkipForward15 = nil
        onCustomSkipBack15 = nil
        onCustomToggleMute = nil
        onCustomCycleSubtitle = nil
        onCustomSetSubtitle = nil
        onCustomStop = nil
    }

    private func cleanup() {
        progressTimer?.invalidate()
        progressTimer = nil
        if let observer = timeObserver, let player = player {
            player.removeTimeObserver(observer)
        }
        timeObserver = nil
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        player = nil
        currentLaunch = nil
        isPlaying = false
        isLoading = true
        isEnded = false
        currentPosition = 0
        duration = 0
    }

    private func addTimeObserver() {
        guard let player = player else { return }
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self else { return }
            MainActor.assumeIsolated {
                self.currentPosition = time.seconds
                self.isLoading = false

                if let dur = player.currentItem?.duration.seconds,
                   dur > 0, !dur.isNaN, !dur.isInfinite {
                    self.duration = dur
                }

                if let loadedRange = player.currentItem?.loadedTimeRanges.first as? CMTimeRange {
                    self.bufferedPosition = loadedRange.end.seconds
                }
            }
        }
    }

    private func startProgressTimer() {
        progressTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.saveProgress()
            }
        }
    }

    private func setupNotifications(playerItem: AVPlayerItem) {
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            MainActor.assumeIsolated {
                self.isEnded = true
                self.isPlaying = false
            }
            Task {
                await self.saveProgress(completed: true)
            }
        }
    }

    private func saveProgress(completed: Bool = false) async {
        guard let launch = currentLaunch,
              let profile = ProfileManager.shared.currentProfile else { return }

        await WatchProgressRepository.shared.updateProgress(
            profileId: profile.id,
            mediaId: launch.videoId,
            mediaType: launch.contentType.rawValue,
            positionSeconds: currentPosition,
            durationSeconds: duration,
            completed: completed,
            name: launch.title,
            poster: launch.poster,
            parentMetaId: launch.parentMetaId,
            season: launch.seasonNumber,
            episode: launch.episodeNumber
        )
    }
}
