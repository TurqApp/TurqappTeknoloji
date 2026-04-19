import Foundation
import QuartzCore

final class PlaybackHealthMonitor {
    typealias StateListener = (PlaybackHealthMonitor) -> Void

    private let tag: String
    private let firstFrameTimeout: CFTimeInterval
    private let freezeFrameThreshold: CFTimeInterval
    private let excessiveStallThreshold: Int

    private var recordedErrors = Set<String>()
    private var errorOrder = [String]()

    var stateListener: StateListener?

    private(set) var playbackRequestedAt: CFTimeInterval = 0
    private(set) var playerReadyAt: CFTimeInterval = 0
    private(set) var firstFrameRenderedAt: CFTimeInterval = 0
    private(set) var lastFrameRenderedAt: CFTimeInterval = 0
    private(set) var lastKnownPlaybackTime: Double = 0

    private(set) var isPlaybackExpected = false
    private(set) var isPlaying = false
    private(set) var hasRenderedFirstFrame = false
    private(set) var isBuffering = false
    private(set) var isInFullscreenTransition = false
    private(set) var isLayerAttached = false

    private(set) var stallCount = 0
    private(set) var layerAttachCount = 0
    private(set) var fullscreenTransitionStartedAt: CFTimeInterval = 0
    private(set) var appDidEnterBackgroundAt: CFTimeInterval = 0
    private(set) var appWillEnterForegroundAt: CFTimeInterval = 0
    private(set) var lastPlaybackProgressedAt: CFTimeInterval = 0
    private(set) var awaitingFullscreenRecovery = false
    private(set) var awaitingBackgroundRecovery = false
    private(set) var lastAccessLogSummary = ""

    init(
        tag: String = "PlaybackHealthMonitor",
        firstFrameTimeout: CFTimeInterval = 1.5,
        freezeFrameThreshold: CFTimeInterval = 1.0,
        excessiveStallThreshold: Int = 3
    ) {
        self.tag = tag
        self.firstFrameTimeout = firstFrameTimeout
        self.freezeFrameThreshold = freezeFrameThreshold
        self.excessiveStallThreshold = excessiveStallThreshold
    }

    func resetForNewPlaybackSession() {
        playbackRequestedAt = 0
        playerReadyAt = 0
        firstFrameRenderedAt = 0
        lastFrameRenderedAt = 0
        lastKnownPlaybackTime = 0
        isPlaybackExpected = false
        isPlaying = false
        hasRenderedFirstFrame = false
        isBuffering = false
        isInFullscreenTransition = false
        isLayerAttached = false
        stallCount = 0
        layerAttachCount = 0
        fullscreenTransitionStartedAt = 0
        appDidEnterBackgroundAt = 0
        appWillEnterForegroundAt = 0
        lastPlaybackProgressedAt = 0
        awaitingFullscreenRecovery = false
        awaitingBackgroundRecovery = false
        lastAccessLogSummary = ""
        recordedErrors.removeAll()
        errorOrder.removeAll()
        publishState("reset")
    }

    func onPlaybackRequested() {
        playbackRequestedAt = now()
        playerReadyAt = 0
        firstFrameRenderedAt = 0
        lastFrameRenderedAt = 0
        lastKnownPlaybackTime = 0
        lastPlaybackProgressedAt = 0
        isPlaybackExpected = true
        isPlaying = false
        isBuffering = false
        awaitingFullscreenRecovery = false
        awaitingBackgroundRecovery = false
        publishState("playbackRequested")
    }

    func onPlayerReady() {
        if playerReadyAt == 0 {
            playerReadyAt = now()
        }
        publishState("playerReady")
    }

    func onPlaybackStarted() {
        isPlaying = true
        isPlaybackExpected = true
        publishState("playbackStarted")
    }

    func onPlaybackPaused() {
        isPlaying = false
        publishState("playbackPaused")
    }

    func onPlaybackCompleted() {
        isPlaying = false
        isPlaybackExpected = false
        isBuffering = false
        lastKnownPlaybackTime = 0
        lastPlaybackProgressedAt = 0
        lastFrameRenderedAt = 0
        awaitingFullscreenRecovery = false
        awaitingBackgroundRecovery = false
        publishState("playbackCompleted")
    }

    func onFirstFrameRendered() {
        let timestamp = now()
        if firstFrameRenderedAt == 0 {
            firstFrameRenderedAt = timestamp
        }
        lastFrameRenderedAt = timestamp
        hasRenderedFirstFrame = true
        awaitingFullscreenRecovery = false
        awaitingBackgroundRecovery = false
        publishState("firstFrameRendered")
    }

    func onFrameRendered() {
        lastFrameRenderedAt = now()
        if !hasRenderedFirstFrame {
            hasRenderedFirstFrame = true
            firstFrameRenderedAt = lastFrameRenderedAt
        }
        awaitingFullscreenRecovery = false
        awaitingBackgroundRecovery = false
        publishState("frameRendered")
    }

    func onTimeProgress(_ seconds: Double) {
        if seconds > lastKnownPlaybackTime {
            lastKnownPlaybackTime = seconds
            lastPlaybackProgressedAt = now()
        }
        publishState("timeProgress=\(String(format: "%.3f", seconds))")
    }

    func onBufferingStarted() {
        isBuffering = true
        publishState("bufferingStarted")
    }

    func onBufferingEnded() {
        isBuffering = false
        publishState("bufferingEnded")
    }

    func onStallDetected() {
        stallCount += 1
        if stallCount >= excessiveStallThreshold {
            recordError("EXCESSIVE_REBUFFERING")
        }
        publishState("stallDetected")
    }

    func onAudioMissing() {
        recordError("AUDIO_NOT_STARTED")
    }

    func onPlaybackNotStarted() {
        recordError("PLAYBACK_NOT_STARTED")
    }

    func onFullscreenTransitionStarted() {
        isInFullscreenTransition = true
        fullscreenTransitionStartedAt = now()
        awaitingFullscreenRecovery = isPlaybackExpected || isPlaying || hasRenderedFirstFrame
        publishState("fullscreenTransitionStarted")
    }

    func onFullscreenTransitionEnded() {
        isInFullscreenTransition = false
        if awaitingFullscreenRecovery {
            fullscreenTransitionStartedAt = now()
        }
        publishState("fullscreenTransitionEnded")
    }

    func onPlayerLayerAttached() {
        isLayerAttached = true
        layerAttachCount += 1
        if layerAttachCount >= 2 && !hasRenderedFirstFrame {
            recordError("DOUBLE_BLACK_SCREEN_RISK")
        }
        publishState("playerLayerAttached")
    }

    func onPlayerLayerDetached() {
        isLayerAttached = false
        publishState("playerLayerDetached")
    }

    func onAppDidEnterBackground() {
        appDidEnterBackgroundAt = now()
        awaitingBackgroundRecovery = isPlaybackExpected || isPlaying || hasRenderedFirstFrame
        isPlaying = false
        publishState("appDidEnterBackground")
    }

    func onAppWillEnterForeground() {
        appWillEnterForegroundAt = now()
        publishState("appWillEnterForeground")
    }

    func onAccessLogUpdate(summary: String) {
        lastAccessLogSummary = summary
        if summary.localizedCaseInsensitiveContains("error") ||
            ((_parseIntMetric(named: "stalls", from: summary) ?? 0) > 0) {
            onStallDetected()
        }
        publishState("accessLog=\(summary)")
    }

    func getErrors() -> [String] {
        errorOrder
    }

    func hasErrors() -> Bool {
        !errorOrder.isEmpty
    }

    func snapshot() -> [String: Any] {
        [
            "playbackRequestedAt": playbackRequestedAt,
            "playerReadyAt": playerReadyAt,
            "firstFrameRenderedAt": firstFrameRenderedAt,
            "lastFrameRenderedAt": lastFrameRenderedAt,
            "lastKnownPlaybackTime": lastKnownPlaybackTime,
            "isPlaybackExpected": isPlaybackExpected,
            "isPlaying": isPlaying,
            "hasRenderedFirstFrame": hasRenderedFirstFrame,
            "isBuffering": isBuffering,
            "isInFullscreenTransition": isInFullscreenTransition,
            "isLayerAttached": isLayerAttached,
            "stallCount": stallCount,
            "layerAttachCount": layerAttachCount,
            "fullscreenTransitionStartedAt": fullscreenTransitionStartedAt,
            "appDidEnterBackgroundAt": appDidEnterBackgroundAt,
            "appWillEnterForegroundAt": appWillEnterForegroundAt,
            "awaitingFullscreenRecovery": awaitingFullscreenRecovery,
            "awaitingBackgroundRecovery": awaitingBackgroundRecovery,
            "lastAccessLogSummary": lastAccessLogSummary,
            "errors": errorOrder,
        ]
    }

    func detectTimeoutAnomalies(referenceTime: CFTimeInterval = CACurrentMediaTime()) {
        let timestamp = referenceTime
        if playbackRequestedAt > 0 &&
            !hasRenderedFirstFrame &&
            timestamp - playbackRequestedAt > firstFrameTimeout {
            recordError("FIRST_FRAME_TIMEOUT")
        }
        if playerReadyAt > 0 &&
            !hasRenderedFirstFrame &&
            timestamp - playerReadyAt > firstFrameTimeout {
            recordError("READY_WITHOUT_FRAME")
        }
        if isPlaybackExpected &&
            !isPlaying &&
            !hasRenderedFirstFrame &&
            playbackRequestedAt > 0 &&
            timestamp - playbackRequestedAt > firstFrameTimeout {
            recordError("PLAYBACK_NOT_STARTED")
        }
        if awaitingFullscreenRecovery &&
            fullscreenTransitionStartedAt > 0 &&
            timestamp - fullscreenTransitionStartedAt > firstFrameTimeout &&
            isPlaybackExpected &&
            !hasFreshFrame(since: fullscreenTransitionStartedAt) {
            recordError("FULLSCREEN_INTERRUPTION")
        }
        if awaitingBackgroundRecovery &&
            appWillEnterForegroundAt > 0 &&
            timestamp - appWillEnterForegroundAt > firstFrameTimeout &&
            isPlaybackExpected &&
            !hasFreshFrame(since: appWillEnterForegroundAt) {
            recordError("BACKGROUND_RESUME_FAILURE")
        }
    }

    func detectVideoFreezeIfNeeded(
        referenceTime: CFTimeInterval = CACurrentMediaTime(),
        frameSilenceThreshold: CFTimeInterval? = nil
    ) {
        let timestamp = referenceTime
        let threshold = frameSilenceThreshold ?? freezeFrameThreshold
        guard isPlaybackExpected || isPlaying || lastKnownPlaybackTime > 0 else { return }
        guard hasRenderedFirstFrame else { return }
        guard lastFrameRenderedAt > 0 else { return }
        if timestamp - lastFrameRenderedAt > threshold {
            recordError("VIDEO_FREEZE")
        }
    }

    func onFullscreenInterruption() {
        recordError("FULLSCREEN_INTERRUPTION")
    }

    func onBackgroundResumeFailure() {
        recordError("BACKGROUND_RESUME_FAILURE")
    }

    func hasFreshFrame(since timestamp: CFTimeInterval) -> Bool {
        lastFrameRenderedAt >= timestamp && lastFrameRenderedAt > 0
    }

    func shouldFlagVideoFreeze(
        referenceTime: CFTimeInterval = CACurrentMediaTime(),
        frameSilenceThreshold: CFTimeInterval? = nil
    ) -> Bool {
        let threshold = frameSilenceThreshold ?? freezeFrameThreshold
        guard hasRenderedFirstFrame else { return false }
        guard isPlaybackExpected || isPlaying || lastPlaybackProgressedAt > 0 else { return false }
        guard lastFrameRenderedAt > 0 else { return false }
        return referenceTime - lastFrameRenderedAt > threshold
    }

    private func recordError(_ code: String) {
        guard !recordedErrors.contains(code) else { return }
        recordedErrors.insert(code)
        errorOrder.append(code)
        log("error=\(code)")
        publishState("error=\(code)")
    }

    private func _parseIntMetric(named metric: String, from summary: String) -> Int? {
        guard let range = summary.range(of: "\(metric)=") else { return nil }
        let suffix = summary[range.upperBound...]
        let digits = suffix.prefix { $0.isNumber }
        guard !digits.isEmpty else { return nil }
        return Int(digits)
    }

    private func publishState(_ event: String) {
        log(event)
        stateListener?(self)
    }

    private func log(_ message: String) {
        print("[\(tag)] \(message)")
    }

    private func now() -> CFTimeInterval {
        CACurrentMediaTime()
    }
}
