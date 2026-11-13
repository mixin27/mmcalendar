package dev.mixin27.mmcalendar.watch

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import java.time.LocalDate
import java.time.ZoneId

/**
 * Redraws the Tile and complications just after midnight. Both also carry
 * tomorrow in their timelines, so this is the backstop; an inexact alarm
 * needs no exact-alarm permission.
 */
object MidnightRefresh {
    const val ACTION = "dev.mixin27.mmcalendar.MIDNIGHT_REFRESH"

    /** Milliseconds since the epoch of the next local midnight. */
    fun nextMidnight(): Long =
        LocalDate.now().plusDays(1).atStartOfDay(ZoneId.systemDefault()).toInstant().toEpochMilli()

    fun schedule(context: Context) {
        val alarms = context.getSystemService(AlarmManager::class.java) ?: return
        alarms.setWindow(
            AlarmManager.RTC,
            nextMidnight() + 5_000,
            10 * 60_000,
            pendingIntent(context),
        )
    }

    private fun pendingIntent(context: Context): PendingIntent =
        PendingIntent.getBroadcast(
            context,
            0,
            Intent(context, MidnightReceiver::class.java).setAction(ACTION),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
}

/** Midnight, boot, an app update, or the clock or time zone changing. */
class MidnightReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        WatchRefresh.requestAll(context)
        MidnightRefresh.schedule(context)
    }
}
