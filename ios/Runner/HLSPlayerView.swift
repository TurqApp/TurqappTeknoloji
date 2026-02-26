import UIKit
import AVFoundation
import Flutter

private final class PlayerContainerView: UIView {
    weak var linkedPlayerLayer: AVPlayerLayer?

    override func layoutSubviews() {
        super.layoutSubviews()
        linkedPlayerLayer?.frame = bounds
    }
}

class HLSPlayerView: NSObject, FlutterPlatformView {

    // MARK: - Properties
    private var _view: PlayerContainerView
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var playerItem: AVPlayerItem?
    private var eventSink: FlutterEventSink?
    private var timeObserver: Any?
    private var isLooping: Bool = false
    private var isAutoPlay: Bool = true

    // MARK: - Observers
    private var statusObserver: NSKeyValueObservation?
    private var playbackBufferEmptyObserver: NSKeyValueObservation?
    private var playbackLikelyToKeepUpObserver: NSKeyValueObservation?
    private var timeControlStatusObserver: NSKeyValueObservation?

    // MARK: - Notification Observers
    private var didPlayToEndTimeObserver: NSObjectProtocol?
    private var failedToPlayToEndTimeObserver: NSObjectProtocol?
    private var playbackStalledObserver: NSObjectProtocol?

    // MARK: - Lifecycle
    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger?,
        eventChannel: FlutterEventChannel
    ) {
        _view = PlayerContainerView(frame: frame)
        _view.backgroundColor = .clear

        super.init()

        // Setup event channel
        eventChannel.setStreamHandler(self)

        // Parse arguments
        if let params = args as? [String: Any] {
            if let url = params["url"] as? String {
                isAutoPlay = params["autoPlay"] as? Bool ?? true
                isLooping = params["loop"] as? Bool ?? false
                loadVideo(url: url)
            }
        }

        // Setup app lifecycle observers
        setupLifecycleObservers()
    }

    deinit {
        cleanup()
    }

    func view() -> UIView {
        return _view
    }

    // MARK: - Video Loading
    func loadVideo(url: String) {
        guard let videoURL = URL(string: url) else {
            sendEvent(["event": "error", "message": "Invalid URL"])
            return
        }

        cleanup()

        // Create AVURLAsset for HLS
        let asset = AVURLAsset(url: videoURL, options: [
            "AVURLAssetHTTPHeaderFieldsKey": [:],
            AVURLAssetPreferPreciseDurationAndTimingKey: true
        ])

        // Create player item
        playerItem = AVPlayerItem(asset: asset)

        // Configure player item for optimal HLS playback
        if #available(iOS 10.0, *) {
            // Segment geçişlerinde takılma olmaması için yeterli forward buffer.
            // 2s çok düşüktü — segment sınırında buffer boşalıyordu.
            playerItem?.preferredForwardBufferDuration = 6.0
        }

        // Create player
        player = AVPlayer(playerItem: playerItem)
        player?.automaticallyWaitsToMinimizeStalling = true

        // Create player layer
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.videoGravity = .resizeAspectFill
        playerLayer?.backgroundColor = UIColor.clear.cgColor
        playerLayer?.frame = _view.bounds

        if let playerLayer = playerLayer {
            _view.layer.addSublayer(playerLayer)
            _view.linkedPlayerLayer = playerLayer
        }

        // Setup observers
        setupPlayerObservers()

        // Auto play if enabled
        if isAutoPlay {
            player?.play()
        }
    }

    // MARK: - Player Controls
    func play() {
        player?.play()
        sendEvent(["event": "play"])
    }

    func pause() {
        player?.pause()
        sendEvent(["event": "pause"])
    }

    func seek(to seconds: Double) {
        let time = CMTime(seconds: seconds, preferredTimescale: 600)
        player?.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] completed in
            if completed {
                self?.sendEvent(["event": "seekCompleted", "position": seconds])
            }
        }
    }

    func setMuted(_ muted: Bool) {
        player?.isMuted = muted
    }

    func setVolume(_ volume: Double) {
        player?.volume = Float(volume)
    }

    func setLoop(_ loop: Bool) {
        isLooping = loop
    }

    func getCurrentTime() -> Double {
        return player?.currentTime().seconds ?? 0.0
    }

    func getDuration() -> Double {
        return playerItem?.duration.seconds ?? 0.0
    }

    func isMuted() -> Bool {
        return player?.isMuted ?? false
    }

    func isPlaying() -> Bool {
        if #available(iOS 10.0, *) {
            return player?.timeControlStatus == .playing
        } else {
            return player?.rate ?? 0 > 0
        }
    }

    // MARK: - Network & Buffer Control

    /// Oynatmayı durdur ve network/decoder kaynaklarını serbest bırak.
    /// Player instance hayatta kalır, tekrar loadVideo ile yüklenebilir.
    func stopPlayback() {
        // Time observer kaldır
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }

        // KVO observer'ları kaldır
        statusObserver?.invalidate()
        playbackBufferEmptyObserver?.invalidate()
        playbackLikelyToKeepUpObserver?.invalidate()
        timeControlStatusObserver?.invalidate()
        statusObserver = nil
        playbackBufferEmptyObserver = nil
        playbackLikelyToKeepUpObserver = nil
        timeControlStatusObserver = nil

        // Notification observer'ları kaldır
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

        // Network + decoder serbest bırak, player shell hayatta kalsın
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        playerItem = nil

        sendEvent(["event": "stopped"])
    }

    /// Forward buffer süresini dinamik ayarla (saniye cinsinden).
    func setPreferredBufferDuration(_ duration: Double) {
        if #available(iOS 10.0, *) {
            playerItem?.preferredForwardBufferDuration = duration
        }
    }

    // MARK: - Observers Setup
    private func setupPlayerObservers() {
        guard let playerItem = playerItem else { return }

        // Status observer
        statusObserver = playerItem.observe(\.status, options: [.new, .old]) { [weak self] item, _ in
            DispatchQueue.main.async {
                switch item.status {
                case .readyToPlay:
                    self?.sendEvent([
                        "event": "ready",
                        "duration": item.duration.seconds.isFinite ? item.duration.seconds : 0.0
                    ])
                case .failed:
                    let errorMessage = item.error?.localizedDescription ?? "Unknown playback error"
                    self?.sendEvent(["event": "error", "message": errorMessage])
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
                self?.sendEvent(["event": "buffering", "isBuffering": true])
            }
        }

        playbackLikelyToKeepUpObserver = playerItem.observe(\.isPlaybackLikelyToKeepUp, options: [.new]) { [weak self] item, _ in
            if item.isPlaybackLikelyToKeepUp {
                self?.sendEvent(["event": "buffering", "isBuffering": false])
            }
        }

        // Time control status observer (iOS 10+)
        if #available(iOS 10.0, *) {
            timeControlStatusObserver = player?.observe(\.timeControlStatus, options: [.new]) { [weak self] player, _ in
                DispatchQueue.main.async {
                    switch player.timeControlStatus {
                    case .playing:
                        self?.sendEvent(["event": "play"])
                    case .paused:
                        self?.sendEvent(["event": "pause"])
                    case .waitingToPlayAtSpecifiedRate:
                        self?.sendEvent(["event": "buffering", "isBuffering": true])
                    @unknown default:
                        break
                    }
                }
            }
        }

        // Periodic time observer
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self, let duration = self.playerItem?.duration else { return }

            let currentTime = time.seconds
            let totalDuration = duration.seconds

            if currentTime.isFinite && totalDuration.isFinite {
                self.sendEvent([
                    "event": "timeUpdate",
                    "position": currentTime,
                    "duration": totalDuration
                ])
            }
        }

        // Notification observers
        didPlayToEndTimeObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            self?.handlePlaybackEnded()
        }

        failedToPlayToEndTimeObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] notification in
            let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error
            self?.sendEvent(["event": "error", "message": error?.localizedDescription ?? "Failed to play to end"])
        }

        playbackStalledObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemPlaybackStalled,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            self?.sendEvent(["event": "buffering", "isBuffering": true])
        }
    }

    private func handlePlaybackEnded() {
        sendEvent(["event": "completed"])

        if isLooping {
            player?.seek(to: .zero)
            player?.play()
        }
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
    }

    @objc private func appDidEnterBackground() {
        player?.pause()
    }

    @objc private func appWillEnterForeground() {
        // Optional: resume playback if needed
    }

    // MARK: - Layout
    func layoutSubviews() {
        playerLayer?.frame = _view.bounds
    }

    // MARK: - Cleanup
    private func cleanup() {
        // Remove time observer
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }

        // Remove KVO observers
        statusObserver?.invalidate()
        playbackBufferEmptyObserver?.invalidate()
        playbackLikelyToKeepUpObserver?.invalidate()
        timeControlStatusObserver?.invalidate()

        statusObserver = nil
        playbackBufferEmptyObserver = nil
        playbackLikelyToKeepUpObserver = nil
        timeControlStatusObserver = nil

        // Remove notification observers
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

        // Remove app lifecycle observers
        NotificationCenter.default.removeObserver(self)

        // Stop player
        player?.pause()
        player?.replaceCurrentItem(with: nil)

        // Remove layer
        playerLayer?.removeFromSuperlayer()

        // Nullify references
        playerLayer = nil
        playerItem = nil
        player = nil
    }

    func dispose() {
        cleanup()
        eventSink = nil
    }

    // MARK: - Event Handling
    private func sendEvent(_ data: [String: Any]) {
        DispatchQueue.main.async { [weak self] in
            self?.eventSink?(data)
        }
    }
}

// MARK: - FlutterStreamHandler
extension HLSPlayerView: FlutterStreamHandler {
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        // Listener geç bağlandıysa mevcut durumu replay et.
        if let item = playerItem, item.status == .readyToPlay {
            sendEvent([
                "event": "ready",
                "duration": item.duration.seconds.isFinite ? item.duration.seconds : 0.0
            ])
        }
        if isPlaying() {
            sendEvent(["event": "play"])
        } else if playerItem?.isPlaybackLikelyToKeepUp == false {
            sendEvent(["event": "buffering", "isBuffering": true])
        }
        let pos = getCurrentTime()
        let dur = getDuration()
        if dur.isFinite && dur > 0 {
            sendEvent([
                "event": "timeUpdate",
                "position": max(0.0, pos),
                "duration": dur
            ])
        }
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
}
