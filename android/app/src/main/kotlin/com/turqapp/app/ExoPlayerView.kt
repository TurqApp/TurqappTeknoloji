package com.turqapp.app

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Color
import android.os.Build
import android.os.Debug
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.util.Log
import android.view.LayoutInflater
import android.view.TextureView
import android.view.View
import android.widget.FrameLayout
import android.widget.ImageView
import androidx.media3.common.AudioAttributes
import androidx.media3.common.MediaItem
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.common.Tracks
import androidx.media3.common.C
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.DefaultLoadControl
import androidx.media3.exoplayer.analytics.AnalyticsListener
import androidx.media3.exoplayer.hls.HlsMediaSource
import androidx.media3.datasource.DefaultHttpDataSource
import androidx.media3.ui.AspectRatioFrameLayout
import androidx.media3.ui.PlayerView
import com.turqapp.app.qa.ExoPlayerPlaybackProbe
import com.turqapp.app.qa.ExoPlayerSmokeRegistry
import com.turqapp.app.qa.PlaybackHealthMonitor
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.platform.PlatformView
import java.util.LinkedHashMap
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

class ExoPlayerView(
    private val context: Context,
    private val viewId: Long,
    private val args: Map<String, Any>?,
    private val eventChannel: EventChannel
) : PlatformView, EventChannel.StreamHandler {

    companion object {
        private const val RESUME_FRAME_CACHE_MAX_ENTRIES = 8
        private val resumeFrameCache = object : LinkedHashMap<String, Bitmap>(
            RESUME_FRAME_CACHE_MAX_ENTRIES,
            0.75f,
            true
        ) {
            override fun removeEldestEntry(eldest: MutableMap.MutableEntry<String, Bitmap>?): Boolean {
                val shouldEvict = size > RESUME_FRAME_CACHE_MAX_ENTRIES
                if (shouldEvict) {
                    eldest?.value?.takeIf { !it.isRecycled }?.recycle()
                }
                return shouldEvict
            }
        }
    }

    private val forceFullscreen = args?.get("forceFullscreen") as? Boolean ?: false
    private val isPrimaryFeedSurface =
        args?.get("primaryFeedSurface") as? Boolean ?: false
    private var preferResumePoster =
        args?.get("preferResumePoster") as? Boolean ?: false
    private val container = object : FrameLayout(context) {
        override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
            if (forceFullscreen) {
                val root = rootView
                val targetWidth = if (root.width > 0) root.width else MeasureSpec.getSize(widthMeasureSpec)
                val targetHeight = if (root.height > 0) root.height else MeasureSpec.getSize(heightMeasureSpec)
                super.onMeasure(
                    MeasureSpec.makeMeasureSpec(targetWidth, MeasureSpec.EXACTLY),
                    MeasureSpec.makeMeasureSpec(targetHeight, MeasureSpec.EXACTLY)
                )
                return
            }
            super.onMeasure(widthMeasureSpec, heightMeasureSpec)
        }
    }
    private val playerView: PlayerView
    private val resumeFrameOverlay: ImageView
    private var player: ExoPlayer? = null
    private var eventSink: EventChannel.EventSink? = null
    private var isLooping = false
    private val handler = Handler(Looper.getMainLooper())
    private var positionRunnable: Runnable? = null
    private var preferredMaxBufferMs: Long = 6000
    private val startupRecoveryMaxResumePositionMs = 1200L
    private var currentUrl: String? = null
    private var isSoftHeld = false
    private var heldVolume: Float = 1f
    private var appBackgroundSoftHeld = false
    private var shouldResumeAfterAppForeground = false
    private var didRenderFirstFrame = false
    private var isPlayerReady = false
    private var hasVideoSize = false
    private var hasStableSurfaceLayout = false
    private var pendingRevealRunnable: Runnable? = null
    private var lastSurfaceWidth = 0
    private var lastSurfaceHeight = 0
    private var stableSurfacePasses = 0
    private var isBufferingDispatched = false
    private var lastVideoFrameAtMs = 0L
    private var firstVideoFrameAtMs = 0L
    private var lastWatchdogPositionMs = 0L
    private var stallRecoveries = 0
    private var startupRecoveryAttempts = 0
    private var droppedVideoFrames = 0
    private var bufferingEvents = 0
    private var stallWatchdogRunnable: Runnable? = null
    private var startupRecoveryRunnable: Runnable? = null
    private var lastBandwidthEstimateKbps = 0L
    private var selectedVideoBitrateKbps = 0L
    private var selectedVideoHeight = 0
    private var selectedVideoWidth = 0
    private var resumeFrameBitmap: Bitmap? = null
    private var resumeFrameCacheKey: String? = null
    private var lastNativeVisualPhase: String? = null
    private var lastNativeVisualPhaseAtMs = 0L
    private var lastSeekCompletedPositionMs = -1L
    private var lastSeekCompletedAtMs = 0L
    private val smokeMonitor = PlaybackHealthMonitor(tag = "PlaybackHealthMonitor#$viewId")
    private var smokeProbe: ExoPlayerPlaybackProbe? = null
    private var isSmokeRegistryActive = false

    private fun hasReusableVideoFrame(): Boolean {
        return didRenderFirstFrame || firstVideoFrameAtMs > 0L || lastVideoFrameAtMs > 0L
    }

    private inline fun runOnMain(crossinline block: () -> Unit) {
        if (Looper.myLooper() == Looper.getMainLooper()) {
            block()
        } else {
            handler.post { block() }
        }
    }

    private inline fun runOnMainBlocking(crossinline block: () -> Unit) {
        if (Looper.myLooper() == Looper.getMainLooper()) {
            block()
            return
        }
        val latch = CountDownLatch(1)
        handler.post {
            try {
                block()
            } finally {
                latch.countDown()
            }
        }
        try {
            latch.await(150, TimeUnit.MILLISECONDS)
        } catch (_: InterruptedException) {
            Thread.currentThread().interrupt()
        }
    }

    private fun shouldUseStartupRecoveryWatchdog(): Boolean = forceFullscreen

    private fun publishSmokeSnapshot(monitor: PlaybackHealthMonitor) {
        if (!isSmokeRegistryActive) {
            return
        }
        val probeSnapshot = smokeProbe?.debugSnapshot().orEmpty()
        val runtimeSnapshot = mapOf(
            "viewId" to viewId,
            "currentUrl" to (currentUrl ?: ""),
            "isSoftHeld" to isSoftHeld,
            "heldVolume" to heldVolume.toDouble(),
            "playerVolume" to (player?.volume ?: 0f).toDouble(),
            "isMuted" to ((player?.volume ?: 1f) == 0f),
            "isPlayingRuntime" to (player?.isPlaying ?: false),
        )
        ExoPlayerSmokeRegistry.publish(
            context,
            monitor,
            probeSnapshot + runtimeSnapshot,
        )
    }

    private fun recordNativeVisualPhase(
        phase: String,
        source: String,
        extra: Map<String, Any?> = emptyMap(),
    ) {
        val now = System.currentTimeMillis()
        val previousPhase = lastNativeVisualPhase
        if (previousPhase == phase) {
            return
        }
        val previousDurationMs = if (lastNativeVisualPhaseAtMs > 0L) {
            now - lastNativeVisualPhaseAtMs
        } else {
            -1L
        }
        lastNativeVisualPhase = phase
        lastNativeVisualPhaseAtMs = now
        val payload = mutableMapOf<String, Any>(
            "event" to "visualPhase",
            "phase" to phase,
            "source" to source,
            "previousPhase" to (previousPhase ?: ""),
            "previousDurationMs" to previousDurationMs,
            "phaseStartedAtEpochMs" to now,
            "overlayVisible" to (resumeFrameOverlay.visibility == View.VISIBLE),
            "playerAlpha" to playerView.alpha.toDouble(),
            "didRenderFirstFrame" to didRenderFirstFrame,
            "preferResumePoster" to preferResumePoster,
            "url" to (currentUrl ?: ""),
        )
        extra.forEach { (key, value) ->
            if (value != null) {
                payload[key] = value
            }
        }
        sendEvent(
            payload,
        )
    }

    init {
        smokeMonitor.stateListener = monitor@{
            if (!isSmokeRegistryActive) {
                return@monitor
            }
            if (Looper.myLooper() != Looper.getMainLooper()) {
                handler.post {
                    publishSmokeSnapshot(it)
                }
                return@monitor
            }
            publishSmokeSnapshot(it)
        }
        val layoutRes = R.layout.turq_texture_player_view
        playerView = (LayoutInflater.from(context)
            .inflate(layoutRes, container, false) as PlayerView).apply {
            useController = false
            resizeMode = AspectRatioFrameLayout.RESIZE_MODE_ZOOM
            setShowBuffering(PlayerView.SHOW_BUFFERING_NEVER)
            setShutterBackgroundColor(Color.TRANSPARENT)
            setBackgroundColor(Color.TRANSPARENT)
            setKeepContentOnPlayerReset(true)
            alpha = if (forceFullscreen) 0f else 1f
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        }
        container.addView(playerView)
        resumeFrameOverlay = ImageView(context).apply {
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
            scaleType = ImageView.ScaleType.CENTER_CROP
            setBackgroundColor(Color.TRANSPARENT)
            alpha = 0f
            visibility = View.GONE
        }
        container.addView(resumeFrameOverlay)
        playerView.videoSurfaceView?.addOnLayoutChangeListener { _, left, top, right, bottom, _, _, _, _ ->
            val width = (right - left).coerceAtLeast(0)
            val height = (bottom - top).coerceAtLeast(0)
            if (width == 0 || height == 0) {
                stableSurfacePasses = 0
                hasStableSurfaceLayout = false
                return@addOnLayoutChangeListener
            }

            if (width == lastSurfaceWidth && height == lastSurfaceHeight) {
                stableSurfacePasses += 1
            } else {
                lastSurfaceWidth = width
                lastSurfaceHeight = height
                stableSurfacePasses = 1
                hasStableSurfaceLayout = false
            }

            if (stableSurfacePasses >= 2) {
                hasStableSurfaceLayout = true
                scheduleSurfaceReveal()
            }
        }
        container.addOnAttachStateChangeListener(object : View.OnAttachStateChangeListener {
            override fun onViewAttachedToWindow(v: View) {
                player?.let { existing ->
                    if (playerView.player !== existing) {
                        playerView.player = existing
                    }
                }
                isSmokeRegistryActive = true
                smokeProbe?.onSurfaceAttached()
                ExoPlayerSmokeRegistry.register(context, smokeMonitor)
            }

            override fun onViewDetachedFromWindow(v: View) {
                // Scroll sırasında geçici detach durumunda sadece pause et.
                // playerView.player = null yapmak son frame'i düşürüp siyah ekran üretir.
                val preserveVisibleFrame =
                    (forceFullscreen || isPrimaryFeedSurface) &&
                        hasReusableVideoFrame()
                if (preserveVisibleFrame) {
                    val captured = captureResumeFrameOverlay(source = "surface_detach")
                    if (!captured) {
                        recordNativeVisualPhase(
                            phase = "siyah",
                            source = "surface_detach_capture_failed",
                        )
                    }
                }
                didRenderFirstFrame = false
                handler.post {
                    pendingRevealRunnable?.let(handler::removeCallbacks)
                    pendingRevealRunnable = null
                    playerView.animate().cancel()
                    playerView.alpha = if (preserveVisibleFrame) 1f else 0f
                }
                sendEvent(mapOf("event" to "surfaceDetached"))
                smokeProbe?.onSurfaceDetached()
                isSmokeRegistryActive = false
                ExoPlayerSmokeRegistry.clear(context, smokeMonitor)
                if (isPrimaryFeedSurface || !preserveVisibleFrame) {
                    softHold()
                }
            }
        })
        eventChannel.setStreamHandler(this)

        if (args?.get("url") as? String != null) {
            isLooping = args?.get("loop") as? Boolean ?: false
        }
    }

    fun loadVideo(
        url: String,
        autoPlay: Boolean = true,
        loop: Boolean = false,
        preferResumePosterOverride: Boolean? = null,
    ) {
        preferResumePosterOverride?.let { preferResumePoster = it }
        isLooping = loop
        val existing = player

        // Aynı URL için sadece player hâlâ media item taşıyorsa soft resume yap.
        // stopPlayback() clearMediaItems() çağırdığı için bu durumda full reload şart.
        val canSoftResumeSameUrl =
            existing != null &&
            currentUrl == url &&
            existing.mediaItemCount > 0 &&
            existing.playbackState != Player.STATE_IDLE
        if (canSoftResumeSameUrl) {
            existing.repeatMode = if (loop) Player.REPEAT_MODE_ONE else Player.REPEAT_MODE_OFF
            if (autoPlay) {
                startupRecoveryAttempts = 0
                play()
            } else {
                softHold()
            }
            return
        }

        val activePlayer = if (existing == null) {
            // Feed/short akışında native player'ın n+1 kuralını ezmemesi için
            // buffer penceresini daha dar tut.
            val targetBufferMs = preferredMaxBufferMs.coerceIn(3500, 8000).toInt()
            val minBufferMs = (targetBufferMs * 0.8).toInt().coerceAtLeast(3200)
            val playbackBufferMs = (minBufferMs * 0.24).toInt().coerceIn(900, 1800)
            val rebufferPlaybackMs =
                (minBufferMs * 0.55).toInt().coerceIn(1600, 3200)
            val loadControl = DefaultLoadControl.Builder()
                .setBufferDurationsMs(
                    minBufferMs,
                    targetBufferMs,
                    playbackBufferMs,
                    rebufferPlaybackMs
                )
                .build()

            ExoPlayer.Builder(context)
                .setLoadControl(loadControl)
                .build()
                .apply {
                    setVideoScalingMode(C.VIDEO_SCALING_MODE_SCALE_TO_FIT_WITH_CROPPING)
                    val audioAttributes = AudioAttributes.Builder()
                        .setUsage(C.USAGE_MEDIA)
                        .setContentType(C.AUDIO_CONTENT_TYPE_MOVIE)
                        .build()
                    // Audio focus'u native katmanda zorla alma.
                    // Feed/SinglePost geçişinde focus churn sesi sıfırlayabiliyor.
                    setAudioAttributes(audioAttributes, false)
                }
        } else {
            existing
        }

        if (smokeProbe == null) {
            smokeProbe = ExoPlayerPlaybackProbe(
                player = activePlayer,
                monitor = smokeMonitor,
                tag = "ExoPlayerPlaybackProbe#$viewId",
            ).also { it.attach() }
        }

        activePlayer.repeatMode = if (loop) Player.REPEAT_MODE_ONE else Player.REPEAT_MODE_OFF
        activePlayer.playWhenReady = autoPlay
        val preserveVisibleFrameOnReset =
            (forceFullscreen || isPrimaryFeedSurface) &&
                hasReusableVideoFrame()
        resetSurfaceVisibility(preserveLastFrame = preserveVisibleFrameOnReset)
        var hasResumeVisual = false
        if (preserveVisibleFrameOnReset) {
            hasResumeVisual = captureResumeFrameOverlay(source = "load_reset")
        } else {
            clearResumeFrameOverlay()
        }
        if (preferResumePoster) {
            val showedCachedPoster = showCachedResumeFrameOverlay(url, source = "load_cached_resume")
            hasResumeVisual = hasResumeVisual || showedCachedPoster
            if (!hasResumeVisual) {
                recordNativeVisualPhase(
                    phase = "siyah",
                    source = if (preserveVisibleFrameOnReset) {
                        "load_reset_capture_failed"
                    } else {
                        "resume_cache_miss"
                    },
                )
            }
        } else if (preserveVisibleFrameOnReset && !hasResumeVisual) {
            recordNativeVisualPhase(
                phase = "siyah",
                source = "load_reset_capture_failed",
            )
        }
        isSoftHeld = false
        didRenderFirstFrame = false
        isPlayerReady = false
        hasVideoSize = false
        hasStableSurfaceLayout = false
        lastSurfaceWidth = 0
        lastSurfaceHeight = 0
        stableSurfacePasses = 0
        isBufferingDispatched = false
        lastVideoFrameAtMs = 0L
        firstVideoFrameAtMs = 0L
        lastWatchdogPositionMs = 0L
        stallRecoveries = 0
        startupRecoveryAttempts = 0
        droppedVideoFrames = 0
        bufferingEvents = 0
        lastBandwidthEstimateKbps = 0L
        selectedVideoBitrateKbps = 0L
        selectedVideoHeight = 0
        selectedVideoWidth = 0
        if (autoPlay && shouldUseStartupRecoveryWatchdog()) {
            startStartupRecoveryWatchdog()
        } else {
            stopStartupRecoveryWatchdog()
        }

        if (existing == null) {
            activePlayer.setVideoFrameMetadataListener { _, _, _, _ ->
                val now = System.currentTimeMillis()
                lastVideoFrameAtMs = now
                smokeMonitor.onVideoFrameSampled()
            }
            activePlayer.addListener(object : Player.Listener {
            override fun onPlaybackStateChanged(playbackState: Int) {
                when (playbackState) {
                    Player.STATE_READY -> {
                        if (isBufferingDispatched) {
                            isBufferingDispatched = false
                            sendEvent(mapOf("event" to "buffering", "isBuffering" to false))
                        }
                        isPlayerReady = true
                        lastWatchdogPositionMs = activePlayer.currentPosition
                        scheduleSurfaceReveal()
                        sendEvent(mapOf(
                            "event" to "ready",
                            "duration" to (activePlayer.duration / 1000.0)
                        ))
                        startPositionUpdates()
                        startStallWatchdog()
                    }
                    Player.STATE_ENDED -> {
                        if (isBufferingDispatched) {
                            isBufferingDispatched = false
                            sendEvent(mapOf("event" to "buffering", "isBuffering" to false))
                        }
                        smokeMonitor.onPlaybackCompleted()
                        sendEvent(mapOf("event" to "completed"))
                        stopPositionUpdates()
                        stopStallWatchdog()
                        stopStartupRecoveryWatchdog()
                    }
                    Player.STATE_BUFFERING -> {
                        bufferingEvents += 1
                        if (!isBufferingDispatched) {
                            isBufferingDispatched = true
                            sendEvent(mapOf("event" to "buffering", "isBuffering" to true))
                        }
                        stopStallWatchdog()
                    }
                    Player.STATE_IDLE -> {}
                }
            }

            override fun onIsPlayingChanged(isPlaying: Boolean) {
                if (isPlaying) {
                    if (isBufferingDispatched) {
                        isBufferingDispatched = false
                        sendEvent(mapOf("event" to "buffering", "isBuffering" to false))
                    }
                    sendEvent(mapOf("event" to "play"))
                    startPositionUpdates()
                    startStallWatchdog()
                } else {
                    val state = activePlayer.playbackState
                    if (state != Player.STATE_ENDED && state != Player.STATE_BUFFERING) {
                        sendEvent(mapOf("event" to "pause"))
                    }
                    stopStallWatchdog()
                }
            }

            override fun onPlayerError(error: PlaybackException) {
                revealSurface()
                sendEvent(mapOf(
                    "event" to "error",
                    "message" to (error.message ?: "Unknown playback error")
                ))
                stopPositionUpdates()
                stopStallWatchdog()
                stopStartupRecoveryWatchdog()
            }

            override fun onVideoSizeChanged(videoSize: androidx.media3.common.VideoSize) {
                hasVideoSize = videoSize.width > 0 && videoSize.height > 0
                scheduleSurfaceReveal()
            }

            override fun onRenderedFirstFrame() {
                val alreadyShowingStableFrame =
                    didRenderFirstFrame && playerView.alpha >= 1f
                val resumeOverlayVisible = resumeFrameOverlay.visibility == View.VISIBLE
                didRenderFirstFrame = true
                stopStartupRecoveryWatchdog()
                lastVideoFrameAtMs = System.currentTimeMillis()
                if (firstVideoFrameAtMs == 0L) {
                    firstVideoFrameAtMs = lastVideoFrameAtMs
                }
                if (!alreadyShowingStableFrame) {
                    if (resumeOverlayVisible) {
                        revealSurface(immediate = true)
                    } else {
                        scheduleSurfaceReveal()
                    }
                    sendEvent(mapOf("event" to "firstFrame"))
                } else if (resumeOverlayVisible) {
                    hideResumeFrameOverlay()
                }
            }
            })
            activePlayer.addAnalyticsListener(object : AnalyticsListener {
                override fun onDroppedVideoFrames(
                    eventTime: AnalyticsListener.EventTime,
                    droppedFrames: Int,
                    elapsedMs: Long,
                ) {
                    droppedVideoFrames += droppedFrames
                }

                override fun onBandwidthEstimate(
                    eventTime: AnalyticsListener.EventTime,
                    totalLoadTimeMs: Int,
                    totalBytesLoaded: Long,
                    bitrateEstimate: Long,
                ) {
                    lastBandwidthEstimateKbps = (bitrateEstimate / 1000L).coerceAtLeast(0L)
                }

                override fun onTracksChanged(
                    eventTime: AnalyticsListener.EventTime,
                    tracks: Tracks,
                ) {
                    for (group in tracks.groups) {
                        if (group.type != C.TRACK_TYPE_VIDEO) continue
                        for (i in 0 until group.length) {
                            if (!group.isTrackSelected(i)) continue
                            val format = group.getTrackFormat(i)
                            selectedVideoBitrateKbps = (format.bitrate / 1000L).coerceAtLeast(0L)
                            selectedVideoHeight = format.height
                            selectedVideoWidth = format.width
                            return
                        }
                    }
                }
            })
        }

        val mediaItem = MediaItem.fromUri(url)
        activePlayer.clearMediaItems()

        // HLS URL'leri için HlsMediaSource kullan (ABR desteği)
        if (url.contains(".m3u8") || url.contains("/hls/")) {
            val httpDataSourceFactory = DefaultHttpDataSource.Factory()
                .setConnectTimeoutMs(6000)
                .setReadTimeoutMs(9000)
                .setDefaultRequestProperties(mapOf(
                    "X-Turq-App" to "turqapp-mobile",
                ))
            val hlsSource = HlsMediaSource.Factory(httpDataSourceFactory)
                .setAllowChunklessPreparation(true)
                .createMediaSource(mediaItem)
            activePlayer.setMediaSource(hlsSource)
        } else {
            activePlayer.setMediaItem(mediaItem)
        }
        activePlayer.prepare()

        playerView.player = activePlayer
        player = activePlayer
        currentUrl = url
        if (autoPlay) {
            smokeMonitor.resetForNewPlaybackSession()
            smokeProbe?.onAutoplayRequested()
        }
    }

    fun play() {
        player?.let { p ->
            val shouldRecordAutoplayRequest =
                !smokeMonitor.isPlaybackExpected || !p.playWhenReady
            if (shouldRecordAutoplayRequest) {
                smokeProbe?.onAutoplayRequested()
            }
            if (isSoftHeld) {
                p.volume = heldVolume
                isSoftHeld = false
            }
            p.play()
            if (!didRenderFirstFrame && shouldUseStartupRecoveryWatchdog()) {
                startStartupRecoveryWatchdog()
            }
            startStallWatchdog()
        }
    }

    fun pause() {
        isSoftHeld = false
        stopStartupRecoveryWatchdog()
        player?.pause()
        stopStallWatchdog()
    }

    fun softHold() {
        stopStartupRecoveryWatchdog()
        player?.let { p ->
            if (!isSoftHeld) {
                heldVolume = p.volume
            }
            p.playWhenReady = false
            p.volume = 0f
            isSoftHeld = true
        }
        stopStallWatchdog()
    }

    fun onAppBackgrounded() {
        val p = player
        if (p == null || currentUrl.isNullOrEmpty()) {
            appBackgroundSoftHeld = false
            shouldResumeAfterAppForeground = false
            return
        }
        val shouldSoftHoldForBackground =
            !isSoftHeld && (p.isPlaying || p.playWhenReady)
        appBackgroundSoftHeld = shouldSoftHoldForBackground
        shouldResumeAfterAppForeground = shouldSoftHoldForBackground
        if (shouldSoftHoldForBackground) {
            softHold()
        }
    }

    fun onAppForegrounded() {
        if (!appBackgroundSoftHeld) {
            shouldResumeAfterAppForeground = false
            return
        }
        appBackgroundSoftHeld = false
        if (!shouldResumeAfterAppForeground) {
            return
        }
        if (player == null || currentUrl.isNullOrEmpty()) {
            shouldResumeAfterAppForeground = false
            return
        }
        if (!container.isAttachedToWindow || !container.isShown || playerView.player !== player) {
            shouldResumeAfterAppForeground = false
            return
        }
        shouldResumeAfterAppForeground = false
        play()
    }

    fun seek(seconds: Double) {
        val posMs = (seconds * 1000).toLong()
        player?.seekTo(posMs)
        val now = System.currentTimeMillis()
        val duplicateSeekCompletion =
            lastSeekCompletedPositionMs >= 0L &&
                kotlin.math.abs(lastSeekCompletedPositionMs - posMs) <= 120L &&
                (now - lastSeekCompletedAtMs) <= 250L
        if (duplicateSeekCompletion) {
            return
        }
        lastSeekCompletedPositionMs = posMs
        lastSeekCompletedAtMs = now
        sendEvent(mapOf(
            "event" to "seekCompleted",
            "position" to seconds
        ))
    }

    fun setMuted(muted: Boolean) {
        val target = if (muted) 0f else 1f
        player?.volume = target
        if (!isSoftHeld) heldVolume = target
    }

    fun setVolume(volume: Float) {
        val target = volume.coerceIn(0f, 1f)
        player?.volume = target
        if (!isSoftHeld) heldVolume = target
    }

    fun setLoop(loop: Boolean) {
        isLooping = loop
        player?.repeatMode = if (loop) Player.REPEAT_MODE_ONE else Player.REPEAT_MODE_OFF
    }

    fun getCurrentTime(): Double {
        return (player?.currentPosition ?: 0L) / 1000.0
    }

    fun getDuration(): Double {
        val dur = player?.duration ?: C.TIME_UNSET
        return if (dur == C.TIME_UNSET) 0.0 else dur / 1000.0
    }

    fun isMuted(): Boolean {
        return (player?.volume ?: 1f) == 0f
    }

    fun isPlaying(): Boolean {
        return player?.isPlaying ?: false
    }

    fun isBuffering(): Boolean {
        val p = player ?: return false
        return p.playbackState == Player.STATE_BUFFERING || isBufferingDispatched
    }

    fun getPlaybackDiagnostics(): Map<String, Any> {
        val p = player
        val positionMs = p?.currentPosition ?: 0L
        val durationMs = p?.duration ?: C.TIME_UNSET
        val now = System.currentTimeMillis()
        val frameSilenceMs = if (lastVideoFrameAtMs <= 0L) 0L else now - lastVideoFrameAtMs
        val firstFrameAgeMs = if (firstVideoFrameAtMs <= 0L) 0L else now - firstVideoFrameAtMs
        return mapOf(
            "platform" to "android",
            "playerExists" to (p != null),
            "currentUrl" to (currentUrl ?: ""),
            "isPlaying" to (p?.isPlaying ?: false),
            "isBuffering" to isBuffering(),
            "isMuted" to ((p?.volume ?: 1f) == 0f),
            "volume" to (p?.volume ?: 0f).toDouble(),
            "position" to (positionMs / 1000.0),
            "duration" to (if (durationMs == C.TIME_UNSET) 0.0 else durationMs / 1000.0),
            "didRenderFirstFrame" to didRenderFirstFrame,
            "isPlayerReady" to isPlayerReady,
            "hasVideoSize" to hasVideoSize,
            "hasStableSurfaceLayout" to hasStableSurfaceLayout,
            "isSoftHeld" to isSoftHeld,
            "stallRecoveries" to stallRecoveries,
            "bufferingEvents" to bufferingEvents,
            "droppedVideoFrames" to droppedVideoFrames,
            "rendererFrameSilenceMs" to frameSilenceMs,
            "firstFrameAgeMs" to firstFrameAgeMs,
            "bandwidthEstimateKbps" to lastBandwidthEstimateKbps,
            "selectedVideoBitrateKbps" to selectedVideoBitrateKbps,
            "selectedVideoHeight" to selectedVideoHeight,
            "selectedVideoWidth" to selectedVideoWidth,
        )
    }

    fun getProcessDiagnostics(): Map<String, Any> {
        val runtime = Runtime.getRuntime()
        val javaHeapMb = (runtime.totalMemory() - runtime.freeMemory()).toDouble() / (1024.0 * 1024.0)
        val nativeHeapMb = Debug.getNativeHeapAllocatedSize().toDouble() / (1024.0 * 1024.0)
        val pssMb = Debug.getPss().toDouble() / 1024.0
        return mapOf(
            "platform" to "android",
            "javaHeapMb" to javaHeapMb,
            "nativeHeapMb" to nativeHeapMb,
            "pssMb" to pssMb,
            "thermalStatus" to readThermalStatus(),
            "playerExists" to (player != null),
        )
    }

    /// Oynatmayı durdur, network/decoder kaynaklarını serbest bırak.
    /// Player view hayatta kalır, tekrar loadVideo ile yüklenebilir.
    fun stopPlayback() {
        stopPositionUpdates()
        stopStallWatchdog()
        stopStartupRecoveryWatchdog()
        isSoftHeld = false
        heldVolume = 0f
        appBackgroundSoftHeld = false
        shouldResumeAfterAppForeground = false
        player?.let { p ->
            p.volume = 0f
            p.playWhenReady = false
            p.pause()
            p.stop()
            p.clearMediaItems()
        }
        sendEvent(mapOf("event" to "stopped"))
    }

    /// Bir sonraki loadVideo çağrısında kullanılacak max buffer süresini ayarla (ms).
    fun setPreferredBufferDuration(durationMs: Long) {
        preferredMaxBufferMs = durationMs
    }

    private fun startPositionUpdates() {
        stopPositionUpdates()
        positionRunnable = object : Runnable {
            override fun run() {
                player?.let { p ->
                    if (p.isPlaying) {
                        sendEvent(mapOf(
                            "event" to "timeUpdate",
                            "position" to (p.currentPosition / 1000.0),
                            "duration" to (if (p.duration == C.TIME_UNSET) 0.0 else p.duration / 1000.0)
                        ))
                        handler.postDelayed(this, 500)
                        return
                    }
                }
                stopPositionUpdates()
            }
        }
        handler.postDelayed(positionRunnable!!, 500)
    }

    private fun stopPositionUpdates() {
        positionRunnable?.let { handler.removeCallbacks(it) }
        positionRunnable = null
    }

    private fun startStallWatchdog() {
        stopStallWatchdog()
        val runnable = object : Runnable {
            override fun run() {
                val p = player
                if (p == null || isSoftHeld) {
                    stopStallWatchdog()
                    return
                }
                val now = System.currentTimeMillis()
                val positionMs = p.currentPosition
                val advancedMs = positionMs - lastWatchdogPositionMs
                val frameSilenceMs = if (lastVideoFrameAtMs <= 0L) 0L else now - lastVideoFrameAtMs
                val firstFrameAgeMs = if (firstVideoFrameAtMs <= 0L) 0L else now - firstVideoFrameAtMs

                val prolongedBufferingAfterFirstFrame =
                    didRenderFirstFrame &&
                        p.playbackState == Player.STATE_BUFFERING &&
                        isBufferingDispatched &&
                        firstFrameAgeMs >= 1500L &&
                        frameSilenceMs >= if (isPrimaryFeedSurface) 1400L else 2200L

                if (prolongedBufferingAfterFirstFrame) {
                    Log.w(
                        "ExoPlayerView#$viewId",
                        "rendererStall kind=buffering_stall position=${positionMs / 1000.0} frameSilenceMs=$frameSilenceMs firstFrameAgeMs=$firstFrameAgeMs advancedMs=$advancedMs recoveryAttempt=${stallRecoveries + 1}"
                    )
                    sendEvent(
                        mapOf(
                            "event" to "rendererStall",
                            "position" to (positionMs / 1000.0),
                            "frameSilenceMs" to frameSilenceMs,
                            "firstFrameAgeMs" to firstFrameAgeMs,
                            "advancedMs" to advancedMs,
                            "stallKind" to "buffering_stall",
                            "recoveryAttempt" to (stallRecoveries + 1),
                        )
                    )
                    recoverFromRendererStall(hardSurfaceRebind = isPrimaryFeedSurface)
                    return
                }

                if (!p.isPlaying || p.playbackState != Player.STATE_READY || isBufferingDispatched) {
                    handler.postDelayed(this, 1200)
                    return
                }

                val rendererFrozenAfterAdvance =
                    didRenderFirstFrame &&
                        firstFrameAgeMs >= 3500L &&
                        advancedMs >= 900L &&
                        frameSilenceMs >= 2200L

                val playbackClockStalled =
                    didRenderFirstFrame &&
                        firstFrameAgeMs >= 2500L &&
                        advancedMs <= 120L &&
                        frameSilenceMs >= 1800L

                if (rendererFrozenAfterAdvance || playbackClockStalled) {
                    Log.w(
                        "ExoPlayerView#$viewId",
                        "rendererStall kind=${if (playbackClockStalled) "clock_stalled" else "renderer_frozen"} position=${positionMs / 1000.0} frameSilenceMs=$frameSilenceMs firstFrameAgeMs=$firstFrameAgeMs advancedMs=$advancedMs recoveryAttempt=${stallRecoveries + 1}"
                    )
                    sendEvent(
                        mapOf(
                            "event" to "rendererStall",
                            "position" to (positionMs / 1000.0),
                            "frameSilenceMs" to frameSilenceMs,
                            "firstFrameAgeMs" to firstFrameAgeMs,
                            "advancedMs" to advancedMs,
                            "stallKind" to if (playbackClockStalled) "clock_stalled" else "renderer_frozen",
                            "recoveryAttempt" to (stallRecoveries + 1),
                        )
                    )
                    recoverFromRendererStall(hardSurfaceRebind = playbackClockStalled)
                }

                lastWatchdogPositionMs = p.currentPosition
                handler.postDelayed(this, 1200)
            }
        }
        stallWatchdogRunnable = runnable
        handler.postDelayed(runnable, 1200)
    }

    private fun stopStallWatchdog() {
        stallWatchdogRunnable?.let { handler.removeCallbacks(it) }
        stallWatchdogRunnable = null
    }

    private fun startStartupRecoveryWatchdog() {
        stopStartupRecoveryWatchdog()
        val runnable = object : Runnable {
            override fun run() {
                val p = player
                if (p == null || isSoftHeld || didRenderFirstFrame || !container.isShown) {
                    stopStartupRecoveryWatchdog()
                    return
                }
                if (p.currentPosition > startupRecoveryMaxResumePositionMs) {
                    stopStartupRecoveryWatchdog()
                    return
                }
                if (!p.playWhenReady || startupRecoveryAttempts >= 1) {
                    stopStartupRecoveryWatchdog()
                    return
                }
                val needsRecovery =
                    !p.isPlaying &&
                        (p.playbackState == Player.STATE_READY ||
                            p.playbackState == Player.STATE_BUFFERING)
                if (!needsRecovery) {
                    stopStartupRecoveryWatchdog()
                    return
                }
                recoverFromStartupTimeout()
            }
        }
        startupRecoveryRunnable = runnable
        handler.postDelayed(runnable, 1650)
    }

    private fun stopStartupRecoveryWatchdog() {
        startupRecoveryRunnable?.let { handler.removeCallbacks(it) }
        startupRecoveryRunnable = null
    }

    private fun recoverFromRendererStall(hardSurfaceRebind: Boolean) {
        val p = player ?: return
        if (stallRecoveries >= 2) return
        stallRecoveries += 1
        val currentPosition = p.currentPosition
        val preserveVisibleRecovery =
            currentPosition > 0L &&
                hasReusableVideoFrame()
        handler.post {
            try {
                if (!hardSurfaceRebind) {
                    Log.w(
                        "ExoPlayerView#$viewId",
                        "softPlaybackNudge position=${currentPosition / 1000.0} recoveryAttempt=$stallRecoveries"
                    )
                    p.playWhenReady = true
                    if (!p.isPlaying) {
                        p.play()
                    }
                    lastVideoFrameAtMs = System.currentTimeMillis()
                    lastWatchdogPositionMs = p.currentPosition
                    return@post
                }
                Log.w(
                    "ExoPlayerView#$viewId",
                    "surfaceRebind position=${currentPosition / 1000.0} recoveryAttempt=$stallRecoveries"
                )
                if (preserveVisibleRecovery) {
                    val captured = captureResumeFrameOverlay(source = "stall_rebind")
                    if (!captured) {
                        recordNativeVisualPhase(
                            phase = "siyah",
                            source = "stall_rebind_capture_failed",
                        )
                    }
                }
                if (!preserveVisibleRecovery) {
                    didRenderFirstFrame = false
                    pendingRevealRunnable?.let(handler::removeCallbacks)
                    pendingRevealRunnable = null
                    playerView.animate().cancel()
                    playerView.alpha = 0f
                }
                sendEvent(
                    mapOf(
                        "event" to "surfaceRebind",
                        "position" to (currentPosition / 1000.0),
                        "recoveryAttempt" to stallRecoveries,
                    )
                )
                if (!preserveVisibleRecovery) {
                    sendEvent(mapOf("event" to "surfaceDetached"))
                }
                playerView.player = null
                playerView.player = p
                p.seekTo(currentPosition)
                p.playWhenReady = true
                p.play()
                lastVideoFrameAtMs = System.currentTimeMillis()
                lastWatchdogPositionMs = p.currentPosition
            } catch (_: Throwable) {
            }
        }
    }

    private fun recoverFromStartupTimeout() {
        val p = player ?: return
        if (startupRecoveryAttempts >= 1) return
        startupRecoveryAttempts += 1
        val currentPosition = p.currentPosition
        val preserveVisibleRecovery =
            currentPosition > 0L &&
                hasReusableVideoFrame()
        handler.post {
            try {
                Log.w(
                    "ExoPlayerView#$viewId",
                    "startupSurfaceRebind position=${currentPosition / 1000.0} recoveryAttempt=$startupRecoveryAttempts"
                )
                if (preserveVisibleRecovery) {
                    val captured = captureResumeFrameOverlay(source = "startup_rebind")
                    if (!captured) {
                        recordNativeVisualPhase(
                            phase = "siyah",
                            source = "startup_rebind_capture_failed",
                        )
                    }
                }
                if (!preserveVisibleRecovery) {
                    didRenderFirstFrame = false
                    pendingRevealRunnable?.let(handler::removeCallbacks)
                    pendingRevealRunnable = null
                    playerView.animate().cancel()
                    playerView.alpha = 0f
                }
                sendEvent(
                    mapOf(
                        "event" to "surfaceRebind",
                        "position" to (currentPosition / 1000.0),
                        "recoveryAttempt" to startupRecoveryAttempts,
                        "recoveryKind" to "startup_timeout",
                    )
                )
                if (!preserveVisibleRecovery) {
                    sendEvent(mapOf("event" to "surfaceDetached"))
                }
                playerView.player = null
                playerView.player = p
                if (currentPosition > 0L) {
                    p.seekTo(currentPosition)
                }
                p.playWhenReady = true
                p.play()
                lastVideoFrameAtMs = System.currentTimeMillis()
                lastWatchdogPositionMs = p.currentPosition
            } catch (_: Throwable) {
            } finally {
                stopStartupRecoveryWatchdog()
            }
        }
    }

    private fun sendEvent(data: Map<String, Any>) {
        handler.post {
            eventSink?.success(data)
        }
    }

    private fun resetSurfaceVisibility(preserveLastFrame: Boolean = false) {
        if (!forceFullscreen) {
            runOnMainBlocking {
                pendingRevealRunnable?.let(handler::removeCallbacks)
                pendingRevealRunnable = null
                playerView.animate().cancel()
                // Feed kartlarında öncelik resume poster, sonra thumbnail.
                // Native yüzeyi ilk frame gelene kadar görünmez tut ki siyah katman
                // Flutter/native poster fallback'lerinin üstüne çıkmasın.
                playerView.alpha = if (preserveLastFrame) 1f else 0f
            }
            return
        }
        runOnMainBlocking {
            pendingRevealRunnable?.let(handler::removeCallbacks)
            pendingRevealRunnable = null
            playerView.animate().cancel()
            playerView.alpha = if (preserveLastFrame) 1f else 0f
        }
    }

    private fun scheduleSurfaceReveal() {
        if (!forceFullscreen) {
            val needsFreshFrame = playerView.alpha < 1f
            val canReveal = if (needsFreshFrame) {
                didRenderFirstFrame
            } else {
                didRenderFirstFrame ||
                    (isPlayerReady && hasVideoSize && hasStableSurfaceLayout)
            }
            if (!canReveal) return
            handler.post {
                pendingRevealRunnable?.let(handler::removeCallbacks)
                val revealRunnable = Runnable {
                    pendingRevealRunnable = null
                    revealSurface(immediate = !didRenderFirstFrame)
                }
                pendingRevealRunnable = revealRunnable
                val revealDelayMs = if (didRenderFirstFrame) 24L else 72L
                handler.postDelayed(revealRunnable, revealDelayMs)
            }
            return
        }
        val needsFreshFrame = playerView.alpha < 1f
        val canReveal = if (needsFreshFrame) {
            didRenderFirstFrame
        } else {
            didRenderFirstFrame || (hasVideoSize && isPlayerReady)
        }
        if (!canReveal) {
            return
        }
        handler.post {
            pendingRevealRunnable?.let(handler::removeCallbacks)
            val revealRunnable = Runnable {
                pendingRevealRunnable = null
                revealSurface()
            }
            pendingRevealRunnable = revealRunnable
            // Stabil yüzey yakalanırsa hızlı aç; gelmezse READY fallback ile beyaz ekranı bırakma.
            val revealDelayMs = if (hasStableSurfaceLayout) 32L else 120L
            handler.postDelayed(revealRunnable, revealDelayMs)
        }
    }

    private fun revealSurface(immediate: Boolean = false) {
        runOnMain {
            pendingRevealRunnable = null
            if (playerView.alpha < 1f) {
                if (immediate) {
                    playerView.animate().cancel()
                    playerView.alpha = 1f
                } else {
                    playerView.animate()
                        .alpha(1f)
                        .setDuration(90)
                        .start()
                }
            }
            hideResumeFrameOverlayNow()
            recordNativeVisualPhase(
                phase = "video_play",
                source = if (immediate) "surface_reveal_immediate" else "surface_reveal",
            )
        }
    }

    private fun captureResumeFrameOverlay(source: String): Boolean {
        if (!isPrimaryFeedSurface) return false
        val cacheKey = currentUrl ?: return false
        val textureView = playerView.videoSurfaceView as? TextureView ?: return false
        if (!textureView.isAvailable || textureView.width <= 0 || textureView.height <= 0) {
            return false
        }
        val rawBitmap = try {
            val target = Bitmap.createBitmap(
                textureView.width,
                textureView.height,
                Bitmap.Config.ARGB_8888
            )
            textureView.getBitmap(target) ?: target
        } catch (_: Throwable) {
            null
        } ?: return false
        val cachedBitmap = try {
            rawBitmap.copy(Bitmap.Config.ARGB_8888, false)
        } catch (_: Throwable) {
            rawBitmap
        }
        if (cachedBitmap !== rawBitmap) {
            rawBitmap.takeIf { !it.isRecycled }?.recycle()
        }
        synchronized(resumeFrameCache) {
            val previous = resumeFrameCache.put(cacheKey, cachedBitmap)
            if (previous !== cachedBitmap) {
                previous?.takeIf { !it.isRecycled }?.recycle()
            }
        }
        runOnMain {
            resumeFrameBitmap = cachedBitmap
            resumeFrameCacheKey = cacheKey
            resumeFrameOverlay.setImageBitmap(cachedBitmap)
            resumeFrameOverlay.animate().cancel()
            resumeFrameOverlay.alpha = 1f
            resumeFrameOverlay.visibility = View.VISIBLE
            recordNativeVisualPhase(
                phase = "resume_poster",
                source = source,
            )
        }
        return true
    }

    private fun showCachedResumeFrameOverlay(url: String, source: String): Boolean {
        if (!isPrimaryFeedSurface || !preferResumePoster) return false
        val cachedBitmap = synchronized(resumeFrameCache) {
            resumeFrameCache[url]
        } ?: return false
        if (cachedBitmap.isRecycled) {
            synchronized(resumeFrameCache) {
                resumeFrameCache.remove(url)
            }
            return false
        }
        runOnMain {
            resumeFrameBitmap = cachedBitmap
            resumeFrameCacheKey = url
            resumeFrameOverlay.setImageBitmap(cachedBitmap)
            resumeFrameOverlay.animate().cancel()
            resumeFrameOverlay.alpha = 1f
            resumeFrameOverlay.visibility = View.VISIBLE
            recordNativeVisualPhase(
                phase = "resume_poster",
                source = source,
            )
        }
        return true
    }

    private fun hideResumeFrameOverlayNow() {
        if (resumeFrameOverlay.visibility != View.VISIBLE) return
        resumeFrameOverlay.animate().cancel()
        resumeFrameOverlay.alpha = 0f
        resumeFrameOverlay.visibility = View.GONE
        resumeFrameOverlay.setImageDrawable(null)
        resumeFrameBitmap = null
        resumeFrameCacheKey = null
    }

    private fun hideResumeFrameOverlay() {
        runOnMain {
            hideResumeFrameOverlayNow()
        }
    }

    private fun clearResumeFrameOverlay() {
        runOnMain {
            resumeFrameOverlay.animate().cancel()
            resumeFrameOverlay.alpha = 0f
            resumeFrameOverlay.visibility = View.GONE
            resumeFrameOverlay.setImageDrawable(null)
            resumeFrameBitmap = null
            resumeFrameCacheKey = null
        }
    }

    private fun releasePlayer(fully: Boolean) {
        stopPositionUpdates()
        stopStallWatchdog()
        stopStartupRecoveryWatchdog()
        player?.pause()
        resetSurfaceVisibility()
        clearResumeFrameOverlay()
        isSmokeRegistryActive = false
        ExoPlayerSmokeRegistry.clear(context, smokeMonitor)
        if (fully) {
            smokeProbe?.detach()
            smokeProbe = null
            player?.release()
            player = null
            currentUrl = null
            isSoftHeld = false
            appBackgroundSoftHeld = false
            shouldResumeAfterAppForeground = false
        }
    }

    // PlatformView
    override fun getView(): View = container

    override fun dispose() {
        releasePlayer(fully = true)
        eventSink = null
    }

    // EventChannel.StreamHandler
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        // Listener geç bağlandıysa mevcut state'i replay et.
        player?.let { p ->
            if (p.playbackState == Player.STATE_READY) {
                sendEvent(
                    mapOf(
                        "event" to "ready",
                        "duration" to (if (p.duration == C.TIME_UNSET) 0.0 else p.duration / 1000.0)
                    )
                )
            }
            if (didRenderFirstFrame) {
                sendEvent(mapOf("event" to "firstFrame"))
            }
            if (p.isPlaying) {
                sendEvent(mapOf("event" to "play"))
                startPositionUpdates()
            } else if (p.playbackState == Player.STATE_BUFFERING) {
                sendEvent(mapOf("event" to "buffering", "isBuffering" to true))
            }
        }
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    private fun readThermalStatus(): String {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            return "unsupported"
        }
        val powerManager = context.getSystemService(Context.POWER_SERVICE) as? PowerManager
        return when (powerManager?.currentThermalStatus) {
            PowerManager.THERMAL_STATUS_NONE -> "none"
            PowerManager.THERMAL_STATUS_LIGHT -> "light"
            PowerManager.THERMAL_STATUS_MODERATE -> "moderate"
            PowerManager.THERMAL_STATUS_SEVERE -> "severe"
            PowerManager.THERMAL_STATUS_CRITICAL -> "critical"
            PowerManager.THERMAL_STATUS_EMERGENCY -> "emergency"
            PowerManager.THERMAL_STATUS_SHUTDOWN -> "shutdown"
            else -> "unknown"
        }
    }
}
