package com.turqapp.app.qa

/**
 * Visible feed player için en son aktif smoke monitor'ı tutar.
 *
 * Amaç:
 * - Espresso testinin gerçek aktif player truth state'ini okuyabilmesi
 * - App kodunda minimum entegrasyonla çalışmak
 */
object ExoPlayerSmokeRegistry {
    @Volatile
    private var activeMonitor: PlaybackHealthMonitor? = null

    fun register(monitor: PlaybackHealthMonitor) {
        activeMonitor = monitor
    }

    fun clear(monitor: PlaybackHealthMonitor) {
        if (activeMonitor === monitor) {
            activeMonitor = null
        }
    }

    fun requireActiveMonitor(): PlaybackHealthMonitor {
        return requireNotNull(activeMonitor) {
            "No active PlaybackHealthMonitor registered."
        }
    }
}
