package com.turqapp.app.qa

import android.os.SystemClock
import android.util.Log
import java.util.concurrent.CopyOnWriteArrayList
import java.util.concurrent.atomic.AtomicInteger

/**
 * Feed / shorts playback smoke monitor.
 *
 * Amaç:
 * - ExoPlayer callback'lerinden gelen truth state'i tek yerde toplamak
 * - kritik playback semptomlarını hafif ama gerçekçi kurallarla işaretlemek
 * - Espresso smoke testi için okunabilir hata listesi üretmek
 */
class PlaybackHealthMonitor(
    private val tag: String = "PlaybackHealthMonitor",
    private val firstFrameTimeoutMs: Long = 1_500L,
    private val freezeFrameTimeoutMs: Long = 1_000L,
    private val excessiveDroppedFramesThreshold: Int = 24,
) {

    private val errors = CopyOnWriteArrayList<String>()
    private val surfaceAttachCount = AtomicInteger(0)
    private val playbackRequestCount = AtomicInteger(0)

    @Volatile
    var playbackRequestedAt: Long = 0L
        private set

    @Volatile
    var firstFrameRenderedAt: Long = 0L
        private set

    @Volatile
    var firstFrameRendered: Boolean = false
        private set

    @Volatile
    var lastFrameRenderedAt: Long = 0L
        private set

    @Volatile
    var lastKnownPlaybackPositionMs: Long = 0L
        private set

    @Volatile
    var playerReadyAt: Long = 0L
        private set

    @Volatile
    var fullscreenTransitionStartedAt: Long = 0L
        private set

    @Volatile
    var lastSurfaceAttachedAt: Long = 0L
        private set

    @Volatile
    var lastSurfaceDetachedAt: Long = 0L
        private set

    @Volatile
    var isPlayerReady: Boolean = false
        private set

    @Volatile
    var isFullscreenTransitionOpen: Boolean = false
        private set

    @Volatile
    var droppedFrames: Int = 0
        private set

    @Volatile
    var isAudioExpected: Boolean = false
        private set

    @Volatile
    var lastErrorAt: Long = 0L
        private set

    fun resetForNewPlaybackSession() {
        playbackRequestedAt = 0L
        firstFrameRenderedAt = 0L
        firstFrameRendered = false
        lastFrameRenderedAt = 0L
        lastKnownPlaybackPositionMs = 0L
        playerReadyAt = 0L
        fullscreenTransitionStartedAt = 0L
        lastSurfaceAttachedAt = 0L
        lastSurfaceDetachedAt = 0L
        isPlayerReady = false
        isFullscreenTransitionOpen = false
        droppedFrames = 0
        isAudioExpected = false
        errors.clear()
        surfaceAttachCount.set(0)
        playbackRequestCount.set(0)
    }

    fun onPlaybackRequested() {
        playbackRequestedAt = now()
        playbackRequestCount.incrementAndGet()
        isAudioExpected = true
        firstFrameRendered = false
        firstFrameRenderedAt = 0L
        lastFrameRenderedAt = 0L
        isPlayerReady = false
        log("playbackRequested")
    }

    fun onPlayerReady() {
        playerReadyAt = now()
        isPlayerReady = true
        log("playerReady")
        maybeFlagReadyWithoutFrame()
    }

    fun onFirstFrameRendered() {
        val ts = now()
        firstFrameRendered = true
        firstFrameRenderedAt = ts
        lastFrameRenderedAt = ts
        log("firstFrameRendered ttffMs=${safeDelta(playbackRequestedAt, ts)}")
        maybeFlagFirstFrameTimeout()
    }

    fun onFrameRendered() {
        lastFrameRenderedAt = now()
    }

    fun onPositionUpdate(positionMs: Long) {
        lastKnownPlaybackPositionMs = positionMs
    }

    fun onAudioMissing() {
        addError("AUDIO_MISSING")
    }

    fun onPlaybackNotStarted() {
        addError("PLAYBACK_NOT_STARTED")
    }

    fun onFullscreenTransitionStarted() {
        fullscreenTransitionStartedAt = now()
        isFullscreenTransitionOpen = true
        log("fullscreenTransitionStarted")
    }

    fun onFullscreenTransitionEnded() {
        isFullscreenTransitionOpen = false
        log("fullscreenTransitionEnded")
    }

    fun onSurfaceAttached() {
        lastSurfaceAttachedAt = now()
        val attachCount = surfaceAttachCount.incrementAndGet()
        log("surfaceAttached count=$attachCount")
        if (!firstFrameRendered && attachCount >= 2) {
            addError("DOUBLE_BLACK_SCREEN_RISK")
        }
    }

    fun onSurfaceDetached() {
        lastSurfaceDetachedAt = now()
        log("surfaceDetached")
    }

    fun onDroppedFrames(count: Int) {
        droppedFrames += count
        log("droppedFrames total=$droppedFrames")
        if (droppedFrames >= excessiveDroppedFramesThreshold) {
            addError("EXCESSIVE_DROPPED_FRAMES")
        }
    }

    fun onRebuffer() {
        addError("REBUFFER_EVENT")
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

    fun getErrors(): List<String> = errors.toList()

    fun hasErrors(): Boolean = errors.isNotEmpty()

    fun snapshot(): Map<String, Any> = mapOf(
        "playbackRequestedAt" to playbackRequestedAt,
        "firstFrameRenderedAt" to firstFrameRenderedAt,
        "firstFrameRendered" to firstFrameRendered,
        "lastFrameRenderedAt" to lastFrameRenderedAt,
        "lastKnownPlaybackPositionMs" to lastKnownPlaybackPositionMs,
        "playerReadyAt" to playerReadyAt,
        "isPlayerReady" to isPlayerReady,
        "isFullscreenTransitionOpen" to isFullscreenTransitionOpen,
        "surfaceAttachCount" to surfaceAttachCount.get(),
        "playbackRequestCount" to playbackRequestCount.get(),
        "droppedFrames" to droppedFrames,
        "errors" to errors.toList(),
    )

    fun evaluatePassiveTimeouts() {
        maybeFlagFirstFrameTimeout()
        maybeFlagReadyWithoutFrame()
    }

    private fun maybeFlagFirstFrameTimeout() {
        if (playbackRequestedAt == 0L || firstFrameRendered) return
        if (now() - playbackRequestedAt > firstFrameTimeoutMs) {
            addError("FIRST_FRAME_TIMEOUT")
        }
    }

    private fun maybeFlagReadyWithoutFrame() {
        if (!isPlayerReady || firstFrameRendered || playerReadyAt == 0L) return
        if (now() - playerReadyAt > firstFrameTimeoutMs) {
            addError("READY_WITHOUT_FRAME")
        }
    }

    private fun addError(code: String) {
        if (errors.contains(code)) return
        errors.add(code)
        lastErrorAt = now()
        Log.e(tag, "error=$code snapshot=${snapshot()}")
    }

    private fun log(message: String) {
        Log.d(tag, message)
    }

    private fun now(): Long = SystemClock.elapsedRealtime()

    private fun safeDelta(start: Long, end: Long): Long {
        if (start <= 0L || end <= 0L) return 0L
        return (end - start).coerceAtLeast(0L)
    }
}
