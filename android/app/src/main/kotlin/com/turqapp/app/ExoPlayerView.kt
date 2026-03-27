package com.turqapp.app

import android.content.Context
import android.graphics.Color
import android.os.Build
import android.os.Debug
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.util.Log
import android.view.LayoutInflater
import android.view.View
import android.widget.FrameLayout
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
import androidx.media3.exoplayer.video.VideoFrameMetadataListener
import androidx.media3.datasource.DefaultHttpDataSource
import androidx.media3.ui.AspectRatioFrameLayout
import androidx.media3.ui.PlayerView
import com.turqapp.app.qa.ExoPlayerPlaybackProbe
import com.turqapp.app.qa.ExoPlayerSmokeRegistry
import com.turqapp.app.qa.PlaybackHealthMonitor
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.platform.PlatformView

class ExoPlayerView(
    private val context: Context,
    private val viewId: Long,
    private val args: Map<String, Any>?,
    private val eventChannel: EventChannel
) : PlatformView, EventChannel.StreamHandler {

    private val forceFullscreen = args?.get("forceFullscreen") as? Boolean ?: false
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
    private var player: ExoPlayer? = null
    private var eventSink: EventChannel.EventSink? = null
    private var isLooping = false
    private val handler = Handler(Looper.getMainLooper())
    private var positionRunnable: Runnable? = null
    private var preferredMaxBufferMs: Long = 10000
    private var currentUrl: String? = null
    private var isSoftHeld = false
    private var heldVolume: Float = 1f
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
    private var droppedVideoFrames = 0
    private var bufferingEvents = 0
    private var stallWatchdogRunnable: Runnable? = null
    private var lastBandwidthEstimateKbps = 0L
    private var selectedVideoBitrateKbps = 0L
    private var selectedVideoHeight = 0
    private var selectedVideoWidth = 0
    private val smokeMonitor = PlaybackHealthMonitor(tag = "PlaybackHealthMonitor#$viewId")
    private var smokeProbe: ExoPlayerPlaybackProbe? = null
    private var isSmokeRegistryActive = false

    init {
        smokeMonitor.stateListener = monitor@{
            if (!isSmokeRegistryActive) {
                return@monitor
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
                it,
                probeSnapshot + runtimeSnapshot,
            )
        }
        val layoutRes = R.layout.turq_texture_player_view
        playerView = (LayoutInflater.from(context)
            .inflate(layoutRes, container, false) as PlayerView).apply {
            useController = false
            resizeMode = AspectRatioFrameLayout.RESIZE_MODE_ZOOM
            setShutterBackgroundColor(if (forceFullscreen) Color.BLACK else Color.TRANSPARENT)
            setBackgroundColor(if (forceFullscreen) Color.BLACK else Color.TRANSPARENT)
            setKeepContentOnPlayerReset(true)
            alpha = if (forceFullscreen) 0f else 1f
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        }
        container.addView(playerView)
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
                didRenderFirstFrame = false
                handler.post {
                    pendingRevealRunnable?.let(handler::removeCallbacks)
                    pendingRevealRunnable = null
                    playerView.animate().cancel()
                    playerView.alpha = 0f
                }
                sendEvent(mapOf("event" to "surfaceDetached"))
                smokeProbe?.onSurfaceDetached()
                isSmokeRegistryActive = false
                ExoPlayerSmokeRegistry.clear(context, smokeMonitor)
                softHold()
            }
        })
        eventChannel.setStreamHandler(this)

        val url = args?.get("url") as? String
        if (url != null) {
            val autoPlay = args?.get("autoPlay") as? Boolean ?: true
            isLooping = args?.get("loop") as? Boolean ?: false
            loadVideo(url, autoPlay, isLooping)
        }
    }

    fun loadVideo(url: String, autoPlay: Boolean = true, loop: Boolean = false) {
        isLooping = loop
        val existing = player

        // Aynı URL tekrar istenirse player'ı yeniden kurma.
        if (existing != null && currentUrl == url) {
            existing.repeatMode = if (loop) Player.REPEAT_MODE_ONE else Player.REPEAT_MODE_OFF
            if (autoPlay) {
                play()
            } else {
                softHold()
            }
            return
        }

        val activePlayer = if (existing == null) {
            // iOS tarafindaki stability-first davranisa yaklasmak icin Android
            // buffer profili biraz daha genis tutulur. Bu, TTFF'i azicik
            // uzatabilir ama scroll gecislerinde siyah ekran/rebuffer oranini
            // gozle gorulur sekilde azaltir.
            val targetBufferMs = preferredMaxBufferMs.coerceIn(4500, 16000).toInt()
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
                    setVideoFrameMetadataListener(
                        VideoFrameMetadataListener { _, _, _, _ ->
                            lastVideoFrameAtMs = System.currentTimeMillis()
                        }
                    )
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
        droppedVideoFrames = 0
        bufferingEvents = 0
        lastBandwidthEstimateKbps = 0L
        selectedVideoBitrateKbps = 0L
        selectedVideoHeight = 0
        selectedVideoWidth = 0
        resetSurfaceVisibility()

        if (existing == null) {
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
                        sendEvent(mapOf("event" to "completed"))
                        stopPositionUpdates()
                        stopStallWatchdog()
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
            }

            override fun onVideoSizeChanged(videoSize: androidx.media3.common.VideoSize) {
                hasVideoSize = videoSize.width > 0 && videoSize.height > 0
                scheduleSurfaceReveal()
            }

            override fun onRenderedFirstFrame() {
                didRenderFirstFrame = true
                lastVideoFrameAtMs = System.currentTimeMillis()
                if (firstVideoFrameAtMs == 0L) {
                    firstVideoFrameAtMs = lastVideoFrameAtMs
                }
                scheduleSurfaceReveal()
                sendEvent(mapOf("event" to "firstFrame"))
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
            smokeProbe?.onAutoplayRequested()
            if (isSoftHeld) {
                p.volume = heldVolume
                isSoftHeld = false
            }
            p.play()
            startStallWatchdog()
        }
    }

    fun pause() {
        isSoftHeld = false
        player?.pause()
        stopStallWatchdog()
    }

    fun softHold() {
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

    fun seek(seconds: Double) {
        val posMs = (seconds * 1000).toLong()
        player?.seekTo(posMs)
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
        player?.stop()
        player?.clearMediaItems()
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
                if (p == null || !p.isPlaying || isSoftHeld) {
                    stopStallWatchdog()
                    return
                }
                if (p.playbackState != Player.STATE_READY || isBufferingDispatched) {
                    handler.postDelayed(this, 1200)
                    return
                }

                val now = System.currentTimeMillis()
                val positionMs = p.currentPosition
                val advancedMs = positionMs - lastWatchdogPositionMs
                val frameSilenceMs = if (lastVideoFrameAtMs <= 0L) 0L else now - lastVideoFrameAtMs
                val firstFrameAgeMs = if (firstVideoFrameAtMs <= 0L) 0L else now - firstVideoFrameAtMs

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
                    recoverFromRendererStall()
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

    private fun recoverFromRendererStall() {
        val p = player ?: return
        if (stallRecoveries >= 2) return
        stallRecoveries += 1
        val currentPosition = p.currentPosition
        handler.post {
            try {
                Log.w(
                    "ExoPlayerView#$viewId",
                    "surfaceRebind position=${currentPosition / 1000.0} recoveryAttempt=$stallRecoveries"
                )
                didRenderFirstFrame = false
                pendingRevealRunnable?.let(handler::removeCallbacks)
                pendingRevealRunnable = null
                playerView.animate().cancel()
                playerView.alpha = 0f
                sendEvent(
                    mapOf(
                        "event" to "surfaceRebind",
                        "position" to (currentPosition / 1000.0),
                        "recoveryAttempt" to stallRecoveries,
                    )
                )
                sendEvent(mapOf("event" to "surfaceDetached"))
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

    private fun sendEvent(data: Map<String, Any>) {
        handler.post {
            eventSink?.success(data)
        }
    }

    private fun resetSurfaceVisibility() {
        if (!forceFullscreen) {
            // Feed kartlarında poster zaten ilk frame gelene kadar üstte tutuluyor.
            // Native view'i her load'ta tekrar alpha=0'a çekmek ikinci siyah dalga
            // üretiyor. Non-fullscreen akışta görünürlük reseti yapma.
            handler.post {
                pendingRevealRunnable?.let(handler::removeCallbacks)
                pendingRevealRunnable = null
                playerView.animate().cancel()
                playerView.alpha = 1f
            }
            return
        }
        handler.post {
            pendingRevealRunnable?.let(handler::removeCallbacks)
            pendingRevealRunnable = null
            playerView.animate().cancel()
            playerView.alpha = 0f
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
        handler.post {
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
        }
    }

    private fun releasePlayer(fully: Boolean) {
        stopPositionUpdates()
        stopStallWatchdog()
        player?.pause()
        resetSurfaceVisibility()
        isSmokeRegistryActive = false
        ExoPlayerSmokeRegistry.clear(context, smokeMonitor)
        if (fully) {
            smokeProbe?.detach()
            smokeProbe = null
            player?.release()
            player = null
            currentUrl = null
            isSoftHeld = false
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
