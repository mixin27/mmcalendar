package dev.mixin27.mmcalendar

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.util.Log
import dev.mixin27.mmcalendar.widgets.AgendaWidgetReceiver
import dev.mixin27.mmcalendar.widgets.AstrologyWidgetReceiver
import dev.mixin27.mmcalendar.widgets.ComingUpWidgetReceiver
import dev.mixin27.mmcalendar.widgets.CountdownWidgetReceiver
import dev.mixin27.mmcalendar.widgets.MonthWidgetReceiver
import dev.mixin27.mmcalendar.widgets.MoonWidgetReceiver
import dev.mixin27.mmcalendar.widgets.TodayWidgetReceiver
import dev.mixin27.mmcalendar.widgets.WeekWidgetReceiver
import dev.mixin27.mmcalendar.widgets.YearWidgetReceiver

object WidgetUpdateBroadcaster {
    private const val TAG = "WidgetUpdateBroadcaster"

    private val widgetReceivers = listOf(
        TodayWidgetReceiver::class.java,
        MoonWidgetReceiver::class.java,
        MonthWidgetReceiver::class.java,
        WeekWidgetReceiver::class.java,
        ComingUpWidgetReceiver::class.java,
        AgendaWidgetReceiver::class.java,
        CountdownWidgetReceiver::class.java,
        AstrologyWidgetReceiver::class.java,
        YearWidgetReceiver::class.java,
    )

    fun updateAllWidgets(context: Context, reason: String) {
        val appWidgetManager = AppWidgetManager.getInstance(context)
        var totalWidgets = 0

        widgetReceivers.forEach { receiverClass ->
            try {
                val componentName = ComponentName(context, receiverClass)
                val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)

                if (appWidgetIds.isNotEmpty()) {
                    totalWidgets += appWidgetIds.size
                    val updateIntent = Intent(context, receiverClass).apply {
                        action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                        putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, appWidgetIds)
                    }
                    context.sendBroadcast(updateIntent)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error updating ${receiverClass.simpleName}", e)
            }
        }

        Log.d(TAG, "Updated $totalWidgets widgets ($reason)")
    }
}
