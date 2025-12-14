package dev.mixin27.mmcalendar

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import androidx.core.graphics.toColorInt
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Compact Date Widget Provider (2x1 or 2x2)
 *
 * Purpose: Minimal Myanmar date display for maximum screen real estate
 * Features:
 * - Myanmar date (primary)
 * - Western date (small, top)
 * - Today indicator
 * - Clean, readable design
 */
class CompactDateWidgetProvider : HomeWidgetProvider() {
    companion object {
        private const val TAG = "CompactDateWidget"
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        Log.d(TAG, "onUpdate called for ${appWidgetIds.size} compact widgets")
        appWidgetIds.forEach { widgetId ->
            updateWidget(context, appWidgetManager, widgetId, widgetData)
        }
    }

    private fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        widgetId: Int,
        widgetData: SharedPreferences
    ) {
        try {
            Log.d(TAG, "Updating compact widget $widgetId")

            val views = RemoteViews(context.packageName, R.layout.widget_layout_compact)

            // Read data
            val myanmarDate = widgetData.getString("myanmar_date", "") ?: ""
            val westernDate = widgetData.getString("western_date", "") ?: ""
            val theme = widgetData.getString("widget_theme", "light") ?: "light"

            // Parse Western date
            val (day, month) = parseWesternDate(westernDate)

            // Update Western date (compact format)
            views.setTextViewText(R.id.western_day, day)
            views.setTextViewText(R.id.western_month, month)

            // Update Myanmar date
            views.setTextViewText(R.id.myanmar_date, myanmarDate)

            // Check if today
            val isToday = isToday(widgetData)
            views.setViewVisibility(
                R.id.today_indicator,
                if (isToday) View.VISIBLE else View.GONE
            )

            // Apply theme
            applyTheme(views, theme)

            // Set up click handler
            setupClickHandler(context, views, widgetId)

            // Update widget
            appWidgetManager.updateAppWidget(widgetId, views)
            Log.d(TAG, "Compact widget $widgetId updated successfully")

        } catch (e: Exception) {
            Log.e(TAG, "Error updating compact widget $widgetId", e)
        }
    }

    private fun parseWesternDate(westernDate: String): Pair<String, String> {
        return try {
            // Expected format: "12 December 2024"
            val parts = westernDate.split(" ")
            if (parts.size >= 2) {
                val day = parts[0]
                val month = parts[1]
                // val month = parts[1].take(3).uppercase() // "DEC"
                Pair(day, month)
            } else {
                Pair("--", "---")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error parsing western date: $westernDate", e)
            Pair("--", "---")
        }
    }

    private fun isToday(widgetData: SharedPreferences): Boolean {
        // Simple check: if last_updated is today
        val lastUpdated = widgetData.getString("last_updated", "") ?: ""
        // You could parse and compare dates here
        // For now, we'll assume the widget shows today if it was updated recently
        return lastUpdated.isNotEmpty()
    }

    private fun applyTheme(views: RemoteViews, theme: String) {

        val textColor = when (theme) {
            "light" -> "#1A1A1A"
            "auto" -> "#1A1A1A"
            else -> "#FFFFFF"
        }

        val secondaryTextColor = when (theme) {
            "light" -> "#666666"
            "auto" -> "#666666"
            else -> "#B0B0B0"
        }

        val bgDrawable = when (theme) {
            "dark" -> R.drawable.widget_background_dark
            "traditional" -> R.drawable.widget_background_traditional
            "gradientBlue" -> R.drawable.widget_background_gradient_blue
            "gradientPurple" -> R.drawable.widget_background_gradient_purple
            "gradientTeal" -> R.drawable.widget_background_gradient_teal
            else -> R.drawable.widget_bg_compact
        }

        views.setInt(R.id.widget_root, "setBackgroundResource", bgDrawable)
        views.setTextColor(R.id.western_day, textColor.toColorInt())
        views.setTextColor(R.id.western_month, secondaryTextColor.toColorInt())
        views.setTextColor(R.id.myanmar_date, textColor.toColorInt())
    }

    private fun setupClickHandler(
        context: Context,
        views: RemoteViews,
        widgetId: Int
    ) {
        try {
            val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            if (launchIntent != null) {
                launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                launchIntent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
                launchIntent.putExtra("opened_from_widget", true)
                launchIntent.putExtra("widget_id", widgetId)
                launchIntent.putExtra("widget_type", "compact")

                val flags = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S) {
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                } else {
                    PendingIntent.FLAG_UPDATE_CURRENT
                }

                val pendingIntent = PendingIntent.getActivity(
                    context,
                    widgetId,
                    launchIntent,
                    flags
                )

                views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error setting up click handler", e)
        }
    }

}