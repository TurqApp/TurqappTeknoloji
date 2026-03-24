package com.turqapp.app.qa

import android.os.SystemClock
import android.util.Log
import java.util.LinkedHashSet

/**
 * Collects feed / shorts playback truth and deduplicated critical errors.
 */
class PlaybackHealthMonitor(
    private val tag: String = "PlaybackHealthMonitor",
    private val firstFrameTimeoutMs: Long = 1_500L,
    private val freezeFrameTimeoutMs: Long = 1_000L,
    private val excessiveDroppedFramesThreshold: Int = 24,
    private val excessiveRebufferThreshold: Int = 3,
) {
    var stateListener: ((PlaybackHealthMonitor) -> Unit)? = null

    private val errorLock = Any()
    private val recordedErrors = LinkedHashSet<String>()

    @Volatile
    var playbackRequestedAt: Long = 0L
        private set

    @Volatile
    var playerReadyAt: Long = 0L
        private set

    @Volatile
    var firstFrameRenderedAt: Long = 0L
        private set

    @Volatile
    var lastFrameRenderedAt: Long = 0L
        private set

    @Volatile
    var lastKnownPlaybackPosition: Long = 0L
        private set

    @Volatile
    var isPlaybackExpected: Boolean = false
        private set

    @Volatile
    var isPlaying: Boolean = false
        private set

    @Volatile
    var hasRenderedFirstFrame: Boolean = false
        private set

    @Volatile
    var isBuffering: Boolean = false
        private set

    @Volatile
    var isInFullscreenTransition: Boolean = false
        private set

    @Volatile
    var surfaceAttachCount: Int = 0
        private set

    @Volatile
    var surfaceDetachCount: Int = 0
        private set

    @Volatile
    var droppedFramesTotal: Int = 0
        private set

    @Volatile
    var rebufferCount: Int = 0
        private set

    @Volatile
    var lastKnownPlaybackAdvanceAt: Long = 0L
        private set

    @Volatile
    var fullscreenTransitionStartedAt: Long = 0L
        private set

    @Volatile
    var appBackgroundedAt: Long = 0L
        private set

    @Volatile
    var appForegroundedAt: Long = 0L
        private set

    @Volatile
    var awaitingFullscreenRecovery: Boolean = false
        private set

    @Volatile
    var awaitingBackgroundRecovery: Boolean = false
        private set

    @Volatile
    var playerReadyObserved: Boolean = false
        private set

    fun resetForNewPlaybackSession() {
        playbackRequestedAt = 0L
        playerReadyAt = 0L
        firstFrameRenderedAt = 0L
        lastFrameRenderedAt = 0L
        lastKnownPlaybackPosition = 0L
        isPlaybackExpected = false
        isPlaying = false
        hasRenderedFirstFrame = false
        isBuffering = false
        isInFullscreenTransition = false
        surfaceAttachCount = 0
        surfaceDetachCount = 0
        droppedFramesTotal = 0
        rebufferCount = 0
        lastKnownPlaybackAdvanceAt = 0L
        fullscreenTransitionStartedAt = 0L
        appBackgroundedAt = 0L
        appForegroundedAt = 0L
        awaitingFullscreenRecovery = false
        awaitingBackgroundRecovery = false
        playerReadyObserved = false
        synchronized(errorLock) {
            recordedErrors.clear()
        }
        publish("reset")
    }

    fun onPlaybackRequested() {
        val timestamp = now()
        playbackRequestedAt = timestamp
        playerReadyAt = 0L
        firstFrameRenderedAt = 0L
        lastFrameRenderedAt = 0L
        lastKnownPlaybackPosition = 0L
        lastKnownPlaybackAdvanceAt = 0L
        isPlaybackExpected = true
        isPlaying = false
        hasRenderedFirstFrame = false
        isBuffering = false
        playerReadyObserved = false
        awaitingFullscreenRecovery = false
        awaitingBackgroundRecovery = false
        log("playbackRequested at=$timestamp")
        publish("playbackRequested")
    }

    fun onPlayerReady() {
        if (!playerReadyObserved) {
            playerReadyObserved = true
            playerReadyAt = now()
        }
        log("playerReady at=$playerReadyAt")
        evaluatePassiveTimeouts()
        publish("playerReady")
    }

    fun onPlaybackStarted() {
        isPlaying = true
        isPlaybackExpected = true
        isBuffering = false
        clearErrors("PLAYBACK_NOT_STARTED")
        publish("playbackStarted")
    }

    fun onPlaybackPaused() {
        isPlaying = false
        publish("playbackPaused")
    }

    fun onFirstFrameRendered() {
        val timestamp = now()
        hasRenderedFirstFrame = true
        if (firstFrameRenderedAt == 0L) {
            firstFrameRenderedAt = timestamp
        }
        lastFrameRenderedAt = timestamp
        awaitingFullscreenRecovery = false
        awaitingBackgroundRecovery = false
        clearErrors(
            "FIRST_FRAME_TIMEOUT",
            "READY_WITHOUT_FRAME",
            "PLAYBACK_NOT_STARTED",
        )
        log("firstFrameRendered ttffMs=${deltaFrom(playbackRequestedAt, timestamp)}")
        publish("firstFrameRendered")
    }

    fun onFrameRendered() {
        lastFrameRenderedAt = now()
        if (!hasRenderedFirstFrame) {
            hasRenderedFirstFrame = true
            if (firstFrameRenderedAt == 0L) {
                firstFrameRenderedAt = lastFrameRenderedAt
            }
        }
        awaitingFullscreenRecovery = false
        awaitingBackgroundRecovery = false
        publish("frameRendered")
    }

    fun onPositionUpdate(positionMs: Long) {
        if (positionMs > lastKnownPlaybackPosition + 40L) {
            lastKnownPlaybackAdvanceAt = now()
        }
        lastKnownPlaybackPosition = positionMs
        publish("position=$positionMs")
    }

    fun onBufferingStarted() {
        if (!isBuffering) {
            rebufferCount += 1
            if (rebufferCount >= excessiveRebufferThreshold) {
                addError("EXCESSIVE_REBUFFERING")
            }
        }
        isBuffering = true
        publish("bufferingStarted")
    }

    fun onBufferingEnded() {
        isBuffering = false
        publish("bufferingEnded")
    }

    fun onAudioMissing() {
        addError("AUDIO_NOT_STARTED")
    }

    fun onPlaybackNotStarted() {
        addError("PLAYBACK_NOT_STARTED")
    }

    fun onFullscreenTransitionStarted() {
        fullscreenTransitionStartedAt = now()
        isInFullscreenTransition = true
        awaitingFullscreenRecovery = isPlaybackExpected || isPlaying || hasRenderedFirstFrame
        publish("fullscreenTransitionStarted")
    }

    fun onFullscreenTransitionEnded() {
        isInFullscreenTransition = false
        if (awaitingFullscreenRecovery) {
            fullscreenTransitionStartedAt = now()
        }
        publish("fullscreenTransitionEnded")
    }

    fun onSurfaceAttached() {
        surfaceAttachCount += 1
        if (!hasRenderedFirstFrame && surfaceAttachCount >= 2) {
            addError("DOUBLE_BLACK_SCREEN_RISK")
        }
        publish("surfaceAttached")
    }

    fun onSurfaceDetached() {
        surfaceDetachCount += 1
        publish("surfaceDetached")
    }

    fun onAppBackgrounded() {
        appBackgroundedAt = now()
        awaitingBackgroundRecovery = isPlaybackExpected || isPlaying || hasRenderedFirstFrame
        isPlaying = false
        publish("appBackgrounded")
    }

    fun onAppForegrounded() {
        appForegroundedAt = now()
        publish("appForegrounded")
    }

    fun onDroppedFrames(count: Int) {
        droppedFramesTotal += count
        if (droppedFramesTotal >= excessiveDroppedFramesThreshold) {
            addError("EXCESSIVE_DROPPED_FRAMES")
        }
        publish("droppedFrames")
    }

    fun onVideoFreeze() {
        addError("VIDEO_FREEZE")
    }

    fun onReadyWithoutFrame() {
        addError("READY_WITHOUT_FRAME")
    }

    fun onFirstFrameTimeout() {
        addError("FIRST_FRAME_TIMEOUT")
    }

    fun onFullscreenInterruption() {
        addError("FULLSCREEN_INTERRUPTION")
    }

    fun onBackgroundResumeFailure() {
        addError("BACKGROUND_RESUME_FAILURE")
    }

    fun getErrors(): List<String> {
        return synchronized(errorLock) { recordedErrors.toList() }
    }

    fun hasErrors(): Boolean {
        return synchronized(errorLock) { recordedErrors.isNotEmpty() }
    }

    fun hasFreshFrameSince(timestamp: Long): Boolean {
        return lastFrameRenderedAt >= timestamp && lastFrameRenderedAt > 0L
    }

    fun snapshot(): Map<String, Any> = mapOf(
        "playbackRequestedAt" to playbackRequestedAt,
        "playerReadyAt" to playerReadyAt,
        "firstFrameRenderedAt" to firstFrameRenderedAt,
        "lastFrameRenderedAt" to lastFrameRenderedAt,
        "lastKnownPlaybackPosition" to lastKnownPlaybackPosition,
        "isPlaybackExpected" to isPlaybackExpected,
        "isPlaying" to isPlaying,
        "hasRenderedFirstFrame" to hasRenderedFirstFrame,
        "isBuffering" to isBuffering,
        "isInFullscreenTransition" to isInFullscreenTransition,
        "surfaceAttachCount" to surfaceAttachCount,
        "surfaceDetachCount" to surfaceDetachCount,
        "droppedFramesTotal" to droppedFramesTotal,
        "rebufferCount" to rebufferCount,
        "appBackgroundedAt" to appBackgroundedAt,
        "appForegroundedAt" to appForegroundedAt,
        "awaitingFullscreenRecovery" to awaitingFullscreenRecovery,
        "awaitingBackgroundRecovery" to awaitingBackgroundRecovery,
        "errors" to getErrors(),
    )

    fun evaluatePassiveTimeouts() {
        val timestamp = now()
        if (playbackRequestedAt > 0L &&
            !hasRenderedFirstFrame &&
            timestamp - playbackRequestedAt > firstFrameTimeoutMs
        ) {
            onFirstFrameTimeout()
            if (!isPlaying && isPlaybackExpected) {
                onPlaybackNotStarted()
            }
        }

        if (playerReadyAt > 0L &&
            !hasRenderedFirstFrame &&
            timestamp - playerReadyAt > firstFrameTimeoutMs
        ) {
            onReadyWithoutFrame()
        }

        if (awaitingFullscreenRecovery &&
            fullscreenTransitionStartedAt > 0L &&
            timestamp - fullscreenTransitionStartedAt > firstFrameTimeoutMs &&
            isPlaybackExpected &&
            !hasFreshFrameSince(fullscreenTransitionStartedAt)
        ) {
            onFullscreenInterruption()
        }

        if (awaitingBackgroundRecovery &&
            appForegroundedAt > 0L &&
            timestamp - appForegroundedAt > firstFrameTimeoutMs &&
            isPlaybackExpected &&
            !hasFreshFrameSince(appForegroundedAt)
        ) {
            onBackgroundResumeFailure()
        }
    }

    fun shouldFlagVideoFreeze(timestamp: Long = now()): Boolean {
        if (!hasRenderedFirstFrame || lastFrameRenderedAt <= 0L) return false
        if (!(isPlaybackExpected || isPlaying || lastKnownPlaybackAdvanceAt > 0L)) return false
        return timestamp - lastFrameRenderedAt > freezeFrameTimeoutMs
    }

    private fun addError(code: String) {
        val inserted = synchronized(errorLock) { recordedErrors.add(code) }
        if (!inserted) return
        Log.e(tag, "error=$code snapshot=${snapshot()}")
        publish("error=$code")
    }

    private fun clearErrors(vararg codes: String) {
        if (codes.isEmpty()) return
        val changed = synchronized(errorLock) {
            recordedErrors.removeAll(codes.toSet())
        }
        if (!changed) return
        publish("clear=${codes.joinToString(",")}")
    }

    private fun publish(event: String) {
        log(event)
        stateListener?.invoke(this)
    }

    private fun deltaFrom(start: Long, end: Long): Long {
        if (start <= 0L || end <= 0L || end < start) return 0L
        return end - start
    }

    private fun log(message: String) {
        Log.d(tag, message)
    }

    private fun now(): Long = SystemClock.elapsedRealtime()
}
