package com.turqapp.app

import com.turqapp.app.qa.PlaybackHealthStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        PlaybackHealthStore.installStatusLabel(this)
        ExoPlayerPlugin.registerWith(flutterEngine, applicationContext)
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
}
