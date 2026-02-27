package dev.mixin27.mmcalendar

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.util.Log

object WidgetUpdateBroadcaster {
    private const val TAG = "WidgetUpdateBroadcaster"

    private val widgetProviders = listOf(
        CompactDateWidgetProvider::class.java,
        FullCalendarWidgetProvider::class.java,
        MoonPhaseWidgetProvider::class.java,
        MyanmarMonthWidgetProvider::class.java,
    )

    fun updateAllWidgets(context: Context, reason: String) {
        val appWidgetManager = AppWidgetManager.getInstance(context)
        var totalWidgets = 0

        widgetProviders.forEach { providerClass ->
            try {
                val componentName = ComponentName(context, providerClass)
                val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)

                if (appWidgetIds.isNotEmpty()) {
                    totalWidgets += appWidgetIds.size
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

        Log.d(TAG, "Updated $totalWidgets widgets ($reason)")
    }
}
