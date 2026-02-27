package dev.mixin27.mmcalendar

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Boot Receiver for All Widget Types
 *
 * Handles device boot and app update events to ensure all widgets are refreshed
 */
class WidgetBootReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "WidgetBootReceiver"
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        if (context == null || intent == null) {
            Log.w(TAG, "Context or intent is null")
            return
        }

        Log.d(TAG, "Received intent: ${intent.action}")

        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED -> {
                try {
                    Log.d(TAG, "Triggering widget updates after boot/update event")
                    WidgetUpdateBroadcaster.updateAllWidgets(
                        context,
                        intent.action ?: "unknown_action",
                    )
                } catch (e: Exception) {
                    Log.e(TAG, "Error updating widgets", e)
                }
            }
        }
    }
}
