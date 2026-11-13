package dev.mixin27.mmcalendar

import android.app.Application
import android.content.SharedPreferences
import dev.mixin27.mmcalendar.watch.MidnightRefresh
import dev.mixin27.mmcalendar.watch.WatchPayload
import dev.mixin27.mmcalendar.watch.WatchRefresh

/**
 * Refreshes the Tile and complications whenever Dart writes a new payload,
 * from the app or from its daily Workmanager task (both run in this
 * process), and keeps the midnight refresh scheduled.
 */
class WatchApplication : Application() {
    // SharedPreferences holds listeners weakly, so keep this one here.
    private val payloadListener =
        SharedPreferences.OnSharedPreferenceChangeListener { _, key ->
            if (key == WatchPayload.PREF_KEY) WatchRefresh.requestAll(this)
        }

    override fun onCreate() {
        super.onCreate()
        WatchPayload.preferences(this).registerOnSharedPreferenceChangeListener(payloadListener)
        MidnightRefresh.schedule(this)
    }
}
