package com.turqapp.app.qa

import android.content.Context
import android.content.Intent
import android.os.SystemClock
import android.util.Log
import androidx.recyclerview.widget.RecyclerView
import androidx.test.core.app.ApplicationProvider
import androidx.test.espresso.Espresso.onView
import androidx.test.espresso.NoMatchingViewException
import androidx.test.espresso.ViewAction
import androidx.test.espresso.action.ViewActions.click
import androidx.test.espresso.action.ViewActions.swipeDown
import androidx.test.espresso.action.ViewActions.swipeUp
import androidx.test.espresso.assertion.ViewAssertions.matches
import androidx.test.espresso.contrib.RecyclerViewActions
import androidx.test.espresso.matcher.ViewMatchers.isDisplayed
import androidx.test.espresso.matcher.ViewMatchers.withId
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.filters.LargeTest
import androidx.test.platform.app.InstrumentationRegistry
import androidx.test.uiautomator.UiDevice
import com.turqapp.app.MainActivity
import org.hamcrest.Matcher
import org.junit.After
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Production-friendly ExoPlayer feed smoke example.
 *
 * Bu test UI tarafında gerçek feed davranışını zorlar.
 * App-specific entegrasyon noktaları:
 * - feed RecyclerView id'si
 * - fullscreen button id'si
 * - görünür hücre bind'inde ExoPlayerPlaybackProbe bağlı olması
 * - playback hata listesinin test tarafından okunabilir olması
 */
@RunWith(AndroidJUnit4::class)
@LargeTest
class ExoPlayerFeedSmokeTest {

    private val device: UiDevice by lazy {
        UiDevice.getInstance(InstrumentationRegistry.getInstrumentation())
    }

    @Before
    fun setup() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        val intent = Intent(context, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TASK or Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        context.startActivity(intent)
        device.waitForIdle()
    }

    @After
    fun tearDown() {
        device.pressHome()
    }

    @Test
    fun feedPlaybackSmoke_detectsCriticalExoPlayerFailures() {
        waitForViewId("feedTab", timeoutMs = 5_000L)
        maybeTap("feedTab")

        val feedRecyclerViewId = resolveId("feedRecyclerView")
        onView(withId(feedRecyclerViewId)).check(matches(isDisplayed()))

        // İlk autoplay için kısa bekleme.
        waitForPlaybackWarmup()

        // Gerçek projede bu veri bir singleton/registry üzerinden okunmalı.
        // Burada placeholder olarak app seviyesinde expose edildiği varsayılıyor.
        val monitor = ExoPlayerSmokeRegistry.requireActiveMonitor()
        waitUntilNoCriticalFirstFrameIssue(monitor, timeoutMs = 2_000L)

        // İlk videoda kısa bekleme.
        SystemClock.sleep(1_500L)

        // 5 video hızlı geçiş.
        repeat(5) { index ->
            onView(withId(feedRecyclerViewId))
                .perform(RecyclerViewActions.scrollToPosition<RecyclerView.ViewHolder>(index + 1))
            performFastSwipeOnFeed(feedRecyclerViewId)
            SystemClock.sleep(450L)
        }

        // Dur ve visible video autoplay bekle.
        SystemClock.sleep(2_000L)
        assertNoCriticalErrors(monitor, stage = "after_scroll")

        // Fullscreen aç.
        maybeTap("fullscreenButton")
        monitor.onFullscreenTransitionStarted()
        SystemClock.sleep(2_000L)
        monitor.onFullscreenTransitionEnded()
        assertNoCriticalErrors(monitor, stage = "fullscreen")

        // Geri çık.
        device.pressBack()
        SystemClock.sleep(1_200L)

        // Arka plan / ön plan.
        device.pressHome()
        SystemClock.sleep(1_000L)
        val context = ApplicationProvider.getApplicationContext<Context>()
        val relaunch = Intent(context, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        context.startActivity(relaunch)
        SystemClock.sleep(2_000L)

        // Son durum.
        assertNoCriticalErrors(monitor, stage = "resume")
    }

    private fun waitUntilNoCriticalFirstFrameIssue(
        monitor: PlaybackHealthMonitor,
        timeoutMs: Long,
    ) {
        val deadline = SystemClock.elapsedRealtime() + timeoutMs
        while (SystemClock.elapsedRealtime() < deadline) {
            val errors = monitor.getErrors()
            if (!errors.contains("FIRST_FRAME_TIMEOUT") &&
                !errors.contains("READY_WITHOUT_FRAME")
            ) {
                if (monitor.firstFrameRendered) {
                    return
                }
            }
            SystemClock.sleep(120L)
        }
        failWithMonitor("Initial autoplay failed first-frame checks", monitor)
    }

    private fun assertNoCriticalErrors(
        monitor: PlaybackHealthMonitor,
        stage: String,
    ) {
        val critical = monitor.getErrors().filter {
            it == "FIRST_FRAME_TIMEOUT" ||
                it == "READY_WITHOUT_FRAME" ||
                it == "VIDEO_FREEZE" ||
                it == "PLAYBACK_NOT_STARTED" ||
                it == "FULLSCREEN_INTERRUPTION"
        }
        assertTrue(
            "Critical playback errors at $stage: $critical snapshot=${monitor.snapshot()}",
            critical.isEmpty(),
        )
    }

    private fun waitForPlaybackWarmup() {
        SystemClock.sleep(1_500L)
    }

    private fun performFastSwipeOnFeed(feedRecyclerViewId: Int) {
        onView(withId(feedRecyclerViewId)).perform(swipeUp())
    }

    private fun waitForViewId(name: String, timeoutMs: Long) {
        val id = resolveId(name)
        val deadline = SystemClock.elapsedRealtime() + timeoutMs
        while (SystemClock.elapsedRealtime() < deadline) {
            try {
                onView(withId(id)).check(matches(isDisplayed()))
                return
            } catch (_: Throwable) {
                SystemClock.sleep(120L)
            }
        }
        throw AssertionError("View not found within timeout: $name")
    }

    private fun maybeTap(name: String) {
        val id = resolveId(name)
        try {
            onView(withId(id)).perform(click())
        } catch (_: NoMatchingViewException) {
            Log.d("ExoPlayerFeedSmokeTest", "optional tap skipped for $name")
        } catch (_: Throwable) {
        }
    }

    private fun resolveId(name: String): Int {
        val context = ApplicationProvider.getApplicationContext<Context>()
        return context.resources.getIdentifier(name, "id", context.packageName)
            .takeIf { it != 0 }
            ?: throw IllegalStateException("Missing id resource: $name")
    }

    private fun failWithMonitor(message: String, monitor: PlaybackHealthMonitor): Nothing {
        throw AssertionError("$message snapshot=${monitor.snapshot()} errors=${monitor.getErrors()}")
    }
}
