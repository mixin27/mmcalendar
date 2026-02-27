package dev.mixin27.mmcalendar

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class WidgetDateChangeReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "WidgetDateChangeReceiver"
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        if (context == null || intent == null) {
            return
        }

        when (intent.action) {
            Intent.ACTION_DATE_CHANGED,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED,
            Intent.ACTION_LOCALE_CHANGED -> {
                Log.d(TAG, "Received ${intent.action}; refreshing widgets")
                WidgetUpdateBroadcaster.updateAllWidgets(
                    context,
                    intent.action ?: "unknown_action",
                )
            }
        }
    }
}
