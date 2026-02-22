import UIKit
import AVFoundation

/// Global Singleton HLS Player Manager
/// TikTok/Instagram-style player reuse mimarisi
/// 1 Player instance + Multiple surfaces support
class GlobalHLSPlayerManager {

    // MARK: - Singleton
    static let shared = GlobalHLSPlayerManager()

    // MARK: - Properties
    private var player: AVPlayer?
    private var currentPlayerItem: AVPlayerItem?
    private var currentSurface: AVPlayerLayer?
    private var currentURL: String?
    private var isPlaying: Bool = false
    private var wasPlayingBeforeBackground: Bool = false

    // Player pool for pre-loading (optional future enhancement)
    private var preloadPlayers: [String: AVPlayer] = [:]

    // Observers
    private var statusObserver: NSKeyValueObservation?
    private var playbackBufferEmptyObserver: NSKeyValueObservation?
    private var playbackLikelyToKeepUpObserver: NSKeyValueObservation?
    private var timeControlStatusObserver: NSKeyValueObservation?
    private var didPlayToEndTimeObserver: NSObjectProtocol?
    private var failedToPlayToEndTimeObserver: NSObjectProtocol?
    private var playbackStalledObserver: NSObjectProtocol?

    // Event callbacks
    var onStateChange: ((PlayerManagerState) -> Void)?
    var onTimeUpdate: ((Double, Double) -> Void)?
    var onError: ((String) -> Void)?

    // MARK: - Initialization
    private init() {
        setupAudioSession()
        setupLifecycleObservers()
    }

    deinit {
        cleanup()
    }

    // MARK: - Audio Session Setup
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .moviePlayback, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("[GlobalPlayerManager] Audio session setup failed: \(error)")
        }
    }

    // MARK: - Public API

    /// Load and play video on specified surface
    func loadAndPlay(url: String, on surface: AVPlayerLayer, autoPlay: Bool = true) {
        // If same video, just attach to new surface
        if url == currentURL, let player = player {
            attachToSurface(surface)
            if autoPlay && !isPlaying {
                play()
            }
            return
        }

        // Load new video
        loadVideo(url: url, on: surface, autoPlay: autoPlay)
    }

    /// Attach existing player to new surface (for scroll reuse)
    func attachToSurface(_ surface: AVPlayerLayer) {
        // Detach from old surface
        currentSurface?.player = nil

        // Attach to new surface
        surface.player = player
        currentSurface = surface

        print("[GlobalPlayerManager] Attached to new surface")
    }

    /// Detach from current surface
    func detachFromSurface() {
        currentSurface?.player = nil
        currentSurface = nil
        print("[GlobalPlayerManager] Detached from surface")
    }

    /// Play current video
    func play() {
        player?.play()
        isPlaying = true
        onStateChange?(.playing)
    }

    /// Pause current video
    func pause() {
        player?.pause()
        isPlaying = false
        onStateChange?(.paused)
    }

    /// Seek to position
    func seek(to seconds: Double, completion: ((Bool) -> Void)? = nil) {
        let time = CMTime(seconds: seconds, preferredTimescale: 600)
        player?.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero) { completed in
            completion?(completed)
        }
    }

    /// Set muted
    func setMuted(_ muted: Bool) {
        player?.isMuted = muted
    }

    /// Set volume
    func setVolume(_ volume: Float) {
        player?.volume = volume
    }

    /// Get current time
    func getCurrentTime() -> Double {
        return player?.currentTime().seconds ?? 0.0
    }

    /// Get duration
    func getDuration() -> Double {
        return currentPlayerItem?.duration.seconds ?? 0.0
    }

    /// Check if playing
    func isCurrentlyPlaying() -> Bool {
        return isPlaying
    }

    /// Get current URL
    func getCurrentURL() -> String? {
        return currentURL
    }

    /// Release all resources
    func release() {
        cleanup()
    }

    // MARK: - Private Methods

    private func loadVideo(url: String, on surface: AVPlayerLayer, autoPlay: Bool) {
        guard let videoURL = URL(string: url) else {
            onError?("Invalid URL: \(url)")
            return
        }

        // Cleanup old player
        cleanupObservers()

        // Create new AVURLAsset for HLS
        let asset = AVURLAsset(url: videoURL, options: [
            AVURLAssetPreferPreciseDurationAndTimingKey: true
        ])

        // Create player item
        let playerItem = AVPlayerItem(asset: asset)

        // Configure for optimal HLS playback
        if #available(iOS 10.0, *) {
            playerItem.preferredForwardBufferDuration = 1.0
        }

        currentPlayerItem = playerItem

        // Create or reuse player
        if player == nil {
            player = AVPlayer(playerItem: playerItem)
            player?.automaticallyWaitsToMinimizeStalling = true
        } else {
            player?.replaceCurrentItem(with: playerItem)
        }

        // Attach to surface
        surface.player = player
        currentSurface = surface

        // Store current URL
        currentURL = url

        // Setup observers
        setupPlayerObservers()

        // Auto play if enabled
        if autoPlay {
            play()
        } else {
            isPlaying = false
        }

        onStateChange?(.loading)
    }

    private func setupPlayerObservers() {
        guard let playerItem = currentPlayerItem else { return }

        // Status observer
        statusObserver = playerItem.observe(\.status, options: [.new]) { [weak self] item, _ in
            DispatchQueue.main.async {
                guard let self = self else { return }

                switch item.status {
                case .readyToPlay:
                    self.onStateChange?(.ready)
                case .failed:
                    let error = item.error?.localizedDescription ?? "Unknown playback error"
                    self.onError?(error)
                    self.onStateChange?(.error)
                case .unknown:
                    break
                @unknown default:
                    break
                }
            }
        }

        // Buffer observers
        playbackBufferEmptyObserver = playerItem.observe(\.isPlaybackBufferEmpty, options: [.new]) { [weak self] item, _ in
            if item.isPlaybackBufferEmpty {
                self?.onStateChange?(.buffering)
            }
        }

        playbackLikelyToKeepUpObserver = playerItem.observe(\.isPlaybackLikelyToKeepUp, options: [.new]) { [weak self] item, _ in
            if item.isPlaybackLikelyToKeepUp {
                self?.onStateChange?(self?.isPlaying == true ? .playing : .paused)
            }
        }

        // Time control status observer
        if #available(iOS 10.0, *) {
            timeControlStatusObserver = player?.observe(\.timeControlStatus, options: [.new]) { [weak self] player, _ in
                DispatchQueue.main.async {
                    guard let self = self else { return }

                    switch player.timeControlStatus {
                    case .playing:
                        self.isPlaying = true
                        self.onStateChange?(.playing)
                    case .paused:
                        self.isPlaying = false
                        self.onStateChange?(.paused)
                    case .waitingToPlayAtSpecifiedRate:
                        self.onStateChange?(.buffering)
                    @unknown default:
                        break
                    }
                }
            }
        }

        // Periodic time observer
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self,
                  let duration = self.currentPlayerItem?.duration else { return }

            let currentTime = time.seconds
            let totalDuration = duration.seconds

            if currentTime.isFinite && totalDuration.isFinite {
                self.onTimeUpdate?(currentTime, totalDuration)
            }
        }

        // Notification observers
        didPlayToEndTimeObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            self?.onStateChange?(.completed)
        }

        failedToPlayToEndTimeObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] notification in
            let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error
            self?.onError?(error?.localizedDescription ?? "Failed to play to end")
        }

        playbackStalledObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemPlaybackStalled,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            self?.onStateChange?(.buffering)
        }
    }

    private func cleanupObservers() {
        statusObserver?.invalidate()
        playbackBufferEmptyObserver?.invalidate()
        playbackLikelyToKeepUpObserver?.invalidate()
        timeControlStatusObserver?.invalidate()

        statusObserver = nil
        playbackBufferEmptyObserver = nil
        playbackLikelyToKeepUpObserver = nil
        timeControlStatusObserver = nil

        if let observer = didPlayToEndTimeObserver {
            NotificationCenter.default.removeObserver(observer)
            didPlayToEndTimeObserver = nil
        }

        if let observer = failedToPlayToEndTimeObserver {
            NotificationCenter.default.removeObserver(observer)
            failedToPlayToEndTimeObserver = nil
        }

        if let observer = playbackStalledObserver {
            NotificationCenter.default.removeObserver(observer)
            playbackStalledObserver = nil
        }
    }

    private func cleanup() {
        cleanupObservers()

        player?.pause()
        player?.replaceCurrentItem(with: nil)
        player = nil

        currentSurface?.player = nil
        currentSurface = nil

        currentPlayerItem = nil
        currentURL = nil
        isPlaying = false

        preloadPlayers.removeAll()

        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Lifecycle Observers

    private func setupLifecycleObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
    }

    @objc private func appDidEnterBackground() {
        wasPlayingBeforeBackground = isPlaying
        if isPlaying {
            pause()
        }
    }

    @objc private func appWillEnterForeground() {
        // Resume playback if it was playing before background
        if wasPlayingBeforeBackground {
            play()
            wasPlayingBeforeBackground = false
        }
    }

    @objc private func handleAudioInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        switch type {
        case .began:
            // Interruption began (phone call, alarm, etc.)
            pause()
        case .ended:
            // Interruption ended
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    play()
                }
            }
        @unknown default:
            break
        }
    }
}

// MARK: - Player Manager State

enum PlayerManagerState {
    case idle
    case loading
    case ready
    case playing
    case paused
    case buffering
    case completed
    case error
}
