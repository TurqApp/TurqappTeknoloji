package com.turqapp.app

import android.content.Intent
import com.turqapp.app.qa.PlaybackHealthStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var initialDeepLink: String? = null
    private var pendingDeepLink: String? = null
    private var deepLinkEventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        PlaybackHealthStore.installStatusLabel(this)
        ExoPlayerPlugin.registerWith(flutterEngine, applicationContext)
        configureDeepLinkBridge(flutterEngine)
    }

    override fun onResume() {
        super.onResume()
        PlaybackHealthStore.installStatusLabel(this)
        PlaybackHealthStore.dispatchAppForegrounded(applicationContext)
        ExoPlayerPlugin.instance?.handleAppForegrounded()
    }

    override fun onPause() {
        ExoPlayerPlugin.instance?.handleAppBackgrounded()
        PlaybackHealthStore.dispatchAppBackgrounded(applicationContext)
        super.onPause()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        dispatchDeepLink(intent)
    }

    private fun configureDeepLinkBridge(flutterEngine: FlutterEngine) {
        initialDeepLink = extractDeepLink(intent)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        MethodChannel(messenger, "turqapp.deep_link/method")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInitialLink" -> {
                        val link = initialDeepLink ?: pendingDeepLink
                        initialDeepLink = null
                        pendingDeepLink = null
                        result.success(link)
                    }
                    else -> result.notImplemented()
                }
            }
        EventChannel(messenger, "turqapp.deep_link/events")
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    deepLinkEventSink = events
                    val pending = pendingDeepLink
                    if (!pending.isNullOrBlank()) {
                        events?.success(pending)
                        pendingDeepLink = null
                    }
                }

                override fun onCancel(arguments: Any?) {
                    deepLinkEventSink = null
                }
            })
    }

    private fun dispatchDeepLink(intent: Intent?) {
        val link = extractDeepLink(intent) ?: return
        val sink = deepLinkEventSink
        if (sink != null) {
            sink.success(link)
            return
        }
        pendingDeepLink = link
    }

    private fun extractDeepLink(intent: Intent?): String? {
        val link = intent?.dataString?.trim() ?: return null
        if (link.isEmpty()) return null
        return link
    }
}
