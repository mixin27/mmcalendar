package dev.mixin27.mmcalendar

import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.ComponentName
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

        // List of all widget provider classes
        private val WIDGET_PROVIDERS = listOf(
            CompactDateWidgetProvider::class.java,
            FullCalendarWidgetProvider::class.java,
            MoonPhaseWidgetProvider::class.java,
            MonthlyCalendarWidgetProvider::class.java,
            AppHomeWidgetProvider::class.java // Legacy provider
        )
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        if (context == null || intent == null) {
            Log.w(TAG, "Context or intent is null")
            return
        }

        Log.d(TAG, "Received intent: ${intent.action}")

        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            "android.appwidget.action.APPWIDGET_UPDATE" -> {
                try {
                    Log.d(TAG, "Triggering widget updates after boot/update")
                    updateAllWidgets(context)
                } catch (e: Exception) {
                    Log.e(TAG, "Error updating widgets", e)
                }
            }
        }
    }

    /**
     * Update all installed widgets across all providers
     */
    private fun updateAllWidgets(context: Context) {
        val appWidgetManager = AppWidgetManager.getInstance(context)
        var totalWidgets = 0

        WIDGET_PROVIDERS.forEach { providerClass ->
            try {
                val componentName = ComponentName(context, providerClass)
                val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)

                if (appWidgetIds.isNotEmpty()) {
                    Log.d(TAG, "Found ${appWidgetIds.size} widgets for ${providerClass.simpleName}")
                    totalWidgets += appWidgetIds.size

                    // Send update broadcast to specific provider
                    val updateIntent = Intent(context, providerClass).apply {
                        action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                        putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, appWidgetIds)
                    }
                    context.sendBroadcast(updateIntent)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error updating ${providerClass.simpleName}", e)
            }
        }

        Log.d(TAG, "Total widgets updated: $totalWidgets")

        if (totalWidgets == 0) {
            Log.d(TAG, "No widgets installed")
        }
    }
}