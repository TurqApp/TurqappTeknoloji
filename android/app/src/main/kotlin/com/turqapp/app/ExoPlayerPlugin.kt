package com.turqapp.app

import android.content.Context
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject

class ExoPlayerPlugin private constructor(
    private val methodChannel: MethodChannel
) : MethodChannel.MethodCallHandler {

    companion object {
        var instance: ExoPlayerPlugin? = null
            private set
        private lateinit var applicationContext: Context
        internal fun appContext(): Context = applicationContext

        fun registerWith(flutterEngine: FlutterEngine, appContext: Context) {
            val messenger = flutterEngine.dartExecutor.binaryMessenger
            applicationContext = appContext

            val channel = MethodChannel(messenger, "turqapp.hls_player/method")
            val plugin = ExoPlayerPlugin(channel)
            channel.setMethodCallHandler(plugin)
            instance = plugin

            val factory = ExoPlayerFactory(messenger)
            flutterEngine.platformViewsController.registry.registerViewFactory(
                "turqapp.hls_player/view",
                factory
            )
        }
    }

    private val playerViews = mutableMapOf<Long, ExoPlayerView>()

    fun registerView(viewId: Long, view: ExoPlayerView) {
        playerViews[viewId] = view
    }

    fun handleAppBackgrounded() {
        playerViews.values.toList().forEach { it.onAppBackgrounded() }
    }

    fun handleAppForegrounded() {
        playerViews.values.toList().forEach { it.onAppForegrounded() }
    }

    private fun handleDisposeAllPlayers(result: MethodChannel.Result) {
        val views = playerViews.values.toList()
        playerViews.clear()
        views.forEach { it.dispose() }
        result.success(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val args = call.arguments as? Map<String, Any>
        if (call.method == "getActiveSmokeSnapshot") {
            result.success(ExoPlayerSmokeBridge.readActiveSnapshot())
            return
        }
        if (call.method == "disposeAllPlayers") {
            handleDisposeAllPlayers(result)
            return
        }

        val viewId = (args?.get("viewId") as? Number)?.toLong()

        if (viewId == null) {
            result.error("INVALID_ARGUMENTS", "viewId is required", null)
            return
        }

        val view = playerViews[viewId]
        if (view == null && call.method != "dispose") {
            result.error("VIEW_NOT_FOUND", "No player view for viewId $viewId", null)
            return
        }

        when (call.method) {
            "loadVideo" -> {
                val url = args?.get("url") as? String
                val autoPlay = args?.get("autoPlay") as? Boolean ?: true
                val loop = args?.get("loop") as? Boolean ?: false
                val preferResumePoster =
                    args?.get("preferResumePoster") as? Boolean
                if (url != null) {
                    view!!.loadVideo(
                        url,
                        autoPlay,
                        loop,
                        preferResumePosterOverride = preferResumePoster,
                    )
                    result.success(null)
                } else {
                    result.error("INVALID_ARGUMENTS", "url is required", null)
                }
            }
            "play" -> {
                view!!.play()
                result.success(null)
            }
            "pause" -> {
                view!!.pause()
                result.success(null)
            }
            "softHold" -> {
                view!!.softHold()
                result.success(null)
            }
            "seek" -> {
                val seconds = (args?.get("seconds") as? Number)?.toDouble() ?: 0.0
                view!!.seek(seconds)
                result.success(null)
            }
            "setMuted" -> {
                val muted = args?.get("muted") as? Boolean ?: false
                view!!.setMuted(muted)
                result.success(null)
            }
            "setVolume" -> {
                val volume = (args?.get("volume") as? Number)?.toFloat() ?: 1.0f
                view!!.setVolume(volume)
                result.success(null)
            }
            "setLoop" -> {
                val loop = args?.get("loop") as? Boolean ?: false
                view!!.setLoop(loop)
                result.success(null)
            }
            "setAutoplayIntent" -> {
                val autoPlay = args?.get("autoPlay") as? Boolean ?: false
                view!!.setAutoplayIntent(autoPlay)
                result.success(null)
            }
            "getCurrentTime" -> {
                result.success(view!!.getCurrentTime())
            }
            "getDuration" -> {
                result.success(view!!.getDuration())
            }
            "isMuted" -> {
                result.success(view!!.isMuted())
            }
            "isPlaying" -> {
                result.success(view!!.isPlaying())
            }
            "isBuffering" -> {
                result.success(view!!.isBuffering())
            }
            "getPlaybackDiagnostics" -> {
                result.success(view!!.getPlaybackDiagnostics())
            }
            "getProcessDiagnostics" -> {
                result.success(view!!.getProcessDiagnostics())
            }
            "stopPlayback" -> {
                view!!.stopPlayback()
                result.success(null)
            }
            "setPreferredBufferDuration" -> {
                // Dart saniye cinsinden gönderiyor, ms'e çevir
                val durationSec = (args?.get("duration") as? Number)?.toDouble() ?: 1.0
                val durationMs = (durationSec * 1000).toLong()
                view!!.setPreferredBufferDuration(durationMs)
                result.success(null)
            }
            "dispose" -> {
                view?.dispose()
                playerViews.remove(viewId)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }
}

private object ExoPlayerSmokeBridge {
    fun readActiveSnapshot(): Map<String, Any?> {
        val snapshot = com.turqapp.app.qa.ExoPlayerSmokeRegistry.readSnapshot(
            ExoPlayerPlugin.appContext()
        )
            ?: return mapOf(
                "supported" to true,
                "active" to false,
                "firstFrameRendered" to false,
                "errors" to emptyList<String>(),
                "raw" to "",
            )
        return mapOf(
            "supported" to true,
            "active" to snapshot.active,
            "status" to snapshot.status,
            "firstFrameRendered" to snapshot.firstFrameRendered,
            "errors" to snapshot.errors,
            "snapshot" to snapshot.snapshot.mapValues { (_, value) -> codecSafe(value) },
            "raw" to snapshot.raw,
        )
    }

    private fun codecSafe(value: Any?): Any? {
        return when (value) {
            null -> null
            is JSONObject -> value.keys().asSequence().associateWith { key ->
                codecSafe(value.opt(key))
            }
            is JSONArray -> List(value.length()) { index ->
                codecSafe(value.opt(index))
            }
            is Map<*, *> -> value.entries.associate { (key, nestedValue) ->
                key.toString() to codecSafe(nestedValue)
            }
            is Iterable<*> -> value.map { nestedValue -> codecSafe(nestedValue) }
            is Array<*> -> value.map { nestedValue -> codecSafe(nestedValue) }
            else -> value
        }
    }
}
