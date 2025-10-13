package dev.mixin27.mmcalendar

import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.util.Log

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
            Intent.ACTION_MY_PACKAGE_REPLACED,
            "android.appwidget.action.APPWIDGET_UPDATE" -> {
                try {
                    Log.d(TAG, "Triggering widget update after boot/update")

                    val appWidgetManager = AppWidgetManager.getInstance(context)
                    val componentName = ComponentName(context, AppHomeWidgetProvider::class.java)
                    val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)

                    Log.d(TAG, "Found ${appWidgetIds.size} widgets to update")

                    if (appWidgetIds.isNotEmpty()) {
                        val updateIntent = Intent(context, AppHomeWidgetProvider::class.java).apply {
                            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                            putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, appWidgetIds)
                        }
                        context.sendBroadcast(updateIntent)
                        Log.d(TAG, "Widget update broadcast sent")
                    } else {
                        Log.d(TAG, "No widgets installed")
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Error updating widgets", e)
                }
            }
        }
    }
}